onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group tb /tb_sdcard/test_running
add wave -noupdate -group tb /tb_sdcard/avm_clk
add wave -noupdate -group tb /tb_sdcard/avm_rst
add wave -noupdate -group tb /tb_sdcard/avm_write
add wave -noupdate -group tb /tb_sdcard/avm_read
add wave -noupdate -group tb /tb_sdcard/avm_address
add wave -noupdate -group tb /tb_sdcard/avm_writedata
add wave -noupdate -group tb /tb_sdcard/avm_burstcount
add wave -noupdate -group tb /tb_sdcard/avm_readdata
add wave -noupdate -group tb /tb_sdcard/avm_readdatavalid
add wave -noupdate -group tb /tb_sdcard/avm_waitrequest
add wave -noupdate -group tb /tb_sdcard/avm_init_error
add wave -noupdate -group tb /tb_sdcard/avm_crc_error
add wave -noupdate -group tb /tb_sdcard/avm_last_state
add wave -noupdate -group tb /tb_sdcard/sd_clk
add wave -noupdate -group tb /tb_sdcard/sd_cmd
add wave -noupdate -group tb /tb_sdcard/sd_dat
add wave -noupdate -expand -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/clk_counter
add wave -noupdate -expand -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/init_count
add wave -noupdate -expand -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/card_ver2
add wave -noupdate -expand -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/card_rca
add wave -noupdate -expand -group sdcard_ctrl /tb_sdcard/sdcard_wrapper_inst/sdcard_ctrl_inst/state
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cmd_ready_o
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_valid_o
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/state
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/idle_count
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/timeout_count
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/cooldown_count
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/sd_clk_d
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/send_data
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/send_count
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/crc
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_data
add wave -noupdate -group sdcard_cmd /tb_sdcard/sdcard_wrapper_inst/sdcard_cmd_logger_inst/i_sdcard_cmd/resp_count
add wave -noupdate -group sdcard_sim /tb_sdcard/sdcard_sim_inst/cmd
add wave -noupdate -group sdcard_sim /tb_sdcard/sdcard_sim_inst/cmd_valid
add wave -noupdate -group sdcard_sim /tb_sdcard/sdcard_sim_inst/cmd_receiving
add wave -noupdate -group sdcard_sim /tb_sdcard/sdcard_sim_inst/cmd_bit_count
add wave -noupdate -group sdcard_sim /tb_sdcard/sdcard_sim_inst/resp_data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {0 ns} {19831 ns}
