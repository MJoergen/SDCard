-- This is the host emulator for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity host is
   port (
      avm_clk_i           : in  std_logic;
      avm_rst_i           : in  std_logic;
      avm_write_o         : in  std_logic;
      avm_read_o          : in  std_logic;
      avm_address_o       : in  std_logic_vector(31 downto 0);
      avm_writedata_o     : in  std_logic_vector(7 downto 0);
      avm_burstcount_o    : in  std_logic_vector(8 downto 0);
      avm_readdata_i      : out std_logic_vector(7 downto 0);
      avm_readdatavalid_i : out std_logic;
      avm_waitrequest_i   : out std_logic
   );
end entity host;

architecture simulation of host is

begin

end architecture simulation;

