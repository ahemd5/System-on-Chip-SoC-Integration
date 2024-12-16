module slave_mux #(
	parameter NUM_MASTERS = 2,
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 32
) (					
	input wire						i_htrans	[NUM_MASTERS-1:0],						
	input wire 						i_hwrite	[NUM_MASTERS-1:0],			
	input wire  [ADDR_WIDTH-1:0]	i_haddr		[NUM_MASTERS-1:0],			
	input wire	[DATA_WIDTH-1:0]	i_hwdata	[NUM_MASTERS-1:0],						 
	
	input wire	[NUM_MASTERS-1:0]	bus_grant,
				
	output reg						o_htrans,									
	output reg 						o_hwrite,			
	output reg  [ADDR_WIDTH-1:0]	o_haddr,			
	output reg	[DATA_WIDTH-1:0]	o_hwdata		
);

 integer i;

always @(*) begin
	
// Route signals from the granted master
	for (i = 0; i < NUM_MASTERS; i = i + 1) begin
		if (bus_grant[i]) begin
				o_htrans	= i_htrans[i];
				o_hwdata	= i_hwdata[i];
				o_haddr		= i_haddr[i];
				o_hwrite	= i_hwrite[i];
			break; // Only route the signals from the granted master
		end
	end
end
	
endmodule