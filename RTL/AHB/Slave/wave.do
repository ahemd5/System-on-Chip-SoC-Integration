onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /AHB_slave_TB/i_clk_ahb_tb
add wave -noupdate /AHB_slave_TB/i_rstn_ahb_tb
add wave -noupdate /AHB_slave_TB/i_hmastlock_tb
add wave -noupdate /AHB_slave_TB/i_haddr_tb
add wave -noupdate /AHB_slave_TB/i_hwdata_tb
add wave -noupdate /AHB_slave_TB/i_hselx_tb
add wave -noupdate /AHB_slave_TB/i_ready_tb
add wave -noupdate /AHB_slave_TB/i_rd_valid_tb
add wave -noupdate -divider out
add wave -noupdate /AHB_slave_TB/o_hreadyout_tb
add wave -noupdate /AHB_slave_TB/o_hresp_tb
add wave -noupdate /AHB_slave_TB/o_valid_tb
add wave -noupdate /AHB_slave_TB/o_rd0_wr1_tb
add wave -noupdate -divider internal
add wave -noupdate /AHB_slave_TB/DUT/addr_reg
add wave -noupdate /AHB_slave_TB/DUT/current_state
add wave -noupdate /AHB_slave_TB/DUT/next_state
add wave -noupdate -divider Waveform
add wave -noupdate /AHB_slave_TB/i_clk_ahb_tb
add wave -noupdate /AHB_slave_TB/i_hwrite_tb
add wave -noupdate /AHB_slave_TB/i_hready_tb
add wave -noupdate /AHB_slave_TB/o_addr_tb
add wave -noupdate /AHB_slave_TB/o_wr_data_tb
add wave -noupdate /AHB_slave_TB/i_rd_data_tb
add wave -noupdate /AHB_slave_TB/o_hrdata_tb
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {95 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
configure wave -timelineunits us
update
WaveRestoreZoom {0 ns} {121 ns}
