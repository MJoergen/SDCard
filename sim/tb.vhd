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

   -- SDCard controller, clock and reset
   signal clk   : std_logic;
   signal rst   : std_logic;

   -- SDCard simulation device interface
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
   -- Instantiate SDCard simulation model
   ---------------------------------------------------------
   i_sdModel : sdModel
      port map (
         sdClk => sdClk,
         cmd   => cmd,
         dat   => dat
      ); -- i_sdModel

end architecture simulation;

