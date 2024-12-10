`timescale 1ns/1ps

module tb_register_file;

    // Parameters
    parameter DATA_WIDTH = 32;
    parameter TRANS_ADDR_WIDTH = 8;

    // DUT Signals
    logic i_clk, i_rstn;
    logic slv_o_valid, slv_o_rd0_wr1;
    logic [DATA_WIDTH-1:0] slv_o_wr_data;
    logic [TRANS_ADDR_WIDTH-1:0] trans_addr;
    logic reg_en, reg_rd_en;
    logic [DATA_WIDTH-1:0] rd_trig_s1_config, rd_trig_s2_config, rd_trig_s3_config, rd_trig_s4_config;
    logic slv_i_ready, slv_i_rd_valid, reg_rd_valid;
    logic [DATA_WIDTH-1:0] slv_i_rd_data;

    // Instantiate DUT
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .TRANS_ADDR_WIDTH(TRANS_ADDR_WIDTH)
    ) dut (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .slv_o_valid(slv_o_valid),
        .slv_o_wr_data(slv_o_wr_data),
        .slv_o_rd0_wr1(slv_o_rd0_wr1),
        .slv_i_ready(slv_i_ready),
        .slv_i_rd_data(slv_i_rd_data),
        .slv_i_rd_valid(slv_i_rd_valid),
        .reg_en(reg_en),
        .reg_rd_en(reg_rd_en),
        .rd_trig_s1_config(rd_trig_s1_config),
        .rd_trig_s2_config(rd_trig_s2_config),
        .rd_trig_s3_config(rd_trig_s3_config),
        .rd_trig_s4_config(rd_trig_s4_config),
        .reg_rd_valid(reg_rd_valid),
        .trans_addr(trans_addr)
    );

    // Clock Generation
    always #5 i_clk = ~i_clk;

    // Task: Reset DUT
    task reset_dut;
        begin
            i_rstn = 0;
            #10;
            i_rstn = 1;
        end
    endtask

    // Test Case 1: Reset Verification
    task test_reset;
        begin
            reset_dut();
            assert(dut.trigger_config[0] == 32'b0) else $error("Trigger 0 reset failed");
            assert(dut.trigger_config[1] == 32'b0) else $error("Trigger 1 reset failed");
            assert(dut.trigger_config[2] == 32'b0) else $error("Trigger 2 reset failed");
            assert(dut.trigger_config[3] == 32'b0) else $error("Trigger 3 reset failed");
			
			assert(slv_i_ready == 1'b1);
			assert(slv_i_rd_valid == 1'b0);
            assert(slv_i_rd_data == {DATA_WIDTH{1'b0}});
			assert(reg_rd_valid == 1'b0);
			$display("reset test passed");
			$display("");
        end
    endtask

    // Test Case 2: Write Operation
    task test_write(input [TRANS_ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            slv_o_valid = 1;
            slv_o_rd0_wr1 = 1; // Write operation
            slv_o_wr_data = data;
            trans_addr = addr;
            reg_en = 1;
			
            #10;
			assert(slv_i_ready == 1'b1);
			assert(slv_i_rd_valid == 1'b0);
            assert(slv_i_rd_data == {DATA_WIDTH{1'b0}});
			assert(reg_rd_valid == 1'b0);
			
            slv_o_valid = 0;
            reg_en = 0;
            #10;
            case (addr)
                8'b0000_0000: assert(dut.trigger_config[0] == data) begin
				                   $display("write test passed");
			                       $display("");
				              end else $error("Write failed for Trigger 0");
                8'b0000_0001: assert(dut.trigger_config[1] == data) begin 
				                   $display("write test passed");
			                       $display("");
				              end else $error("Write failed for Trigger 1");
                8'b0000_0010: assert(dut.trigger_config[2] == data) begin 
				                   $display("write test passed");
			                       $display("");				
				              end else $error("Write failed for Trigger 2");
                8'b0000_0011: assert(dut.trigger_config[3] == data) begin
				                   $display("write test passed");
			                       $display("");				
				              end else $error("Write failed for Trigger 3");
                default: begin $error("Write should not occur for invalid address");
				               $display("write test passed");
			                   $display(""); end 
            endcase
        end
    endtask

    // Test Case 3: Read Operation
    task test_read(input [TRANS_ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] expected_data);
        begin
            slv_o_valid = 1;
            slv_o_rd0_wr1 = 0; // Read operation
            trans_addr = addr;
            reg_en = 1;
			
            #10;
			assert(slv_i_ready == 1'b1);
            assert(slv_i_rd_valid == 1) else $error("Read valid not asserted");
            assert(slv_i_rd_data == expected_data) begin
			    $display("read test passed");
			    $display("");
			end else $error("Read data mismatch");
			assert(reg_rd_valid == 1'b0);
			
            slv_o_valid = 0;
            reg_en = 0;
            #10;
        end
    endtask
	
// Task: Test FSM Read Access
task test_fsm_read(input integer index, input [DATA_WIDTH-1:0] expected_data);
    begin
        $display("Testing FSM Read Access for Trigger %0d...", index);
        
        // Enable FSM Read
        reg_rd_en = 1;
        #10; // Wait for one clock cycle
        
        // Check the corresponding output
        case (index)
            1: assert(rd_trig_s1_config == expected_data)begin
				    $display("fsm read test passed");
			        $display("");
				end else $error("FSM Read mismatch for Trigger 1: Expected %h, Got %h", expected_data, rd_trig_s1_config);
            2: assert(rd_trig_s2_config == expected_data)begin
				    $display("fsm read test passed");
			        $display("");
				end else $error("FSM Read mismatch for Trigger 2: Expected %h, Got %h", expected_data, rd_trig_s2_config);
            3: assert(rd_trig_s3_config == expected_data)begin
				    $display("fsm read test passed");
			        $display("");
				end else $error("FSM Read mismatch for Trigger 3: Expected %h, Got %h", expected_data, rd_trig_s3_config);
            4: assert(rd_trig_s4_config == expected_data)begin
				    $display("fsm read test passed");
			        $display("");
				end else $error("FSM Read mismatch for Trigger 4: Expected %h, Got %h", expected_data, rd_trig_s4_config);
            default: $error("Invalid FSM Trigger Index: %0d", index);
        endcase
        
		assert(slv_i_ready == 1'b1);
        assert(slv_i_rd_valid == 1'b0);
        assert(slv_i_rd_data == {DATA_WIDTH{1'b0}});  
	    assert(reg_rd_valid == 1'b1) else $error("all Read data is zero but fsm read test passed");
		$display("");
		
        // Deassert FSM Read Enable
        reg_rd_en = 0;
        #10;
    end
endtask

// Enhanced FSM Read Tests
task test_fsm_reads;
    begin
        $display("Starting Enhanced FSM Read Tests...");

        // 1. Read Default Values after Reset
        reset_dut();
        test_fsm_read(1, 32'h00000000);
        test_fsm_read(2, 32'h00000000);
        test_fsm_read(3, 32'h00000000);
        test_fsm_read(4, 32'h00000000);

        // 2. Write to Registers and Verify FSM Reads
        test_write(8'b0000_0000, 32'hAAAA_BBBB); // Write to Trigger 0
        test_write(8'b0000_0001, 32'hCCCC_DDDD); // Write to Trigger 1
        test_write(8'b0000_0010, 32'hEEEE_FFFF); // Write to Trigger 2
        test_write(8'b0000_0011, 32'h1234_5678); // Write to Trigger 3

        test_fsm_read(1, 32'hAAAA_BBBB);
        test_fsm_read(2, 32'hCCCC_DDDD);
        test_fsm_read(3, 32'hEEEE_FFFF);
        test_fsm_read(4, 32'h1234_5678);

        // 3. Sequential Reads
        $display("Testing Sequential FSM Reads...");
        reg_rd_en = 1; // Enable FSM Reads
        #10;
        assert(rd_trig_s1_config == 32'hAAAA_BBBB) else $error("Sequential Read Trigger 1 failed");
        assert(rd_trig_s2_config == 32'hCCCC_DDDD) else $error("Sequential Read Trigger 2 failed");
        assert(rd_trig_s3_config == 32'hEEEE_FFFF) else $error("Sequential Read Trigger 3 failed");
        assert(rd_trig_s4_config == 32'h1234_5678) else $error("Sequential Read Trigger 4 failed");
        reg_rd_en = 0;
        #10;

        $display("FSM Read Tests Completed Successfully.");
		$display("");
    end
endtask

task test_fsm_and_ahb_read_simultaneous;
    input [TRANS_ADDR_WIDTH-1:0] ahb_addr; // AHB Address for reading
    input integer fsm_index;              // FSM index for trigger config
    input [DATA_WIDTH-1:0] expected_data; // Expected data for both FSM and AHB reads

    begin
        $display("Testing Concurrent FSM and AHB Read Access...");

        // Step 1: Enable FSM Read
        reg_rd_en = 1;

        // Step 2: Trigger AHB Read
		reg_en = 1;
        slv_o_valid = 1;
        slv_o_rd0_wr1 = 0; // Read operation
        trans_addr = ahb_addr;
        #10; // Wait for one clock cycle
    
        // Step 3: Verify Outputs
        // Verify FSM Output
        case (fsm_index)
            1: assert(rd_trig_s1_config == expected_data)
                else $error("FSM Read Trigger 1 mismatch: Expected %h, Got %h", expected_data, rd_trig_s1_config);
            2: assert(rd_trig_s2_config == expected_data)
                else $error("FSM Read Trigger 2 mismatch: Expected %h, Got %h", expected_data, rd_trig_s2_config);
            3: assert(rd_trig_s3_config == expected_data)
                else $error("FSM Read Trigger 3 mismatch: Expected %h, Got %h", expected_data, rd_trig_s3_config);
            4: assert(rd_trig_s4_config == expected_data)
                else $error("FSM Read Trigger 4 mismatch: Expected %h, Got %h", expected_data, rd_trig_s4_config);
            default: $error("Invalid FSM Trigger Index: %0d", fsm_index);
        endcase

        // Verify AHB Output
        assert(slv_i_rd_data == expected_data)
            else $error("AHB Read mismatch: Expected %h, Got %h", expected_data, slv_i_rd_data);

	    assert(slv_i_ready == 1'b1);
        assert(slv_i_rd_valid == 1'b1); 
	    assert(reg_rd_valid == 1'b1) else $error("all Read data is zero and reg_rd_valid set to zero");	
			
        // Step 4: Reset signals
		reg_en = 0;
        reg_rd_en = 0;
        slv_o_valid = 0;
        #10;

        $display("Concurrent FSM and AHB Read Test Passed!");
		$display("");
    end
endtask

// Test FSM and AHB Read Simultaneously
task test_concurrent_reads;
    begin
        $display("Starting Concurrent FSM and AHB Read Tests...");

        // Preload values into trigger_config registers
        test_write(8'b0000_0000, 32'hAAAA_BBBB); // Trigger 1
        test_write(8'b0000_0001, 32'hCCCC_DDDD); // Trigger 2
        test_write(8'b0000_0010, 32'hEEEE_FFFF); // Trigger 3
        test_write(8'b0000_0011, 32'h1234_5678); // Trigger 4

        // Test simultaneous reads
        test_fsm_and_ahb_read_simultaneous(8'b0000_0000, 1, 32'hAAAA_BBBB); // Trigger 1
        test_fsm_and_ahb_read_simultaneous(8'b0000_0001, 2, 32'hCCCC_DDDD); // Trigger 2
        test_fsm_and_ahb_read_simultaneous(8'b0000_0010, 3, 32'hEEEE_FFFF); // Trigger 3
        test_fsm_and_ahb_read_simultaneous(8'b0000_0011, 4, 32'h1234_5678); // Trigger 4

        $display("Concurrent FSM and AHB Read Tests Completed Successfully.");
    end
endtask

// Task: Test FSM Read while AHB Write occurs simultaneously
task test_fsm_read_ahb_write_simultaneous;
    input integer fsm_index;                // FSM index for trigger config
    input [DATA_WIDTH-1:0] fsm_expected_data; // Expected data for FSM Read
    input [TRANS_ADDR_WIDTH-1:0] ahb_addr; // AHB Address for writing
    input [DATA_WIDTH-1:0] ahb_write_data; // Data for AHB Write

    begin
        $display("Testing FSM Read with Simultaneous AHB Write...");

        // Step 1: Enable FSM Read
        reg_rd_en = 1;

        // Step 2: Trigger AHB Write
		reg_en = 1;
        slv_o_valid = 1;
        slv_o_rd0_wr1 = 1; // Write operation
        slv_o_wr_data = ahb_write_data;
        trans_addr = ahb_addr;

        #10; // Wait for one clock cycle

        // Step 3: Verify Outputs
        // Verify FSM Output
        case (fsm_index)
            1: assert(rd_trig_s1_config == fsm_expected_data)
                else $error("FSM Read Trigger 1 mismatch: Expected %h, Got %h", fsm_expected_data, rd_trig_s1_config);
            2: assert(rd_trig_s2_config == fsm_expected_data)
                else $error("FSM Read Trigger 2 mismatch: Expected %h, Got %h", fsm_expected_data, rd_trig_s2_config);
            3: assert(rd_trig_s3_config == fsm_expected_data)
                else $error("FSM Read Trigger 3 mismatch: Expected %h, Got %h", fsm_expected_data, rd_trig_s3_config);
            4: assert(rd_trig_s4_config == fsm_expected_data)
                else $error("FSM Read Trigger 4 mismatch: Expected %h, Got %h", fsm_expected_data, rd_trig_s4_config);
            default: $error("Invalid FSM Trigger Index: %0d", fsm_index);
        endcase

        // Verify AHB Write Effects
        case (ahb_addr)
            8'b0000_0000: assert(dut.trigger_config[0] == ahb_write_data)
                else $error("AHB Write Trigger 0 failed: Expected %h, Got %h", ahb_write_data, dut.trigger_config[0]);
            8'b0000_0001: assert(dut.trigger_config[1] == ahb_write_data)
                else $error("AHB Write Trigger 1 failed: Expected %h, Got %h", ahb_write_data, dut.trigger_config[1]);
            8'b0000_0010: assert(dut.trigger_config[2] == ahb_write_data)
                else $error("AHB Write Trigger 2 failed: Expected %h, Got %h", ahb_write_data, dut.trigger_config[2]);
            8'b0000_0011: assert(dut.trigger_config[3] == ahb_write_data)
                else $error("AHB Write Trigger 3 failed: Expected %h, Got %h", ahb_write_data, dut.trigger_config[3]);
            default: $error("AHB Write should not occur for invalid address");
        endcase

        // Verify No Interference
        assert(slv_i_ready == 1'b1);
        assert(slv_i_rd_valid == 1'b0); // Read data should be inactive for write
        assert(reg_rd_valid == 1'b1) else $error("FSM Read not valid during AHB Write");

        // Step 4: Reset signals
		reg_en = 0;
        slv_o_valid = 0;
        reg_rd_en = 0;
        #10;

        $display("FSM Read and AHB Write Simultaneous Test Passed!");
		$display("");
    end
endtask

// Initial Block with Enhanced FSM Read Tests
initial begin
    // Initialize signals
    i_clk = 0;
    i_rstn = 1;
    slv_o_valid = 0;
    slv_o_rd0_wr1 = 0;
    slv_o_wr_data = 0;
    trans_addr = 0;
    reg_en = 0;
    reg_rd_en = 0;

    // Execute Test Cases
    $display("Starting Testbench...");
    test_reset();
    test_write(8'b0000_0000, 32'hDEADBEEF); // Write to Trigger 0
    test_read(8'b0000_0000, 32'hDEADBEEF);  // Read back Trigger 0
    test_write(8'b0000_0001, 32'hCAFEBABE); // Write to Trigger 1
    test_read(8'b0000_0001, 32'hCAFEBABE);  // Read back Trigger 1
    test_write(8'b0000_0100, 32'hBADADD);   // Invalid Write
    test_read(8'b0000_0100, 32'h00000000);  // Read Invalid Address

    // Enhanced FSM Read Tests
    test_fsm_reads();

	// Perform Concurrent FSM and AHB Read Tests
    test_concurrent_reads();
	
	// Preload values into trigger_config registers
    test_write(8'b0000_0000, 32'hAAAA_BBBB); // Trigger 1
    test_write(8'b0000_0001, 32'hCCCC_DDDD); // Trigger 2
    test_write(8'b0000_0010, 32'hEEEE_FFFF); // Trigger 3
    test_write(8'b0000_0011, 32'h1234_5678); // Trigger 4

    // Simultaneous FSM Read and AHB Write
    test_fsm_read_ahb_write_simultaneous(1, 32'h0000_0000, 8'b0000_0000, 32'hDEADBEEF);
    test_fsm_read_ahb_write_simultaneous(2, 32'h0000_0000, 8'b0000_0001, 32'hCAFEBABE);
    test_fsm_read_ahb_write_simultaneous(3, 32'h0000_0000, 8'b0000_0010, 32'hBADF00D);
    test_fsm_read_ahb_write_simultaneous(4, 32'h0000_0000, 8'b0000_0011, 32'hFEEDFACE);
	
	
    $display("All Tests Completed Successfully.");
    $finish;
end

endmodule 