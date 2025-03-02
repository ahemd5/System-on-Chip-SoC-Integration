module slave_mux #(
    parameter NUM_MASTERS = 2,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) (             
    input wire                      i_htrans    [NUM_MASTERS-1:0],                        
    input wire                      i_hwrite    [NUM_MASTERS-1:0],            
    input wire  [ADDR_WIDTH-1:0]    i_haddr     [NUM_MASTERS-1:0],            
    input wire  [DATA_WIDTH-1:0]    i_hwdata    [NUM_MASTERS-1:0],
    input wire  [1:0]               i_hsize     [NUM_MASTERS-1:0],
    input wire                      i_hreadyout,
		
    input wire  [NUM_MASTERS-1:0]   bus_grant,
                
    output reg                      o_htrans,                                    
    output reg                      o_hwrite,            
    output reg  [ADDR_WIDTH-1:0]    o_haddr,
    output reg  [1:0]               o_hsize,
    output reg  [DATA_WIDTH-1:0]    o_hwdata,
	output reg                      o_hselx,
	output reg				        o_shready
);

integer i;


always @(*) begin
	for (i = 0; i < NUM_MASTERS; i = i + 1) begin
		if (bus_grant[i] == 1) begin
		    o_hwdata    = i_hwdata[i];
			o_haddr     = i_haddr[i];
			o_hwrite    = i_hwrite[i];
			o_hsize     = i_hsize[i];
			o_htrans    = i_htrans[i];
			o_hselx     = 1;
			o_shready   = i_hreadyout;
			break; // Only route the signals from the granted master
		end else begin 
		    o_hwdata    = 0;
			o_haddr     = 0;
			o_hwrite    = 0;
			o_hsize     = 0;
			o_htrans    = 0;
			o_hselx     = 0;
			o_shready   = i_hreadyout;

       end 		
	end
 
end
    
endmodule