-- This is the host emulator for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use ieee.numeric_std_unsigned.all;

entity host is
   port (
      avm_clk_i           : in    std_logic;
      avm_rst_i           : in    std_logic;
      avm_write_o         : out   std_logic;
      avm_read_o          : out   std_logic;
      avm_address_o       : out   std_logic_vector(31 downto 0);
      avm_writedata_o     : out   std_logic_vector(7 downto 0);
      avm_burstcount_o    : out   std_logic_vector(15 downto 0);  -- Must be a multiple of 512 bytes
      avm_readdata_i      : in    std_logic_vector(7 downto 0);
      avm_readdatavalid_i : in    std_logic;
      avm_waitrequest_i   : in    std_logic
   );
end entity host;

architecture synthesis of host is

   type   state_type is (
      READ_ST,
      WAIT_ST
   );

   signal state : state_type := READ_ST;

   signal fsm_update    : std_logic;
   signal random_output : std_logic_vector(21 downto 0);

begin

   -- Only update address once every read command
   fsm_update    <= avm_read_o and not avm_waitrequest_i;

   random_inst : entity work.random
      port map (
         clk_i      => avm_clk_i,
         rst_i      => '0',
         update_i   => fsm_update,
         load_i     => avm_rst_i,
         load_val_i => (others => '1'),
         output_o   => random_output
      ); -- random_inst

   avm_address_o <= "0000000000" & not random_output;


   fsm_proc : process (avm_clk_i)
   begin
      if rising_edge(avm_clk_i) then
         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

         case state is

            when READ_ST =>
               avm_write_o      <= '0';
               avm_read_o       <= '1';
               avm_burstcount_o <= X"0200";
               state            <= WAIT_ST;

            when WAIT_ST =>
               if avm_waitrequest_i = '0' then
                  state <= READ_ST;
               end if;

         end case;

         if avm_rst_i = '1' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
            state       <= READ_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

