
	 module RisingEdgeDetector (
    input wire i_clk_ahb , // Clock signal
    input wire reg_20,          
    output reg edge_detect      // Output: High for one clock cycle on rising edge
);

    // Internal register to hold the previous state of the signal
    reg previous_state;

    // Always block triggered on the clock's positive edge
    always @(posedge i_clk_ahb) begin
        // Detect rising edge
        if (previous_state == 0 && reg_20 == 1) begin
            edge_detect <= 1; // Rising edge detected
        end else begin
            edge_detect <= 0; // No rising edge
        end

        // Update the previous state
        previous_state <= reg_20;
    end
endmodule