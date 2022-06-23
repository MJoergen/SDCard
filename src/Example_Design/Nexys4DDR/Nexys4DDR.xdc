# Signal mapping for Nexys4DDR platform
#
# Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).


# Place SD close to I/O pins
create_pblock pblock_i_sd
add_cells_to_pblock pblock_i_sd [get_cells [list i_sdcard_wrapper/i_sdcard_cmd_logger/i_sdcard_cmd]]
resize_pblock pblock_i_sd -add {SLICE_X82Y113:SLICE_X89Y132}

## External clock signal (100 MHz)
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk_i]
create_clock -period 10.000 -name clk [get_ports clk_i]

# Buttons
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports btnl_i]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports btnr_i]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports btnu_i]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports btnd_i]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports btnc_i]

## Micro SD Connector (external slot at back of the cover)
set_property -dict {PACKAGE_PIN A1 IOSTANDARD LVCMOS33} [get_ports sd_cd_i]
set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS33} [get_ports sd_clk_o]
set_property -dict {PACKAGE_PIN C1 IOSTANDARD LVCMOS33} [get_ports sd_cmd_io]
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[0]]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[1]]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[2]]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[3]]

## USB-RS232 Interface (rxd, txd only; rts/cts are not available)
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports uart_rx_i]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports uart_tx_o]

## Configuration and Bitstream properties
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

