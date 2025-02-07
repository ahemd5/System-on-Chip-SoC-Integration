onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Source
add wave -noupdate /bridge_tb/i_clk_src_tb
add wave -noupdate /bridge_tb/i_rstn_src_tb
add wave -noupdate /bridge_tb/DUT/U0_source/u0_src_ctrl/current_state
add wave -noupdate /bridge_tb/DUT/U0_source/u0_src_ctrl/next_state
add wave -noupdate /bridge_tb/DUT/U0_source/u0_src_ctrl/reset_flag
add wave -noupdate /bridge_tb/i_src_sleep_req_tb
add wave -noupdate /bridge_tb/o_src_sleep_ack_tb
add wave -noupdate /bridge_tb/DUT/source_sleep_status
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/i_hwrite
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/i_haddr
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/i_hwdata
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/i_ready
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/i_rd_valid
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/i_rd_data
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/o_rd0_wr1
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/o_wr_data
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/o_addr
add wave -noupdate -expand -group Slave /bridge_tb/DUT/U0_source/u3_slave/o_hrdata
add wave -noupdate /bridge_tb/DUT/U0_source/u1_req_src_async_fifo/u_fifo_mem/FIFO_MEM
add wave -noupdate /bridge_tb/DUT/U0_source/u0_src_ctrl/req_fifo_full
add wave -noupdate /bridge_tb/DUT/U0_source/u0_src_ctrl/req_fifo_empty
add wave -noupdate /bridge_tb/DUT/U0_source/u0_src_ctrl/rsp_fifo_empty
add wave -noupdate /bridge_tb/DUT/U0_source/u1_req_src_async_fifo/gray_rd_ptr_sync
add wave -noupdate /bridge_tb/DUT/U0_source/u1_req_src_async_fifo/gray_w_ptr
add wave -noupdate -divider Sink
add wave -noupdate /bridge_tb/i_clk_sink_tb
add wave -noupdate /bridge_tb/i_rstn_sink_tb
add wave -noupdate /bridge_tb/DUT/U1_sink/u0_sink_ctrl/current_state
add wave -noupdate /bridge_tb/DUT/U1_sink/u0_sink_ctrl/next_state
add wave -noupdate /bridge_tb/i_sink_sleep_req_tb
add wave -noupdate /bridge_tb/o_sink_sleep_ack_tb
add wave -noupdate /bridge_tb/DUT/sink_sleep_status
add wave -noupdate /bridge_tb/DUT/U1_sink/u0_sink_ctrl/reset_flag
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/i_clk_ahb
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/i_rstn_ahb
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/o_hwrite
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/o_htrans
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/i_hrdata
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/o_haddr
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/o_hwdata
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/i_valid
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/i_rd0_wr1
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/o_ready
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/o_rd_valid
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/i_addr
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/i_wr_data
add wave -noupdate -expand -group Master /bridge_tb/DUT/U1_sink/u3_master/o_rd_data
add wave -noupdate /bridge_tb/DUT/U1_sink/u1_req_sink_async_fifo/FIFO_MEM_sync
add wave -noupdate /bridge_tb/DUT/U1_sink/u1_req_sink_async_fifo/gray_w_ptr_sync
add wave -noupdate /bridge_tb/DUT/U1_sink/u1_req_sink_async_fifo/gray_rd_ptr
add wave -noupdate /bridge_tb/DUT/U1_sink/u0_sink_ctrl/req_fifo_empty
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {206078 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 144
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
WaveRestoreZoom {123291 ps} {309301 ps}
