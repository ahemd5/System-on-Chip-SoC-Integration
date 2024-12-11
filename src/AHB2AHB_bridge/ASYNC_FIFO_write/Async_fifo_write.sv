module Async_fifo_write #(
	parameter D_SIZE = 16 ,                         // data size
	parameter F_DEPTH = 4  ,                        // fifo depth
	parameter P_SIZE = 4                            // pointer width
	)(
	input              i_w_clk,              // write domian operating clock
	input              i_w_rstn,             // write domian active low reset  
	input              i_w_inc,              // write control signal 
	input [D_SIZE-1:0] i_w_data,             // write data bus
	input [P_SIZE-1:0] gray_rd_ptr_sync,
	
	output 				o_full,               // fifo full flag
	output 				o_empty,
	output [D_SIZE-1:0] FIFO_MEM [F_DEPTH-1:0],
	output [P_SIZE-1:0]	gray_w_ptr
	);
	
	wire [P_SIZE-2:0] w_addr ;
	
	fifo_mem_write #(.F_DEPTH(F_DEPTH), .D_SIZE(D_SIZE), .P_SIZE(P_SIZE) ) 
	u_fifo_mem (
	.w_clk(i_w_clk),              
	.w_rstn(i_w_rstn),
	.w_inc(i_w_inc),                             
	.w_full(o_full),              
	.w_addr(w_addr),            
	.w_data(i_w_data),  
	.FIFO_MEM(FIFO_MEM)
	);
	
	fifo_wr # (.P_SIZE(P_SIZE)) u_fifo_wr (            
	.w_clk(i_w_clk),              
	.w_rstn(i_w_rstn),             
	.w_inc(i_w_inc),            
	.sync_rd_ptr(gray_rd_ptr_sync),                
	.w_addr(w_addr),            
	.gray_w_ptr(gray_w_ptr),        
	.full(o_full),
	.empty(o_empty)
	); 

endmodule
