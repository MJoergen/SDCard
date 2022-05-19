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

   signal card_ver1     : std_logic;
   signal card_ccs      : std_logic;
   signal card_cid      : std_logic_vector(119 downto 0);
   signal card_rca      : std_logic_vector(15 downto 0);

   -- State diagram in Figure 4-7 page 56.
   type state_t is (
      INIT_ST,
      GO_IDLE_STATE_ST,
      SEND_IF_COND_ST,
      SD_SEND_OP_COND_APP_ST,
      SD_SEND_OP_COND_ST,
      ALL_SEND_CID_ST,
      SEND_RELATIVE_ADDR_ST,
      ERROR_ST,
      SEND_STATUS_ST
   );

   signal state : state_t := INIT_ST;

   attribute mark_debug                 : boolean;
   attribute mark_debug of sd_clk_o     : signal is true;
   attribute mark_debug of sd_cmd_in_i  : signal is true;
   attribute mark_debug of sd_cmd_oe_o  : signal is true;
   attribute mark_debug of state        : signal is true;
   attribute mark_debug of resp_timeout : signal is true;
   attribute mark_debug of resp_error   : signal is true;
   attribute mark_debug of resp_valid   : signal is true;

   attribute mark_debug of card_ver1    : signal is true;
   attribute mark_debug of card_ccs     : signal is true;

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
                  -- Send CMD0 (see section 4.2.1)
                  cmd_index  <= CMD_GO_IDLE_STATE;  -- CMD0
                  cmd_data   <= X"00000000";  -- No additional data
                  cmd_resp   <= 0;            -- No response expected.
                  cmd_valid  <= '1';
                  state      <= GO_IDLE_STATE_ST;
                  init_count <= INIT_COUNT_MAX;
                  card_ver1  <= '1';
                  card_ccs   <= '0';
                  card_cid   <= (others => '0');
                  card_rca   <= (others => '0');
               end if;

            when GO_IDLE_STATE_ST => -- We've sent CMD0, no response expected
               if cmd_ready = '1' then
                  -- Send CMD8 (see sections 4.2.2 and 4.3.13)
                  cmd_index <= CMD_SEND_IF_COND;  -- CMD8
                  cmd_data  <= X"000001AA";  -- Voltage is 1, Check pattern is AA
                  cmd_resp  <= RESP_R7_LEN;  -- Expect response R7
                  cmd_valid <= '1';
                  state     <= SEND_IF_COND_ST;
               end if;

            when SEND_IF_COND_ST => -- We've sent CMD8
               if resp_valid = '1' then      -- Wait for response or timeout
                  -- Check response
                  if resp_timeout = '0' and resp_error = '0' then
                     -- TBD: Here we should check the contents of the response

                     card_ver1 <= '0'; -- Valid response means card is Ver 2.X

                     -- Send ACMD41 (see section 5.1)
                     cmd_index <= CMD_APP_CMD;  -- First send CMD55
                     cmd_data  <= X"00000000";  -- RCA default value of all zeros
                     cmd_resp  <= RESP_R1_LEN;  -- Expect response R1
                     cmd_valid <= '1';
                     state     <= SD_SEND_OP_COND_APP_ST;
                  elsif resp_timeout = '1' then
                     -- Timeout means the card did not respond to our CMD8.
                     -- Most likely, it is a "Ver 1.X Standard Capacity SD Memory Card".
                     card_ver1 <= '1';

                     -- Send ACMD41 (see section 5.1)
                     cmd_index <= CMD_APP_CMD;  -- First send CMD55
                     cmd_data  <= X"00000000";  -- RCA default value of all zeros
                     cmd_resp  <= RESP_R1_LEN;  -- Expect response R1
                     cmd_valid <= '1';
                     state     <= SD_SEND_OP_COND_APP_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SD_SEND_OP_COND_APP_ST => -- We've sent CMD55
               if resp_valid = '1' then      -- Wait for response or timeout
                  -- Check response
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(CARD_STAT_CURRENT_STATE)  = CARD_STATE_IDLE and
                     resp_data(CARD_STAT_READY_FOR_DATA) = '1' and
                     resp_data(CARD_STAT_APP_CMD)        = '1'
                  then
                     cmd_index <= ACMD_SD_SEND_OP_COND;  -- ACMD41
                     cmd_data  <= (others => '0');
                     cmd_data(OCR_33X) <= '1';           -- Indicate host support for 3.3 V
                     if card_ver1 = '0' then
                        cmd_data(OCR_CCS) <= '1';        -- Indicate host support for SDHC or SDXC
                     end if;
                     cmd_resp  <= RESP_R3_LEN;           -- Expect response R3
                     cmd_valid <= '1';
                     state     <= SD_SEND_OP_COND_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SD_SEND_OP_COND_ST => -- We've sent ACMD41
               if resp_valid = '1' then      -- Wait for response or timeout
                  if resp_timeout = '0' and resp_error = '0' then
                     -- Wait for BUSY bit to be set (de-asserted)
                     if resp_data(OCR_BUSY) = '1' then
                        if card_ver1 = '0' then
                           card_ccs <= resp_data(OCR_CCS);  -- Card Capacity Status
                        end if;
                        cmd_index <= CMD_ALL_SEND_CID;      -- CMD2
                        cmd_data  <= X"00000000";           -- No additional data
                        cmd_resp  <= RESP_R2_LEN;           -- Expect response R2
                        cmd_valid <= '1';
                        state     <= ALL_SEND_CID_ST;
                     elsif init_count > 0 then
                        init_count <= init_count - 1;

                        -- Send ACMD41 again
                        cmd_index <= CMD_APP_CMD;  -- First send CMD55
                        cmd_data  <= X"00000000";  -- RCA default value of all zeros
                        cmd_resp  <= RESP_R1_LEN;  -- Expect response R1
                        cmd_valid <= '1';
                        state     <= SD_SEND_OP_COND_APP_ST;
                     else
                        state <= ERROR_ST;
                     end if;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when ALL_SEND_CID_ST => -- We've sent CMD2
               if resp_valid = '1' then
                  if resp_timeout = '0' and resp_error = '0' and
                     resp_data(127 downto 120) = X"3F"      -- Validate response
                  then
                     card_cid  <= resp_data(119 downto 0);  -- Store CID
                     cmd_index <= CMD_SEND_RELATIVE_ADDR;   -- CMD3
                     cmd_data  <= X"00000000";              -- No additional data
                     cmd_resp  <= RESP_R6_LEN;              -- Expect response R6
                     cmd_valid <= '1';
                     state     <= SEND_RELATIVE_ADDR_ST;
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when SEND_RELATIVE_ADDR_ST =>
               if resp_valid = '1' then
                  if resp_timeout = '0' and resp_error = '0' then
                     card_rca <= resp_data(31 downto 16);
                  else
                     state <= ERROR_ST;
                  end if;
               end if;

            when ERROR_ST =>
               if cmd_ready = '1' then
                  cmd_index <= CMD_SEND_STATUS;  -- CMD13
                  cmd_data  <= X"00000000";  -- No arguments
                  cmd_resp  <= RESP_R1_LEN;  -- Expect response R1
                  cmd_valid <= '1';
                  state     <= SEND_STATUS_ST;
               end if;

            when SEND_STATUS_ST => -- We've sent CMD13
               null;

            when others =>
               null;
         end case;

         if avm_rst_i = '1' then
            state               <= INIT_ST;
            cmd_valid           <= '0';
            sd_dat_out_o        <= "1111";   -- bit 3 : CS, bit 0 : DO
            sd_dat_oe_o         <= '1';      -- Force output high => SD Mode
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

end architecture synthesis;

