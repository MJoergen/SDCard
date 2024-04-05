-- This is the host emulator for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity host is
   port (
      clk_i      : in    std_logic;
      rst_i      : in    std_logic;
      start_i    : in    std_logic;
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
      err_i      : in    std_logic_vector(7 downto 0)
   );
end entity host;

architecture synthesis of host is

   type   state_type is (
      IDLE_ST,
      READY_ST,
      WAIT_ST,
      WRITE_ST,
      READ_ST,
      READING_ST,
      ERROR_ST,
      WRITING_ST
   );

   signal state : state_type := IDLE_ST;

   signal fsm_update    : std_logic;
   signal random_output : std_logic_vector(31 downto 0);
   signal sector        : std_logic_vector(31 downto 0);
   signal offset        : natural range 0 to 511;

begin

   -- Only update address once every read command
   fsm_update <= (wr_o or rd_o) and not busy_i;

   random_inst : entity work.random
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         update_i   => fsm_update,
         load_i     => rst_i,
         load_val_i => X"89ABCDEF",
         output_o   => random_output
      ); -- random_inst

   lba_o      <= "0000" & not random_output(27 downto 0);

   rd_ready_o <= '1';

   fsm_proc : process (clk_i)
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
               if start_i = '1' then
                  state <= READY_ST;
               end if;

            when READY_ST =>
               sector <= lba_o;
               offset <= 0;
               if random_output(31) = '1' then
                  wr_o  <= '1';
                  state <= WRITE_ST;
               else
                  rd_o  <= '1';
                  state <= READ_ST;
               end if;

            when WRITE_ST =>
               if busy_i = '0' then
                  wr_data_o  <= get_data(sector, 0);
                  wr_valid_o <= '1';
                  offset     <= 1;
                  state      <= WRITING_ST;
               end if;

            when WRITING_ST =>
               if wr_ready_i = '1' then
                  wr_data_o  <= get_data(sector, offset);
                  wr_valid_o <= '1';
                  if offset < 511 then
                     offset <= offset + 1;
                  else
                     offset <= 0;
                     state  <= WAIT_ST;
                  end if;
               end if;

            when WAIT_ST =>
               if busy_i = '0' then
                  state <= READY_ST;
               end if;

            when READ_ST =>
               if busy_i = '0' then
                  state <= READING_ST;
               end if;

            when READING_ST =>
               if rd_valid_i = '1' then
                  if offset < 511 then
                     offset <= offset + 1;
                  else
                     state <= READY_ST;
                  end if;
                  assert rd_data_i = get_data(sector, offset)
                     report "Read error at sector=" & to_hstring(sector)
                            & ", offset=" & to_string(offset)
                            & ". Got=" & to_hstring(rd_data_i)
                            & ", expected=" & to_hstring(get_data(sector, offset));
               end if;

            when ERROR_ST =>
               null;

         end case;

         if rst_i = '1' then
            rd_o       <= '0';
            rd_multi_o <= '0';
            wr_o       <= '0';
            wr_multi_o <= '0';
            wr_erase_o <= (others => '0');
            wr_valid_o <= '0';
            state      <= IDLE_ST;
         end if;
      end if;
   end process fsm_proc;

end architecture synthesis;

