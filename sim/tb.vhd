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

   -- SDCard controller interface
   signal clk                  : std_logic;
   signal rst                  : std_logic;
   signal ctrl_rd              : std_logic;  -- active-high read block request.
   signal ctrl_wr              : std_logic;  -- active-high write block request.
   signal ctrl_wr_multi        : std_logic;  -- for all but last block of multi-block write
   signal ctrl_wr_multi_first  : std_logic;  -- for first block of multi-block write
   signal ctrl_wr_multi_last   : std_logic;  -- for last block of multi-block write
   signal ctrl_addr            : std_logic_vector(31 downto 0);   -- Block address.
   signal ctrl_data            : std_logic_vector(7 downto 0);    -- Data to write to block.
   signal ctrl_busy            : std_logic;  -- High when controller is busy performing some operation.
   signal ctrl_hndShk_in       : std_logic;  -- High when host has data to give or has taken data.
   signal ctrl_hndShk_out      : std_logic;  -- High when controller has taken data or has data to give.
   signal ctrl_error           : std_logic_vector(15 downto 0);
   signal ctrl_last_state      : std_logic_vector(7 downto 0);
   signal ctrl_last_sd_rxbyte  : std_logic_vector(7 downto 0);
   signal ctrl_clear_error     : std_logic;

   -- SDCard device interface
   signal sd_clk          : std_logic;
   signal sd_cmd_in       : std_logic;
   signal sd_cmd_out      : std_logic;
   signal sd_cmd_oe       : std_logic;
   signal sd_dat_in       : std_logic_vector(3 downto 0);
   signal sd_dat_out      : std_logic_vector(3 downto 0);
   signal sd_dat_oe       : std_logic;

   -- Tristate
   signal sdClk : std_logic;
   signal cmd   : std_logic;
   signal dat   : std_logic_vector(3 downto 0);

   component sdModel is
      port (
         sdClk : in    std_logic;
         cmd   : inout std_logic;
         dat   : inout std_logic_vector(3 downto 0)
      );
   end component sdModel;

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   i_tb_clk : entity work.tb_clk
      port map (
         clk_o => clk,
         rst_o => rst
      ); -- i_tb_clk


   ---------------------------------------------------------
   -- Instantiate SDCard controller
   ---------------------------------------------------------

   i_sdcard : entity work.sdcard
      port map (
         clk_i              => clk,
         rst_i              => rst,
         rd_i               => ctrl_rd,
         wr_i               => ctrl_wr,
         wr_multi           => ctrl_wr_multi,
         wr_multi_first     => ctrl_wr_multi_first,
         wr_multi_last      => ctrl_wr_multi_last,
         addr_i             => ctrl_addr,
         data_i             => ctrl_data,
         busy_o             => ctrl_busy,
         hndShk_in_i        => ctrl_hndShk_in,
         hndShk_out_o       => ctrl_hndShk_out,
         error_o            => ctrl_error,
         last_state_o       => ctrl_last_state,
         last_sd_rxbyte_o   => ctrl_last_sd_rxbyte,
         clear_error_i      => ctrl_clear_error,
         sd_clk_o           => sd_clk,
         sd_cmd_in_i        => sd_cmd_in,
         sd_cmd_out_o       => sd_cmd_out,
         sd_cmd_oe_o        => sd_cmd_oe,
         sd_dat_in_i        => sd_dat_in,
         sd_dat_out_o       => sd_dat_out,
         sd_dat_oe_o        => sd_dat_oe
      ); -- i_sdcard


   ---------------------------------------------------------
   -- Connect tri-state buffers
   ---------------------------------------------------------

   sdClk <= sd_clk;
   cmd <= sd_cmd_out when sd_cmd_oe = '1' else 'Z';
   dat <= sd_dat_out when sd_dat_oe = '1' else (others => 'Z');
   sd_cmd_in <= cmd;
   sd_dat_in <= dat;


   ---------------------------------------------------------
   -- Instantiate SDCard simulation model
   ---------------------------------------------------------

   i_sdModel : sdModel
      port map (
         sdClk => sdClk,
         cmd   => cmd,
         dat   => dat
      ); -- i_sdModel

end architecture simulation;

