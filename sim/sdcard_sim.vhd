-- Simulation model of SD card

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

entity sdcard_sim is
   port (
      sd_clk_i   : in    std_logic;
      sd_cmd_io  : inout std_logic                    := 'H';
      sd_dat_io  : inout std_logic_vector(3 downto 0) := (others => 'H');

      mem_addr_o : out   std_logic_vector(31 downto 0);
      mem_data_o : out   std_logic_vector(7 downto 0);
      mem_data_i : in    std_logic_vector(7 downto 0);
      mem_we_o   : out   std_logic
   );
end entity sdcard_sim;

architecture simulation of sdcard_sim is

   signal   cmd           : unsigned(47 downto 0);
   signal   cmd_valid     : boolean;
   signal   cmd_receiving : boolean;
   signal   cmd_bit_count : natural range 0 to 48;

   signal   resp_data      : unsigned(135 downto 0)                := (others => 'H');
   signal   resp_bit_count : natural range 0 to 136                := 0;

   constant C_RESP_PADDING : unsigned(87 downto 0)                 := (others => 'H');

   -- Registers on card
   signal   card_status : unsigned( 31 downto 0)                   := X"00000000";
   signal   card_ocr    : unsigned( 31 downto 0)                   := X"C0FF8000";
   signal   card_cid    : unsigned(119 downto 0)                   := X"03534453433136478006DBCE32014C";
   signal   card_csd    : unsigned(119 downto 0)                   := X"400E00325B59000076B27F800A4040";
   signal   card_rca    : unsigned( 15 downto 0)                   := X"AAAA";

   subtype  r_card_status_state is natural range 12 downto 9;
   constant C_CARD_STATUS_STATE_IDLE  : unsigned(3 downto 0)       := "0000";
   constant C_CARD_STATUS_STATE_READY : unsigned(3 downto 0)       := "0001";
   constant C_CARD_STATUS_STATE_IDENT : unsigned(3 downto 0)       := "0010";
   constant C_CARD_STATUS_STATE_STBY  : unsigned(3 downto 0)       := "0011";
   constant C_CARD_STATUS_STATE_TRAN  : unsigned(3 downto 0)       := "0100";
   constant C_CARD_STATUS_STATE_DATA  : unsigned(3 downto 0)       := "0101";
   constant C_CARD_STATUS_STATE_RCV   : unsigned(3 downto 0)       := "0110";
   constant C_CARD_STATUS_STATE_PRG   : unsigned(3 downto 0)       := "0111";
   constant C_CARD_STATUS_STATE_DIS   : unsigned(3 downto 0)       := "1000";

   constant C_CARD_STAT_OUT_OF_RANGE       : unsigned(31 downto 0) := X"80000000";
   constant C_CARD_STAT_ADDRESS_ERROR      : unsigned(31 downto 0) := X"40000000";
   constant C_CARD_STAT_BLOCK_LEN_ERROR    : unsigned(31 downto 0) := X"20000000";
   constant C_CARD_STAT_ERASE_SEQ_ERROR    : unsigned(31 downto 0) := X"10000000";
   constant C_CARD_STAT_ERASE_PARAM        : unsigned(31 downto 0) := X"08000000";
   constant C_CARD_STAT_WP_VIOLATION       : unsigned(31 downto 0) := X"04000000";
   constant C_CARD_STAT_CARD_IS_LOCKED     : unsigned(31 downto 0) := X"02000000";
   constant C_CARD_STAT_LOCK_UNLOCK_FAILED : unsigned(31 downto 0) := X"01000000";
   constant C_CARD_STAT_COM_CRC_ERROR      : unsigned(31 downto 0) := X"00800000";
   constant C_CARD_STAT_ILLEGAL_COMMAND    : unsigned(31 downto 0) := X"00400000";
   constant C_CARD_STAT_CARD_ECC_FAILED    : unsigned(31 downto 0) := X"00200000";
   constant C_CARD_STAT_CC_ERROR           : unsigned(31 downto 0) := X"00100000";
   constant C_CARD_STAT_ERROR              : unsigned(31 downto 0) := X"00080000";
   constant C_CARD_STAT_CSD_OVERWRITE      : unsigned(31 downto 0) := X"00010000";
   constant C_CARD_STAT_WP_ERASE_SKIP      : unsigned(31 downto 0) := X"00008000";
   constant C_CARD_STAT_CARD_ECC_DISABED   : unsigned(31 downto 0) := X"00004000";
   constant C_CARD_STAT_ERASE_RESET        : unsigned(31 downto 0) := X"00002000";
   constant C_CARD_STAT_READY_FOR_DATA     : unsigned(31 downto 0) := X"00000100";
   constant C_CARD_STAT_FX_EVENT           : unsigned(31 downto 0) := X"00000040";
   constant C_CARD_STAT_APP_CMD            : unsigned(31 downto 0) := X"00000020";
   constant C_CARD_STAT_AKE_SEQ_ERROR      : unsigned(31 downto 0) := X"00000008";

   constant C_CMD_GO_IDLE            : unsigned(7 downto 0)        := X"00"; -- CMD0
   constant C_CMD_ALL_SEND_CID       : unsigned(7 downto 0)        := X"02"; -- CMD2
   constant C_CMD_SEND_RELATIVE_ADDR : unsigned(7 downto 0)        := X"03"; -- CMD3
   constant C_CMD_SEND_IF_COND       : unsigned(7 downto 0)        := X"08"; -- CMD8
   constant C_CMD_APP_CMD            : unsigned(7 downto 0)        := X"37"; -- CMD55
   constant C_CMD_SD_SEND_OP_COND    : unsigned(7 downto 0)        := X"29"; -- ACMD41

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

begin

   -- TBD
   mem_addr_o <= (others => '0');
   mem_data_o <= (others => '0');
   mem_we_o   <= '0';

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
                  resp_data      <= X"3F" & append_crc(card_cid);
                  resp_bit_count <= 136;

               -- CMD3
               when C_CMD_SEND_RELATIVE_ADDR =>
                  -- R6
                  resp_v                      := cmd(47 downto 8);
                  resp_v(R_CARD_STATUS_STATE) := card_status(r_card_status_state);
                  resp_data                   <= append_crc(resp_v) & C_RESP_PADDING;

               -- CMD8
               when C_CMD_SEND_IF_COND =>
                  -- R7
                  resp_data <= append_crc(C_CMD_SEND_IF_COND & cmd(39 downto 8)) & C_RESP_PADDING;

               -- CMD55
               when C_CMD_APP_CMD =>
                  -- R1
                  resp_v                      := C_CMD_APP_CMD &
                                                 (C_CARD_STAT_READY_FOR_DATA or C_CARD_STAT_APP_CMD);
                  resp_v(R_CARD_STATUS_STATE) := card_status(r_card_status_state);
                  resp_data                   <= append_crc(resp_v) & C_RESP_PADDING;
                  card_status                 <= card_status or C_CARD_STAT_APP_CMD;

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

