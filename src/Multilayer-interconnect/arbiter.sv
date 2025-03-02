module arbiter #(
    parameter NUM_MASTERS = 2  // Number of masters
)(
    input  wire                   i_clk,
    input  wire                   i_reset_n,
    input  reg  [NUM_MASTERS-1:0] i_req,        // Request signals from each master
	output reg  [NUM_MASTERS-1:0] o_grant       // Grant signals to each master
);

    logic [$clog2(NUM_MASTERS)-1:0] current_priority;
	logic [31:0] index;

    always @(posedge i_clk or negedge i_reset_n) begin
        if (!i_reset_n) begin
            current_priority <= 0;
			index<=0;
        end else begin
            // Rotate priority if a grant was made
            if (|o_grant) begin
                current_priority <= (current_priority + 1) % NUM_MASTERS;
            end
        end
    end

    always @(*) begin
        o_grant = 0;  // Initialize all grants to 0
		// Check requests starting from the current priority
		for (int i = 0; i < NUM_MASTERS; i++) begin
			index = (current_priority + i) % NUM_MASTERS;
			if (i_req[index]) begin
				o_grant[index] = 1;
				break;  // Grant to the first requesting master in the current priority order
		    end
		end 
    end

endmodule
