library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr is
   generic (
      G_TAPS  : std_logic_vector(63 downto 0);
      G_WIDTH : natural
   );
   port (
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;
      load_i     : in  std_logic;
      load_val_i : in  std_logic_vector(G_WIDTH-1 downto 0);
      output_o   : out std_logic_vector(G_WIDTH-1 downto 0)
   );
end entity lfsr;

architecture synthesis of lfsr is

   constant C_UPDATE : std_logic_vector(G_WIDTH-1 downto 0) := G_TAPS(G_WIDTH-2 downto 0) & "1";

   signal lfsr : std_logic_vector(G_WIDTH-1 downto 0) := (others => '1');

begin

   p_lfsr : process (clk_i)
   begin
      if rising_edge(clk_i) then
         lfsr <= lfsr(G_WIDTH-2 downto 0) & "0";
         if lfsr(G_WIDTH-1) = '1' then
            report "XOR with C_UPDATE:" & to_hstring(C_UPDATE);
            lfsr <= (lfsr(G_WIDTH-2 downto 0) & "0") xor C_UPDATE;
         end if;

         if load_i = '1' then
            lfsr <= load_val_i;
         end if;

         if rst_i = '1' then
            lfsr <= (others => '1');
         end if;
      end if;
   end process p_lfsr;

   output_o <= lfsr;

end architecture synthesis;

