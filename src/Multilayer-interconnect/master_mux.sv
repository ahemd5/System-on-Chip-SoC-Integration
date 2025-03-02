module master_mux #(
    parameter NUM_SLAVES = 2,
    parameter DATA_WIDTH = 32
) (
    input wire  [DATA_WIDTH-1:0]    i_shrdata    [NUM_SLAVES-1:0],       // hrdata from slave 
    input wire                      i_shresp     [NUM_SLAVES-1:0],       // hresp from slave 
	input wire                      i_hreadyout  [NUM_SLAVES-1:0],
	
    
    input wire  [NUM_SLAVES-1:0]    i_hsel,
    
    output reg  [DATA_WIDTH-1:0]     o_mhrdata,                          // hrdata to master 
    output reg                       o_mhresp ,                           // hresp to master
	output reg                       o_mhready 
    
);

integer i;

always @(*) begin
    // Default outputs
    o_mhrdata = 32'b0;
    o_mhresp = 1'b0;
    for(i = 0; i < NUM_SLAVES; i = i + 1) begin
        if (i_hsel[i]) begin
            o_mhrdata = i_shrdata[i];      // Forward hrdata from selected slave
            o_mhresp = i_shresp[i];        // Forward hresp from selected slave
			o_mhready = i_hreadyout[i];
            break; // Stop after finding the selected slave
        end else begin 
		    o_mhrdata = 0;      // Forward hrdata from selected slave
            o_mhresp = 0;        // Forward hresp from selected slave
			o_mhready = i_hreadyout[i];
		end 
    end
end

endmodule