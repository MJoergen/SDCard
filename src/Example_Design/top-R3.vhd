library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity top_r3 is
   port (
      sys_clk_i      : in    std_logic;
      sys_rstn_i     : in    std_logic;
      kb_io0_o       : out   std_logic;
      kb_io1_o       : out   std_logic;
      kb_io2_i       : in    std_logic;
      sd_cd_i        : in    std_logic;
      sd_clk_o       : out   std_logic;
      sd_cmd_io      : inout std_logic;
      sd_dat_io      : inout std_logic_vector(3 downto 0);
      uart_rx_i      : in    std_logic;
      uart_tx_o      : out   std_logic;
      vga_red_o      : out   std_logic_vector(7 downto 0);
      vga_green_o    : out   std_logic_vector(7 downto 0);
      vga_blue_o     : out   std_logic_vector(7 downto 0);
      vga_hs_o       : out   std_logic;
      vga_vs_o       : out   std_logic;
      vdac_clk_o     : out   std_logic;
      vdac_sync_n_o  : out   std_logic;
      vdac_blank_n_o : out   std_logic;
      vdac_psave_n_o : out   std_logic
   );
end entity top_r3;

architecture synthesis of top_r3 is

   signal clk      : std_logic;
   signal rst      : std_logic;
   signal wr       : std_logic;
   signal wr_multi : std_logic;
   signal wr_erase : std_logic_vector(7 downto 0); -- for wr_multi_i only
   signal wr_data  : std_logic_vector(7 downto 0);
   signal wr_valid : std_logic;
   signal wr_ready : std_logic;
   signal rd       : std_logic;
   signal rd_multi : std_logic;
   signal rd_data  : std_logic_vector(7 downto 0);
   signal rd_valid : std_logic;
   signal rd_ready : std_logic;
   signal busy     : std_logic;
   signal lba      : std_logic_vector(31 downto 0);
   signal err      : std_logic_vector(7 downto 0);

begin

   ---------------------------------------------------------
   -- Instantiate clock generator
   ---------------------------------------------------------

   clk_inst : entity work.clk
      port map (
         sys_clk_i  => sys_clk_i,
         sys_rstn_i => sys_rstn_i,
         clk_o      => clk,
         rst_o      => rst
      ); -- clk_inst


   ---------------------------------------------------------
   -- Instantiate MEGA65 platform interface
   ---------------------------------------------------------

   mega65_inst : entity work.mega65
      generic map (
         G_AVM_CLK_HZ => 50_000_000
      )
      port map (
         sys_clk_i      => sys_clk_i,
         sys_rst_i      => not sys_rstn_i,
         -- Interface to SDCard controller
         clk_i          => clk,
         rst_i          => rst,
         wr_o           => wr,
         wr_multi_o     => wr_multi,
         wr_erase_o     => wr_erase,
         wr_data_o      => wr_data,
         wr_valid_o     => wr_valid,
         wr_ready_i     => wr_ready,
         rd_o           => rd,
         rd_multi_o     => rd_multi,
         rd_data_i      => rd_data,
         rd_valid_i     => rd_valid,
         rd_ready_o     => rd_ready,
         busy_i         => busy,
         lba_o          => lba,
         err_i          => err,
         -- Interface to MEGA65 I/O ports
         kb_io0_o       => kb_io0_o,
         kb_io1_o       => kb_io1_o,
         kb_io2_i       => kb_io2_i,
         uart_rx_i      => uart_rx_i,
         uart_tx_o      => uart_tx_o,
         vga_red_o      => vga_red_o,
         vga_green_o    => vga_green_o,
         vga_blue_o     => vga_blue_o,
         vga_hs_o       => vga_hs_o,
         vga_vs_o       => vga_vs_o,
         vdac_clk_o     => vdac_clk_o,
         vdac_sync_n_o  => vdac_sync_n_o,
         vdac_blank_n_o => vdac_blank_n_o,
         vdac_psave_n_o => vdac_psave_n_o
      ); -- mega65_inst


   ---------------------------------------------------------
   -- Instantiate SDCard controller
   ---------------------------------------------------------

   sdcard_wrapper_inst : entity work.sdcard_wrapper
      port map (
         clk_i      => clk,
         rst_i      => rst or not uart_rx_i,
         wr_i       => wr,
         wr_multi_i => wr_multi,
         wr_erase_i => wr_erase,
         wr_data_i  => wr_data,
         wr_valid_i => wr_valid,
         wr_ready_o => wr_ready,
         rd_i       => rd,
         rd_multi_i => rd_multi,
         rd_data_o  => rd_data,
         rd_valid_o => rd_valid,
         rd_ready_i => rd_ready,
         busy_o     => busy,
         lba_i      => lba,
         err_o      => err,
         -- Interface to MEGA65 I/O ports
         sd_clk_o   => sd_clk_o,
         sd_cmd_io  => sd_cmd_io,
         sd_dat_io  => sd_dat_io
      ); -- sdcard_wrapper_inst

end architecture synthesis;

