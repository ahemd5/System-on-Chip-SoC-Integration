module tb_address_decoder;

    // Parameters
    parameter ADDR_WIDTH = 32;
    parameter TRANS_ADDR_WIDTH = 8;

    // DUT Inputs
    reg [ADDR_WIDTH-1:0] slv_o_addr;

    // DUT Outputs
    wire [TRANS_ADDR_WIDTH-1:0] trans_addr;
    wire reg_en;
    wire cmd_en;

    // Instantiate the DUT (Device Under Test)
    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .TRANS_ADDR_WIDTH(TRANS_ADDR_WIDTH)
    ) dut (
        .slv_o_addr(slv_o_addr),
        .trans_addr(trans_addr),
        .reg_en(reg_en),
        .cmd_en(cmd_en)
    );

    // Task for stimulus
    task apply_stimulus(input [ADDR_WIDTH-1:0] address, 
                        input [7:0] expected_trans_addr, 
                        input expected_reg_en, 
                        input expected_cmd_en);
        begin
            slv_o_addr = address;
            #10; // Wait for combinational logic to settle
            $display("Address: 0x%h | reg_en: %b | cmd_en: %b | trans_addr: %h | Expected: reg_en=%b, cmd_en=%b, trans_addr=0x%h", 
                      address, reg_en, cmd_en, trans_addr, expected_reg_en, expected_cmd_en, expected_trans_addr);

            // Assertions
            if (reg_en !== expected_reg_en || cmd_en !== expected_cmd_en || trans_addr !== expected_trans_addr) begin
                $fatal("Test failed for address: 0x%h", address);
            end
        end
    endtask

    // Testbench procedure
    initial begin
        $display("Starting Address Decoder Testbench...");

        // Basic Functionality Tests
        apply_stimulus(32'h00, 8'd0, 1'b1, 1'b0); // Register File
        apply_stimulus(32'h10, 8'd0, 1'b0, 1'b1); // Command Buffer

        // Boundary Tests
        apply_stimulus(32'h0C, 8'd3, 1'b1, 1'b0);    // Register File upper bound
        apply_stimulus(32'h40C, 8'd255, 1'b0, 1'b1); // Command Buffer upper bound

        // Invalid Address Tests
        apply_stimulus(32'hFFFFFFFF, 8'd0, 1'b0, 1'b0); // Max invalid address

        // Corner Case Tests
        apply_stimulus(32'h01, 8'd0, 1'b0, 1'b0); // Misaligned address (should fail alignment)

        // Stress Testing
        apply_stimulus(32'h1A4, 8'd101, 1'b0, 1'b1); // Command Buffer		
		apply_stimulus(32'h204, 8'd125, 1'b0, 1'b1); // Command Buffer		
		apply_stimulus(32'h13C, 8'd75 , 1'b0, 1'b1); // Command Buffer 
		apply_stimulus(32'h0C , 8'd3  , 1'b1, 1'b0); // Register File 
		apply_stimulus(32'h74 , 8'd25 , 1'b0, 1'b1); // Command Buffer 
		apply_stimulus(32'h00 , 8'd0  , 1'b1, 1'b0); // Register File 
		apply_stimulus(32'h04 , 8'd1  , 1'b1, 1'b0); // Register File 
		apply_stimulus(32'h358, 8'd210, 1'b0, 1'b1); // Command Buffer
		apply_stimulus(32'h08 , 8'd2  , 1'b1, 1'b0); // Register File 
		apply_stimulus(32'h27C, 8'd155, 1'b0, 1'b1); // Command Buffer
		apply_stimulus(32'hC4 , 8'd45 , 1'b0, 1'b1); // Command Buffer		
		apply_stimulus(32'h88 , 8'd30 , 1'b0, 1'b1); // Command Buffer

        $display("All tests passed!");
        $finish;
    end
endmodule
