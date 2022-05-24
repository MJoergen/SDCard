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

begin

   tx_ready_o   <= '1';
   rx_valid_o   <= '0';

   sd_dat_out_o <= "1111";
   sd_dat_oe_o  <= '0';

end architecture synthesis;

