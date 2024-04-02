# Signal mapping for MEGA65 platform revision 3
#
# Created by Michael Jørgensen in 2022 (mjoergen.github.io/SDCard).


# Place output registers close to I/O pads
set_property IOB TRUE [get_cells sdcard_wrapper_inst/sd_clk_reg_reg ]
set_property IOB TRUE [get_cells sdcard_wrapper_inst/sd_cmd_out_reg_reg ]
set_property IOB TRUE [get_cells sdcard_wrapper_inst/sd_cmd_oe_n_reg_reg ]

# Place KBD close to I/O pins
startgroup
create_pblock pblock_i_kbd
resize_pblock pblock_i_kbd -add {SLICE_X0Y225:SLICE_X7Y237}
add_cells_to_pblock pblock_i_kbd [get_cells [list mega65_inst/m2m_keyb_inst/m65driver]]
endgroup

## External clock signal (connected to 100 MHz oscillator)
set_property -dict {PACKAGE_PIN V13  IOSTANDARD LVCMOS33}            [get_ports {sys_clk_i}]

## Reset button (Active high)
set_property -dict {PACKAGE_PIN J19  IOSTANDARD LVCMOS33}            [get_ports {sys_rst_i}]

create_clock -period 10.000 -name clk [get_ports sys_clk_i]

## Micro SD Connector (external slot at back of the cover)
set_property -dict {PACKAGE_PIN K1  IOSTANDARD LVCMOS33}             [get_ports sd_cd_i]
set_property -dict {PACKAGE_PIN G2  IOSTANDARD LVCMOS33}             [get_ports sd_clk_o]
set_property -dict {PACKAGE_PIN J2  IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_cmd_io]
set_property -dict {PACKAGE_PIN H2  IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[0]]
set_property -dict {PACKAGE_PIN H3  IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[1]]
set_property -dict {PACKAGE_PIN J1  IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[2]]
set_property -dict {PACKAGE_PIN K2  IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[3]]

## SD Connector (this is the slot at the bottom side of the case under the cover)
#set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33}             [get_ports sd_cd_i]
#set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33}             [get_ports sd_clk_o]
#set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_cmd_io]
#set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[0]]
#set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[1]]
#set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[2]]
#set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33 PULLUP true} [get_ports sd_dat_io[3]]

## MEGA65 smart keyboard controller
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports kb_io0_o]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports kb_io1_o]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports kb_io2_i]

## USB-RS232 Interface (rxd, txd only; rts/cts are not available)
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports uart_rx_i]
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports uart_tx_o]

## Configuration and Bitstream properties
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

