library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library work;
   use work.video_modes_pkg.all;

entity mega65 is
   generic (
      G_AVM_CLK_HZ : natural
   );
   port (
      sys_clk_i           : in    std_logic;
      sys_rst_i           : in    std_logic;
      -- Interface to SDCard controller
      avm_clk_i           : in    std_logic;
      avm_rst_i           : in    std_logic;
      avm_write_o         : out   std_logic;
      avm_read_o          : out   std_logic;
      avm_address_o       : out   std_logic_vector(31 downto 0);
      avm_writedata_o     : out   std_logic_vector(7 downto 0);
      avm_burstcount_o    : out   std_logic_vector(15 downto 0);
      avm_readdata_i      : in    std_logic_vector(7 downto 0);
      avm_readdatavalid_i : in    std_logic;
      avm_waitrequest_i   : in    std_logic;
      uart_valid_i        : in    std_logic;
      uart_ready_o        : out   std_logic;
      uart_data_i         : in    std_logic_vector(7 downto 0);
      -- Interface to MEGA65 I/O ports
      uart_rx_i           : in    std_logic;
      uart_tx_o           : out   std_logic;
      kb_io0_o            : out   std_logic;
      kb_io1_o            : out   std_logic;
      kb_io2_i            : in    std_logic;
      vga_red_o           : out   std_logic_vector(7 downto 0);
      vga_green_o         : out   std_logic_vector(7 downto 0);
      vga_blue_o          : out   std_logic_vector(7 downto 0);
      vga_hs_o            : out   std_logic;
      vga_vs_o            : out   std_logic;
      vdac_clk_o          : out   std_logic;
      vdac_sync_n_o       : out   std_logic;
      vdac_blank_n_o      : out   std_logic;
      vdac_psave_n_o      : out   std_logic
   );
end entity mega65;

architecture synthesis of mega65 is

   -- video mode selection: 720p @ 60 Hz
   constant C_VIDEO_MODE : video_modes_t := C_VIDEO_MODE_1280_720_60;
   constant C_FONT_FILE  : string        := "font8x8.txt";

   signal   vga_clk    : std_logic;
   signal   vga_rst    : std_logic;
   signal   vga_digits : std_logic_vector(31 downto 0);

begin

   mega65_clk_inst : entity work.mega65_clk
      port map (
         sys_clk_i => sys_clk_i,
         sys_rst_i => sys_rst_i,
         vga_clk_o => vga_clk,
         vga_rst_o => vga_rst
      ); -- mega65_clk_inst

   m2m_keyb_inst : entity work.m2m_keyb
      port map (
         clk_main_i       => sys_clk_i,
         clk_main_speed_i => 100 * 1000 * 1000,
         kio8_o           => kb_io0_o,
         kio9_o           => kb_io1_o,
         kio10_i          => kb_io2_i,
         enable_core_i    => '1',
         key_num_o        => open,
         key_pressed_n_o  => open,
         drive_led_i      => '0',
         qnice_keys_n_o   => open
      ); -- m2m_keyb_inst

   host_inst : entity work.host
      port map (
         avm_clk_i           => avm_clk_i,
         avm_rst_i           => avm_rst_i,
         avm_write_o         => avm_write_o,
         avm_read_o          => avm_read_o,
         avm_address_o       => avm_address_o,
         avm_writedata_o     => avm_writedata_o,
         avm_burstcount_o    => avm_burstcount_o,
         avm_readdata_i      => avm_readdata_i,
         avm_readdatavalid_i => avm_readdatavalid_i,
         avm_waitrequest_i   => avm_waitrequest_i
      ); -- host_inst

   uart_inst : entity work.uart
      port map (
         clk_i      => avm_clk_i,
         rst_i      => avm_rst_i,
         uart_div_i => G_AVM_CLK_HZ / 115_200,
         s_valid_i  => uart_valid_i,
         s_ready_o  => uart_ready_o,
         s_data_i   => uart_data_i,
         uart_tx_o  => uart_tx_o
      ); -- uart_inst

   cdc_avm2vga_inst : component xpm_cdc_array_single
      generic map (
         WIDTH => 32
      )
      port map (
         src_clk  => avm_clk_i,
         src_in   => avm_address_o,
         dest_clk => vga_clk,
         dest_out => vga_digits
      ); -- cdc_avm2vga_inst

   video_inst : entity work.video
      generic map (

         G_FONT_FILE   => C_FONT_FILE,
         G_DIGITS_SIZE => 32,
         G_VIDEO_MODE  => C_VIDEO_MODE
      )
      port map (
         rst_i         => vga_rst,
         clk_i         => vga_clk,
         digits_i      => vga_digits,
         video_vs_o    => vga_vs_o,
         video_hs_o    => vga_hs_o,
         video_de_o    => open,
         video_red_o   => vga_red_o,
         video_green_o => vga_green_o,
         video_blue_o  => vga_blue_o
      ); -- video_inst

   vdac_clk_o     <= vga_clk;
   vdac_sync_n_o  <= '0';
   vdac_blank_n_o <= '1';
   vdac_psave_n_o <= '1';

end architecture synthesis;

