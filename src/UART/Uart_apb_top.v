module UART_apb_top #(parameter DATA_WIDTH = 8, ADDR_WIDTH = 32, 
	F_DEPTH = 8, apb_dataW = 32, ratio_wd = 8, prescale = 32) (
	// APB interface                                        
	input wire PRSTn,     				// APB active-low reset signal
	input wire PCLK,					// APB clock
	input wire PSEL,					// Peripheral select signal
	input wire PENABLE,					// Enable signal for APB transaction
	input wire PWRITE,					// Read (0) or Write (1) operation
	input wire  [ADDR_WIDTH-1:0] PADDR,	// Address bus
	input wire  [apb_dataW-1:0] PWDATA,	// Write data bus
	output wire [apb_dataW-1:0] PRDATA,	// Read data bus
	output wire PREADY,					// Ready signal for handshake
	output wire PSLVERR,				// Error signal
	// Uart signals 
	input wire Rx_s,      	// Serial RX pin
    output wire Tx_s,     	// Serial TX pin
	/*
	// Flow Control
    input wire CTS,     	// Clear To Send
    output reg RTS,     	// Request To Send
	*/
	// Interrupts
	output wire TX_FIFO_Empty,
	output wire RX_FIFO_Full,
	output wire Parity_Error,
	output wire Frame_Error,
	output reg overrun_error
	);
	// internal signals 
	// clk divider
	wire baud_clk;
	// apb if 
	wire [DATA_WIDTH-1:0] rx_data_sync;
	wire [DATA_WIDTH-1:0] tx_data_p;
	wire tx_fifo_full;
	wire rx_fifo_empty;
	wire tx_fifo_wr_en;
	wire rx_fifo_rd_en;
	wire tx_fifo_rst;
	wire rx_fifo_rst;
	wire [7:0] baud_div;
	wire [31:0] control_reg;
	// fifos
	wire [DATA_WIDTH-1:0] tx_data_sync;
	wire [DATA_WIDTH-1:0] rx_data_p;
	// uart 
	wire tx_busy;
	wire tx_data_valid; 
	
	// for LOOPBACK
	wire internal_rx;
	assign internal_rx = (control_reg[0]) ? Tx_s : Rx_s;
	
	wire tx_en = control_reg[4]; // TX_EN bit from control register
	assign tx_data_valid = tx_en ? ((TX_FIFO_Empty || tx_busy) ? 0 : 1) : 0;
	
	///////////// Uart top module /////////////
	// control_reg = {2'd0, UART_EN, TX_EN, RX_EN, par_en, par_type, LOOPBACK}
	UART  U0_UART (
	.RST(PRSTn),
	.TX_CLK(baud_clk),
	.RX_CLK(baud_clk_rx),
	.parity_enable(control_reg[2]),
	.parity_type(control_reg[1]),
	.Prescale(control_reg[12:5]),
	.RX_IN_S(internal_rx),
	.RX_OUT_P(rx_data_p),                      
	.RX_OUT_V(rx_fifo_wr_en),                      
	.TX_IN_P(tx_data_sync), 
	.TX_IN_V(tx_data_valid),
	.TX_OUT_S(Tx_s),
	.TX_OUT_V(tx_busy),
	.parity_error(Parity_Error),
	.framing_error(Frame_Error)                  
	);	
	
	wire rx_en = control_reg[3]; // RX_EN bit from control register
	wire gated_rx_fifo_wr_en = rx_en ? rx_fifo_wr_en : 1'b0;
	
	///////////////////////////// APB if ////////////////////////
	APB_interface # (.DATA_WIDTH(DATA_WIDTH),.APB_dataW(apb_dataW),.ADDR_WIDTH(ADDR_WIDTH)) 
	U2_IF (
	.PRESETn(PRSTn),
	.PCLK(PCLK),
	.PSEL(PSEL),
	.PENABLE(PENABLE),
	.PWRITE(PWRITE),
	.PADDR(PADDR),
	.PWDATA(PWDATA),
	.PRDATA(PRDATA),
	.PREADY(PREADY),
	.PSLVERR(PSLVERR),
	.Rx_data(rx_data_sync),
	.Tx_data(tx_data_p),
	.tx_fifo_full(tx_fifo_full),
	.tx_fifo_empty(TX_FIFO_Empty),
	.rx_fifo_full(RX_FIFO_Full),
	.rx_fifo_empty(rx_fifo_empty),
	.tx_fifo_wr_en(tx_fifo_wr_en),
	.rx_fifo_rd_en(rx_fifo_rd_en),
	.parity_error(Parity_Error),
	.frame_error(Frame_Error),
	.overrun_error(overrun_error),
	.tx_fifo_rst(tx_fifo_rst),
	.rx_fifo_rst(rx_fifo_rst),
	.baud_rate(baud_div),
	.control_reg(control_reg)
	);
	
	//////////////////////// FIFOs ////////////////////////
	// TX 
	Async_fifo #(.F_DEPTH(F_DEPTH),.D_SIZE(DATA_WIDTH))
	U4_tx_fifo (
	.i_w_clk(PCLK),
	.i_w_rstn(PRSTn & ~tx_fifo_rst),
	.i_w_inc(tx_fifo_wr_en),
	.i_r_clk(baud_clk),
	.i_r_rstn(PRSTn),
	.i_r_inc(tx_data_valid),
	.i_w_data(tx_data_p),
	.o_r_data(tx_data_sync),
	.o_full(tx_fifo_full),
	.o_empty(TX_FIFO_Empty)
	);

	// RX 
	Async_fifo #(.F_DEPTH(F_DEPTH),.D_SIZE(DATA_WIDTH))
	U4_rx_fifo (
	.i_w_clk(baud_clk),
	.i_w_rstn(PRSTn),
	.i_w_inc(gated_rx_fifo_wr_en),
	.i_r_clk(PCLK),
	.i_r_rstn(PRSTn),
	.i_r_inc(rx_fifo_rd_en),
	.i_w_data(rx_data_p),
	.o_r_data(rx_data_sync),
	.o_full(RX_FIFO_Full),
	.o_empty(rx_fifo_empty)
	);
	
	///////////// clock divider /////////////
	ClkDiv #(.RATIO_WD(ratio_wd))  
	U5_clkDiv_tx (
	.i_ref_clk(PCLK),
	.i_rst(PRSTn),
	.i_clk_en(tx_en),
	.i_div_ratio(baud_div),
	.o_div_clk(baud_clk)
	);
	
	///////////// clock divider /////////////
	ClkDiv #(.RATIO_WD(ratio_wd))  
	U5_clkDiv_rx (
	.i_ref_clk(PCLK),
	.i_rst(PRSTn),
	.i_clk_en(rx_en), 
	.i_div_ratio(baud_div/8'd8),			// clk div mux 
	.o_div_clk(baud_clk_rx)
	);
		
	
	// overrun error
	always @(posedge PCLK or negedge PRSTn) begin
		if (!PRSTn) begin
			overrun_error <= 1'b0;
		end else if (RX_FIFO_Full && rx_fifo_wr_en) begin
			// If FIFO is full and we're trying to write new data
			overrun_error <= 1'b1;
		end else if (rx_fifo_rd_en) begin
			// Clear error when reading from FIFO (or make it software clearable)
			overrun_error <= 1'b0;
		end
	end
	
endmodule      
	