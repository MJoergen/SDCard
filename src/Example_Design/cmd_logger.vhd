library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cmd_logger is
   port (
      clk_i          : in  std_logic; -- 50 MHz
      rst_i          : in  std_logic;

      -- Command to send to SDCard
      cmd_valid_i    : in  std_logic;
      cmd_ready_o    : out std_logic;
      cmd_index_i    : in  natural range 0 to 63;
      cmd_data_i     : in  std_logic_vector(31 downto 0);
      cmd_resp_i     : in  natural range 0 to 255;   -- Expected number of bits in response

      -- Response received from SDCard
      resp_valid_o   : out std_logic;
      resp_ready_i   : in  std_logic;
      resp_data_o    : out std_logic_vector(135 downto 0);
      resp_timeout_o : out std_logic;  -- No response received
      resp_error_o   : out std_logic;  -- Reponse with CRC error

      -- SDCard device interface
      sd_clk_i       : in  std_logic; -- 25 MHz or 400 kHz
      sd_cmd_in_i    : in  std_logic;
      sd_cmd_out_o   : out std_logic;
      sd_cmd_oe_o    : out std_logic;

      uart_tx_o      : out std_logic
   );
end entity cmd_logger;

architecture synthesis of cmd_logger is

   -- Duplicated command
   signal cmd_valid_cmd   : std_logic;
   signal cmd_ready_cmd   : std_logic;
   signal cmd_valid_ser   : std_logic;
   signal cmd_ready_ser   : std_logic;

   -- Duplicated response
   signal resp_valid_cmd  : std_logic;
   signal resp_ready_cmd  : std_logic;
   signal resp_valid_ser  : std_logic;
   signal resp_ready_ser  : std_logic;

   -- Hexified command and response
   signal cmd_hex         : std_logic_vector(79 downto 0);
   signal resp_hex        : std_logic_vector(271 downto 0);
   signal resp_data       : std_logic_vector(135 downto 0);

   -- Serialized command and response
   signal ser_valid_resp  : std_logic;
   signal ser_ready_resp  : std_logic;
   signal ser_valid_cmd   : std_logic;
   signal ser_ready_cmd   : std_logic;
   signal ser_data_resp   : std_logic_vector(7 downto 0);
   signal ser_data_cmd    : std_logic_vector(7 downto 0);

   -- UART output
   signal uart_valid      : std_logic;
   signal uart_ready      : std_logic;
   signal uart_data       : std_logic_vector(7 downto 0);

begin

   -----------------------------------------------------
   -- Duplicate command to cmd and serializer
   -----------------------------------------------------

   i_duplicator_cmd : entity work.duplicator
      port map (
         s_valid_i  => cmd_valid_i,
         s_ready_o  => cmd_ready_o,
         m1_valid_o => cmd_valid_cmd,
         m1_ready_i => cmd_ready_cmd,
         m2_valid_o => cmd_valid_ser,
         m2_ready_i => cmd_ready_ser
      ); -- i_duplicator_cmd


   -----------------------------------------------------
   -- Send command and get response
   -----------------------------------------------------

   i_cmd : entity work.cmd
      port map (
         clk_i          => clk_i,
         rst_i          => rst_i,
         cmd_valid_i    => cmd_valid_cmd,
         cmd_ready_o    => cmd_ready_cmd,
         cmd_index_i    => cmd_index_i,
         cmd_data_i     => cmd_data_i,
         cmd_resp_i     => cmd_resp_i,
         resp_valid_o   => resp_valid_cmd,
         resp_ready_i   => resp_ready_cmd,
         resp_data_o    => resp_data_o,
         resp_timeout_o => resp_timeout_o,
         resp_error_o   => resp_error_o,
         sd_clk_i       => sd_clk_i,
         sd_cmd_in_i    => sd_cmd_in_i,
         sd_cmd_out_o   => sd_cmd_out_o,
         sd_cmd_oe_o    => sd_cmd_oe_o
      ); -- i_cmd


   -----------------------------------------------------
   -- Serialize command
   -----------------------------------------------------

   i_hexifier_cmd : entity work.hexifier
      generic map (
         G_DATA_NIBBLES => 10
      )
      port map (
         s_data_i => std_logic_vector(to_unsigned(cmd_index_i,8)) & cmd_data_i,
         m_data_o => cmd_hex
      );

   i_serializer_cmd : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 88,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => cmd_valid_ser,
         s_ready_o => cmd_ready_ser,
         s_data_i  => cmd_hex & X"2E",
         m_valid_o => ser_valid_cmd,
         m_ready_i => ser_ready_cmd,
         m_data_o  => ser_data_cmd
      ); -- i_serializer


   -----------------------------------------------------
   -- Duplicate response to serializer and output
   -----------------------------------------------------

   i_duplicator_resp : entity work.duplicator
      port map (
         s_valid_i  => resp_valid_cmd,
         s_ready_o  => resp_ready_cmd,
         m1_valid_o => resp_valid_o,
         m1_ready_i => resp_ready_i,
         m2_valid_o => resp_valid_ser,
         m2_ready_i => resp_ready_ser
      ); -- i_duplicator_resp


   -----------------------------------------------------
   -- Serialize response
   -----------------------------------------------------

   resp_data <= (others => '1') when resp_timeout_o = '1' or resp_error_o = '1' else resp_data_o;

   i_hexifier_resp : entity work.hexifier
      generic map (
         G_DATA_NIBBLES => 34
      )
      port map (
         s_data_i => resp_data,
         m_data_o => resp_hex
      );

   i_serializer_resp : entity work.serializer
      generic map (
         G_DATA_SIZE_IN  => 288,
         G_DATA_SIZE_OUT => 8
      )
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => resp_valid_ser,
         s_ready_o => resp_ready_ser,
         s_data_i  => resp_hex & X"0D0A",
         m_valid_o => ser_valid_resp,
         m_ready_i => ser_ready_resp,
         m_data_o  => ser_data_resp
      ); -- i_serializer


   -----------------------------------------------------
   -- Merge output streams from the two serializers
   -----------------------------------------------------

   i_merginator : entity work.merginator
      generic map (
         G_DATA_SIZE => 8
      )
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         s1_valid_i => ser_valid_resp,
         s1_ready_o => ser_ready_resp,
         s1_data_i  => ser_data_resp,
         s2_valid_i => ser_valid_cmd,
         s2_ready_o => ser_ready_cmd,
         s2_data_i  => ser_data_cmd,
         m_valid_o  => uart_valid,
         m_ready_i  => uart_ready,
         m_data_o   => uart_data
      ); -- i_merginator

   i_uart : entity work.uart
      port map (
         clk_i     => clk_i,
         rst_i     => rst_i,
         s_valid_i => uart_valid,
         s_ready_o => uart_ready,
         s_data_i  => uart_data,
         uart_tx_o => uart_tx_o
      ); -- i_uart

end architecture synthesis;

