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

entity dat is
   port (
      clk_i        : in  std_logic; -- 50 MHz
      rst_i        : in  std_logic;

      -- Command to send to SDCard
      tx_valid_i   : in  std_logic;
      tx_ready_o   : out std_logic;
      tx_data_i    : in  std_logic_vector(7 downto 0);
      tx_last_i    : in  std_logic;

      -- Response received from SDCard
      rx_valid_o   : out std_logic;
      rx_ready_i   : in  std_logic;
      rx_data_o    : out std_logic_vector(7 downto 0);
      rx_last_o    : out std_logic;

      -- SDCard device interface
      sd_clk_i     : in  std_logic; -- 25 MHz or 400 kHz
      sd_dat_in_i  : in  std_logic_vector(3 downto 0);
      sd_dat_out_o : out std_logic_vector(3 downto 0);
      sd_dat_oe_o  : out std_logic
   );
end entity dat;

architecture synthesis of dat is

   constant RX_COUNT_MAX : natural := 1024+16;

   signal sd_clk_d : std_logic;

   signal rx_count : natural range 0 to RX_COUNT_MAX;
   signal crc0     : std_logic_vector(15 downto 0);
   signal crc1     : std_logic_vector(15 downto 0);
   signal crc2     : std_logic_vector(15 downto 0);
   signal crc3     : std_logic_vector(15 downto 0);

   -- This calculates the 16-bit CRC using the polynomial x^16 + x^12 + x^5 + x^0.
   -- See this link: http://www.ghsi.de/pages/subpages/Online%20CRC%20Calculation/indexDetails.php?Polynom=10001001&Message=7700000000
   function new_crc(cur_crc : std_logic_vector; val : std_logic) return std_logic_vector is
      variable inv : std_logic;
      variable upd : std_logic_vector(15 downto 0);
   begin
      inv := val xor cur_crc(15);
      upd := (0 => inv, 5 => inv, 12 => inv, others => '0');
      return (cur_crc(14 downto 0) & "0") xor upd;
   end function new_crc;

   type state_t is (
      IDLE_ST,
      RX_ST
   );

   signal state : state_t := IDLE_ST;

   attribute mark_debug                 : boolean;
   attribute mark_debug of sd_dat_in_i  : signal is true;
   attribute mark_debug of sd_dat_out_o : signal is true;
   attribute mark_debug of sd_dat_oe_o  : signal is true;
   attribute mark_debug of crc0         : signal is true;
   attribute mark_debug of crc1         : signal is true;
   attribute mark_debug of crc2         : signal is true;
   attribute mark_debug of crc3         : signal is true;
   attribute mark_debug of state        : signal is true;
   attribute mark_debug of rx_count     : signal is true;

begin

   tx_ready_o <= '1';
   rx_valid_o <= '0';

   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if sd_clk_d = '0' and sd_clk_i = '1' then -- Rising edge of sd_clk_i
            case state is
               when IDLE_ST =>
                  if sd_dat_in_i = "0000" then
                     rx_count <= RX_COUNT_MAX;
                     crc0     <= (others => '0');
                     crc1     <= (others => '0');
                     crc2     <= (others => '0');
                     crc3     <= (others => '0');
                     state    <= RX_ST;
                  end if;

               when RX_ST =>
                  if rx_count > 16 then
                     crc0 <= new_crc(crc0, sd_dat_in_i(0));
                     crc1 <= new_crc(crc1, sd_dat_in_i(1));
                     crc2 <= new_crc(crc2, sd_dat_in_i(2));
                     crc3 <= new_crc(crc3, sd_dat_in_i(3));
                  end if;

                  if rx_count > 0 then
                     rx_count <= rx_count - 1;
                  end if;
            end case;
         end if;

         if rst_i = '1' then
            state <= IDLE_ST;
         end if;
      end if;
   end process p_fsm;

   -- Output is changed on falling edge of clk. The SDCard samples on rising clock edge.
   p_out : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sd_clk_d <= sd_clk_i;
         if sd_clk_d = '1' and sd_clk_i = '0' then -- Falling edge of sd_clk_i
            sd_dat_out_o <= "1111";
            sd_dat_oe_o  <= '0';
         end if;
      end if;
   end process p_out;

end architecture synthesis;

