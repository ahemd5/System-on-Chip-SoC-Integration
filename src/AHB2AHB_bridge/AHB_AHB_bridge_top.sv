module AHB_AHB_bridge #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, P_SIZE = 3, F_DEPTH = 4)(
	input 	i_clk_src,
	input 	i_rstn_src,
	input 	i_src_sleep_req,
	output 	o_src_sleep_ack,
	input 	i_clk_sink,
	input 	i_rstn_sink,
	input 	i_sink_sleep_req,
	output 	o_sink_sleep_ack,
	// slave interface 
	input                   i_hready_sink,         
    input                   i_htrans,   
    input  [2:0]            i_hsize,
    input                   i_hwrite,
    input  [ADDR_WIDTH-1:0] i_haddr,
    input  [DATA_WIDTH-1:0] i_hwdata,
    input                   i_hselx,
	output                  o_hreadyout,
    output                  o_hresp,
    output [DATA_WIDTH-1:0] o_hrdata,
	// master interface 
	input 					i_hready_src,
    input 					i_hresp,
	input [DATA_WIDTH-1:0] 	i_hrdata,
    output 					o_hwrite,  
    output 					o_htrans,   
    output [2:0] 			o_hsize,  
    output [ADDR_WIDTH-1:0] o_haddr, 
    output [DATA_WIDTH-1:0] o_hwdata
	);
	
	// internal signals 
	wire [P_SIZE-1:0] rsp_wr_ptr;
	wire [P_SIZE-1:0] req_rd_ptr;
	wire [DATA_WIDTH:0] rsp_fifo_mem [F_DEPTH-1:0];
	wire [DATA_WIDTH+ADDR_WIDTH+1:0] req_fifo_mem [F_DEPTH-1:0];
	wire [P_SIZE-1:0] req_wr_ptr;
	wire [P_SIZE-1:0] rsp_rd_ptr;
	wire sink_sleep_status;
	wire source_sleep_status;
	
	source_top #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.F_DEPTH(F_DEPTH),.P_SIZE(P_SIZE))
	U0_source (
	.i_clk_src(i_clk_src),
	.i_rstn_src(i_rstn_src),
	.i_src_sleep_req(i_src_sleep_req),
	.o_src_sleep_ack(o_src_sleep_ack),
	.i_hready(i_hready_src),
	.i_htrans(i_htrans),
	.i_hsize(i_hsize),
	.i_hwrite(i_hwrite),
	.i_haddr(i_haddr),
	.i_hwdata(i_hwdata),
	.i_hselx(i_hselx),
	.o_hreadyout(o_hreadyout),
	.o_hresp(o_hresp),
	.o_hrdata(o_hrdata),
	.rsp_wr_ptr(rsp_wr_ptr),
	.req_rd_ptr(req_rd_ptr),
	.rsp_FIFO_MEM(rsp_fifo_mem),
	.req_FIFO_MEM(req_fifo_mem),
	.req_wr_ptr(req_wr_ptr),
	.rsp_rd_ptr(rsp_rd_ptr),
	.sink_sleep_status(sink_sleep_status),
	.source_sleep_status(source_sleep_status)
	);
	
	sink_top #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.F_DEPTH(F_DEPTH),.P_SIZE(P_SIZE))
	U1_sink( 
	.i_rstn_sink(i_rstn_sink),
	.i_clk_sink(i_clk_sink),
	.i_sink_sleep_req(i_sink_sleep_req),
	.o_sink_sleep_ack(o_sink_sleep_ack),
	.i_hready(i_hready_sink),
	.i_hresp(i_hresp),
	.i_hrdata(i_hrdata),
	.o_hwrite(o_hwrite),
	.o_htrans(o_htrans),
	.o_hsize(o_hsize),
	.o_haddr(o_haddr),
	.o_hwdata(o_hwdata),
	.req_wr_ptr(req_wr_ptr),
	.req_FIFO_MEM(req_fifo_mem),
	.rsp_rd_ptr(rsp_rd_ptr),
	.req_rd_ptr(req_rd_ptr),
	.rsp_wr_ptr(rsp_wr_ptr),
	.rsp_FIFO_MEM(rsp_fifo_mem),
	.source_sleep_status(source_sleep_status),
	.sink_sleep_status(sink_sleep_status)
	);
	
endmodule
