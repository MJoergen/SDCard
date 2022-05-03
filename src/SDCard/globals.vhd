library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sdcard_globals is

   -- Section 4.10.1 Card Status, Page 134
   constant CARD_STAT_OUT_OF_RANGE       : natural := 31;
   constant CARD_STAT_ADDRESS_ERROR      : natural := 30;
   constant CARD_STAT_BLOCK_LEN_ERROR    : natural := 29;
   constant CARD_STAT_ERASE_SEQ_ERROR    : natural := 28;
   constant CARD_STAT_ERASE_PARAM        : natural := 27;
   constant CARD_STAT_WP_VIOLATION       : natural := 26;
   constant CARD_STAT_CARD_IS_LOCKED     : natural := 25;
   constant CARD_STAT_LOCK_UNLOCK_FAILED : natural := 24;
   constant CARD_STAT_COM_CRC_ERROR      : natural := 23;
   constant CARD_STAT_ILLEGAL_COMMAND    : natural := 22;
   constant CARD_STAT_CARD_ECC_FAILED    : natural := 21;
   constant CARD_STAT_CC_ERROR           : natural := 20;
   constant CARD_STAT_ERROR              : natural := 19;
   constant CARD_STAT_CSD_OVERWRITE      : natural := 16;
   constant CARD_STAT_WP_ERASE_SKIP      : natural := 15;
   constant CARD_STAT_CARD_ECC_DISABED   : natural := 14;
   constant CARD_STAT_ERASE_RESET        : natural := 13;
   subtype  CARD_STAT_CURRENT_STATE     is natural range 12 downto 9;
   constant CARD_STAT_READY_FOR_DATA     : natural :=  8;
   constant CARD_STAT_FX_EVENT           : natural :=  6;
   constant CARD_STAT_APP_CMD            : natural :=  5;
   constant CARD_STAT_AKE_SEQ_ERROR      : natural :=  3;

   constant CARD_STATE_IDLE  : std_logic_vector(3 downto 0) := X"0";
   constant CARD_STATE_READY : std_logic_vector(3 downto 0) := X"1";
   constant CARD_STATE_IDENT : std_logic_vector(3 downto 0) := X"2";
   constant CARD_STATE_STBY  : std_logic_vector(3 downto 0) := X"3";
   constant CARD_STATE_TRAN  : std_logic_vector(3 downto 0) := X"4";
   constant CARD_STATE_DATA  : std_logic_vector(3 downto 0) := X"5";
   constant CARD_STATE_RCV   : std_logic_vector(3 downto 0) := X"6";
   constant CARD_STATE_PRG   : std_logic_vector(3 downto 0) := X"7";
   constant CARD_STATE_DIS   : std_logic_vector(3 downto 0) := X"8";

   -- Class 0 Basic Commands
   constant CMD_GO_IDLE_STATE           : natural :=  0;
   constant CMD_ALL_SEND_CID            : natural :=  2;
   constant CMD_SEND_RELATIVE_ADDR      : natural :=  3;
   constant CMD_SET_DSR                 : natural :=  4;
   constant CMD_SELECT_CARD             : natural :=  7;
   constant CMD_SEND_IF_COND            : natural :=  8;
   constant CMD_SEND_CSD                : natural :=  9;
   constant CMD_SEND_CID                : natural := 10;
   constant CMD_VOLTAGE_SWITCH          : natural := 11;
   constant CMD_STOP_TRANSMISSION       : natural := 12;
   constant CMD_SEND_STATUS             : natural := 13;
   constant CMD_GO_INACTIVE_STATE       : natural := 15;

   -- Class 2 and 4 Block Commands
   constant CMD_SET_BLOCKLEN            : natural := 16;
   constant CMD_READ_SINGLE_BLOCK       : natural := 17;
   constant CMD_READ_MULTIPLE_BLOCK     : natural := 18;
   constant CMD_SET_TUNING_BLOCK        : natural := 19;
   constant CMD_SPEED_CLASS_CONTROL     : natural := 20;
   constant CMD_ADDRESS_EXTENSION       : natural := 22;
   constant CMD_SET_BLOCK_COUNT         : natural := 23;
   constant CMD_WRITE_BLOCK             : natural := 24;
   constant CMD_WRITE_MULTIPLE_BLOCK    : natural := 25;
   constant CMD_PROGRAM_CSD             : natural := 27;

   -- Class 6 Write Protection Commands
   constant CMD_SET_WRITE_PROT          : natural := 28;
   constant CMD_CLR_WRITE_PROT          : natural := 29;
   constant CMD_SEND_WRITE_PROT         : natural := 30;

   -- Class 5 Erase Commands
   constant CMD_ERASE_WR_BLK_START      : natural := 32;
   constant CMD_ERASE_WR_BLK_END        : natural := 33;
   constant CMD_ERASE                   : natural := 38;

   -- Class 8 Application Specific Commands
   constant CMD_APP_CMD                 : natural := 55;
   constant CMD_GEN_CMD                 : natural := 56;

   -- Class 10 Switch Function Commands
   constant CMD_SWITCH_FUNC             : natural :=  6;

   -- Application Specific Commands
   constant ACMD_SET_BUS_WIDTH          : natural :=  6;
   constant ACMD_SD_STATUS              : natural := 13;
   constant ACMD_SET_NUM_WR_BLOCKS      : natural := 22;
   constant ACMD_SET_WR_BLK_ERASE_COUNT : natural := 23;
   constant ACMD_SD_SEND_OP_COND        : natural := 41;
   constant ACMD_SET_CLR_CARD_DETECT    : natural := 42;
   constant ACMD_SEND_SCR               : natural := 51;

end package sdcard_globals;

