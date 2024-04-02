-- Simulation model of SD card

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity sdcard_sim is
   port (
      sd_clk_i  : in    std_logic;
      sd_cmd_io : inout std_logic                    := 'H';
      sd_dat_io : inout std_logic_vector(3 downto 0) := (others => 'H')
   );
end entity sdcard_sim;

architecture simulation of sdcard_sim is

   signal   cmd           : unsigned(47 downto 0);
   signal   cmd_valid     : boolean;
   signal   cmd_receiving : boolean;
   signal   cmd_bit_count : natural range 0 to 48;

   signal   resp_data      : unsigned(135 downto 0)                      := (others => 'H');
   signal   resp_bit_count : natural range 0 to 136                      := 0;

   constant C_RESP_PADDING : unsigned(87 downto 0)                       := (others => 'H');

   -- Registers on card
   signal   card_status : unsigned( 31 downto 0)                         := X"00000000";
   signal   card_ocr    : unsigned( 31 downto 0)                         := X"C0FF8000";
   signal   card_cid    : unsigned(119 downto 0)                         := X"03534453433136478006DBCE32014C";
   signal   card_csd    : unsigned(119 downto 0)                         := X"400E00325B59000076B27F800A4040";
   signal   card_rca    : unsigned( 15 downto 0)                         := X"AAAA";

   subtype  R_CARD_STATUS_STATE is natural range 12 downto 9;
   constant C_CARD_STATUS_STATE_IDLE  : unsigned(3 downto 0)             := "0000";
   constant C_CARD_STATUS_STATE_READY : unsigned(3 downto 0)             := "0001";
   constant C_CARD_STATUS_STATE_IDENT : unsigned(3 downto 0)             := "0010";
   constant C_CARD_STATUS_STATE_STBY  : unsigned(3 downto 0)             := "0011";
   constant C_CARD_STATUS_STATE_TRAN  : unsigned(3 downto 0)             := "0100";
   constant C_CARD_STATUS_STATE_DATA  : unsigned(3 downto 0)             := "0101";
   constant C_CARD_STATUS_STATE_RCV   : unsigned(3 downto 0)             := "0110";
   constant C_CARD_STATUS_STATE_PRG   : unsigned(3 downto 0)             := "0111";
   constant C_CARD_STATUS_STATE_DIS   : unsigned(3 downto 0)             := "1000";

   constant C_CARD_STAT_OUT_OF_RANGE       : unsigned(31 downto 0)       := X"80000000";
   constant C_CARD_STAT_ADDRESS_ERROR      : unsigned(31 downto 0)       := X"40000000";
   constant C_CARD_STAT_BLOCK_LEN_ERROR    : unsigned(31 downto 0)       := X"20000000";
   constant C_CARD_STAT_ERASE_SEQ_ERROR    : unsigned(31 downto 0)       := X"10000000";
   constant C_CARD_STAT_ERASE_PARAM        : unsigned(31 downto 0)       := X"08000000";
   constant C_CARD_STAT_WP_VIOLATION       : unsigned(31 downto 0)       := X"04000000";
   constant C_CARD_STAT_CARD_IS_LOCKED     : unsigned(31 downto 0)       := X"02000000";
   constant C_CARD_STAT_LOCK_UNLOCK_FAILED : unsigned(31 downto 0)       := X"01000000";
   constant C_CARD_STAT_COM_CRC_ERROR      : unsigned(31 downto 0)       := X"00800000";
   constant C_CARD_STAT_ILLEGAL_COMMAND    : unsigned(31 downto 0)       := X"00400000";
   constant C_CARD_STAT_CARD_ECC_FAILED    : unsigned(31 downto 0)       := X"00200000";
   constant C_CARD_STAT_CC_ERROR           : unsigned(31 downto 0)       := X"00100000";
   constant C_CARD_STAT_ERROR              : unsigned(31 downto 0)       := X"00080000";
   constant C_CARD_STAT_CSD_OVERWRITE      : unsigned(31 downto 0)       := X"00010000";
   constant C_CARD_STAT_WP_ERASE_SKIP      : unsigned(31 downto 0)       := X"00008000";
   constant C_CARD_STAT_CARD_ECC_DISABED   : unsigned(31 downto 0)       := X"00004000";
   constant C_CARD_STAT_ERASE_RESET        : unsigned(31 downto 0)       := X"00002000";
   constant C_CARD_STAT_READY_FOR_DATA     : unsigned(31 downto 0)       := X"00000100";
   constant C_CARD_STAT_FX_EVENT           : unsigned(31 downto 0)       := X"00000040";
   constant C_CARD_STAT_APP_CMD            : unsigned(31 downto 0)       := X"00000020";
   constant C_CARD_STAT_AKE_SEQ_ERROR      : unsigned(31 downto 0)       := X"00000008";

   constant C_CMD_GO_IDLE              : unsigned(7 downto 0)            := X"00"; -- CMD0
   constant C_CMD_ALL_SEND_CID         : unsigned(7 downto 0)            := X"02"; -- CMD2
   constant C_CMD_SEND_RELATIVE_ADDR   : unsigned(7 downto 0)            := X"03"; -- CMD3
   constant C_CMD_SELECT_DESELECT_CARD : unsigned(7 downto 0)            := X"07"; -- CMD7
   constant C_CMD_SEND_IF_COND         : unsigned(7 downto 0)            := X"08"; -- CMD8
   constant C_CMD_SEND_CSD             : unsigned(7 downto 0)            := X"09"; -- CMD9
   constant C_CMD_READ_SINGLE_BLOCK    : unsigned(7 downto 0)            := X"11"; -- CMD17
   constant C_CMD_APP_CMD              : unsigned(7 downto 0)            := X"37"; -- CMD55
   constant C_CMD_SET_BUS_WIDTH        : unsigned(7 downto 0)            := X"06"; -- ACMD6
   constant C_CMD_SD_SEND_OP_COND      : unsigned(7 downto 0)            := X"29"; -- ACMD41

   pure function calc_crc (
      arg : unsigned
   ) return unsigned is
      constant C_POLYNOMIAL : unsigned(6 downto 0) := "0001001";
      variable crc_v        : unsigned(6 downto 0);
   begin
      crc_v := (others => '0');

      for i in arg'range loop
         if to_01(arg(i)) /= crc_v(6) then
            crc_v := (crc_v(5 downto 0) & "0") xor C_POLYNOMIAL;
         else
            crc_v := (crc_v(5 downto 0) & "0");
         end if;
      end loop;

      return crc_v;
   end function calc_crc;

   pure function crc_valid (
      arg : unsigned
   ) return boolean is
   begin
      return arg(7 downto 0) = calc_crc(arg(arg'left downto 8)) & "1";
   end function crc_valid;

   pure function append_crc (
      arg : unsigned
   ) return unsigned is
   begin
      return arg & calc_crc(arg) & "1";
   end function append_crc;

   type     reader_state_type is (IDLE_ST, WAIT_ST, READ_ST, SEND_ST);
   signal   reader_state        : reader_state_type                      := IDLE_ST;
   constant C_READER_WAITER_MAX : natural                                := 10000;
   signal   reader_waiter       : natural range 0 to C_READER_WAITER_MAX := 0;
   signal   reader_addr         : unsigned(31 downto 0);

   type     ram_type is array (natural range <>) of std_logic_vector(7 downto 0);

   pure function gen_ram_data return ram_type is
      variable data_v : std_logic_vector(31 downto 0);
      variable res_v  : ram_type(0 to 32767);
   begin
      for i in 0 to 32767 loop
         data_v   := std_logic_vector(to_signed(i * (i - 512), 32));
         res_v(i) := data_v(15 downto 8);
      end loop;

      return res_v;
   end function;

   signal   ram : ram_type(0 to 32767)                                   := gen_ram_data;

begin

   cmd_proc : process (sd_clk_i)
   begin
      if rising_edge(sd_clk_i) then
         cmd_valid <= false;

         if cmd_receiving = false then
            -- Wait for a start bit.
            if to_01(sd_cmd_io) = '0' and resp_bit_count = 0 then
               cmd_receiving <= true;
               cmd           <= (others => '0');
               cmd_bit_count <= 1;
            end if;
         else
            if cmd_bit_count <= 47 then
               cmd           <= cmd(46 downto 0) & to_01(sd_cmd_io);
               cmd_bit_count <= cmd_bit_count + 1;
            else
               if crc_valid(cmd) and to_01(cmd(47 downto 46)) = "01" then
                  cmd_valid <= true;
               end if;
               cmd_receiving <= false;
            end if;
         end if;
      end if;
   end process cmd_proc;

   reader_proc : process (sd_clk_i)
   begin
      if rising_edge(sd_clk_i) then
         sd_dat_io <= (others => 'H');

         case reader_state is

            when IDLE_ST =>
               if cmd_valid and ("00" & cmd(45 downto 40) = C_CMD_READ_SINGLE_BLOCK) then
                  reader_waiter <= C_READER_WAITER_MAX;
                  reader_addr   <= cmd(30 downto 8) & "000000000";
                  reader_state  <= WAIT_ST;
               end if;

            when WAIT_ST =>
               if reader_waiter > 0 then
                  reader_waiter <= reader_waiter - 1;
               else
                  reader_state <= READ_ST;
                  sd_dat_io    <= (others => '0');
               end if;

            when READ_ST =>
               sd_dat_io <= ram(to_integer(reader_addr(14 downto 0)))(7 downto 4);
               reader_state <= SEND_ST;

            when SEND_ST =>
               sd_dat_io <= ram(to_integer(reader_addr(14 downto 0)))(3 downto 0);
               if reader_addr(8 downto 0) = "111111111" then
                  reader_state <= IDLE_ST;
               else
                  reader_addr  <= reader_addr  + 1;
                  reader_state <= READ_ST;
               end if;

         end case;

      end if;
   end process reader_proc;

   fsm_proc : process (sd_clk_i)
      variable resp_v : unsigned(39 downto 0);
   begin
      if rising_edge(sd_clk_i) then
         if resp_bit_count > 0 then
            -- Send back response
            sd_cmd_io      <= resp_data(135);
            resp_data      <= resp_data(134 downto 0) & "H";
            resp_bit_count <= resp_bit_count - 1;
         else
            sd_cmd_io <= 'Z';
         end if;

         if cmd_valid then
            card_status    <= card_status and not C_CARD_STAT_APP_CMD;
            resp_bit_count <= 48;

            case "00" & cmd(45 downto 40) is

               -- CMD0
               when C_CMD_GO_IDLE =>
                  card_status                      <= (others => '0');
                  card_status(R_CARD_STATUS_STATE) <= C_CARD_STATUS_STATE_IDLE;
                  resp_bit_count                   <= 0;

               -- CMD2
               when C_CMD_ALL_SEND_CID =>
                  -- R2
                  resp_data                        <= X"3F" & append_crc(card_cid);
                  resp_bit_count                   <= 136;
                  card_status(R_CARD_STATUS_STATE) <= C_CARD_STATUS_STATE_IDENT;

               -- CMD3
               when C_CMD_SEND_RELATIVE_ADDR =>
                  -- R6
                  resp_v                           := "00" & cmd(45 downto 8) or (X"00" & C_CARD_STAT_READY_FOR_DATA);
                  resp_v(R_CARD_STATUS_STATE)      := card_status(R_CARD_STATUS_STATE);
                  resp_data                        <= append_crc(resp_v) & C_RESP_PADDING;
                  card_status(R_CARD_STATUS_STATE) <= C_CARD_STATUS_STATE_STBY;

               -- CMD7
               when C_CMD_SELECT_DESELECT_CARD =>
                  -- R1b
                  resp_v                      := "00" & cmd(45 downto 8) or (X"00" & C_CARD_STAT_READY_FOR_DATA);
                  resp_v(R_CARD_STATUS_STATE) := card_status(R_CARD_STATUS_STATE);
                  resp_data                   <= append_crc(resp_v) & C_RESP_PADDING;
                  if card_status(R_CARD_STATUS_STATE) = C_CARD_STATUS_STATE_STBY then
                     card_status(R_CARD_STATUS_STATE) <= C_CARD_STATUS_STATE_TRAN;
                  elsif card_status(R_CARD_STATUS_STATE) = C_CARD_STATUS_STATE_TRAN then
                     card_status(R_CARD_STATUS_STATE) <= C_CARD_STATUS_STATE_STBY;
                  end if;


               -- CMD8
               when C_CMD_SEND_IF_COND =>
                  -- R7
                  resp_data <= append_crc(C_CMD_SEND_IF_COND & cmd(39 downto 8)) & C_RESP_PADDING;

               -- CMD9
               when C_CMD_SEND_CSD =>
                  -- R2
                  resp_data      <= X"3F" & append_crc(card_csd);
                  resp_bit_count <= 136;

               -- CMD17
               when C_CMD_READ_SINGLE_BLOCK =>
                  -- R1
                  resp_v                      := "00" & cmd(45 downto 8);
                  resp_v(R_CARD_STATUS_STATE) := card_status(R_CARD_STATUS_STATE);
                  resp_data                   <= append_crc(resp_v) & C_RESP_PADDING;

               -- CMD55
               when C_CMD_APP_CMD =>
                  -- R1
                  resp_v                      := C_CMD_APP_CMD &
                                                 (C_CARD_STAT_READY_FOR_DATA or C_CARD_STAT_APP_CMD);
                  resp_v(R_CARD_STATUS_STATE) := card_status(R_CARD_STATUS_STATE);
                  resp_data                   <= append_crc(resp_v) & C_RESP_PADDING;
                  card_status                 <= card_status or C_CARD_STAT_APP_CMD;

               -- ACMD6
               when C_CMD_SET_BUS_WIDTH =>
                  if (card_status and C_CARD_STAT_APP_CMD) /= 0 then
                     -- R1
                     resp_v                      := "00" & cmd(45 downto 8)
                                                    or X"00" & (C_CARD_STAT_READY_FOR_DATA or C_CARD_STAT_APP_CMD);
                     resp_v(R_CARD_STATUS_STATE) := card_status(R_CARD_STATUS_STATE);
                     resp_data                   <= append_crc(resp_v) & C_RESP_PADDING;
                  end if;

               -- ACMD41
               when C_CMD_SD_SEND_OP_COND =>
                  if (card_status and C_CARD_STAT_APP_CMD) /= 0 then
                     -- R3
                     resp_v    := X"3F" & card_ocr;
                     resp_data <= append_crc(resp_v) & C_RESP_PADDING;
                  end if;

               when others =>
                  null;

            end case;

         end if;
      end if;
   end process fsm_proc;

end architecture simulation;

