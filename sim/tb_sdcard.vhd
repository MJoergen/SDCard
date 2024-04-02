library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_sdcard is
end entity tb_sdcard;

architecture simulation of tb_sdcard is

   signal test_running : std_logic                         := '1';

   signal avm_clk           : std_logic                    := '1'; -- 50 Mhz
   signal avm_rst           : std_logic                    := '1'; -- Synchronous reset, active high
   signal avm_write         : std_logic;
   signal avm_read          : std_logic;
   signal avm_address       : std_logic_vector(31 downto 0);
   signal avm_writedata     : std_logic_vector(7 downto 0);
   signal avm_burstcount    : std_logic_vector(15 downto 0);
   signal avm_readdata      : std_logic_vector(7 downto 0);
   signal avm_readdatavalid : std_logic;
   signal avm_waitrequest   : std_logic;
   signal avm_init_error    : std_logic;
   signal avm_crc_error     : std_logic;
   signal avm_last_state    : std_logic_vector(7 downto 0);
   signal sd_clk            : std_logic;
   signal sd_cmd            : std_logic                    := 'H';
   signal sd_dat            : std_logic_vector(3 downto 0) := (others => 'H');

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   avm_clk <= test_running and not avm_clk after 10 ns;
   avm_rst <= '1', '0' after 100 ns;


   ---------------------------------------------------------
   -- Main test procedure
   ---------------------------------------------------------

   test_proc : process
      --

      procedure read_sector (
         addr : std_logic_vector
      ) is
         --

         pure function get_data (
            addr_v : std_logic_vector;
            offset_v : integer
         ) return std_logic_vector is
            variable data_v : std_logic_vector(31 downto 0);
            variable i_v    : integer;
         begin
            i_v    := to_integer(unsigned(addr_v)) * 512 + offset_v;
            data_v := std_logic_vector(to_signed(i_v * (i_v - 512), 32));
            return data_v(15 downto 8);
         end function get_data;

      --
      begin
         report "+read_sector";
         avm_write      <= '0';
         avm_read       <= '1';
         avm_address    <= addr;
         avm_burstcount <= X"0100";
         wait until rising_edge(avm_clk);

         while avm_waitrequest = '1' loop
            wait until rising_edge(avm_clk);
         end loop;

         avm_write      <= '0';
         avm_read       <= '0';
         avm_address    <= (others => '0');
         avm_burstcount <= (others => '0');

         for i in 0 to 511 loop
            --
            while avm_readdatavalid = '0' loop
               wait until rising_edge(avm_clk);
            end loop;

            assert avm_readdata = get_data(addr, i)
               report "Read error: Got=" & to_hstring(avm_readdata)
                      & ", Expected=" & to_hstring(get_data(addr, i))
                      & ", at addr=" & to_hstring(addr)
                      & " and i=" & to_string(i);
            wait until rising_edge(avm_clk);
         end loop;

         report "-read_sector";
      end procedure read_sector;

   --
   begin
      avm_write <= '0';
      avm_read  <= '0';
      wait until avm_rst = '0';
      wait until rising_edge(avm_clk);
      wait until rising_edge(avm_clk);

      while avm_waitrequest = '1' loop
         wait until rising_edge(avm_clk);
      end loop;

      read_sector(X"00012345");

      wait for 100 us;
      report "Test finished";
      test_running <= '0';
      wait;
   end process test_proc;


   ---------------------------------------------------------
   -- Instantiate SDCard controller
   ---------------------------------------------------------

   sdcard_wrapper_inst : entity work.sdcard_wrapper
      generic map (
         G_UART => false
      )
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
         avm_init_error_o    => avm_init_error,
         avm_crc_error_o     => avm_crc_error,
         avm_last_state_o    => avm_last_state,
         sd_cd_i             => '1',
         sd_clk_o            => sd_clk,
         sd_cmd_io           => sd_cmd,
         sd_dat_io           => sd_dat,
         uart_valid_o        => open,
         uart_ready_i        => '1',
         uart_data_o         => open
      ); -- sdcard_wrapper_inst

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

