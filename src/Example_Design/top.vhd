library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
   port (
      clk_i          : in    std_logic;
      kb_io0_o       : out   std_logic;
      kb_io1_o       : out   std_logic;
      kb_io2_i       : in    std_logic;
      sd_cd_i        : in    std_logic;
      sd_clk_o       : out   std_logic;
      sd_cmd_io      : inout std_logic;
      sd_dat_io      : inout std_logic_vector(3 downto 0);
      uart_rx_i      : in    std_logic;
      uart_tx_o      : out   std_logic
   );
end entity top;

architecture synthesis of top is

   signal avm_clk           : std_logic;
   signal avm_rst           : std_logic;
   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_address       : std_logic_vector(31 downto 0);
   signal avm_writedata     : std_logic_vector(7 downto 0);
   signal avm_burstcount    : std_logic_vector(15 downto 0);
   signal avm_readdata      : std_logic_vector(7 downto 0);
   signal avm_readdatavalid : std_logic;
   signal avm_waitrequest   : std_logic;
   signal sd_clk            : std_logic;
   signal sd_cmd_in         : std_logic;
   signal sd_cmd_out        : std_logic;
   signal sd_cmd_oe         : std_logic;
   signal sd_dat_in         : std_logic_vector(3 downto 0);
   signal sd_dat_out        : std_logic_vector(3 downto 0);
   signal sd_dat_oe         : std_logic;

   signal key_num           : integer range 0 to 79;
   signal key_pressed_n     : std_logic;
   signal keys              : std_logic_vector(79 downto 0);
   signal reset_n           : std_logic;

   signal count_low         : natural range 0 to 4095;
   signal drive_led         : std_logic;
   signal avm_reset_val     : std_logic_vector(21 downto 0);

   signal counter           : natural range 0 to 65535;
   signal start             : std_logic;

begin

   ---------------------------------------------------------
   -- Instantiate clock generator
   ---------------------------------------------------------

   drive_led <= '1' when count_low < 4095 else '0';

   i_m2m_keyb : entity work.m2m_keyb
      port map (
         clk_main_i       => clk_i,
         clk_main_speed_i => 100*1000*1000,
         kio8_o           => kb_io0_o,
         kio9_o           => kb_io1_o,
         kio10_i          => kb_io2_i,
         enable_core_i    => '1',
         key_num_o        => key_num,
         key_pressed_n_o  => key_pressed_n,
         drive_led_i      => drive_led,
         qnice_keys_n_o   => open
      ); -- i_m2m_keyb

   p_keys : process (avm_clk)
   begin
      if rising_edge(avm_clk) then
         keys(key_num) <= key_pressed_n;
      end if;
   end process p_keys;

   reset_n <= and(keys);


   ---------------------------------------------------------
   -- Instantiate clock generator
   ---------------------------------------------------------

   i_clk : entity work.clk
      port map (
         sys_clk_i  => clk_i,
         sys_rstn_i => reset_n,
         clk_o      => avm_clk,
         rst_o      => open
      ); -- i_clk

   avm_rst <= not reset_n;


   avm_reset_val <= keys(21 downto 0) and keys(43 downto 22) and keys(65 downto 44) and (X"FF" & keys(79 downto 66));

   ---------------------------------------------------------
   -- Instantiate host emulator
   ---------------------------------------------------------

   i_host : entity work.host
      port map (
         avm_clk_i           => avm_clk,
         avm_rst_i           => avm_rst,
         avm_reset_val_i     => avm_reset_val,
         avm_write_o         => avm_write,
         avm_read_o          => avm_read,
         avm_address_o       => avm_address,
         avm_writedata_o     => avm_writedata,
         avm_burstcount_o    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest
      ); -- i_host

   p_counter : process (avm_clk)
   begin
      if rising_edge(avm_clk) then
         if avm_read = '1' and avm_waitrequest = '0' then
            counter <= counter + 1;
         end if;
         if avm_rst = '1' then
            counter <= 0;
         end if;
      end if;
   end process p_counter;


   ---------------------------------------------------------
   -- Instantiate SDCard controller
   ---------------------------------------------------------

   i_sdcard_wrapper : entity work.sdcard_wrapper
      port map (
         avm_clk_i           => avm_clk,
         avm_rst_i           => avm_rst,
         avm_write_i         => avm_write,
         avm_read_i          => avm_read,
         avm_address_i       => avm_address,
         avm_writedata_i     => avm_writedata,
         avm_burstcount_i    => avm_burstcount,
         avm_readdata_o      => avm_readdata,
         avm_readdatavalid_o => avm_readdatavalid,
         avm_waitrequest_o   => avm_waitrequest,
         sd_clk_o            => sd_clk,
         sd_cmd_in_i         => sd_cmd_in,
         sd_cmd_out_o        => sd_cmd_out,
         sd_cmd_oe_o         => sd_cmd_oe,
         sd_dat_in_i         => sd_dat_in,
         sd_dat_out_o        => sd_dat_out,
         sd_dat_oe_o         => sd_dat_oe,
         uart_tx_o           => uart_tx_o
      ); -- i_sdcard_wrapper


   p_count_low : process (avm_clk)
   begin
      if rising_edge(avm_clk) then
         if sd_cmd_in = '1' then
            count_low <= 0;
         end if;

         if sd_cmd_in = '0' and count_low < 4095 and start = '1' then
            count_low <= count_low + 1;
         end if;
      end if;
   end process p_count_low;

   p_start : process (avm_clk)
   begin
      if rising_edge(avm_clk) then
         if avm_read = '1' and avm_waitrequest = '0' then
            start <= '1';
         end if;

         if avm_rst = '1' then
            start <= '0';
         end if;
      end if;
   end process p_start;


   ---------------------------------------------------------
   -- Connect I/O buffers
   ---------------------------------------------------------

   sd_clk_o  <= sd_clk;
   sd_cmd_in <= sd_cmd_io;
   sd_dat_in <= sd_dat_io;
   sd_cmd_io <= sd_cmd_out when sd_cmd_oe = '1' else 'Z';
   sd_dat_io <= sd_dat_out when sd_dat_oe = '1' else (others => 'Z');

end architecture synthesis;

