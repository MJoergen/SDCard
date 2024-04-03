-- This is the wrapper file for the complete SDCard controller.

-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDCard).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std_unsigned.all;

entity sdcard_wrapper is
   port (
      clk_i      : in    std_logic;                    -- 50 Mhz
      rst_i      : in    std_logic;                    -- Synchronous reset, active high

      wr_i       : in    std_logic;
      wr_multi_i : in    std_logic;
      wr_erase_i : in    std_logic_vector(7 downto 0); -- for wr_multi_i only
      wr_data_i  : in    std_logic_vector(7 downto 0);
      wr_valid_i : in    std_logic;
      wr_ready_o : out   std_logic;

      rd_i       : in    std_logic;
      rd_multi_i : in    std_logic;
      rd_data_o  : out   std_logic_vector(7 downto 0);
      rd_valid_o : out   std_logic;
      rd_ready_i : in    std_logic;

      busy_o     : out   std_logic;
      lba_i      : in    std_logic_vector(31 downto 0);
      err_o      : out   std_logic_vector(7 downto 0);

      -- SDCard device interface
      sd_clk_o   : out   std_logic;
      sd_cmd_io  : inout std_logic;
      sd_dat_io  : inout std_logic_vector(3 downto 0)
   );
end entity sdcard_wrapper;

architecture synthesis of sdcard_wrapper is

   signal sd_clk      : std_logic; -- 25 MHz or 400 kHz
   signal sd_cmd_in   : std_logic;
   signal sd_cmd_out  : std_logic;
   signal sd_cmd_oe_n : std_logic;
   signal sd_dat_in   : std_logic_vector(3 downto 0);
   signal sd_dat_out  : std_logic_vector(3 downto 0);
   signal sd_dat_oe_n : std_logic;

   signal sd_clk_reg      : std_logic;
   signal sd_cmd_out_reg  : std_logic;
   signal sd_cmd_oe_n_reg : std_logic;
   signal sd_dat_out_reg  : std_logic_vector(3 downto 0);
   signal sd_dat_oe_n_reg : std_logic;

   -- These signals are references in the XDC file, and must therefore not be optimized or
   -- altered in any way.
   attribute dont_touch : string;
   attribute dont_touch of sd_clk_reg      : signal is "true";
   attribute dont_touch of sd_cmd_out_reg  : signal is "true";
   attribute dont_touch of sd_cmd_oe_n_reg : signal is "true";
   attribute dont_touch of sd_dat_out_reg  : signal is "true";
   attribute dont_touch of sd_dat_oe_n_reg : signal is "true";

   signal cmd_valid    : std_logic;
   signal cmd_ready    : std_logic;
   signal cmd_index    : natural range 0 to 63;
   signal cmd_data     : std_logic_vector(31 downto 0);
   signal cmd_resp     : natural range 0 to 255;
   signal cmd_timeout  : natural range 0 to 2 ** 24 - 1;
   signal resp_valid   : std_logic;
   signal resp_ready   : std_logic;
   signal resp_data    : std_logic_vector(135 downto 0);
   signal resp_timeout : std_logic;
   signal resp_error   : std_logic;
   signal dat_rd_done  : std_logic;

   signal sd_clk_d  : std_logic;
   signal count_low : std_logic_vector(7 downto 0);

begin

   ----------------------------------
   -- Instantiate main state machine
   ----------------------------------

   sdcard_ctrl_inst : entity work.sdcard_ctrl
      port map (
         clk_i           => clk_i,
         rst_i           => rst_i,
         ctrl_wr_i       => wr_i,
         ctrl_wr_multi_i => wr_multi_i,
         ctrl_wr_erase_i => wr_erase_i,
         ctrl_rd_i       => rd_i,
         ctrl_rd_multi_i => rd_multi_i,
         ctrl_busy_o     => busy_o,
         ctrl_lba_i      => lba_i,
         ctrl_err_o      => err_o,
         sd_clk_o        => sd_clk,
         dat_rd_done_i   => dat_rd_done,
         cmd_valid_o     => cmd_valid,
         cmd_ready_i     => cmd_ready,
         cmd_index_o     => cmd_index,
         cmd_data_o      => cmd_data,
         cmd_resp_o      => cmd_resp,
         cmd_timeout_o   => cmd_timeout,
         resp_valid_i    => resp_valid,
         resp_ready_o    => resp_ready,
         resp_data_i     => resp_data,
         resp_timeout_i  => resp_timeout,
         resp_error_i    => resp_error
      ); -- sdcard_ctrl_inst


   ----------------------------------
   -- Instantiate CMD controller
   ----------------------------------

   sdcard_cmd_inst : entity work.sdcard_cmd
      port map (
         clk_i          => clk_i,
         rst_i          => rst_i,
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
      ); -- sdcard_cmd_logger_inst


   ----------------------------------
   -- Instantiate DAT controller
   ----------------------------------

   sdcard_dat_inst : entity work.sdcard_dat
      port map (
         clk_i          => clk_i,
         rst_i          => rst_i,
         dat_wr_data_i  => wr_data_i,
         dat_wr_valid_i => wr_valid_i,
         dat_wr_ready_o => wr_ready_o,
         dat_rd_data_o  => rd_data_o,
         dat_rd_valid_o => rd_valid_o,
         dat_rd_ready_i => rd_ready_i,
         dat_rd_done_o  => dat_rd_done,
         sd_clk_i       => sd_clk,
         sd_dat_in_i    => sd_dat_in,
         sd_dat_out_o   => sd_dat_out,
         sd_dat_oe_n_o  => sd_dat_oe_n
      ); -- sdcard_dat_inst

   count_low_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sd_clk_d <= sd_clk;

         if sd_clk_d = '0' and sd_clk = '1' then
            if sd_cmd_in = '0' then
               count_low <= count_low + 1;
            else
               count_low <= (others => '0');
            end if;
         end if;
      end if;
   end process count_low_proc;


   ---------------------------------------------------------
   -- Connect I/O buffers
   ---------------------------------------------------------

   output_reg_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sd_clk_reg      <= sd_clk;
         sd_cmd_out_reg  <= sd_cmd_out;
         sd_cmd_oe_n_reg <= sd_cmd_oe_n;
         sd_dat_out_reg  <= sd_dat_out;
         sd_dat_oe_n_reg <= sd_dat_oe_n;
      end if;
   end process output_reg_proc;

   sd_clk_o  <= sd_clk_reg;
   sd_cmd_in <= sd_cmd_io;
   sd_dat_in <= sd_dat_io;
   sd_cmd_io <= sd_cmd_out_reg when sd_cmd_oe_n_reg = '0' else
                'Z';
   sd_dat_io <= sd_dat_out_reg when sd_dat_oe_n_reg = '0' else
                (others => 'Z');

end architecture synthesis;

