-- This is the wrapper file for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdcard is
   port (
      -- Avalon Memory Map
      avm_clk_i           : in  std_logic;
      avm_rst_i           : in  std_logic;  -- Synchronous reset, active high
      avm_write_i         : in  std_logic;
      avm_read_i          : in  std_logic;
      avm_address_i       : in  std_logic_vector(31 downto 0);
      avm_writedata_i     : in  std_logic_vector(7 downto 0);
      avm_burstcount_i    : in  std_logic_vector(8 downto 0);
      avm_readdata_o      : out std_logic_vector(7 downto 0);
      avm_readdatavalid_o : out std_logic;
      avm_waitrequest_o   : out std_logic;

      -- SDCard device interface
      sd_clk_o            : out std_logic;
      sd_cmd_in_i         : in  std_logic;
      sd_cmd_out_o        : out std_logic;
      sd_cmd_oe_o         : out std_logic;
      sd_dat_in_i         : in  std_logic_vector(3 downto 0);
      sd_dat_out_o        : out std_logic_vector(3 downto 0);
      sd_dat_oe_o         : out std_logic
   );
end entity sdcard;

architecture synthesis of sdcard is

   type state_t is (
      IDLE_ST
   );

   signal state : state_t;

begin

   p_fsm : process (avm_clk_i)
   begin
      if rising_edge(avm_clk_i) then

         if avm_rst_i = '1' then
            state <= IDLE_ST;
         end if;
      end if;
   end process p_fsm;

end architecture synthesis;

