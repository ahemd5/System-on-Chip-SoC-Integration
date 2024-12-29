
// ************************* Description *********************** //
//  This module is implemented to:-                              //
//   -- generate write address in binary code                    //
//   -- generate full flag to overcome fifo overwrite            //
//   -- generate gray coded write pointer                        //
// ************************************************************* //

module fifo_wr #(
  parameter P_SIZE = 4                          // pointer width
)
  (
   input  wire                    w_clk,              // write domian operating clock
   input  wire                    w_rstn,             // write domian active low reset 
   input  wire                    w_inc,              // write control signal 
   input  wire  [P_SIZE-1:0]      sync_rd_ptr,        // synced gray coded read pointer         
   output wire  [P_SIZE-2:0]      w_addr,             // generated binary write address
   output reg   [P_SIZE-1:0]      w_ptr,        
   output wire                    full                // fifo full flag

);



// increment binary pointer
always @(posedge w_clk or negedge w_rstn)
 begin
  if(!w_rstn)
   begin
    w_ptr <= 0 ;
   end
 else if (!full && w_inc)
    w_ptr <= w_ptr + 1 ;
 end


// generation of write address
assign w_addr = w_ptr[P_SIZE-2:0] ;




// generation of full flag
assign full = (sync_rd_ptr[P_SIZE-1]!= w_ptr[P_SIZE-1] && sync_rd_ptr[P_SIZE-2]!= w_ptr[P_SIZE-2] && sync_rd_ptr[P_SIZE-3:0]== w_ptr[P_SIZE-3:0]) ;



endmodule

