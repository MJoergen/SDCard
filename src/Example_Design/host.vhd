-- This is the host emulator for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;

entity host is
   port (
      avm_clk_i           : in  std_logic;
      avm_rst_i           : in  std_logic;
      avm_write_o         : out std_logic;
      avm_read_o          : out std_logic;
      avm_address_o       : out std_logic_vector(31 downto 0);
      avm_writedata_o     : out std_logic_vector(7 downto 0);
      avm_burstcount_o    : out std_logic_vector(15 downto 0);  -- Must be a multiple of 512 bytes
      avm_readdata_i      : in  std_logic_vector(7 downto 0);
      avm_readdatavalid_i : in  std_logic;
      avm_waitrequest_i   : in  std_logic
   );
end entity host;

architecture simulation of host is

   type state_t is (
      INIT_ST,
      WAIT_ST
   );

   signal state : state_t := INIT_ST;

   attribute mark_debug                        : boolean;
   attribute mark_debug of avm_read_o          : signal is true;
   attribute mark_debug of avm_readdata_i      : signal is true;
   attribute mark_debug of avm_readdatavalid_i : signal is true;
   attribute mark_debug of avm_waitrequest_i   : signal is true;

begin

   p_fsm : process (avm_clk_i)
   begin
      if rising_edge(avm_clk_i) then
         if avm_waitrequest_i = '0' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
         end if;

         case state is
            when INIT_ST =>
               avm_write_o      <= '0';
               avm_read_o       <= '1';
               avm_address_o    <= X"00000004"; -- Byte address 0x0800
               avm_burstcount_o <= X"0200";
               state            <= WAIT_ST;

            when WAIT_ST =>
               if avm_waitrequest_i = '0' and avm_address_o < X"00000007" then
                  avm_read_o       <= '1';
                  avm_address_o    <= avm_address_o + 1;
                  avm_burstcount_o <= X"0200";
                  state            <= WAIT_ST;
               end if;
         end case;

         if avm_rst_i = '1' then
            avm_write_o <= '0';
            avm_read_o  <= '0';
            state       <= INIT_ST;
         end if;
      end if;
   end process p_fsm;

end architecture simulation;

