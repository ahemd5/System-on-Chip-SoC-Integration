module AHB_slave #(parameter DATA_WIDTH = 32, ADDR = 32)(
input logic						i_clk_ahb,
input logic						i_rstn_ahb,
//Inputs from master
input logic						i_hready,			// AHB ready signal, indicates when the slave is ready for a new transfer
input logic						i_hmastlock,		// Master lock signal for exclusive transactions
input logic						i_htrans,			// AHB transaction type
input logic	[3:0]				i_hprot,			// AHB protection control
input logic [2:0]				i_hburst,			// AHB burst type
input logic	[2:0]				i_hsize,			// AHB transfer size
input logic 					i_hwrite,			// AHB write control, 1 for write, 0 for read
input logic [ADDR-1:0]			i_haddr,			// AHB address for the transaction
input logic	[DATA_WIDTH-1:0]	i_hwdata,			// AHB write data from master
input logic 					i_hselx,			// AHB slave select, indicates if the slave is selected
//Inputs from memory
input logic					 	i_ready,			// Ready signal from integration logic
input logic					 	i_rd_valid,			// Read data valid signal from memory, indicates data is available
input logic	[DATA_WIDTH-1:0] 	i_rd_data,			// Read data from memory

//Outputs for master
output reg					o_hreadyout,		// Slave ready output signal
output reg 					o_hresp,			// Slave response signal, always OKAY in this module
output reg [DATA_WIDTH-1:0]	o_hrdata,			// Read data output to AHB bus
//Outputs for memory
output reg					o_valid,			// Valid transaction signal, asserted when parameters are set on outputs
output reg					o_rd0_wr1,			// Transaction type, 0 for read and 1 for write
output reg [DATA_WIDTH-1:0]	o_wr_data,			// Write data for memory
output reg [ADDR-1:0]		o_addr				// Address for memory
);

// Internal signals
 reg [ADDR-1:0] addr_reg;								// Register to hold address during write phase
 
// FSM states
typedef enum logic {
	IDLE   = 1'b0,  // Idle state, waiting for new transaction
	NON_SEQ  = 1'b1  // Non-sequential state, active transaction
} state;

state current_state, next_state;

// Sequential block 	
always@(posedge i_clk_ahb or negedge i_rstn_ahb)
	begin 
		if(!i_rstn_ahb) 
			current_state <= IDLE ;
		else 					  				 
			current_state <= next_state ;
	end 
	
// next state logic
always @(*)
	begin
		case(current_state)
			IDLE : begin
				if (i_hselx && i_hready && i_ready && i_htrans == NON_SEQ) begin
					next_state = NON_SEQ;
				end
				else begin
					next_state = IDLE;
				end
			end
			
			NON_SEQ : begin
				if(i_hselx && i_htrans == NON_SEQ) begin
					next_state = NON_SEQ;
				end
				else begin
					next_state = IDLE;
				end
			end
			
			default : next_state = IDLE;
		endcase
	end
	
// Output logic to control transaction parameters
always @(*)
	begin
		// don't touch
		o_hresp = 0;						// OKAY response
		
		//change 
		o_valid = 0;
		o_rd0_wr1 = i_hwrite;			// Transaction type: 0 for read
		o_wr_data = 0; 
		case(current_state)
			IDLE : begin
				o_addr = 0;
				o_hreadyout = 1;
				o_hrdata = 0;
				if(i_hready) begin 
					addr_reg =  i_haddr;
				end 
				else begin 
					addr_reg =  0;
				end 
			end
			
			NON_SEQ : begin
				o_valid = (i_hselx)? 1 : 0 ;
				addr_reg =  i_haddr;	
				o_addr = addr_reg;				
				if(i_ready) begin 
					o_hreadyout = 1;
					if(i_hwrite) begin 
						o_wr_data = i_hwdata;		// Set write data 
						o_hrdata = i_rd_data;						
					end 
					else begin 
						if(i_rd_valid) begin
							o_hrdata = i_rd_data;		// For read, set output data
							o_wr_data = i_hwdata;
						end
						else begin 
							o_hrdata = 0;
							o_wr_data = i_hwdata;	
						end 						
					end
				end
				else begin							// busy state 
					o_hreadyout = 0;
				end
			end
			
			default : begin 
				o_valid = 0;
				o_rd0_wr1 = i_hwrite;
				o_hreadyout = 1;
				o_addr = 1'b0;
				addr_reg = 0;
				o_hrdata = 0;
			end 
		endcase
	end
endmodule