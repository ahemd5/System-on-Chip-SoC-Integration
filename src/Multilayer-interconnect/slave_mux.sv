module slave_mux #(
	parameter NUM_MASTERS = 2,
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 32
) (
	input wire						i_hready	[NUM_MASTERS-1:0],					
	input wire						i_htrans	[NUM_MASTERS-1:0],						
	input wire 						i_hwrite	[NUM_MASTERS-1:0],			
	input wire  [ADDR_WIDTH-1:0]	i_haddr		[NUM_MASTERS-1:0],			
	input wire	[DATA_WIDTH-1:0]	i_hwdata	[NUM_MASTERS-1:0],			
	input wire 						i_hselx		[NUM_MASTERS-1:0],			 
	
	input wire						bus_grant	[NUM_MASTERS-1:0],
	
	output reg						o_hready,			
	output reg						o_htrans,									
	output reg 						o_hwrite,			
	output reg  [ADDR_WIDTH-1:0]	o_haddr,			
	output reg	[DATA_WIDTH-1:0]	o_hwdata,			
	output reg 						o_hselx
);

 integer i;

always @(*) begin
	
// Route signals from the granted master
	for (i = 0; i < NUM_MASTERS; i = i + 1) begin
		if (bus_grant[i]) begin
				o_htrans	= i_htrans[i];
				o_hready	= i_hready[i];
				o_hselx		= i_hselx[i];
				o_hwdata	= i_hwdata[i];
				o_haddr		= i_haddr[i];
				o_hwrite	= i_hwrite[i];
			break; // Only route the signals from the granted master
		end
	end
end
	
endmodule