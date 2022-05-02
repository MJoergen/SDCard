-- This is the CMD controller for the complete SDCard controller.

-- Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This block includes generation of the 7-bit CRC checksum.
-- Output is changed on falling edge of sd_clk_o. The SDCard samples on rising clock edge.
-- Input is sampled on rising edge of sd_clk_o. The SDCard outputs on falling clock edge.

entity cmd is
   port (
      clk_i           : in  std_logic;
      rst_i           : in  std_logic;
      cmd_i           : in  std_logic_vector(37 downto 0);
      cmd_valid_i     : in  std_logic;
      cmd_ready_o     : out std_logic;
      resp_o          : out std_logic_vector(135 downto 0);
      resp_valid_o    : out std_logic;

      -- SDCard device interface
      sd_cmd_in_i     : in  std_logic;
      sd_cmd_out_o    : out std_logic;
      sd_cmd_oe_o     : out std_logic
   );
end entity cmd;

architecture synthesis of cmd is

   signal sd_cmd_oe    : std_logic;
   signal sd_cmd_out   : std_logic;

   signal idle_count   : natural range 0 to 25000;  -- 1 msec @ 25 MHz
   signal cmd_with_crc : std_logic_vector(47 downto 0);

   type state_t is (
      INIT_ST,
      IDLE_ST,
      WRITING_ST
   );

   signal state : state_t := INIT_ST;

   function crc7(arg : std_logic_vector) return std_logic_vector is
      variable res : std_logic_vector(6 downto 0);
   begin
      res := (others => '0');
      return res;
   end function crc7;

begin

   sd_cmd_out <= '1' when state = INIT_ST else cmd_with_crc(47);
   sd_cmd_oe  <= '1' when state = INIT_ST or state = WRITING_ST else '0';

   -- Output is changed on falling edge of clk. The SDCard samples on rising clock edge.
   p_out : process (clk_i)
   begin
      if falling_edge(clk_i) then
         sd_cmd_oe_o <= sd_cmd_oe;
         if sd_cmd_oe = '1' then
            sd_cmd_out_o <= sd_cmd_out;
         else
            sd_cmd_out_o <= 'Z';
         end if;
      end if;
   end process p_out;

   cmd_ready_o <= '1' when state = IDLE_ST else '0';

   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         resp_valid_o <= '0';

         case state is
            when INIT_ST =>
               if idle_count = 1 then
                  state <= IDLE_ST;
               end if;
               idle_count <= idle_count - 1;

            when IDLE_ST =>
               if cmd_valid_i = '1' then
                  cmd_with_crc <= "01" & cmd_i & crc7(cmd_i) & "1";
                  state <= WRITING_ST;
               end if;

            when WRITING_ST =>
               if or(cmd_with_crc) = '0' then
                  resp_valid_o <= '1';
                  state        <= IDLE_ST;
               end if;
               cmd_with_crc <= cmd_with_crc(46 downto 0) & "0";

            when others =>
               null;
         end case;

         if rst_i = '1' then
            idle_count <= 25000;
            state      <= INIT_ST;
         end if;
      end if;
   end process p_fsm;

end architecture synthesis;

