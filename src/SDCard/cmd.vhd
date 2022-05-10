-- This block sends commands to the SDCard and receives responses.
-- Only one outstanding command is allowed at any time.
-- This module checks for timeout, and always generates a response, when a response is expected.
-- CRC generation is performed on all commands.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sdcard_globals.all;

entity cmd is
   port (
      clk_i          : in  std_logic; -- 50 MHz
      rst_i          : in  std_logic;

      -- Command to send to SDCard
      cmd_valid_i    : in  std_logic;
      cmd_ready_o    : out std_logic;
      cmd_index_i    : in  natural range 0 to 63;
      cmd_data_i     : in  std_logic_vector(31 downto 0);
      cmd_resp_i     : in  natural range 0 to 255;   -- Expected number of bits in response

      -- Response received from SDCard
      resp_valid_o   : out std_logic;
      resp_ready_i   : in  std_logic;
      resp_data_o    : out std_logic_vector(135 downto 0);
      resp_timeout_o : out std_logic;  -- No response received
      resp_error_o   : out std_logic;  -- Reponse with CRC error

      -- SDCard device interface
      sd_clk_i       : in  std_logic; -- 25 MHz or 400 kHz
      sd_cmd_in_i    : in  std_logic;
      sd_cmd_out_o   : out std_logic;
      sd_cmd_oe_o    : out std_logic
   );
end entity cmd;

architecture synthesis of cmd is

   constant IDLE_MAX     : natural := 400;    -- Idle for 1 ms after power-on.
   constant TIMEOUT_MAX  : natural := 4000;   -- Timeout after 10 ms.
   constant COOLDOWN_MAX : natural := 5;      -- Wait a few clock cycles before next command.

   type state_t is (
      INIT_ST,
      IDLE_ST,
      WRITING_ST,
      SEND_CRC_ST,
      WAIT_RESPONSE_ST,
      GET_RESPONSE_ST,
      COOLDOWN_ST
   );

   signal state : state_t := INIT_ST;

   signal idle_count     : natural range 0 to IDLE_MAX;
   signal timeout_count  : natural range 0 to TIMEOUT_MAX;
   signal cooldown_count : natural range 0 to COOLDOWN_MAX;

   signal sd_clk_d       : std_logic;
   signal sd_cmd_oe      : std_logic;
   signal sd_cmd_out     : std_logic;

   signal send_data      : std_logic_vector(39 downto 0);
   signal send_count     : natural range 0 to 39;
   signal crc            : std_logic_vector(6 downto 0);
   signal resp_data      : std_logic_vector(39 downto 0);
   signal resp_count     : natural range 0 to 255;

   -- This calculates the 7-bit CRC using the polynomial x^7 + x^3 + x^0.
   -- See this link: http://www.ghsi.de/pages/subpages/Online%20CRC%20Calculation/indexDetails.php?Polynom=10001001&Message=7700000000
   function new_crc(cur_crc : std_logic_vector; val : std_logic) return std_logic_vector is
      variable inv : std_logic;
      variable upd : std_logic_vector(6 downto 0);
   begin
      inv := val xor cur_crc(6);
      upd := (0 => inv, 3 => inv, others => '0');
      return (cur_crc(5 downto 0) & "0") xor upd;
   end function new_crc;

   attribute mark_debug               : boolean;
   attribute mark_debug of state      : signal is true;
   attribute mark_debug of resp_data  : signal is true;
   attribute mark_debug of resp_count : signal is true;

begin

   cmd_ready_o <= '1' when state = IDLE_ST and sd_clk_d = '0' and sd_clk_i = '1' else '0';

   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if resp_ready_i = '1' then
            resp_valid_o <= '0';
         end if;

         if sd_clk_d = '0' and sd_clk_i = '1' then -- Rising edge of sd_clk_i
            case state is
               when INIT_ST =>
                  if idle_count > 0 then
                     idle_count <= idle_count - 1;
                  elsif resp_valid_o = '0' then
                     state <= IDLE_ST;
                  end if;

               when IDLE_ST =>
                  if cmd_valid_i = '1' then
                     resp_timeout_o <= '0';
                     resp_error_o   <= '0';
                     send_data      <= "01" & std_logic_vector(to_unsigned(cmd_index_i, 6)) & cmd_data_i;
                     send_count     <= 39;   -- Commands are always 40 bits excluding CRC
                     resp_count     <= cmd_resp_i; -- Store expected number of response bits
                     crc            <= (others => '0');
                     state          <= WRITING_ST;
                  end if;

               when WRITING_ST =>
                  if send_count > 0 then
                     send_data  <= send_data(38 downto 0) & "0";
                     send_count <= send_count - 1;
                     crc        <= new_crc(crc, send_data(39));
                  else
                     send_data(39 downto 32) <= new_crc(crc, send_data(39)) & "1";
                     send_count              <= 7;
                     state                   <= SEND_CRC_ST;
                  end if;

               when SEND_CRC_ST =>
                  if send_count > 0 then
                     send_data  <= send_data(38 downto 0) & "0";
                     send_count <= send_count - 1;
                  else
                     if resp_count > 0 then
                        resp_count    <= resp_count - 1;
                        crc           <= (others => '0');
                        timeout_count <= TIMEOUT_MAX;
                        state         <= WAIT_RESPONSE_ST;
                     else
                        cooldown_count <= COOLDOWN_MAX;
                        state          <= COOLDOWN_ST;
                     end if;
                  end if;

               when WAIT_RESPONSE_ST =>
                  if sd_cmd_in_i = '0' then
                     state <= GET_RESPONSE_ST;
                  elsif timeout_count > 0 then
                     timeout_count <= timeout_count - 1;
                  else
                     resp_timeout_o <= '1';
                     resp_valid_o   <= '1';
                     cooldown_count <= COOLDOWN_MAX;
                     state          <= COOLDOWN_ST;
                  end if;

               when GET_RESPONSE_ST =>
                  if resp_count > 8 then
                     crc <= new_crc(crc, sd_cmd_in_i);
                  end if;

                  if resp_count > 0 then
                     resp_data  <= resp_data(38 downto 0) & sd_cmd_in_i;
                     resp_count <= resp_count - 1;
                  else
                     if resp_data(7 downto 0) = crc & "1" or resp_data(7 downto 0) = X"FF" then
                        resp_data_o              <= (others => '0');
                        resp_data_o(31 downto 0) <= resp_data(39 downto 8);
                        resp_valid_o             <= '1';
                        report "Received response 0x" & to_hstring(resp_data(39 downto 8))
                           & " with valid CRC";
                     else
                        resp_error_o <= '1';
                        resp_valid_o <= '1';
                        report "CRC error";
                     end if;
                     cooldown_count <= COOLDOWN_MAX;
                     state          <= COOLDOWN_ST;
                  end if;

               when COOLDOWN_ST =>
                  if cooldown_count > 0 then
                     cooldown_count <= cooldown_count - 1;
                  else
                     state <= IDLE_ST;
                  end if;

            end case;
         end if;

         if rst_i = '1' then
            idle_count <= IDLE_MAX;
            state      <= INIT_ST;
         end if;
      end if;
   end process p_fsm;


   p_sd_cmd : process (all)
   begin
      -- Default is to always drive the CMD high
      sd_cmd_out <= '1';
      sd_cmd_oe  <= '1';

      case state is
         when INIT_ST | IDLE_ST =>
            sd_cmd_out <= '1';
            sd_cmd_oe  <= '1';

         when WRITING_ST | SEND_CRC_ST =>
            sd_cmd_out <= send_data(39);
            sd_cmd_oe  <= '1';

         when WAIT_RESPONSE_ST | GET_RESPONSE_ST | COOLDOWN_ST =>
            sd_cmd_out <= '0';
            sd_cmd_oe  <= '0';

      end case;
   end process p_sd_cmd;


   -- Output is changed on falling edge of clk. The SDCard samples on rising clock edge.
   p_out : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sd_clk_d <= sd_clk_i;
         if sd_clk_d = '1' and sd_clk_i = '0' then -- Falling edge of sd_clk_i
            sd_cmd_oe_o <= sd_cmd_oe;
            if sd_cmd_oe = '1' then
               sd_cmd_out_o <= sd_cmd_out;
            else
               sd_cmd_out_o <= 'Z';
            end if;
         end if;
      end if;
   end process p_out;

end architecture synthesis;

