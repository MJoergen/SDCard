-- Main testbench for the SDCard controller.
-- This closely mimics the MEGA65 top level file, except that
-- clocks are generated directly, instead of via MMCM.
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
   signal sd_cmd_in         : std_logic;
   signal sd_cmd_out        : std_logic;
   signal sd_cmd_oe         : std_logic;
   signal sd_dat_in         : std_logic_vector(3 downto 0);
   signal sd_dat_out        : std_logic_vector(3 downto 0);
   signal sd_dat_oe         : std_logic;

   -- Tristate
   signal sd_cd             : std_logic;
   signal sdClk             : std_logic;
   signal cmd               : std_logic;
   signal dat               : std_logic_vector(3 downto 0);

   component sdModel is
      port (
         sdClk : in    std_logic;
         cmd   : inout std_logic;
         dat   : inout std_logic_vector(3 downto 0)
      );
   end component sdModel;

   signal uart_tx           : std_logic;

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

   i_sdcard : entity work.sdcard
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
         sd_cd_i             => sd_cd,
         sd_clk_o            => sd_clk,
         sd_cmd_in_i         => sd_cmd_in,
         sd_cmd_out_o        => sd_cmd_out,
         sd_cmd_oe_o         => sd_cmd_oe,
         sd_dat_in_i         => sd_dat_in,
         sd_dat_out_o        => sd_dat_out,
         sd_dat_oe_o         => sd_dat_oe,
         uart_tx_o           => uart_tx
      ); -- i_sdcard


   ---------------------------------------------------------
   -- Connect I/O buffers
   ---------------------------------------------------------

   sdClk     <= sd_clk;
   sd_cmd_in <= cmd;
   sd_dat_in <= dat;
   cmd <= sd_cmd_out when sd_cmd_oe = '1' else 'Z';
   dat <= sd_dat_out when sd_dat_oe = '1' else (others => 'Z');


   ---------------------------------------------------------
   -- Instantiate SDCard simulation model
   ---------------------------------------------------------

   sd_cd <= '0';
   i_sdModel : sdModel
      port map (
         sdClk => sdClk,
         cmd   => cmd,
         dat   => dat
      ); -- i_sdModel

end architecture simulation;

