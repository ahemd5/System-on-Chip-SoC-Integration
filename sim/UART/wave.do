onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /A_UART_TB/PRSTn_tb
add wave -noupdate /A_UART_TB/PCLK_tb
add wave -noupdate /A_UART_TB/PSEL_tb
add wave -noupdate /A_UART_TB/PENABLE
add wave -noupdate /A_UART_TB/PWRITE
add wave -noupdate /A_UART_TB/PADDR
add wave -noupdate /A_UART_TB/PWDATA
add wave -noupdate /A_UART_TB/PRDATA
add wave -noupdate /A_UART_TB/PREADY
add wave -noupdate /A_UART_TB/PSLVERR
add wave -noupdate /A_UART_TB/Rx_s
add wave -noupdate /A_UART_TB/Dut/U0_UART/U0_UART_TX/U0_fsm/current_state
add wave -noupdate /A_UART_TB/Tx_s
add wave -noupdate /A_UART_TB/Dut/U0_UART/U0_UART_TX/busy
add wave -noupdate /A_UART_TB/Dut/U0_UART/TX_IN_V
add wave -noupdate /A_UART_TB/Dut/U0_UART/TX_IN_P
add wave -noupdate /A_UART_TB/Dut/U0_UART/TX_CLK
add wave -noupdate /A_UART_TB/Dut/U0_UART/RX_CLK
add wave -noupdate -expand -group TX_Fifo /A_UART_TB/Dut/U4_tx_fifo/i_w_inc
add wave -noupdate -expand -group TX_Fifo /A_UART_TB/Dut/U4_tx_fifo/i_r_inc
add wave -noupdate -expand -group TX_Fifo /A_UART_TB/Dut/U4_tx_fifo/i_w_data
add wave -noupdate -expand -group TX_Fifo /A_UART_TB/Dut/U4_tx_fifo/o_r_data
add wave -noupdate -expand -group TX_Fifo /A_UART_TB/Dut/U4_tx_fifo/o_full
add wave -noupdate -expand -group TX_Fifo /A_UART_TB/Dut/U4_tx_fifo/o_empty
add wave -noupdate -expand -group TX_Fifo /A_UART_TB/Dut/U4_tx_fifo/w2r_ptr
add wave -noupdate -expand -group TX_Fifo /A_UART_TB/Dut/U4_tx_fifo/r2w_ptr
add wave -noupdate /A_UART_TB/Dut/U2_IF/status_reg
add wave -noupdate -radix binary /A_UART_TB/captured_data
add wave -noupdate /A_UART_TB/Dut/U4_rx_fifo/i_w_inc
add wave -noupdate -expand -group Uart_rx /A_UART_TB/Dut/U0_UART/U0_UART_RX/RX_IN
add wave -noupdate -expand -group Uart_rx /A_UART_TB/Dut/U0_UART/U0_UART_RX/P_DATA
add wave -noupdate -expand -group Uart_rx /A_UART_TB/Dut/U0_UART/RX_OUT_V
add wave -noupdate -expand -group Uart_rx /A_UART_TB/Dut/U0_UART/RX_OUT_P
add wave -noupdate -expand -group Uart_rx /A_UART_TB/Dut/U0_UART/U0_UART_RX/bit_count
add wave -noupdate /A_UART_TB/Dut/U0_UART/U0_UART_RX/U0_uart_fsm/current_state
add wave -noupdate /A_UART_TB/Dut/U0_UART/U0_UART_RX/U0_uart_fsm/strt_glitch
add wave -noupdate /A_UART_TB/Dut/U0_UART/U0_UART_RX/Prescale
add wave -noupdate /A_UART_TB/Dut/control_reg
add wave -noupdate /A_UART_TB/Dut/U0_UART/U0_UART_RX/U0_edge_bit_counter/edge_count
add wave -noupdate /A_UART_TB/Dut/U0_UART/U0_UART_RX/sampled_bit
add wave -noupdate /A_UART_TB/Dut/U4_rx_fifo/o_empty
add wave -noupdate /A_UART_TB/Dut/U4_rx_fifo/u_fifo_mem/FIFO_MEM
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8651 ns} 0}
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
WaveRestoreZoom {8023 ns} {9047 ns}
