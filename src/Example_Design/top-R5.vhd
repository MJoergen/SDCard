library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity top_r5 is
   port (
      sys_clk_i  : in    std_logic;
      sys_rst_i  : in    std_logic;
      kb_io0_o   : out   std_logic;
      kb_io1_o   : out   std_logic;
      kb_io2_i   : in    std_logic;
      sd_cd_i    : in    std_logic;
      sd_clk_o   : out   std_logic;
      sd_cmd_io  : inout std_logic;
      sd_dat_io  : inout std_logic_vector(3 downto 0);
      uart_rx_i  : in    std_logic;
      uart_tx_o  : out   std_logic
   );
end entity top_r5;

architecture synthesis of top_r5 is

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

   signal uart_valid        : std_logic;
   signal uart_ready        : std_logic;
   signal uart_data         : std_logic_vector(7 downto 0);

begin

   ---------------------------------------------------------
   -- Instantiate clock generator
   ---------------------------------------------------------

   clk_inst : entity work.clk
      port map (
         sys_clk_i  => sys_clk_i,
         sys_rstn_i => (not sys_rst_i) and uart_rx_i,
         clk_o      => avm_clk,
         rst_o      => avm_rst
      ); -- clk_inst


   ---------------------------------------------------------
   -- Instantiate MEGA65 platform interface
   ---------------------------------------------------------

   mega65_inst : entity work.mega65
      generic map (
         G_AVM_CLK_HZ => 50_000_000
      )
      port map (
         sys_clk_i           => sys_clk_i,
         -- Interface to SDCard controller
         avm_clk_i           => avm_clk,
         avm_rst_i           => avm_rst,
         avm_write_o         => avm_write,
         avm_read_o          => avm_read,
         avm_address_o       => avm_address,
         avm_writedata_o     => avm_writedata,
         avm_burstcount_o    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest,
         uart_valid_i        => uart_valid,
         uart_ready_o        => uart_ready,
         uart_data_i         => uart_data,
         -- Interface to MEGA65 I/O ports
         uart_rx_i           => uart_rx_i,
         uart_tx_o           => uart_tx_o,
         kb_io0_o            => kb_io0_o,
         kb_io1_o            => kb_io1_o,
         kb_io2_i            => kb_io2_i
      ); -- mega65_inst


   ---------------------------------------------------------
   -- Instantiate SDCard controller
   ---------------------------------------------------------

   sdcard_wrapper_inst : entity work.sdcard_wrapper
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
         uart_valid_o        => uart_valid,
         uart_ready_i        => uart_ready,
         uart_data_o         => uart_data,
         -- Interface to MEGA65 I/O ports
         sd_cd_i             => sd_cd_i,
         sd_clk_o            => sd_clk_o,
         sd_cmd_io           => sd_cmd_io,
         sd_dat_io           => sd_dat_io
      ); -- sdcard_wrapper_inst

end architecture synthesis;

