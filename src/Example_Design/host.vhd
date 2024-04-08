-- This is the host emulator for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity host is
   port (
      clk_i       : in    std_logic;
      rst_i       : in    std_logic;
      start_i     : in    std_logic;
      wr_o        : out   std_logic;
      wr_multi_o  : out   std_logic;
      wr_erase_o  : out   std_logic_vector(7 downto 0); -- for wr_multi_i only
      wr_data_o   : out   std_logic_vector(7 downto 0);
      wr_valid_o  : out   std_logic;
      wr_ready_i  : in    std_logic;
      rd_o        : out   std_logic;
      rd_multi_o  : out   std_logic;
      rd_data_i   : in    std_logic_vector(7 downto 0);
      rd_valid_i  : in    std_logic;
      rd_ready_o  : out   std_logic;
      busy_i      : in    std_logic;
      lba_o       : out   std_logic_vector(31 downto 0);
      iteration_o : out   std_logic_vector(15 downto 0);
      err_i       : in    std_logic_vector(7 downto 0)
   );
end entity host;

architecture synthesis of host is

   type   state_type is (
      IDLE_ST,
      WRITE_ST,
      READ_ST,
      READING_ST,
      ERROR_ST,
      WRITING_ST
   );

   signal state : state_type := IDLE_ST;

   signal offset    : natural range 0 to 511;
   signal seed      : unsigned(15 downto 0);
   signal iteration : unsigned(15 downto 0);

begin

   iteration_o <= std_logic_vector(iteration);
   rd_ready_o  <= '1';

   fsm_proc : process (clk_i)
      --

      pure function get_addr (
         seed_v      : unsigned;
         iteration_v : unsigned
      ) return std_logic_vector is
      begin
         return std_logic_vector(seed_v * (seed_v - iteration_v));
      end function get_addr;

      pure function get_data (
         seed_v   : unsigned;
         sector_v : std_logic_vector;
         offset_v : integer
      ) return std_logic_vector is
         variable data_v : std_logic_vector(31 downto 0);
         variable addr_v : integer;
      begin
         addr_v := to_integer(unsigned(sector_v)) * 512 + offset_v;
         data_v := std_logic_vector(to_signed(addr_v * (addr_v - to_integer(seed_v)), 32));
         return data_v(15 downto 8);
      end function get_data;

   --
   begin
      if rising_edge(clk_i) then
         if wr_ready_i = '1' then
            wr_valid_o <= '0';
         end if;

         if busy_i = '0' then
            rd_o       <= '0';
            rd_multi_o <= '0';
            wr_o       <= '0';
            wr_multi_o <= '0';
            wr_erase_o <= (others => '0');
         end if;

         case state is

            when IDLE_ST =>
               seed <= seed + 1;

            when WRITE_ST =>
               lba_o  <= get_addr(seed, iteration);
               offset <= 1;
               wr_o   <= '1';
               if wr_o = '1' and busy_i = '0' then
                  wr_o       <= '0';
                  wr_data_o  <= get_data(seed, lba_o, 0);
                  wr_valid_o <= '1';
                  state      <= WRITING_ST;
               end if;

            when WRITING_ST =>
               if wr_ready_i = '1' then
                  wr_data_o  <= get_data(seed, lba_o, offset);
                  wr_valid_o <= '1';
                  if offset < 511 then
                     offset <= offset + 1;
                  else
                     offset    <= 0;
                     state     <= READ_ST;
                     iteration <= iteration + 1;
                     if iteration = 0 then
                        state <= WRITE_ST;
                     end if;
                  end if;
               end if;

            when READ_ST =>
               lba_o  <= get_addr(seed, iteration - 2);
               offset <= 0;
               rd_o   <= '1';
               if rd_o = '1' and busy_i = '0' then
                  rd_o  <= '0';
                  state <= READING_ST;
               end if;

            when READING_ST =>
               if rd_valid_i = '1' then
                  if offset < 511 then
                     offset <= offset + 1;
                  else
                     state <= WRITE_ST;
                  end if;
                  assert rd_data_i = get_data(seed, lba_o, offset)
                     report "Read error at lba_o=" & to_hstring(lba_o)
                            & ", offset=" & to_string(offset)
                            & ". Got=" & to_hstring(rd_data_i)
                            & ", expected=" & to_hstring(get_data(seed, lba_o, offset));
                  if rd_data_i /= get_data(seed, lba_o, offset) then
                     state <= ERROR_ST;
                  end if;
               end if;

            when ERROR_ST =>
               null;

         end case;

         if start_i = '1' then
            iteration <= (others => '0');
            state     <= WRITE_ST;
         end if;

         if rst_i = '1' then
            rd_o       <= '0';
            rd_multi_o <= '0';
            wr_o       <= '0';
            wr_multi_o <= '0';
            wr_erase_o <= (others => '0');
            wr_valid_o <= '0';
            state      <= IDLE_ST;
            seed       <= (others => '0');
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

