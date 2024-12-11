module Async_fifo_read #(
	parameter D_SIZE = 16 ,                         // data size
	parameter F_DEPTH = 4  ,                        // fifo depth
	parameter P_SIZE = 4                            // pointer width
	)(
	input              i_r_clk,             // read domian operating clock
	input              i_r_rstn,            // read domian active low reset 
	input              i_r_inc,             // read control signal
	input [P_SIZE-1:0] gray_w_ptr_sync,
	input [D_SIZE-1:0] FIFO_MEM_sync [F_DEPTH-1:0],
	
	output [D_SIZE-1:0] o_r_data,           // read data bus
	output 				o_empty,            // fifo empty flag
	output [P_SIZE-1:0]	gray_rd_ptr
	);
	
	wire [P_SIZE-2:0] r_addr;
 
	fifo_mem_read #(.F_DEPTH(F_DEPTH), .D_SIZE(D_SIZE), .P_SIZE(P_SIZE) ) 
	u_fifo_mem (
	.r_clk(i_r_clk),              
	.r_rstn(i_r_rstn),                                                       
	.r_addr(r_addr),                        
	.r_data(o_r_data),
	.FIFO_MEM_sync(FIFO_MEM_sync)
	); 

	fifo_rd # (.P_SIZE(P_SIZE)) u_fifo_rd (
	.r_clk(i_r_clk),              
	.r_rstn(i_r_rstn),             
	.r_inc(i_r_inc),
	.sync_wr_ptr(gray_w_ptr_sync),
	.rd_addr(r_addr),
	.gray_rd_ptr(gray_rd_ptr),
	.empty(o_empty)
	);


endmodule
