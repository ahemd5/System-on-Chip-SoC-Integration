onerror {resume}
quietly virtual function -install /AHB_master_tb -env /AHB_master_tb { (32'h6)} virtual_000001
quietly virtual function -install /AHB_master_tb -env /AHB_master_tb { (32'h6)} virtual_000002
quietly virtual function -install /AHB_master_tb -env /AHB_master_tb { (32'h6)} virtual_000003
quietly WaveActivateNextPane {} 0
add wave -noupdate /AHB_master_tb/i_clk_ahb_tb
add wave -noupdate /AHB_master_tb/i_hresp_tb
add wave -noupdate -radix hexadecimal /AHB_master_tb/i_hrdata_tb
add wave -noupdate /AHB_master_tb/i_valid_tb
add wave -noupdate -radix hexadecimal /AHB_master_tb/i_addr_tb
add wave -noupdate -radix hexadecimal /AHB_master_tb/i_wr_data_tb
add wave -noupdate /AHB_master_tb/i_rd0_wr1_tb
add wave -noupdate /AHB_master_tb/o_htrans_tb
add wave -noupdate /AHB_master_tb/o_ready_tb
add wave -noupdate /AHB_master_tb/DUT/current_state
add wave -noupdate /AHB_master_tb/DUT/next_state
add wave -noupdate /AHB_master_tb/DUT/data_temp
add wave -noupdate /AHB_master_tb/DUT/read_temp
add wave -noupdate -divider Write
add wave -noupdate /AHB_master_tb/i_clk_ahb_tb
add wave -noupdate -radix hexadecimal /AHB_master_tb/o_haddr_tb
add wave -noupdate -radix hexadecimal /AHB_master_tb/o_hwdata_tb
add wave -noupdate /AHB_master_tb/i_hready_tb
add wave -noupdate /AHB_master_tb/o_hwrite_tb
add wave -noupdate -divider Read
add wave -noupdate /AHB_master_tb/i_clk_ahb_tb
add wave -noupdate -radix hexadecimal /AHB_master_tb/o_haddr_tb
add wave -noupdate /AHB_master_tb/i_hready_tb
add wave -noupdate -radix hexadecimal /AHB_master_tb/o_rd_data_tb
add wave -noupdate /AHB_master_tb/o_rd_valid_tb
add wave -noupdate /AHB_master_tb/DUT/busy
add wave -noupdate /AHB_master_tb/DUT/flag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {37486922 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 132
configure wave -valuecolwidth 39
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
WaveRestoreZoom {0 ps} {110250 ns}
