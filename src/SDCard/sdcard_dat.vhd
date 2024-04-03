-- Created by Michael Jørgensen in 2024 (mjoergen.github.io/SDCard).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library work;
   use work.sdcard_globals.all;

entity sdcard_dat is
   port (
      clk_i          : in    std_logic; -- 50 MHz
      rst_i          : in    std_logic;

      dat_wr_data_i  : in    std_logic_vector(7 downto 0);
      dat_wr_valid_i : in    std_logic;
      dat_wr_ready_o : out   std_logic;

      dat_rd_data_o  : out   std_logic_vector(7 downto 0);
      dat_rd_valid_o : out   std_logic;
      dat_rd_ready_i : in    std_logic;
      dat_rd_done_o  : out   std_logic;
      dat_rd_error_o : out   std_logic;

      -- SDCard device interface
      sd_clk_i       : in    std_logic; -- 25 MHz or 400 kHz
      sd_dat_in_i    : in    std_logic_vector(3 downto 0);
      sd_dat_out_o   : out   std_logic_vector(3 downto 0);
      sd_dat_oe_n_o  : out   std_logic
   );
end entity sdcard_dat;

architecture synthesis of sdcard_dat is

   constant C_RX_COUNT_MAX : natural := 1024 + 16;

   signal   sd_clk_d : std_logic;

   signal   rx_count : natural range 0 to C_RX_COUNT_MAX;
   signal   crc0     : std_logic_vector(15 downto 0);
   signal   crc1     : std_logic_vector(15 downto 0);
   signal   crc2     : std_logic_vector(15 downto 0);
   signal   crc3     : std_logic_vector(15 downto 0);
   signal   rx_crc0  : std_logic_vector(15 downto 0);
   signal   rx_crc1  : std_logic_vector(15 downto 0);
   signal   rx_crc2  : std_logic_vector(15 downto 0);
   signal   rx_crc3  : std_logic_vector(15 downto 0);

   signal   rx_msb_data  : std_logic_vector(3 downto 0);
   signal   rx_msb_valid : std_logic;

   -- This calculates the 16-bit CRC using the polynomial x^16 + x^12 + x^5 + x^0.
   -- See this link: http://www.ghsi.de/pages/subpages/Online%20CRC%20Calculation/indexDetails.php?Polynom=10001000000100001&Message=AB

   pure function new_crc (
      cur_crc : std_logic_vector;
      val : std_logic
   ) return std_logic_vector is
      variable inv_v : std_logic;
      variable upd_v : std_logic_vector(15 downto 0);
   begin
      inv_v := val xor cur_crc(15);
      upd_v := (0 => inv_v, 5 => inv_v, 12 => inv_v, others => '0');
      return (cur_crc(14 downto 0) & "0") xor upd_v;
   end function new_crc;

   type     state_type is (
      IDLE_ST,
      RX_ST,
      FORWARD_ST
   );

   signal   state : state_type       := IDLE_ST;

   type     sector_type is array (0 to 511) of std_logic_vector(7 downto 0);
   signal   sector : sector_type;
   signal   addr   : natural range 0 to 511;

begin

   dat_wr_ready_o <= '1';
   dat_rd_data_o  <= sector(addr);

   fsm_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         dat_rd_done_o <= '0';
         dat_rd_error_o <= '0';

         if dat_rd_ready_i = '1' then
            dat_rd_valid_o <= '0';
         end if;

         case state is

            when IDLE_ST =>
               if sd_clk_d = '0' and sd_clk_i = '1' then
                  -- Rising edge of sd_clk_i
                  if sd_dat_in_i = "0000" then
                     rx_count     <= C_RX_COUNT_MAX;
                     crc0         <= (others => '0');
                     crc1         <= (others => '0');
                     crc2         <= (others => '0');
                     crc3         <= (others => '0');
                     rx_msb_valid <= '0';
                     state        <= RX_ST;
                     addr         <= 0;
                  end if;
               end if;

            when RX_ST =>
               if sd_clk_d = '0' and sd_clk_i = '1' then
                  -- Rising edge of sd_clk_i
                  if rx_count > 16 then
                     if rx_msb_valid = '0' then
                        rx_msb_data  <= sd_dat_in_i;
                        rx_msb_valid <= '1';
                     else
                        sector(addr) <= rx_msb_data & sd_dat_in_i;
                        if addr < 511 then
                           addr <= addr + 1;
                        else
                           addr <= 0;
                        end if;
                        rx_msb_valid <= '0';
                     end if;
                     crc0 <= new_crc(crc0, sd_dat_in_i(0));
                     crc1 <= new_crc(crc1, sd_dat_in_i(1));
                     crc2 <= new_crc(crc2, sd_dat_in_i(2));
                     crc3 <= new_crc(crc3, sd_dat_in_i(3));
                  end if;

                  if rx_count > 0 then
                     rx_count <= rx_count - 1;
                     rx_crc0  <= rx_crc0(14 downto 0) & sd_dat_in_i(0);
                     rx_crc1  <= rx_crc1(14 downto 0) & sd_dat_in_i(1);
                     rx_crc2  <= rx_crc2(14 downto 0) & sd_dat_in_i(2);
                     rx_crc3  <= rx_crc3(14 downto 0) & sd_dat_in_i(3);
                  else
                     if rx_crc0 /= crc0 or rx_crc1 /= crc1 or rx_crc2 /= crc2 or rx_crc3 /= crc3 then
                        dat_rd_error_o <= '1';
                        state <= IDLE_ST;
                     else
                        addr           <= 0;
                        dat_rd_valid_o <= '1';
                        state          <= FORWARD_ST;
                     end if;
                  end if;
               end if;

            when FORWARD_ST =>
               if dat_rd_ready_i = '1' then
                  if addr < 511 then
                     addr           <= addr + 1;
                     dat_rd_valid_o <= '1';
                  else
                     dat_rd_done_o <= '1';
                     state         <= IDLE_ST;
                  end if;
               end if;

         end case;

         if rst_i = '1' then
            state <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

   -- Output is changed on falling edge of clk. The SDCard samples on rising clock edge.
   out_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         sd_clk_d <= sd_clk_i;
         if sd_clk_d = '1' and sd_clk_i = '0' then -- Falling edge of sd_clk_i
            sd_dat_out_o  <= "1111";
            sd_dat_oe_n_o <= '1';
         end if;
      end if;
   end process out_proc;

end architecture synthesis;

