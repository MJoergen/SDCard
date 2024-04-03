library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity mega65 is
   generic (
      G_AVM_CLK_HZ : natural
   );
   port (
      sys_clk_i  : in    std_logic;
      -- Interface to SDCard controller
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;
      wr_o       : out   std_logic;
      wr_multi_o : out   std_logic;
      wr_erase_o : out   std_logic_vector(7 downto 0); -- for wr_multi_i only
      wr_data_o  : out   std_logic_vector(7 downto 0);
      wr_valid_o : out   std_logic;
      wr_ready_i : in    std_logic;
      rd_o       : out   std_logic;
      rd_multi_o : out   std_logic;
      rd_data_i  : in    std_logic_vector(7 downto 0);
      rd_valid_i : in    std_logic;
      rd_ready_o : out   std_logic;
      busy_i     : in    std_logic;
      lba_o      : out   std_logic_vector(31 downto 0);
      err_i      : in    std_logic_vector(7 downto 0);
      -- Interface to MEGA65 I/O ports
      kb_io0_o   : out   std_logic;
      kb_io1_o   : out   std_logic;
      kb_io2_i   : in    std_logic
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
         clk_i      => clk_i,
         rst_i      => rst_i,
         wr_o       => wr_o,
         wr_multi_o => wr_multi_o,
         wr_erase_o => wr_erase_o,
         wr_data_o  => wr_data_o,
         wr_valid_o => wr_valid_o,
         wr_ready_i => wr_ready_i,
         rd_o       => rd_o,
         rd_multi_o => rd_multi_o,
         rd_data_i  => rd_data_i,
         rd_valid_i => rd_valid_i,
         rd_ready_o => rd_ready_o,
         busy_i     => busy_i,
         lba_o      => lba_o,
         err_i      => err_i
      ); -- host_inst

end architecture synthesis;

