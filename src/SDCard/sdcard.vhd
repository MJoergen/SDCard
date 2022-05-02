-- This is the wrapper file for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdcard is
   port (
      clk_i             : in  std_logic;  -- Main clock
      rst_i             : in  std_logic;  -- Synchronous reset

      -- Host interface
      rd_i              : in  std_logic;  -- active-high read block request.
      wr_i              : in  std_logic;  -- active-high write block request.
      wr_multi          : in  std_logic;  -- for all but last block of multi-block write
      wr_multi_first    : in  std_logic;  -- for first block of multi-block write
      wr_multi_last     : in  std_logic;  -- for last block of multi-block write
      addr_i            : in  std_logic_vector(31 downto 0);   -- Block address.
      data_i            : in  std_logic_vector(7 downto 0);    -- Data to write to block.
      busy_o            : out std_logic;  -- High when controller is busy performing some operation.
      hndShk_in_i       : in  std_logic;  -- High when host has data to give or has taken data.
      hndShk_out_o      : out std_logic;  -- High when controller has taken data or has data to give.
      error_o           : out std_logic_vector(15 downto 0);
      last_state_o      : out std_logic_vector(7 downto 0);
      last_sd_rxbyte_o  : out std_logic_vector(7 downto 0);
      clear_error_i     : in  std_logic;

      -- SDCard device interface
      sd_clk_o          : out std_logic;
      sd_cmd_in_i       : in  std_logic;
      sd_cmd_out_o      : out std_logic;
      sd_cmd_oe_o       : out std_logic;
      sd_dat_in_i       : in  std_logic_vector(3 downto 0);
      sd_dat_out_o      : out std_logic_vector(3 downto 0);
      sd_dat_oe_o       : out std_logic
   );
end entity sdcard;

architecture synthesis of sdcard is

begin

end architecture synthesis;

