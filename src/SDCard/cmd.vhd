-- This is the CMD controller for the complete SDCard controller.
-- This block includes generation of the 7-bit CRC checksum.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sdcard_globals.all;

entity cmd is
   port (
      clk_i           : in  std_logic; -- 50 MHz
      rst_i           : in  std_logic;
      cmd_index_i     : in  natural range 0 to 63;
      cmd_dat_i       : in  std_logic_vector(31 downto 0);
      cmd_valid_i     : in  std_logic;
      cmd_ready_o     : out std_logic;
      resp_o          : out std_logic_vector(135 downto 0);
      resp_valid_o    : out std_logic;

      -- SDCard device interface
      sd_clk_i        : in  std_logic; -- 25 MHz or 400 kHz
      sd_cmd_in_i     : in  std_logic;
      sd_cmd_out_o    : out std_logic;
      sd_cmd_oe_o     : out std_logic
   );
end entity cmd;

architecture synthesis of cmd is

   signal sd_clk_d   : std_logic;
   signal sd_cmd_oe  : std_logic;
   signal sd_cmd_out : std_logic;

   signal idle_count : natural range 0 to 400;  -- 1 msec @ 400 kHz

   signal send_dat   : std_logic_vector(39 downto 0);
   signal send_count : natural range 0 to 39;
   signal crc        : std_logic_vector(6 downto 0);
   signal resp_dat   : std_logic_vector(39 downto 0);
   signal resp_count : natural range 0 to 47;

   type state_t is (
      INIT_ST,
      IDLE_ST,
      WRITING_ST,
      SEND_CRC_ST,
      WAIT_RESPONSE_ST,
      GET_RESPONSE_ST
   );

   signal state : state_t := INIT_ST;

   -- This calculates the 7-bit CRC using the polynomial x^7 + x^3 + x^0.
   -- See this link: http://www.ghsi.de/pages/subpages/Online%20CRC%20Calculation/indexDetails.php?Polynom=10001001&Message=7700000000
   function new_crc(crc : std_logic_vector; val : std_logic) return std_logic_vector is
      variable inv : std_logic;
      variable upd : std_logic_vector(6 downto 0);
   begin
      inv := val xor crc(6);
      upd := (0 => inv, 3 => inv, others => '0');
      return (crc(5 downto 0) & "0") xor upd;
   end function new_crc;

begin

   cmd_ready_o <= '1' when state = IDLE_ST and sd_clk_d = '0' and sd_clk_i = '1' else '0';

   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         resp_valid_o <= '0';

         if sd_clk_d = '0' and sd_clk_i = '1' then -- Rising edge of sd_clk_i
            case state is
               when INIT_ST =>
                  if idle_count > 0 then
                     idle_count <= idle_count - 1;
                  else
                     state <= IDLE_ST;
                  end if;

               when IDLE_ST =>
                  if cmd_valid_i = '1' then
                     send_dat   <= "01" & std_logic_vector(to_unsigned(cmd_index_i, 6)) & cmd_dat_i;
                     send_count <= 39;
                     crc        <= (others => '0');
                     state      <= WRITING_ST;
                  end if;

               when WRITING_ST =>
                  if send_count > 0 then
                     send_dat   <= send_dat(38 downto 0) & "0";
                     send_count <= send_count - 1;
                     crc        <= new_crc(crc, send_dat(39));
                  else
                     send_dat(39 downto 32) <= new_crc(crc, send_dat(39)) & "1";
                     send_count             <= 7;
                     state                  <= SEND_CRC_ST;
                  end if;

               when SEND_CRC_ST =>
                  if send_count > 0 then
                     send_dat   <= send_dat(38 downto 0) & "0";
                     send_count <= send_count - 1;
                  else
                     resp_count <= 47;
                     crc        <= (others => '0');
                     state      <= WAIT_RESPONSE_ST;
                  end if;

               when WAIT_RESPONSE_ST =>
                  if sd_cmd_in_i = '0' then
                     state   <= GET_RESPONSE_ST;
                  end if;

               when GET_RESPONSE_ST =>
                  if resp_count > 8 then
                     crc <= new_crc(crc, sd_cmd_in_i);
                  end if;

                  if resp_count > 0 then
                     resp_dat   <= resp_dat(38 downto 0) & sd_cmd_in_i;
                     resp_count <= resp_count - 1;
                  else
                     if resp_dat(7 downto 0) = crc & "1" or
                        (resp_dat(7 downto 0) = X"FF" and cmd_index_i = ACMD_SD_SEND_OP_COND) then
                        resp_o              <= (others => '0');
                        resp_o(31 downto 0) <= resp_dat(39 downto 8);
                        resp_valid_o        <= '1';
                        report "Received response 0x" & to_hstring(resp_dat(39 downto 8))
                           & " with valid CRC";
                     end if;
                     state <= IDLE_ST;
                  end if;
            end case;
         end if;

         if rst_i = '1' then
            idle_count <= 400;
            state      <= INIT_ST;
         end if;
      end if;
   end process p_fsm;

   -- Make sure sd_cmd_oe is clear when receiving response
   sd_cmd_out <= '1' when state = INIT_ST
                       or state = IDLE_ST
            else send_dat(39);
   sd_cmd_oe  <= '1' when state = INIT_ST
                       or state = IDLE_ST
                       or state = WRITING_ST
                       or state = SEND_CRC_ST
            else '0';

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

