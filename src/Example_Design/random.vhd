library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

entity random is
   port (
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;
      update_i   : in  std_logic;
      load_i     : in  std_logic;
      load_val_i : in  std_logic_vector(31 downto 0);
      output_o   : out std_logic_vector(31 downto 0)
   );
end entity random;

architecture synthesis of random is

   signal output_1 : std_logic_vector(31 downto 0);
   signal output_2 : std_logic_vector(31 downto 0);
   signal output_2_reverse : std_logic_vector(31 downto 0);

begin

   ---------------------------------------------------------
   -- Instantiate two different LFSRs
   ---------------------------------------------------------

   i_lfsr_1 : entity work.lfsr
      generic map (
         G_WIDTH => 32,
         G_TAPS  => X"0000000080000EA6"
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         update_i   => update_i,
         load_i     => load_i,
         load_val_i => load_val_i,
         output_o   => output_1
      ); -- i_lfsr_1

   i_lfsr_2 : entity work.lfsr
      generic map (
         G_WIDTH => 32,
         G_TAPS  => X"0000000080000E74"
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         update_i   => update_i,
         load_i     => load_i,
         load_val_i => load_val_i,
         output_o   => output_2
      ); -- i_lfsr_2


   ---------------------------------------------------------
   -- Combine their output
   ---------------------------------------------------------

   p_reverse : process(all)
   begin
      for i in output_2'low to output_2'high loop
         output_2_reverse(output_2'high - i) <= output_2(i);
      end loop;
   end process p_reverse;

   output_o <= output_1 + output_2_reverse;

end architecture synthesis;

