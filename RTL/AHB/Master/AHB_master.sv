module AHB_master #(parameter DATA_WIDTH = 32, ADDR = 32)(
input logic 					i_clk_ahb,	
input logic 					i_rstn_ahb,
// Standard signals 
input logic 					i_hready,
input logic 					i_hresp,
input logic [DATA_WIDTH-1:0] 	i_hrdata,    	// read from slave 
// Transaction signals
input logic 					i_valid,
input logic [ADDR-1:0] 			i_addr,
input logic [DATA_WIDTH-1:0]    i_wr_data,
input logic 					i_rd0_wr1,	//type of the transaction, if 0 =>read, if 1 => write

// Standard signals
output reg [ADDR-1:0] 		o_haddr,
output reg [2:0] 			o_hburst,
output reg 					o_hmastlock,
output reg [3:0] 			o_hprot,
output reg [2:0] 			o_hsize,
output reg 		 			o_htrans,
output reg [DATA_WIDTH-1:0] o_hwdata,
output reg 					o_hwrite,
// Transaction signals
output reg [DATA_WIDTH-1:0] o_rd_data,
output reg 					o_rd_valid,
output reg 					o_ready
);

reg [ADDR-1:0] addr_old;
reg [DATA_WIDTH-1:0] data_temp;
reg [DATA_WIDTH-1:0] read_temp;
reg busy;
reg flag ;


// FSM states
typedef enum logic {
	IDLE   = 1'b0,  	// Idle state
	NONSEQ = 1'b1	 	// 
} state;

state current_state, next_state, htrans;

// Sequential block 	
always@(posedge i_clk_ahb or negedge i_rstn_ahb)
	begin 
		if(!i_rstn_ahb) 
			current_state <= IDLE ;
		else 					  				 
			current_state <= next_state ;

	end 
		
always@(*)
	begin 
		case(current_state)
			IDLE : begin 
				if (i_valid)
					next_state =  NONSEQ ;
				else begin 
					next_state =  IDLE ;
				end 
			end
			
			NONSEQ : begin 
				if (!i_valid)  	
					next_state = IDLE;  // no Transaction back to IDLE case 				// check
					// if hready = 0 >> Stay in NONSEQ until transfer completes
					// if hready = 1 >> back-to-back transactions	
				else 
					next_state = NONSEQ;		
			end 
			
			default : next_state =  IDLE ;  	
		endcase
	end 	
	
	
always@(*)
begin 
	// don't touch
	o_hburst = 'b000;			// no burst
	o_hmastlock = 'b0;         // optional feature
	o_hprot = 'b0011;          // no protection control 'b0011
	o_hsize = 'b010;           // one word 'b010
	//change
	o_hwrite = i_rd0_wr1;				// 1 write, 0read
	o_ready = 1; 
	
	
	case(current_state)  
	IDLE : begin	 
		o_htrans = 0;
		o_hwdata = 'b0;
		o_haddr = 'b0;
		o_rd_data = 'b0;
		o_rd_valid = 'b0;
		data_temp = 'b0;
		read_temp = 'b0;
		flag = 0;
		busy = 0;
		if(i_hready && i_valid) begin 
			if (i_rd0_wr1)	begin			//write 
				data_temp = 0;
			end
			else begin 						// read 
				read_temp = 0;  		// previous read data if available
				o_rd_valid = 1;	
			end
		end
		else begin 							// hready = 0 
			o_ready = 0;           			// Master is busy processing
			if (i_rd0_wr1)					//write 
				o_hwdata = i_wr_data;
			else begin 						// read 
				//o_rd_data = 0;  			// don't read 
				o_rd_valid = 0;	
			end
		end	
	end 		
	
	NONSEQ : begin 
		o_htrans = 1;						// name of state 
		o_hwdata = 'b0;
		o_rd_data = 'b0;
		o_haddr = i_addr;
		//addr_old = i_addr;	
		//change
		//busy = 0;
		if(i_hready)
		begin 
			if (i_rd0_wr1)	begin 				//write 
				if(busy) begin 
					busy = !i_hready;
					o_rd_data = read_temp;  		// previous read data if available
					read_temp = i_hrdata;
					o_rd_valid = flag;
					flag = 0;
				end 
				else begin 
					o_hwdata = data_temp;
					data_temp = i_wr_data;
					o_rd_data = read_temp;  		// previous read data if available
					read_temp = i_hrdata;
					o_rd_valid = flag;
					flag = 0;
					busy = 0;
				end						
				end
			else begin 								// read 
				o_rd_data = read_temp;  			// previous read data if available
				read_temp = i_hrdata;
				o_hwdata = data_temp;
				data_temp = i_wr_data;
				o_rd_valid = flag;
				flag = 1;
				busy = 0;
			end
		end
		else begin 							// hready = 0 
			o_rd_valid = 0;
			o_ready = 0;           			// Master is busy processing
			busy = 1;
			flag = 1;
			if (i_rd0_wr1) begin 			//write 
				o_hwdata = data_temp;
				data_temp = i_wr_data;
				end
			else begin 						// read 
				//o_rd_data = 0;  			// don't read 
				o_hwdata = data_temp;				
			end
		end
		
	end 
	
	default : begin 
		o_htrans = 0;
		o_hwdata = 0;
		o_rd_data = 0;
		o_rd_valid = 0;
	end 
	
	endcase
end



endmodule