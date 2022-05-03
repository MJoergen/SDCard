-- This is the CMD controller for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This block includes generation of the 7-bit CRC checksum.
-- Output is changed on falling edge of sd_clk_o. The SDCard samples on rising clock edge.
-- Input is sampled on rising edge of sd_clk_o. The SDCard outputs on falling clock edge.

entity cmd is
   port (
      clk_i           : in  std_logic;
      rst_i           : in  std_logic;
      cmd_i           : in  std_logic_vector(37 downto 0);
      cmd_valid_i     : in  std_logic;
      cmd_ready_o     : out std_logic;
      resp_o          : out std_logic_vector(135 downto 0);
      resp_valid_o    : out std_logic;

      -- SDCard device interface
      sd_clk_i        : in  std_logic;
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

   type state_t is (
      INIT_ST,
      IDLE_ST,
      WRITING_ST,
      SEND_CRC_ST
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

   resp_o <= (others => '0');
   sd_cmd_out <= '1' when state = INIT_ST or state = IDLE_ST else send_dat(39);
   sd_cmd_oe  <= '1' when state = INIT_ST or state = IDLE_ST or state = WRITING_ST else '0';

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

   cmd_ready_o <= '1' when state = IDLE_ST and sd_clk_d = '0' and sd_clk_i = '1' else '0';

   p_fsm : process (clk_i)
      variable inv : std_logic;
   begin
      if rising_edge(clk_i) then
         resp_valid_o <= '0';

         crc <= new_crc(crc, send_dat(39));
--         -- This calculates the 7-bit CRC using the polynomial x^7 + x^3 + x^0.
--         -- See this link: http://www.ghsi.de/pages/subpages/Online%20CRC%20Calculation/indexDetails.php?Polynom=10001001&Message=7700000000
--         inv := send_dat(39) xor crc(6);
--         crc(6) <= crc(5);
--         crc(5) <= crc(4);
--         crc(4) <= crc(3);
--         crc(3) <= crc(2) xor inv;
--         crc(2) <= crc(1);
--         crc(1) <= crc(0);
--         crc(0) <= inv;

         if sd_clk_d = '0' and sd_clk_i = '1' then -- Rising edge of sd_clk_i
            case state is
               when INIT_ST =>
                  if idle_count = 1 then
                     state <= IDLE_ST;
                  end if;
                  idle_count <= idle_count - 1;

               when IDLE_ST =>
                  if cmd_valid_i = '1' then
                     send_dat   <= "01" & cmd_i;
                     send_count <= 39;
                     crc        <= (others => '0');
                     state      <= WRITING_ST;
                  end if;

               when WRITING_ST =>
                  if send_count = 0 then
                     send_dat(39 downto 32) <= crc & "1";
                     send_count             <= 8;
                     state                  <= SEND_CRC_ST;
                  else
                     send_dat   <= send_dat(38 downto 0) & "0";
                     send_count <= send_count - 1;
                  end if;

               when SEND_CRC_ST =>
                  if send_count = 0 then
                     resp_valid_o <= '1';
                     state        <= IDLE_ST;
                  else
                     send_dat   <= send_dat(38 downto 0) & "0";
                     send_count <= send_count - 1;
                  end if;

               when others =>
                  null;
            end case;
         end if;

         if rst_i = '1' then
            idle_count <= 400;
            state      <= INIT_ST;
         end if;
      end if;
   end process p_fsm;

end architecture synthesis;

