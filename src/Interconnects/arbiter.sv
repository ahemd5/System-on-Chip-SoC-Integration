module arbiter #(
    parameter NUM_MASTERS = 2  // Number of masters requesting access
)(
    input  wire	i_clk,          					// System clock
    input  wire	i_reset_n,      					// Active-low reset
    input  wire	i_req		[NUM_MASTERS-1:0],      // Request signals from decoders (o_hsel)
    input  wire i_hreadyout,  						// Ready signal from the slave
    output reg  o_grant		[NUM_MASTERS-1:0],     	// Grant signal to the selected master
    output reg  o_hready	[NUM_MASTERS-1:0]      	// Ready signal for the selected master
);

    integer i;

    always @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
				o_grant[i] <= 'b0;
				o_hready[i] <= 'b0; // Indicate the selected master is ready
        end 
		else if(i_hreadyout) begin
			for (i = 0; i < NUM_MASTERS; i = i + 1) begin
                // Fixed priority: check requests in order of master index
                    if (i_req[i]) begin
						o_grant[i] <= 1;
                        o_hready[i] <= 1; // Indicate the selected master is ready
                    break; 	// Exit loop once a master is granted
					end
			end	
		end
		else begin
				o_grant[i] <= 'b0;
				o_hready[i] <= 'b0; // Indicate the selected master is ready  
		end
    end

endmodule