module sink_top #(parameter ADDR_WIDTH = 32,
	DATA_WIDTH = 32,
	F_DEPTH = 4,
	P_SIZE = 3					// p_size = log2(F_depth) + 1
	)( 
	input i_rstn_sink,
	input i_clk_sink,
	input i_sink_sleep_req,
	output o_sink_sleep_ack,
	// master interface 
	input [DATA_WIDTH-1:0] i_prdata,
	input i_pready,
	input i_pslverr,
	output o_psel,
	output o_penable,
	output o_pwrite,
	output [ADDR_WIDTH-1:0] o_paddr,
	output [DATA_WIDTH-1:0]o_pwdata,
	
	// async interface
	input [P_SIZE-1:0] req_wr_ptr_sync,
	input [DATA_WIDTH+ADDR_WIDTH+1:0] req_FIFO_MEM_sync [F_DEPTH-1:0],
	input [P_SIZE-1:0] rsp_rd_ptr_sync,
	output [P_SIZE-1:0] req_rd_ptr,
	output [P_SIZE-1:0] rsp_wr_ptr,
	output [DATA_WIDTH:0] rsp_FIFO_MEM [F_DEPTH-1:0],
	// src 
	input source_sleep_status,
	output sink_sleep_status
	);
	
	// internal signals 
	wire 					i_rd_valid;
	wire [DATA_WIDTH-1:0] 	i_rd_data;
	wire        			i_ready_from_master;
	wire 					o_rd0_wr1;
	wire [ADDR_WIDTH-1:0]   o_addr;
	wire 					o_valid;
	wire [DATA_WIDTH-1:0]   o_wr_data;
	// sink signals 
	wire req_sink_empty;
	wire rsp_sink_full;
	wire rsp_sink_empty;
	wire [DATA_WIDTH:0] o_packet_sink;
	wire req_sink_rd_en;
	wire rsp_sink_wr_en;
	wire sink_fifos_reset;
	wire [DATA_WIDTH+ADDR_WIDTH+1:0] o_r_data_sink;
	
	sink_controller #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.packet_width(ADDR_WIDTH+DATA_WIDTH+2))
	u0_sink_ctrl(
	.i_clk_sink(i_clk_sink),
	.i_rstn_sink(i_rstn_sink),
	.i_sink_sleep_req(i_sink_sleep_req),
	.source_sleep_status(source_sleep_status),
	.i_packet(o_r_data_sink),
	.rd_data(i_rd_data),
	.rd_valid(i_rd_valid),
	.i_ready(i_ready_from_master),
	.rd0_wr1(o_rd0_wr1),
	.addr(o_addr),
	.valid(o_valid),
	.wr_data(o_wr_data),
	.req_fifo_empty(req_sink_empty),
	.rsp_fifo_full(rsp_sink_full),
	.rsp_fifo_empty(rsp_sink_empty),
	.o_sink_sleep_ack(o_sink_sleep_ack),
	.sink_sleep_status(sink_sleep_status),
	.o_packet(o_packet_sink),
	.req_fifo_rd_en(req_sink_rd_en),
	.rsp_fifo_wr_en(rsp_sink_wr_en),
	.reset_flag(sink_fifos_reset)
	);
	
	Async_fifo_read #(.D_SIZE(DATA_WIDTH+ADDR_WIDTH+2),.F_DEPTH(F_DEPTH),.P_SIZE(P_SIZE))
	u1_req_sink_async_fifo(
	.i_r_clk(i_clk_sink),
	.i_r_rstn(sink_fifos_reset),
	.i_r_inc(req_sink_rd_en),
	.gray_w_ptr_sync(req_wr_ptr_sync),
	.FIFO_MEM_sync(req_FIFO_MEM_sync),
	.o_r_data(o_r_data_sink),
	.o_empty(req_sink_empty),
	.gray_rd_ptr(req_rd_ptr)
	);

	Async_fifo_write #(.D_SIZE(DATA_WIDTH+1),.F_DEPTH(F_DEPTH),.P_SIZE(P_SIZE))
	u2_rsp_sink_async_fifo(
	.i_w_clk(i_clk_sink),
	.i_w_rstn(sink_fifos_reset),
	.i_w_inc(rsp_sink_wr_en),
	.i_w_data(o_packet_sink),
	.gray_rd_ptr_sync(rsp_rd_ptr_sync),
	.o_full(rsp_sink_full),
	.o_empty(rsp_sink_empty),
	.FIFO_MEM(rsp_FIFO_MEM),
	.gray_w_ptr(rsp_wr_ptr)
	);	
	
	apb_master #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH))
	u3_master(
	.i_clk_apb(i_clk_sink),
	.i_rstn_apb(i_rstn_sink),
	.i_valid(o_valid),
	.i_rd0_wr1(o_rd0_wr1),
	.o_ready(i_ready_from_master),
	.o_rd_valid(i_rd_valid),
	.i_addr(o_addr),
	.i_wr_data(o_wr_data),
	.o_rd_data(i_rd_data),
	.i_prdata(i_prdata),
	.i_pready(i_pready),
	.i_pslverr(i_pslverr),
	.o_psel(o_psel),
	.o_penable(o_penable),
	.o_pwrite(o_pwrite),
	.o_paddr(o_paddr),
	.o_pwdata(o_pwdata)
	);
endmodule