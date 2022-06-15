library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

entity tb_random is
end entity tb_random;

architecture simulation of tb_random is

   signal clk      : std_logic;
   signal rst      : std_logic;
   signal load     : std_logic;
   signal load_val : std_logic_vector(21 downto 0);
   signal output   : std_logic_vector(21 downto 0);

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
   -- Generate stimulus
   ---------------------------------------------------------

   p_load : process
   begin
      load <= '0';
      wait for 1 us;
      wait until clk = '1';
      load_val <= (others => '1');
      load <= '1';
      wait until clk = '1';
      load <= '0';
      wait;
   end process p_load;


   ---------------------------------------------------------
   -- Instantiate DUT
   ---------------------------------------------------------

   i_random : entity work.random
      port map (
         clk_i      => clk,
         rst_i      => rst,
         load_i     => load,
         load_val_i => load_val,
         output_o   => output
      ); -- i_random

end architecture simulation;

