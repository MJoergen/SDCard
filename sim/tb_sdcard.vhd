library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_sdcard is
end entity tb_sdcard;

architecture simulation of tb_sdcard is

   signal test_running : std_logic                    := '1';
   signal clk          : std_logic                    := '1'; -- 50 Mhz
   signal rst          : std_logic                    := '1'; -- Synchronous reset, active high
   signal start        : std_logic;
   signal wr           : std_logic;
   signal wr_multi     : std_logic;
   signal wr_erase     : std_logic_vector(7 downto 0);        -- for wr_multi_i only
   signal wr_data      : std_logic_vector(7 downto 0);
   signal wr_valid     : std_logic;
   signal wr_ready     : std_logic;
   signal rd           : std_logic;
   signal rd_multi     : std_logic;
   signal rd_data      : std_logic_vector(7 downto 0);
   signal rd_valid     : std_logic;
   signal rd_ready     : std_logic;
   signal busy         : std_logic;
   signal lba          : std_logic_vector(31 downto 0);
   signal err          : std_logic_vector(7 downto 0);
   signal sd_clk       : std_logic;
   signal sd_cmd       : std_logic                    := 'H';
   signal sd_dat       : std_logic_vector(3 downto 0) := (others => 'H');

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   clk    <= test_running and not clk after 10 ns;
   rst    <= '1', '0' after 100 ns;

   start_proc : process
   begin
      start <= '0';
      wait until busy = '0';
      wait for 10 us;
      wait until rising_edge(clk);
      start <= '1';
      wait until rising_edge(clk);
      start <= '0';
      wait;
   end process start_proc;


   ---------------------------------------------------------
   -- Main test procedure
   ---------------------------------------------------------

   host_inst : entity work.host
      port map (
         clk_i      => clk,
         rst_i      => rst,
         start_i    => start,
         wr_o       => wr,
         wr_multi_o => wr_multi,
         wr_erase_o => wr_erase,
         wr_data_o  => wr_data,
         wr_valid_o => wr_valid,
         wr_ready_i => wr_ready,
         rd_o       => rd,
         rd_multi_o => rd_multi,
         rd_data_i  => rd_data,
         rd_valid_i => rd_valid,
         rd_ready_o => rd_ready,
         busy_i     => busy,
         lba_o      => lba,
         err_i      => err
      ); -- host_inst


   ---------------------------------------------------------
   -- Instantiate SDCard controller
   ---------------------------------------------------------

   sdcard_wrapper_inst : entity work.sdcard_wrapper
      port map (
         clk_i      => clk,
         rst_i      => rst,
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
         sd_clk_o   => sd_clk,
         sd_cmd_io  => sd_cmd,
         sd_dat_io  => sd_dat
      );

   sd_cmd <= 'H';
   sd_dat <= (others => 'H');


   ---------------------------------------------------------
   -- Instantiate SDCard simulation model
   ---------------------------------------------------------

   sdcard_sim_inst : entity work.sdcard_sim
      port map (
         sd_clk_i  => sd_clk,
         sd_cmd_io => sd_cmd,
         sd_dat_io => sd_dat
      ); -- sdcard_sim_inst


end architecture simulation;

