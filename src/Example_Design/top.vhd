library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity top is
   port (
      sys_clk_i  : in    std_logic;
      sys_rstn_i : in    std_logic;
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
         sys_rstn_i => sys_rstn_i,
         clk_o      => avm_clk,
         rst_o      => open
      ); -- clk_inst

   avm_rst   <= not sys_rstn_i;


   ---------------------------------------------------------
   -- Instantiate MEGA65 platform interface
   ---------------------------------------------------------

   mega65_inst : entity work.mega65
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
         sd_clk_o            => sd_clk,
         sd_cmd_in_i         => sd_cmd_in,
         sd_cmd_out_o        => sd_cmd_out,
         sd_cmd_oe_o         => sd_cmd_oe,
         sd_dat_in_i         => sd_dat_in,
         sd_dat_out_o        => sd_dat_out,
         sd_dat_oe_o         => sd_dat_oe
      ); -- sdcard_wrapper_inst


   ---------------------------------------------------------
   -- Connect I/O buffers
   ---------------------------------------------------------

   sd_clk_o  <= sd_clk;
   sd_cmd_in <= sd_cmd_io;
   sd_dat_in <= sd_dat_io;
   sd_cmd_io <= sd_cmd_out when sd_cmd_oe = '1' else
                'Z';
   sd_dat_io <= sd_dat_out when sd_dat_oe = '1' else
                (others => 'Z');

end architecture synthesis;

