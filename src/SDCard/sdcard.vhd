-- This is the wrapper file for the complete SDCard controller.

-- The SD Card is powered up in the SD mode. It will enter SPI mode if the
-- CS (DAT3) signal is asserted (negative) during the reception of the reset
-- command (CMD0). If the card recognizes that the SD mode is required it
-- will not respond to the command and remain in the SD mode. If SPI mode is
-- required, the card will switch to SPI and respond with the SPI mode R1
-- response.

-- List of used commands:
-- CMD0  : GO_IDLE_STATE: Resets the SD Card.
-- CMD3  : SEND_RCA
-- CMD8  : SEND_IF_COND: Sends SD Memory Card interface condition that includes host supply voltage.
-- ACMD41: SD_SEND_OP_COND: Sends host capacity support information and activated the card's initialization process.
-- CMD13 : SEND_STATUS: Asks the selected card to send its status register.
-- CMD16 : SET_BLOCKLEN: In case of non-SDHC card, this sets the block length. Block length of SDHC/SDXC cards are fixed to 512 bytes
-- CMD17 : READ_SINGLE_BLOCK
-- CMD24 : WRITE_BLOCK
-- CMD55 : APP_CMD: Next command is an application specific command.
-- CMD58 : READ_OCR: Read the OCR register of the card.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.sdcard_globals.all;

entity sdcard is
   port (
      -- Avalon Memory Map
      avm_clk_i           : in  std_logic;   -- 50 Mhz
      avm_rst_i           : in  std_logic;   -- Synchronous reset, active high
      avm_write_i         : in  std_logic;
      avm_read_i          : in  std_logic;
      avm_address_i       : in  std_logic_vector(31 downto 0);
      avm_writedata_i     : in  std_logic_vector(7 downto 0);
      avm_burstcount_i    : in  std_logic_vector(15 downto 0);
      avm_readdata_o      : out std_logic_vector(7 downto 0);
      avm_readdatavalid_o : out std_logic;
      avm_waitrequest_o   : out std_logic;

      -- SDCard device interface
      sd_cd_i             : in  std_logic;
      sd_clk_o            : out std_logic;   -- 25 MHz or 400 kHz
      sd_cmd_in_i         : in  std_logic;
      sd_cmd_out_o        : out std_logic;
      sd_cmd_oe_o         : out std_logic;
      sd_dat_in_i         : in  std_logic_vector(3 downto 0);
      sd_dat_out_o        : out std_logic_vector(3 downto 0);
      sd_dat_oe_o         : out std_logic;

      uart_tx_o           : out std_logic
   );
end entity sdcard;

architecture synthesis of sdcard is

   -- Number of attempts at initiliazing card (ACMD41)
   constant INIT_COUNT_MAX : natural := 100; -- Approximately one second

   signal sd_cd         : std_logic;
   signal counter_slow  : std_logic_vector(6 downto 0) := (others => '0');
   signal cmd_valid     : std_logic;
   signal cmd_ready     : std_logic;
   signal cmd_index     : natural range 0 to 63;
   signal cmd_data      : std_logic_vector(31 downto 0);
   signal cmd_resp      : natural range 0 to 255;
   signal resp_valid    : std_logic;
   signal resp_ready    : std_logic;
   signal resp_data     : std_logic_vector(135 downto 0);
   signal resp_timeout  : std_logic;
   signal resp_error    : std_logic;
   signal init_count    : natural range 0 to INIT_COUNT_MAX;

   signal card_ver2     : std_logic;
   signal card_ccs      : std_logic;
   signal card_cid      : std_logic_vector(127 downto 0);
   signal card_csd      : std_logic_vector(127 downto 0);
   signal card_rca      : std_logic_vector(15 downto 0);

   -- State diagram in Figure 4-7 page 56.
   type state_t is (
      -- Slow clock
      INIT_ST,
      GO_IDLE_STATE_ST,
      SEND_IF_COND_ST,
      SD_SEND_OP_COND_APP_ST,
      SD_SEND_OP_COND_ST,
      ALL_SEND_CID_ST,
      SEND_RELATIVE_ADDR_ST,
      ERROR_ST,
      SEND_STATUS_ST,
      -- Fast clock
      SEND_CSD_ST,
      SELECT_CARD_ST,
      SET_BUS_WIDTH_APP_ST,
      SET_BUS_WIDTH_ST
   );

   signal state : state_t := INIT_ST;

   attribute mark_debug                 : boolean;
--   attribute mark_debug of sd_clk_o     : signal is true;
--   attribute mark_debug of sd_cmd_in_i  : signal is true;
--   attribute mark_debug of sd_cmd_oe_o  : signal is true;
   attribute mark_debug of state        : signal is true;
   attribute mark_debug of resp_timeout : signal is true;
   attribute mark_debug of resp_error   : signal is true;
   attribute mark_debug of resp_valid   : signal is true;

   attribute mark_debug of card_ver2    : signal is true;
   attribute mark_debug of card_ccs     : signal is true;
   attribute mark_debug of card_cid     : signal is true;
   attribute mark_debug of card_csd     : signal is true;
   attribute mark_debug of card_rca     : signal is true;

begin

   ----------------------------------
   -- Generate SD clock
   ----------------------------------

   -- Divide by 64
   p_counter : process (avm_clk_i)
   begin
      if rising_edge(avm_clk_i) then
         counter_slow <= std_logic_vector(unsigned(counter_slow) + 1);
      end if;
   end process p_counter;

   sd_clk_o <= counter_slow(6) when state = INIT_ST   -- 50 MHz / 64 / 2 = 391 kHz
                                 or state = GO_IDLE_STATE_ST
                                 or state = SEND_IF_COND_ST
                                 or state = SD_SEND_OP_COND_APP_ST
                                 or state = SD_SEND_OP_COND_ST
                                 or state = ALL_SEND_CID_ST
                                 or state = SEND_RELATIVE_ADDR_ST
                                 or state = ERROR_ST
                                 or state = SEND_STATUS_ST
          else counter_slow(0);                       -- 50 MHz / 2 = 25 MHz


   -- From Part1_Physical_Layer_Simplified_Specification_Ver8.00.pdf,
   -- Section 4.8 Card State Transition Table, Page 128.
   -- Section 4.2 Card Identification Mode, Page 59.
   -- State Machine shown in Figure 4-2, Page 62.
   -- Section 4.7.4 Detailed Command Description

   p_fsm : process (avm_clk_i)
   begin
      if rising_edge(avm_clk_i) then
         sd_cd <= sd_cd_i;

         if cmd_ready = '1' then
            cmd_valid <= '0';
         end if;

         case state is
            when INIT_ST =>
               if cmd_ready = '1' then
                  -- Initialize information about card
                  card_ver2  <= '0';
                  card_ccs   <= '0';
                  card_cid   <= (others => '0');
                  card_csd   <= (others => '0');
                  card_rca   <= (others => '0');

                  -- Send CMD0 (see section 4.2.1)
                  -- This resets the SD Card
                  cmd_index  <= CMD_GO_IDLE_STATE;       -- CMD0 (bc)
                  cmd_data   <= (others => '0');         -- No additional data
                  cmd_resp   <= 0;                       -- Expect no response
                  cmd_valid  <= '1';
                  init_count <= INIT_COUNT_MAX;          -- Retry count for ACMD41
                  state      <= GO_IDLE_STATE_ST;
               end if;

            when GO_IDLE_STATE_ST =>                     -- We've sent CMD0, no response expected
               if cmd_ready = '1' then
                  -- Send CMD8 (see sections 4.2.2 and 4.3.13)
                  -- This probes the SD Card for protocol version 2.0 or later.
                  cmd_index <= CMD_SEND_IF_COND;         -- CMD8 (bcr)
                  cmd_data  <= (others => '0');
                  cmd_data(CMD8_1_2V)  <= "0";           -- Not asking 1.2V support
                  cmd_data(CMD8_PCIE)  <= "0";           -- Not asking PCIe availability
                  cmd_data(CMD8_VHS)   <= CMD8_VHS_27_36; -- Voltage is 2.7-3.6V
                  cmd_data(CMD8_CHECK) <= X"AA";         -- Check pattern
                  cmd_resp  <= RESP_R7_LEN;              -- Expect response R7
                  cmd_valid <= '1';
                  state     <= SEND_IF_COND_ST;
               end if;

            when SEND_IF_COND_ST =>                      -- We've sent CMD8, expecting response R7
               if resp_valid = '1' then                  -- Wait for response or timeout
                  -- Check response R7
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(R_CMD_INDEX) = std_logic_vector(to_unsigned(CMD_SEND_IF_COND, 8)) and
                     resp_data(CMD8_VHS)    = CMD8_VHS_27_36 and
                     resp_data(CMD8_CHECK)  = X"AA"  then

                     -- Valid response means card is Ver 2.X
                     card_ver2 <= '1';

                     -- Send ACMD41 (see section 5.1)
                     cmd_index <= CMD_APP_CMD;           -- First send CMD55 (ac)
                     cmd_data  <= (others => '0');
                     cmd_data(CMD_RCA) <= CMD_RCA_DEFAULT;
                     cmd_resp  <= RESP_R1_LEN;           -- Expect response R1
                     cmd_valid <= '1';
                     state     <= SD_SEND_OP_COND_APP_ST;
                  elsif resp_timeout = '1' then
                     -- Timeout means the card did not respond to our CMD8.
                     -- Most likely, it is a "Ver 1.X Standard Capacity SD Memory Card".

                     -- Send ACMD41 (see section 5.1)
                     cmd_index <= CMD_APP_CMD;           -- First send CMD55 (ac)
                     cmd_data  <= (others => '0');
                     cmd_data(CMD_RCA) <= CMD_RCA_DEFAULT;
                     cmd_resp  <= RESP_R1_LEN;           -- Expect response R1
                     cmd_valid <= '1';
                     state     <= SD_SEND_OP_COND_APP_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SD_SEND_OP_COND_APP_ST =>               -- We've sent CMD55, expecting response R1
               if resp_valid = '1' then                  -- Wait for response or timeout
                  -- Check response R1
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(R_CMD_INDEX) = std_logic_vector(to_unsigned(CMD_APP_CMD, 8)) and
                     resp_data(CARD_STAT_CURRENT_STATE)  = CARD_STATE_IDLE and
                     resp_data(CARD_STAT_READY_FOR_DATA) = '1' and
                     resp_data(CARD_STAT_APP_CMD)        = '1'
                  then
                     cmd_index <= ACMD_SD_SEND_OP_COND;  -- ACMD41 (bcr)
                     cmd_data  <= (others => '0');
                     cmd_data(OCR_33X) <= '1';           -- Indicate host support for 3.3 V
                     if card_ver2 = '1' then
                        cmd_data(OCR_CCS) <= '1';        -- Indicate host support for SDHC or SDXC
                     end if;
                     cmd_resp  <= RESP_R3_LEN;           -- Expect response R3
                     cmd_valid <= '1';
                     state     <= SD_SEND_OP_COND_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SD_SEND_OP_COND_ST =>                   -- We've sent ACMD41, expecting response R3
               if resp_valid = '1' then                  -- Wait for response or timeout
                  -- Check response R3
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(R_CMD_INDEX) = X"3F"
                  then
                     -- Wait for BUSY bit to be set (de-asserted)
                     if resp_data(OCR_BUSY) = '1' then
                        -- Card Capacity Status
                        if card_ver2 = '1' then
                           card_ccs <= resp_data(OCR_CCS);
                        end if;

                        cmd_index <= CMD_ALL_SEND_CID;   -- CMD2 (bcr)
                        cmd_data  <= (others => '0');    -- No additional data
                        cmd_resp  <= RESP_R2_LEN;        -- Expect response R2
                        cmd_valid <= '1';
                        state     <= ALL_SEND_CID_ST;
                     elsif init_count > 0 then
                        init_count <= init_count - 1;

                        -- Send ACMD41 again
                        cmd_index <= CMD_APP_CMD;        -- First send CMD55 (ac)
                        cmd_data  <= (others => '0');
                        cmd_data(CMD_RCA) <= CMD_RCA_DEFAULT;
                        cmd_resp  <= RESP_R1_LEN;        -- Expect response R1
                        cmd_valid <= '1';
                        state     <= SD_SEND_OP_COND_APP_ST;
                     else
                        state <= ERROR_ST;
                     end if;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when ALL_SEND_CID_ST =>                      -- We've sent CMD2, expecting response R2
               if resp_valid = '1' then
                  -- Check response R2
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(127 downto 120) = X"3F"   -- Validate response
                  then
                     -- Store CID
                     card_cid  <= resp_data(R2_CID);

                     cmd_index <= CMD_SEND_RELATIVE_ADDR; -- CMD3 (bcr)
                     cmd_data  <= (others => '0');       -- No additional data
                     cmd_resp  <= RESP_R6_LEN;           -- Expect response R6
                     cmd_valid <= '1';
                     state     <= SEND_RELATIVE_ADDR_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SEND_RELATIVE_ADDR_ST =>                -- We've sent CMD3, expecting response R6
               if resp_valid = '1' then
                  -- Check response R6
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(R_CMD_INDEX) = std_logic_vector(to_unsigned(CMD_SEND_RELATIVE_ADDR, 8)) and
                     resp_data(R6_STAT_CURRENT_STATE)  = CARD_STATE_IDENT and
                     resp_data(R6_STAT_READY_FOR_DATA) = '1' and
                     resp_data(R6_STAT_APP_CMD)        = '1'
                  then
                     card_rca <= resp_data(R6_RCA);

                     cmd_index <= CMD_SEND_CSD;          -- CMD9 (ac)
                     cmd_data  <= (others => '0');
                     cmd_data(CMD_RCA) <= resp_data(R6_RCA);
                     cmd_resp  <= RESP_R2_LEN;           -- Expect response R2
                     cmd_valid <= '1';
                     state     <= SEND_CSD_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SEND_CSD_ST =>                          -- We've sent CMD9, expecting response R2
               if resp_valid = '1' then
                  -- Check response R2
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(127 downto 120) = X"3F"   -- Validate response
                  then
                     -- Store CSD
                     card_csd  <= resp_data(R2_CSD);

                     cmd_index <= CMD_SELECT_CARD;       -- CMD7 (ac)
                     cmd_data  <= (others => '0');
                     cmd_data(CMD_RCA) <= card_rca;
                     cmd_resp  <= RESP_R1_LEN;           -- Expect response R1b
                     cmd_valid <= '1';
                     state     <= SELECT_CARD_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SELECT_CARD_ST =>                       -- We've sent CMD7, expecting response R1b
               if resp_valid = '1' then
                  -- Check response R1b
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(R_CMD_INDEX) = std_logic_vector(to_unsigned(CMD_SELECT_CARD, 8)) and
                     resp_data(CARD_STAT_CURRENT_STATE)  = CARD_STATE_STBY and
                     resp_data(CARD_STAT_READY_FOR_DATA) = '1' and
                     resp_data(CARD_STAT_APP_CMD)        = '0'
                  then
                     cmd_index <= CMD_APP_CMD;           -- First send CMD55 (ac)
                     cmd_data  <= (others => '0');
                     cmd_data(31 downto 16) <= card_rca;
                     cmd_resp  <= RESP_R1_LEN;           -- Expect response R1
                     cmd_valid <= '1';
                     state     <= SET_BUS_WIDTH_APP_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SET_BUS_WIDTH_APP_ST =>                 -- We've sent CMD55, expecting response R1
               if resp_valid = '1' then                  -- Wait for response or timeout
                  -- Check response R1
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(R_CMD_INDEX) = std_logic_vector(to_unsigned(CMD_APP_CMD, 8)) and
                     resp_data(CARD_STAT_CURRENT_STATE)  = CARD_STATE_TRAN and
                     resp_data(CARD_STAT_READY_FOR_DATA) = '1' and
                     resp_data(CARD_STAT_APP_CMD)        = '1'
                  then
                     cmd_index <= ACMD_SET_BUS_WIDTH;    -- ACMD6
                     cmd_data  <= (others => '0');
                     cmd_data(ACMD6_BUS_WIDTH) <= ACMD6_BUS_WIDTH_4;
                     cmd_resp  <= RESP_R1_LEN;           -- Expect response R1
                     cmd_valid <= '1';
                     state     <= SET_BUS_WIDTH_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SET_BUS_WIDTH_ST =>                     -- We've sent ACMD6, expecting response R1
               if resp_valid = '1' then                  -- Wait for response or timeout
                  -- Check response R1
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(R_CMD_INDEX) = std_logic_vector(to_unsigned(ACMD_SET_BUS_WIDTH, 8)) and
                     resp_data(CARD_STAT_CURRENT_STATE)  = CARD_STATE_TRAN and
                     resp_data(CARD_STAT_READY_FOR_DATA) = '1' and
                     resp_data(CARD_STAT_APP_CMD)        = '1'
                  then
                     null;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when ERROR_ST =>
               if cmd_ready = '1' then
                  cmd_index <= CMD_SEND_STATUS;          -- CMD13
                  cmd_data  <= (others => '0');
                  cmd_data(31 downto 16) <= card_rca;
                  cmd_data(15)           <= '0';         -- Send Status
                  cmd_resp  <= RESP_R1_LEN;              -- Expect response R1
                  cmd_valid <= '1';
                  state     <= SEND_STATUS_ST;
               end if;

            when SEND_STATUS_ST =>                       -- We've sent CMD13, expecting response R1
               null;

            when others =>
               null;
         end case;

         if avm_rst_i = '1' then
            state               <= INIT_ST;
            cmd_valid           <= '0';
            avm_readdatavalid_o <= '0';
            avm_waitrequest_o   <= '1';
         end if;
      end if;
   end process p_fsm;


   ----------------------------------
   -- Instantiate CMD controller
   ----------------------------------

   i_cmd_logger : entity work.cmd_logger
      port map (
         clk_i          => avm_clk_i,
         rst_i          => avm_rst_i,
         cmd_valid_i    => cmd_valid,
         cmd_ready_o    => cmd_ready,
         cmd_index_i    => cmd_index,
         cmd_data_i     => cmd_data,
         cmd_resp_i     => cmd_resp,
         resp_valid_o   => resp_valid,
         resp_ready_i   => '1',
         resp_data_o    => resp_data,
         resp_timeout_o => resp_timeout,
         resp_error_o   => resp_error,
         sd_clk_i       => sd_clk_o,
         sd_cmd_in_i    => sd_cmd_in_i,
         sd_cmd_out_o   => sd_cmd_out_o,
         sd_cmd_oe_o    => sd_cmd_oe_o,
         uart_tx_o      => uart_tx_o
      ); -- i_cmd_logger


   ----------------------------------
   -- Instantiate DAT controller
   ----------------------------------

   i_dat : entity work.dat
      port map (
         clk_i        => avm_clk_i,
         rst_i        => avm_rst_i,
         tx_valid_i   => '0',
         tx_ready_o   => open,
         tx_data_i    => (others => '0'),
         tx_last_i    => '0',
         rx_valid_o   => open,
         rx_ready_i   => '1',
         rx_data_o    => open,
         rx_last_o    => open,
         sd_clk_i     => sd_clk_o,
         sd_dat_in_i  => sd_dat_in_i,
         sd_dat_out_o => sd_dat_out_o,
         sd_dat_oe_o  => sd_dat_oe_o
      ); -- i_dat

end architecture synthesis;

