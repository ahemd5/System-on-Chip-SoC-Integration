module mux #(
	parameter NUM_MASTERS = 2,
	parameter DATA_WIDTH = 32
) (
	input wire						i_hready	[NUM_MASTERS-1:0],			
	input wire						i_hmastlock [NUM_MASTERS-1:0],		
	input wire						i_htrans	[NUM_MASTERS-1:0],			
	input wire	[3:0]				i_hprot		[NUM_MASTERS-1:0],			
	input wire  [2:0]				i_hburst	[NUM_MASTERS-1:0],			
	input wire	[2:0]				i_hsize		[NUM_MASTERS-1:0],			
	input wire 						i_hwrite	[NUM_MASTERS-1:0],			
	input wire  [ADDR-1:0]			i_haddr		[NUM_MASTERS-1:0],			
	input wire	[DATA_WIDTH-1:0]	i_hwdata	[NUM_MASTERS-1:0],			
	input wire 						i_hselx		[NUM_MASTERS-1:0],			 
	
	input wire	[NUM_MASTERS-1:0]	bus_grant,
	
	output reg						o_hready,			
	output reg						o_hmastlock,		
	output reg						o_htrans,			
	output reg	[3:0]				o_hprot,			
	output reg  [2:0]				o_hburst,			
	output reg	[2:0]				o_hsize,			
	output reg 						o_hwrite,			
	output reg  [ADDR-1:0]			o_haddr,			
	output reg	[DATA_WIDTH-1:0]	o_hwdata,			
	output reg 						o_hselx,
);

 integer i;

always @(*) begin
	
// Route signals from the granted master
	for (i = 0; i < NUM_MASTERS; i = i + 1) begin
		if (bus_grant[i]) begin
				o_hprot		= i_hprot[i];
				o_htrans	= i_htrans[i];
				o_hmastlock = i_hmastlock[i];
				o_hready	= i_hready[i];
				o_hselx		= i_hselx[i];
				o_hwdata	= i_hwdata[i];
				o_haddr		= i_haddr[i];
				o_hwrite	= i_hwrite[i];
				o_hsize		= i_hsize[i];
				o_hburst	= i_hburst[i];
			break; // Only route the signals from the granted master
		end
	end
end
	
endmodule