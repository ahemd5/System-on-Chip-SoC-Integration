module source_top #(parameter ADDR_WIDTH = 32,
	DATA_WIDTH = 32,
	F_DEPTH = 4,
	P_SIZE = 3,					// p_size = log2(F_depth) + 1
	NUM_STAGES = 2
	)( 
	input i_clk_src,
	input i_rstn_src,
	input i_src_sleep_req,
	output o_src_sleep_ack,
	// slave interface 
    input  i_hready,
    input  i_htrans,
    input  [2:0] i_hsize,
    input  i_hwrite,
    input  [ADDR_WIDTH-1:0] i_haddr,
    input  [DATA_WIDTH-1:0] i_hwdata,
    input  i_hselx,
	output o_hreadyout,
    output o_hresp,
    output [DATA_WIDTH-1:0] o_hrdata,
	// async interface (sync inputs)
	input  [P_SIZE-1:0] rsp_wr_ptr,
	input  [P_SIZE-1:0] req_rd_ptr,
	input  [DATA_WIDTH:0] rsp_FIFO_MEM [F_DEPTH-1:0],
	// outputs to synchronizer
	output reg [DATA_WIDTH+ADDR_WIDTH+1:0] req_FIFO_MEM [F_DEPTH-1:0],
	output [P_SIZE-1:0] req_wr_ptr,
	output [P_SIZE-1:0] rsp_rd_ptr,
	// sink
	input sink_sleep_status,
	output source_sleep_status
	);
	
	// internal signals 
	wire req_src_full;
	wire req_src_empty;
	wire rsp_src_empty;
	wire [DATA_WIDTH+ADDR_WIDTH+1:0] o_packet_src;

	wire req_src_wr_en;
	wire rsp_src_rd_en;
	wire src_fifos_reset;
	wire [DATA_WIDTH:0] o_r_data_src;						// rsp fifo to controller
	
	wire o_ready_2slave;	
	wire o_rd_valid;
	wire [DATA_WIDTH-1:0] o_rd_data;
	wire i_valid;
	wire i_rd0_wr1;
	wire [DATA_WIDTH-1:0] i_wr_data;
	wire [ADDR_WIDTH-1:0] i_addr;
	
	wire [P_SIZE-1:0] rsp_wr_ptr_sync;
	wire [DATA_WIDTH:0] rsp_FIFO_MEM_sync [F_DEPTH-1:0];
	wire [P_SIZE-1:0] req_rd_ptr_sync;
	
	/*
	genvar i;
	generate
		for (i = 0; i < F_DEPTH; i = i + 1) begin
			synchronizer_logic #(.NUM_STAGES(NUM_STAGES),.BUS_WIDTH(DATA_WIDTH),.F_DEPTH(F_DEPTH),.P_SIZE(P_SIZE)
			) U4_sync (
			.CLK(i_clk_src), .RST(i_rstn_src),
			.async_gray_ptr(rsp_wr_ptr),
			.sync_gray_ptr(rsp_wr_ptr_sync),
			.input_mem(rsp_FIFO_MEM[i]),
			.my_mem(rsp_FIFO_MEM_sync[i])
			);
		end
	endgenerate
*/
	synchronizer_logic #(.NUM_STAGES(NUM_STAGES),.BUS_WIDTH(DATA_WIDTH+1),.F_DEPTH(F_DEPTH),.P_SIZE(P_SIZE)
	) U4_sync (
	.CLK(i_clk_src), .RST(src_fifos_reset),
	.async_gray_ptr(rsp_wr_ptr),
	.sync_gray_ptr(rsp_wr_ptr_sync),
	.input_mem(rsp_FIFO_MEM),
	.my_mem(rsp_FIFO_MEM_sync)
	);

		
	synchronizer #(.BUS_WIDTH(P_SIZE))
	u10_src2sink_req (
	.CLK(i_clk_src),
	.RST(src_fifos_reset),
    .ASYNC(req_rd_ptr),
    .SYNC(req_rd_ptr_sync)
	);
	
	source_controller #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.packet_width(ADDR_WIDTH+DATA_WIDTH+2)) 
	u0_src_ctrl(
	.i_clk_src(i_clk_src),
	.i_rstn_src(i_rstn_src),
	.i_src_sleep_req(i_src_sleep_req),
	.sink_sleep_status(sink_sleep_status),
	.i_read_packet(o_r_data_src),
	.rd0_wr1(i_rd0_wr1),
	.addr(i_addr),
	.valid(i_valid),
	.wr_data(i_wr_data),
	.ready(o_ready_2slave),
	.rd_data(o_rd_data),
	.rd_valid(o_rd_valid),
	.req_fifo_full(req_src_full),
	.req_fifo_empty(req_src_empty),
	.rsp_fifo_empty(rsp_src_empty),
	.o_src_sleep_ack(o_src_sleep_ack),
	.source_sleep_status(source_sleep_status),
	.o_packet(o_packet_src),
	.req_fifo_wr_en(req_src_wr_en),
	.rsp_fifo_rd_en(rsp_src_rd_en),
	.reset_flag(src_fifos_reset)
	);
	
	Async_fifo_write #(.D_SIZE(DATA_WIDTH+ADDR_WIDTH+2),.F_DEPTH(F_DEPTH),.P_SIZE(P_SIZE))
	u1_req_src_async_fifo(
	.i_w_clk(i_clk_src),
	.i_w_rstn(src_fifos_reset),
	.i_w_inc(req_src_wr_en),
	.i_w_data(o_packet_src),
	.gray_rd_ptr_sync(req_rd_ptr_sync),
	.o_full(req_src_full),
	.o_empty(req_src_empty),
	.FIFO_MEM(req_FIFO_MEM),
	.gray_w_ptr(req_wr_ptr)
	);
	
	Async_fifo_read #(.D_SIZE(DATA_WIDTH+1),.F_DEPTH(F_DEPTH),.P_SIZE(P_SIZE))
	u2_rsp_src_async_fifo(
	.i_r_clk(i_clk_src),
	.i_r_rstn(src_fifos_reset),
	.i_r_inc(rsp_src_rd_en),
	.gray_w_ptr_sync(rsp_wr_ptr_sync),
	.FIFO_MEM_sync(rsp_FIFO_MEM_sync),
	.o_r_data(o_r_data_src),
	.o_empty(rsp_src_empty),
	.gray_rd_ptr(rsp_rd_ptr)
	); 
	
	ahb_slave #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) 
	u3_slave(
	.i_clk_ahb(i_clk_src),
	.i_rstn_ahb(i_rstn_src),
	.i_hready(i_hready),
	.i_htrans(i_htrans),
	.i_hsize(i_hsize),
	.i_hwrite(i_hwrite),
	.i_haddr(i_haddr),
	.i_hwdata(i_hwdata),
	.i_hselx(i_hselx),
	.i_ready(o_ready_2slave),
	.i_rd_valid(o_rd_valid),
	.i_rd_data(o_rd_data),
	.o_hreadyout(o_hreadyout),
	.o_hresp(o_hresp),
	.o_hrdata(o_hrdata),
	.o_valid(i_valid),
	.o_rd0_wr1(i_rd0_wr1),
	.o_wr_data(i_wr_data),
	.o_addr(i_addr)
	);
	
endmodule