module arbiter #(parameter NUM_MASTERS = 2, NUM_SLAVES = 2)(
    input  wire    i_clk,
    input  wire    [NUM_SLAVES-1:0] i_req [NUM_MASTERS-1:0],   // Request signals from decoders (o_hsel)
    input  wire i_hreadyout,                                  // Ready signal from the slave
    input  wire [31:0]	s,
    output reg  [NUM_MASTERS-1:0] o_grant ,                     // Grant signal to the selected master
    output reg  [NUM_MASTERS-1:0] o_mhready,                      // Ready signal for the selected master
    output reg  o_shready,
	output reg  o_hselx
	);

    integer m;

    always @(posedge i_clk) begin
        if (i_hreadyout) begin
            for (m = 0; m < NUM_MASTERS; m = m + 1) begin
                if (i_req[m][s]) begin
                    o_grant[m] <= 1;              // Grant master m
                    o_mhready[m] <= 1;            // Indicate slave s is ready
                    o_shready <= 1;
					o_hselx <= 1;
					break;                         // Break first loops
                end
                else begin 
                    o_grant[m] <= 0;              // Grant master m
                    o_mhready[m] <= 0;            // Indicate slave s is ready
					o_shready <= 0;
					o_hselx <= 0;
				end 
            end
        end
         
		else begin
            for (m = 0; m < NUM_MASTERS; m = m + 1) begin
                o_grant[m] <= 0;              // Grant master m
                o_mhready[m] <= 0;            // Indicate slave s is ready
				o_shready <= 0;
				o_hselx <= 0;
			end
        end
    end

endmodule