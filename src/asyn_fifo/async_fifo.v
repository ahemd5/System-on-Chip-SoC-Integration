
module Async_fifo #(
  parameter D_SIZE = 16 ,                         // data size
  parameter F_DEPTH = 8  ,                        // fifo depth
  parameter P_SIZE = 4                            // pointer width
)
 (
   input                    i_clk_wr,              // write domian operating clock
   input                    i_rstn_wr,             // write domian active low reset  
   input                    i_wr_en,              // write control signal 
   input                    i_clk_rd,              // read domian operating clock
   input                    i_rstn_rd,             // read domian active low reset 
   input                    i_rd_en,              // read control signal
   input   [D_SIZE-1:0]     i_wr_data,             // write data bus 
   output  [D_SIZE-1:0]     o_rd_data,             // read data bus
   output                   o_full,               // fifo full flag
   output                   o_empty               // fifo empty flag

);


wire [P_SIZE-2:0] r_addr , w_addr ;
wire [P_SIZE-1:0] w2r_ptr , r2w_ptr ;
wire [P_SIZE-1:0] gray_w_ptr , gray_rd_ptr ;

 
fifo_mem #(.F_DEPTH(F_DEPTH), .D_SIZE(D_SIZE), .P_SIZE(P_SIZE) ) 
u_fifo_mem (
.w_clk( i_clk_wr),              
.w_rstn( i_rstn_wr),
.w_inc(i_wr_en),                             
.w_full(o_full),              
.w_addr(w_addr),            
.r_addr(r_addr),
.w_data(i_wr_data),                        
.r_data(o_rd_data)
); 

fifo_rd # (.P_SIZE(P_SIZE)) u_fifo_rd (
.r_clk(i_clk_rd),              
.r_rstn(i_rstn_rd),             
.r_inc(i_rd_en),              
.sync_wr_ptr(w2r_ptr),                 
.rd_addr(r_addr),            
.gray_rd_ptr(gray_rd_ptr),        
.empty(o_empty)
);

BIT_SYNC #(.NUM_STAGES(2) , .BUS_WIDTH(P_SIZE)) u_w2r_sync (
.CLK(i_clk_rd) ,
.RST(i_rstn_rd) ,
.ASYNC(gray_w_ptr) ,
.SYNC(w2r_ptr)
);

fifo_wr # (.P_SIZE(P_SIZE)) u_fifo_wr (            
.w_clk(i_clk_wr),              
.w_rstn(i_rstn_wr),             
.w_inc(i_wr_en),            
.sync_rd_ptr(r2w_ptr),                
.w_addr(w_addr),            
.gray_w_ptr(gray_w_ptr),        
.full(o_full)
);               

BIT_SYNC #(.NUM_STAGES(2) , .BUS_WIDTH(P_SIZE)) u_r2w_sync
(
.CLK(i_clk_wr) ,
.RST(i_rstn_wr) ,
.ASYNC(gray_rd_ptr) ,
.SYNC(r2w_ptr)
);

endmodule
