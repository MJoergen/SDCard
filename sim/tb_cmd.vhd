library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity tb_cmd is
end entity tb_cmd;

architecture simulation of tb_cmd is

   signal   test_running : std_logic   := '1';
   signal   clk          : std_logic   := '1';            -- 50 MHz
   signal   rst          : std_logic   := '1';

   -- Command to send to SDCard
   signal   cmd_valid   : std_logic;
   signal   cmd_ready   : std_logic;
   signal   cmd_index   : natural range 0 to 63;
   signal   cmd_data    : std_logic_vector(31 downto 0);
   signal   cmd_resp    : natural range 0 to 255;         -- Expected number of bits in response
   signal   cmd_timeout : natural range 0 to 2 ** 24 - 1; -- Timeout in SD card clock cycles (max 1 second)

   -- Response received from SDCard
   signal   resp_valid   : std_logic;
   signal   resp_ready   : std_logic;
   signal   resp_data    : std_logic_vector(135 downto 0);
   signal   resp_timeout : std_logic;                     -- No response received
   signal   resp_error   : std_logic;                     -- Reponse with CRC error

   -- SDCard device interface
   signal   sd_clk      : std_logic;                      -- 25 MHz or 400 kHz
   signal   sd_cmd_in   : std_logic;
   signal   sd_cmd_out  : std_logic;
   signal   sd_cmd_oe_n : std_logic;

   signal   sd_cmd : std_logic;
   signal   sd_dat : std_logic_vector(3 downto 0);

   signal   mem_addr     : std_logic_vector(31 downto 0);
   signal   mem_data_out : std_logic_vector(7 downto 0);
   signal   mem_data_in  : std_logic_vector(7 downto 0);
   signal   mem_we       : std_logic;

   constant NAU : unsigned(0 downto 1) := (others => '0');

begin

   ---------------------------------------------------------
   -- Generate clock and reset
   ---------------------------------------------------------

   clk       <= test_running and not clk after 10 ns;
   rst       <= '1', '0' after 100 ns;

   sd_clk_proc : process (clk)
   begin
      if rising_edge(clk) then
         sd_clk <= not sd_clk;
         if rst = '1' then
            sd_clk <= '1';
         end if;
      end if;
   end process sd_clk_proc;

   test_proc : process
      --

      procedure send_cmd_and_verify_resp (
         arg_cmd     : unsigned(39 downto 0);
         arg_resp    : unsigned                       := NAU;
         arg_timeout : natural range 0 to 2 ** 24 - 1 := 25000 -- 1 ms
      ) is
      begin
         cmd_index <= to_integer(arg_cmd(39 downto 32));
         cmd_valid <= '1';
         cmd_data  <= std_logic_vector(arg_cmd(31 downto 0));
         if arg_resp'length > 0 then
            cmd_resp <= arg_resp'length + 8;
         else
            cmd_resp <= 0;
         end if;

         cmd_timeout <= arg_timeout;
         wait until rising_edge(clk);

         while cmd_ready = '0' loop
            wait until rising_edge(clk);
         end loop;

         cmd_valid <= '0';
         wait until rising_edge(clk);

         if arg_resp'length > 0 then

            while resp_valid = '0' loop
               wait until rising_edge(clk);
            end loop;

            assert resp_timeout = '0';
            assert resp_error = '0';
            assert unsigned(resp_data(39 downto 0)) = arg_resp;
         else
            while cmd_ready = '0' loop
               wait until rising_edge(clk);
            end loop;
         end if;
      --
      end procedure send_cmd_and_verify_resp;

   --
   begin
      cmd_valid    <= '0';
      resp_ready   <= '1';
      wait until falling_edge(rst);
      wait until rising_edge(clk);
      wait until rising_edge(clk);

      send_cmd_and_verify_resp(X"0000000000");

      wait for 1 us;

      send_cmd_and_verify_resp(X"080000015B", X"080000015B");

      report "Test finished";
      test_running <= '0';
      wait;
   end process test_proc;


   ---------------------------------------------------------
   -- Instantiate SDCard controller
   ---------------------------------------------------------

   sdcard_cmd_inst : entity work.sdcard_cmd
      port map (
         clk_i          => clk,
         rst_i          => rst,
         cmd_valid_i    => cmd_valid,
         cmd_ready_o    => cmd_ready,
         cmd_index_i    => cmd_index,
         cmd_data_i     => cmd_data,
         cmd_resp_i     => cmd_resp,
         cmd_timeout_i  => cmd_timeout,
         resp_valid_o   => resp_valid,
         resp_ready_i   => resp_ready,
         resp_data_o    => resp_data,
         resp_timeout_o => resp_timeout,
         resp_error_o   => resp_error,
         sd_clk_i       => sd_clk,
         sd_cmd_in_i    => sd_cmd_in,
         sd_cmd_out_o   => sd_cmd_out,
         sd_cmd_oe_n_o  => sd_cmd_oe_n
      ); -- sdcard_cmd_inst

   sd_cmd    <= sd_cmd_out when sd_cmd_oe_n = '0' else
                'Z';
   sd_cmd_in <= sd_cmd;


   ---------------------------------------------------------
   -- Instantiate SDCard simulation model
   ---------------------------------------------------------

   sdcard_sim_inst : entity work.sdcard_sim
      port map (
         sd_clk_i   => sd_clk,
         sd_cmd_io  => sd_cmd,
         sd_dat_io  => sd_dat,
         mem_addr_o => mem_addr,
         mem_data_o => mem_data_out,
         mem_data_i => mem_data_in,
         mem_we_o   => mem_we
      ); -- sdcard_sim_inst

end architecture simulation;

