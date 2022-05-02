-- This is the wrapper file for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

-- From SanDisk_ProdManualSDCardv1.9.pdf, page 15:
-- The block length for read operations is limited by the device sector size
-- (512 bytes) but can be as small as a single byte. Misalignment is not allowed.
-- Every data block must be contained in a single physical sector. The block
-- length for write operations must be identical to the sector size and the
-- start address aligned to a sector boundary.

-- Timing diagram is in Figure 3-7 in page 35.
-- Output is changed on falling edge of sd_clk_o. The SDCard samples on rising clock edge.
-- Input is sampled on rising edge of sd_clk_o. The SDCard outputs on falling clock edge.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdcard is
   port (
      -- Avalon Memory Map
      avm_clk_i           : in  std_logic;   -- 25 Mhz
      avm_rst_i           : in  std_logic;   -- Synchronous reset, active high
      avm_write_i         : in  std_logic;
      avm_read_i          : in  std_logic;
      avm_address_i       : in  std_logic_vector(31 downto 0);
      avm_writedata_i     : in  std_logic_vector(7 downto 0);
      avm_burstcount_i    : in  std_logic_vector(15 downto 0); -- Must be a multiple of 512 bytes
      avm_readdata_o      : out std_logic_vector(7 downto 0);
      avm_readdatavalid_o : out std_logic;
      avm_waitrequest_o   : out std_logic;

      -- SDCard device interface
      sd_clk_o            : out std_logic;   -- 25 MHz
      sd_cmd_in_i         : in  std_logic;
      sd_cmd_out_o        : out std_logic;
      sd_cmd_oe_o         : out std_logic;
      sd_dat_in_i         : in  std_logic_vector(3 downto 0);
      sd_dat_out_o        : out std_logic_vector(3 downto 0);
      sd_dat_oe_o         : out std_logic
   );
end entity sdcard;

architecture synthesis of sdcard is

   signal counter_slow  : std_logic_vector(5 downto 0) := "000000";
   signal cmd           : std_logic_vector(37 downto 0);
   signal cmd_valid     : std_logic;
   signal cmd_ready     : std_logic;
   signal resp          : std_logic_vector(135 downto 0);
   signal resp_valid    : std_logic;

   signal idle_count    : natural range 0 to 74;

   -- State diagram in Figure 4-7 page 56.
   type state_t is (
      IDLE_ST,
      ACMD41_ST,
      CMD2_ST,
      CMD3_ST,
      CMD15_ST,
      CMD0_ST
   );

   signal state : state_t := IDLE_ST;

begin

   sd_clk_o <= counter_slow(5) when state = IDLE_ST or state = ACMD41_ST or state = CMD2_ST else
               avm_clk_i;

   p_counter : process (avm_clk_i)
   begin
      if rising_edge(avm_clk_i) then
         counter_slow <= std_logic_vector(unsigned(counter_slow) + 1);
      end if;
   end process p_counter;

   ----------------------------------
   -- Instantiate CMD controller
   ----------------------------------

   i_cmd : entity work.cmd
      port map (
         clk_i        => avm_clk_i,
         rst_i        => avm_rst_i,
         cmd_i        => cmd,
         cmd_valid_i  => cmd_valid,
         cmd_ready_o  => cmd_ready,
         resp_o       => resp,
         resp_valid_o => resp_valid,
         sd_cmd_in_i  => sd_cmd_in_i,
         sd_cmd_out_o => sd_cmd_out_o,
         sd_cmd_oe_o  => sd_cmd_oe_o
      ); -- i_cmd

   p_fsm : process (avm_clk_i)
   begin
      if rising_edge(avm_clk_i) then
         case state is
            when IDLE_ST =>
               cmd       <= (others => '0');
               cmd_valid <= '1';
               state     <= ACMD41_ST;

            when ACMD41_ST =>
               if cmd_ready = '1' then
                  state <= CMD2_ST;
               end if;

            when CMD2_ST =>
               if cmd_ready = '1' then
                  state <= CMD3_ST;
               end if;

            when others =>
               null;
         end case;

         if avm_rst_i = '1' then
            idle_count          <= 74;
            state               <= IDLE_ST;
            cmd_valid           <= '0';
            sd_dat_out_o        <= "0000";
            sd_dat_oe_o         <= '0';
            avm_readdatavalid_o <= '0';
            avm_waitrequest_o   <= '1';
         end if;
      end if;
   end process p_fsm;

end architecture synthesis;

