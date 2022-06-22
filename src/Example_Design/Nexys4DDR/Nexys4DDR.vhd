library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
   port (
      clk_i          : in    std_logic;
      btnl_i         : in    std_logic;
      btnr_i         : in    std_logic;
      btnu_i         : in    std_logic;
      btnd_i         : in    std_logic;
      btnc_i         : in    std_logic;
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

   signal reset_n           : std_logic;

begin

   reset_n <= not btnc_i;


   ---------------------------------------------------------
   -- Instantiate clock generator
   ---------------------------------------------------------

   i_clk : entity work.clk
      port map (
         sys_clk_i  => clk_i,
         sys_rstn_i => reset_n,
         clk_o      => avm_clk,
         rst_o      => avm_rst
      ); -- i_clk


   ---------------------------------------------------------
   -- Instantiate host emulator
   ---------------------------------------------------------

   i_host : entity work.host
      port map (
         avm_clk_i           => avm_clk,
         avm_rst_i           => avm_rst,
         avm_write_o         => avm_write,
         avm_read_o          => avm_read,
         avm_address_o       => avm_address,
         avm_writedata_o     => avm_writedata,
         avm_burstcount_o    => avm_burstcount,
         avm_readdata_i      => avm_readdata,
         avm_readdatavalid_i => avm_readdatavalid,
         avm_waitrequest_i   => avm_waitrequest
      ); -- i_host


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
         sd_cd_i             => sd_cd_i,
         sd_clk_o            => sd_clk,
         sd_cmd_in_i         => sd_cmd_in,
         sd_cmd_out_o        => sd_cmd_out,
         sd_cmd_oe_o         => sd_cmd_oe,
         sd_dat_in_i         => sd_dat_in,
         sd_dat_out_o        => sd_dat_out,
         sd_dat_oe_o         => sd_dat_oe,
         uart_tx_o           => uart_tx_o
      ); -- i_sdcard_wrapper


   ---------------------------------------------------------
   -- Connect I/O buffers
   ---------------------------------------------------------

   sd_clk_o  <= sd_clk;
   sd_cmd_in <= sd_cmd_io;
   sd_dat_in <= sd_dat_io;
   sd_cmd_io <= sd_cmd_out when sd_cmd_oe = '1' else 'Z';
   sd_dat_io <= sd_dat_out when sd_dat_oe = '1' else (others => 'Z');

end architecture synthesis;

