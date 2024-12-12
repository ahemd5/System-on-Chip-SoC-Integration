module RegFile #(parameter DATA_WIDTH = 32, REG_FILE_DEPTH = 11, ADDR_WIDTH = 32 )

(
input    wire                     clk,
input    wire                     rst,
input    wire                     i_rd0_wr1,
input    wire                     i_valid,
input    wire                     i_trig_end_fsm,
input    wire   [7:0]             i_dma_start_trig,
input    wire   [ADDR_WIDTH-1:0]  i_addr,
input    wire   [DATA_WIDTH-1:0]  i_data,
output   reg    [DATA_WIDTH-1:0]  o_rd_data,
output   reg                      o_rd_valid,
output   reg                      o_ready,
output   reg                      o_sw_en,
output   reg    [7:0]             o_hw_en,
output   reg    [DATA_WIDTH:0]    o_src_addr,
output   reg    [DATA_WIDTH:0]    o_dist_addr,
output   reg    [DATA_WIDTH:0]    o_src_addr_type,
output   reg    [DATA_WIDTH:0]    o_dist_addr_type,
output   reg    [DATA_WIDTH:0]    o_src_data_width,
output   reg    [DATA_WIDTH:0]    o_dist_data_width,
output   reg    [DATA_WIDTH:0]    o_total_trans

);

  
// register file of 8 registers each of 16 bits width
reg [DATA_WIDTH-1:0] regArr [REG_FILE_DEPTH-1:0] ;    

always @(posedge clk or negedge rst)
 begin
   if(!rst)begin  // Asynchronous active low reset 
	 o_rd_valid <= 1'b0 ;
	 o_rd_data     <= 'b0 ;
	 o_ready             <= 'b1 ;
	 o_src_addr <= 'b0 ;
     o_dist_addr <= 'b0 ;
     o_src_addr_type <= 'b0 ;
     o_dist_addr_type <= 'b0 ;
     o_src_data_width <= 'b0 ;
     o_dist_data_width <= 'b0 ;
     o_total_trans <= 'b0 ;
	 
	end else if (i_trig_end_fsm)begin 
	regArr [REG_FILE_DEPTH-2][DATA_WIDTH-1:0] = 1 ;    ///// interrupt status reg 
	regArr [REG_FILE_DEPTH-4][DATA_WIDTH-1:0] = 0 ;
	o_ready <= 1;
	
	end else if (regArr [REG_FILE_DEPTH-1][DATA_WIDTH-1:0])begin   ///// interrupt clear reg 
	regArr [REG_FILE_DEPTH-2][DATA_WIDTH-1:0] = 0 ;   
	
    end else if (i_rd0_wr1 && i_valid)begin 
      regArr[i_addr] <= i_data ;
    end else if (!i_rd0_wr1 && i_valid)begin
       o_rd_data <= regArr[i_addr] ;
	   o_rd_valid <= 1'b1 ;
	end else if (!regArr [REG_FILE_DEPTH-2][DATA_WIDTH-1:0])begin
	 o_rd_valid <= 1'b0 ;
	 o_ready <= 0;
    end else begin
	   o_rd_valid <= 1'b0 ;
     end	 
  end

always@(*)begin
regArr [REG_FILE_DEPTH-3][DATA_WIDTH-1:0] = {0,i_dma_start_trig} ;

o_src_addr = regArr [0][DATA_WIDTH-1:0];
o_dist_addr = regArr [1][DATA_WIDTH-1:0];
o_src_addr_type = regArr [2][DATA_WIDTH-1:0];
o_dist_addr_type = regArr [3][DATA_WIDTH-1:0];
o_src_data_width = regArr [4][DATA_WIDTH-1:0];
o_dist_data_width = regArr [5][DATA_WIDTH-1:0];
o_total_trans = regArr [6][DATA_WIDTH-1:0];
o_sw_en = regArr [REG_FILE_DEPTH-4][DATA_WIDTH-1:0];
o_hw_en = regArr [REG_FILE_DEPTH-3][7:0];
end

endmodule