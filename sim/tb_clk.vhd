-- Generate clocks needed for the HyperRAM controller.
--
-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).

library ieee;
use ieee.std_logic_1164.all;

entity tb_clk is
   port (
      clk_o : out std_logic;
      rst_o : out std_logic
   );
end entity tb_clk;

architecture simulation of tb_clk is

   constant C_CLK_PERIOD : time := 10 ns; -- 100 MHz

begin

   p_clk : process
   begin
      clk_o <= '1';
      wait for C_CLK_PERIOD/2;
      clk_o <= '0';
      wait for C_CLK_PERIOD/2;
   end process p_clk;

   p_rst : process
   begin
      rst_o <= '1';
      wait for 10*C_CLK_PERIOD;
      wait until clk_o = '1';
      rst_o <= '0';
      wait;
   end process p_rst;

end architecture simulation;

