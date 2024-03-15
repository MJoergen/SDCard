onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group tb /tb_sdcard/test_running
add wave -noupdate -group tb /tb_sdcard/avm_clk
add wave -noupdate -group tb /tb_sdcard/avm_rst
add wave -noupdate -group tb /tb_sdcard/avm_waitrequest
add wave -noupdate -group tb /tb_sdcard/avm_write
add wave -noupdate -group tb /tb_sdcard/avm_read
add wave -noupdate -group tb /tb_sdcard/avm_address
add wave -noupdate -group tb /tb_sdcard/avm_writedata
add wave -noupdate -group tb /tb_sdcard/avm_burstcount
add wave -noupdate -group tb /tb_sdcard/avm_readdata
add wave -noupdate -group tb /tb_sdcard/avm_readdatavalid
add wave -noupdate -group tb /tb_sdcard/avm_init_error
add wave -noupdate -group tb /tb_sdcard/avm_crc_error
add wave -noupdate -group tb /tb_sdcard/avm_last_state
add wave -noupdate -group tb /tb_sdcard/sd_clk
add wave -noupdate -group tb /tb_sdcard/sd_cmd
add wave -noupdate -group tb /tb_sdcard/sd_dat
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_clk_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_rst_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_write_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_read_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_address_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_writedata_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_burstcount_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_readdata_o
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_readdatavalid_o
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_waitrequest_o
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_init_error_o
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_crc_error_o
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/avm_last_state_o
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/sd_cd_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/sd_clk_o
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/sd_cmd_io
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/sd_dat_io
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/uart_valid_o
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/uart_ready_i
add wave -noupdate -group sdcard_wrapper /tb_sdcard/sdcard_wrapper_inst/uart_data_o
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_clk
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_cmd_in
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_cmd_out
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_cmd_oe_n
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_dat_in
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_dat_out
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_dat_oe_n
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_clk_reg
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_cmd_out_reg
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_cmd_oe_n_reg
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_dat_out_reg
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_dat_oe_n_reg
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/cmd_valid
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/cmd_ready
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/cmd_index
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/cmd_data
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/cmd_resp
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/cmd_timeout
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/resp_valid
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/resp_ready
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/resp_data
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/resp_timeout
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/resp_error
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/dat_ready
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/sd_clk_d
add wave -noupdate -group sdcard_wrapper -expand -group Internal /tb_sdcard/sdcard_wrapper_inst/count_low
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_clk_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_rst_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_write_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_read_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_address_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_writedata_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_burstcount_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_waitrequest_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_init_error_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/avm_last_state_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/sd_clk_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/cmd_valid_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/cmd_ready_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/cmd_index_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/cmd_data_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/cmd_resp_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/cmd_timeout_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/resp_valid_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/resp_ready_o
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/resp_data_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/resp_timeout_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/resp_error_i
add wave -noupdate -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/dat_ready_i
add wave -noupdate -group sdcard_ctrl -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/clk_counter
add wave -noupdate -group sdcard_ctrl -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/init_count
add wave -noupdate -group sdcard_ctrl -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/card_ver2
add wave -noupdate -group sdcard_ctrl -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/card_ccs
add wave -noupdate -group sdcard_ctrl -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/card_cid
add wave -noupdate -group sdcard_ctrl -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/card_csd
add wave -noupdate -group sdcard_ctrl -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/card_rca
add wave -noupdate -group sdcard_ctrl -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/state
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/clk_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/rst_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cmd_valid_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cmd_ready_o
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cmd_index_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cmd_data_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cmd_resp_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cmd_timeout_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_valid_o
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_ready_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_data_o
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_timeout_o
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_error_o
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/sd_clk_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/sd_cmd_in_i
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/sd_cmd_out_o
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/sd_cmd_oe_n_o
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/state
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/idle_count
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/timeout_count
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cooldown_count
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/sd_clk_d
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/send_data
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/send_count
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/crc
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_data
add wave -noupdate -group sdcard_cmd -group Internal /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_count
add wave -noupdate -expand -group sdcard_sim /tb_sdcard/sdcard_sim_inst/sd_clk_i
add wave -noupdate -expand -group sdcard_sim /tb_sdcard/sdcard_sim_inst/sd_cmd_io
add wave -noupdate -expand -group sdcard_sim /tb_sdcard/sdcard_sim_inst/sd_dat_io
add wave -noupdate -expand -group sdcard_sim /tb_sdcard/sdcard_sim_inst/mem_addr_o
add wave -noupdate -expand -group sdcard_sim /tb_sdcard/sdcard_sim_inst/mem_data_o
add wave -noupdate -expand -group sdcard_sim /tb_sdcard/sdcard_sim_inst/mem_data_i
add wave -noupdate -expand -group sdcard_sim /tb_sdcard/sdcard_sim_inst/mem_we_o
add wave -noupdate -expand -group sdcard_sim -expand -group Internal /tb_sdcard/sdcard_sim_inst/cmd
add wave -noupdate -expand -group sdcard_sim -expand -group Internal /tb_sdcard/sdcard_sim_inst/cmd_valid
add wave -noupdate -expand -group sdcard_sim -expand -group Internal /tb_sdcard/sdcard_sim_inst/cmd_receiving
add wave -noupdate -expand -group sdcard_sim -expand -group Internal /tb_sdcard/sdcard_sim_inst/cmd_bit_count
add wave -noupdate -expand -group sdcard_sim -expand -group Internal /tb_sdcard/sdcard_sim_inst/resp_data
add wave -noupdate -expand -group sdcard_sim -expand -group Internal /tb_sdcard/sdcard_sim_inst/resp_bit_count
add wave -noupdate -expand -group sdcard_sim -expand -group Internal /tb_sdcard/sdcard_sim_inst/card_status
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1167826705 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 353
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {3150 us}
