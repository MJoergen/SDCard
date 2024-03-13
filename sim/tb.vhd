-- Main testbench for the SDCard controller.
-- This closely mimics the MEGA65 top level file, except that
-- clocks are generated directly, instead of via MMCM.
--
-- Run for 2000 us.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb is
end entity tb;

architecture simulation of tb is

   -- Avalon Memory Map
   signal avm_clk           : std_logic;
   signal avm_rst           : std_logic;  -- Synchronous reset, active high
   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_address       : std_logic_vector(31 downto 0);
   signal avm_writedata     : std_logic_vector(7 downto 0);
   signal avm_burstcount    : std_logic_vector(15 downto 0);
   signal avm_readdata      : std_logic_vector(7 downto 0);
   signal avm_readdatavalid : std_logic;
   signal avm_waitrequest   : std_logic;

   -- SDCard device interface
   signal sd_clk            : std_logic;
   signal sd_cmd            : std_logic;
   signal sd_dat            : std_logic_vector(3 downto 0);

   component mdl_sdio is
      generic (
         OPT_DUAL_VOLTAGE  : std_logic_vector(0 downto 0);
         OPT_HIGH_CAPACITY : std_logic_vector(0 downto 0);
         LGMEMSZ           : natural
      );
      port (
         sd_clk : in    std_logic;
         sd_cmd : inout std_logic;
         sd_dat : inout std_logic_vector(3 downto 0)
      );
   end component mdl_sdio;

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   i_tb_clk : entity work.tb_clk
      port map (
         clk_o => avm_clk,
         rst_o => avm_rst
      ); -- i_tb_clk


   ---------------------------------------------------------
   -- Instantiate host emulator
   ---------------------------------------------------------

   i_host : entity work.host
      port map (
         avm_clk_i           => avm_clk,
         avm_rst_i           => avm_rst,
         avm_write_o         => avm_write,
         avm_read_o          => avm_read,
         avm_address_o       => avm_address,
         avm_writedata_o     => avm_writedata,
         avm_burstcount_o    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest
      ); -- i_host


   ---------------------------------------------------------
   -- Instantiate SDCard controller
   ---------------------------------------------------------

   sdcard_wrapper_inst : entity work.sdcard_wrapper
      generic map (
         G_UART => false
      )
      port map (
         avm_clk_i           => avm_clk,
         avm_rst_i           => avm_rst,
         avm_write_i         => avm_write,
         avm_read_i          => avm_read,
         avm_address_i       => avm_address,
         avm_writedata_i     => avm_writedata,
         avm_burstcount_i    => avm_burstcount,
         avm_readdata_o      => avm_readdata,
         avm_readdatavalid_o => avm_readdatavalid,
         avm_waitrequest_o   => avm_waitrequest,
         uart_valid_o        => open,
         uart_ready_i        => '1',
         uart_data_o         => open,
         -- Interface to MEGA65 I/O ports
         sd_cd_i             => '0',
         sd_clk_o            => sd_clk,
         sd_cmd_io           => sd_cmd,
         sd_dat_io           => sd_dat
      ); -- sdcard_wrapper_inst

   sd_cmd <= 'H';
   sd_dat <= (others => 'H');


   ---------------------------------------------------------
   -- Instantiate SDCard simulation model
   ---------------------------------------------------------

   i_mdl_sdio : mdl_sdio
      generic map (
         OPT_DUAL_VOLTAGE  => "0",
         OPT_HIGH_CAPACITY => "1",
         LGMEMSZ           => 16
      )
      port map (
         sd_clk => sd_clk,
         sd_cmd => sd_cmd,
         sd_dat => sd_dat
      ); -- i_mdl_sdio

end architecture simulation;

