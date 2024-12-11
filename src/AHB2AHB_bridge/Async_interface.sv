module Async_interface #(parameter SIZE_src2sink = 66, P_SIZE = 4 , SIZE_sink2src = 33, F_DEPTH = 4)
	( 
	// clock and reset 
	input i_clk_src,
	input i_rstn_src,
	input i_clk_sink,
	input i_rstn_sink,
	
	// request fifo
	input [P_SIZE-1:0]			req_gray_w_ptr,
	input [P_SIZE-1:0]			req_gray_rd_ptr,
	input [SIZE_src2sink-1:0] 	req_FIFO_MEM [F_DEPTH-1:0],

	output [SIZE_src2sink-1:0] 	req_FIFO_MEM_sync [F_DEPTH-1:0],
	output [P_SIZE-1:0] 		req_gray_w_ptr_sync,
	output [P_SIZE-1:0]			req_gray_rd_ptr_sync,
	// response fifo
	input [P_SIZE-1:0]			rsp_gray_w_ptr,
	input [P_SIZE-1:0]			rsp_gray_rd_ptr,
	input [SIZE_sink2src-1:0] 	rsp_FIFO_MEM [F_DEPTH-1:0],
	
	output [SIZE_sink2src-1:0] 	rsp_FIFO_MEM_sync [F_DEPTH-1:0],
	output [P_SIZE-1:0] 		rsp_gray_w_ptr_sync,
	output [P_SIZE-1:0]			rsp_gray_rd_ptr_sync
	);
	
	// request fifos
	genvar i;
	generate
		for (i = 0; i < F_DEPTH; i = i + 1) begin
			synchronizer #(.BUS_WIDTH(SIZE_src2sink)) Ui_src2sink_req (
			.CLK(i_clk_sink),.RST(i_rstn_sink),
			.ASYNC(req_FIFO_MEM[i]),
			.SYNC(req_FIFO_MEM_sync[i])
			);
		end
	endgenerate

	synchronizer #(.BUS_WIDTH(P_SIZE))
	u99_src2sink_req (
	.CLK(i_clk_sink),
	.RST(i_rstn_sink),
    .ASYNC(req_gray_w_ptr),
    .SYNC(req_gray_w_ptr_sync)
	);
	
	synchronizer #(.BUS_WIDTH(P_SIZE))
	u100_sink2src_req (
	.CLK(i_clk_src),
	.RST(i_rstn_src),
    .ASYNC(req_gray_rd_ptr),
    .SYNC(req_gray_rd_ptr_sync)
	);
	//////////////// response fifos //////////////////
	genvar j;
	generate
		for (j = 0; j < F_DEPTH; j = j + 1) begin	
			synchronizer #(.BUS_WIDTH(SIZE_sink2src)) Uj_sink2src_rsp (
			.CLK(i_clk_sink),
			.RST(i_rstn_sink),
			.ASYNC(rsp_FIFO_MEM[j]),
			.SYNC(rsp_FIFO_MEM_sync[j])
			);
		end
	endgenerate
	
	synchronizer #(.BUS_WIDTH(P_SIZE))
	u101_sink2src_rsp (
	.CLK(i_clk_src),
	.RST(i_rstn_src),
    .ASYNC(rsp_gray_w_ptr),
    .SYNC(rsp_gray_w_ptr_sync)
	);
	
	synchronizer #(.BUS_WIDTH(P_SIZE))
	u102_src2sink_rsp (
	.CLK(i_clk_sink),
	.RST(i_rstn_sink),
    .ASYNC(rsp_gray_rd_ptr),
    .SYNC(rsp_gray_rd_ptr_sync)
	);
	
endmodule