library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity mega65 is
   generic (
      G_AVM_CLK_HZ : natural
   );
   port (
      sys_clk_i           : in    std_logic;
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
      kb_io2_i            : in    std_logic
   );
end entity mega65;

architecture synthesis of mega65 is

begin

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

end architecture synthesis;

