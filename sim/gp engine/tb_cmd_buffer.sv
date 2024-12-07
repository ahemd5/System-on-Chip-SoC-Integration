module tb_cmd_buffer;

    // Parameters
    parameter CMD_WIDTH = 64;
    parameter DATA_WIDTH = 32;
    parameter BUFFER_WIDTH = 32;
    parameter BUFFER_DEPTH = 256;
    parameter TRANS_ADDR_WIDTH = 8;

    // Testbench Signals
    reg clk, rst_n;
    reg cmd_rd_en;
    reg [TRANS_ADDR_WIDTH-1:0] cmd_addr;
    wire cmd_rd_valid;
    wire [CMD_WIDTH-1:0] cmd_out;

    reg cmd_en;
    reg [TRANS_ADDR_WIDTH-1:0] trans_addr;

    reg slv_o_valid;
    reg [DATA_WIDTH-1:0] slv_o_wr_data;
    reg slv_o_rd0_wr1;
    wire slv_i_ready;
    wire [DATA_WIDTH-1:0] slv_i_rd_data;
    wire slv_i_rd_valid;

    // Instantiate DUT
    cmd_buffer #(
        .CMD_WIDTH(CMD_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BUFFER_WIDTH(BUFFER_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .TRANS_ADDR_WIDTH(TRANS_ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_rd_en(cmd_rd_en),
        .cmd_addr(cmd_addr),
        .cmd_rd_valid(cmd_rd_valid),
        .cmd_out(cmd_out),
        .cmd_en(cmd_en),
        .trans_addr(trans_addr),
        .slv_o_valid(slv_o_valid),
        .slv_o_wr_data(slv_o_wr_data),
        .slv_o_rd0_wr1(slv_o_rd0_wr1),
        .slv_i_ready(slv_i_ready),
        .slv_i_rd_data(slv_i_rd_data),
        .slv_i_rd_valid(slv_i_rd_valid)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Testbench Initialization
    initial begin
        // Initialize signals
        clk = 1;
        rst_n = 0;
        cmd_rd_en = 0;
        cmd_addr = 0;
        cmd_en = 0;
        trans_addr = 0;
        slv_o_valid = 0;
        slv_o_wr_data = 0;
        slv_o_rd0_wr1 = 0;

        // Apply reset
        #10 rst_n = 1;

        // Test reset behavior
        $display("Running Reset Test...");
        #10 assert_reset();

        // Test AHB write transaction
        $display("Testing AHB Write Transaction...");
        test_ahb_write();

        // Test AHB read transaction
        $display("Testing AHB Read Transaction...");
        test_ahb_read();

        // Test FSM read transaction
        $display("Testing FSM Read Transaction...");
        test_fsm_read();

        // Test boundary conditions
        $display("Testing Boundary Conditions...");
        test_boundary_conditions();

		// Testing FSM and AHB Simultaneous Access
        $display("Testing FSM and AHB Simultaneous Access...");
        test_fsm_ahb_simultaneous_access();
		
		// Testing Multiple Random Write Transactions
		$display("Testing Multiple Random Write Transactions...");
        test_multiple_random_writes();
		
		// Testing FSM and AHB Simultaneous Read Transactions
        $display("Testing FSM and AHB Simultaneous Read Transactions...");
        test_fsm_ahb_simultaneous_reads();
		
        // Finish simulation
        $display("All tests completed.");
        $finish;
    end

    // Task: Assert reset behavior
    task assert_reset;
        for (int i = 0; i < BUFFER_DEPTH; i++) begin
            if (dut.cmd_mem[i] !== 0) begin
                $fatal("Reset failed at address %d", i);
            end
        end
        assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 0);
        assert(dut.cmd_rd_valid === 0);
        $display("Reset test passed.");
    endtask

    // Task: Test AHB write transaction
    task test_ahb_write;
        slv_o_valid = 1;
        slv_o_wr_data = 32'hDEADBEEF;
        slv_o_rd0_wr1 = 1;
        cmd_en = 1;
        trans_addr = 8'h0A;
        #10;
        cmd_en = 0;
        slv_o_valid = 0;
		assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 0);
        assert(dut.cmd_rd_valid === 0);
        if (dut.cmd_mem[trans_addr] !== slv_o_wr_data) begin
            $fatal("AHB Write failed: Expected 0x%h, Got 0x%h", slv_o_wr_data, dut.cmd_mem[trans_addr]);
        end
        $display("AHB Write test passed.");
    endtask

    // Task: Test AHB read transaction
    task test_ahb_read;
        slv_o_valid = 1;
        slv_o_rd0_wr1 = 0;
        cmd_en = 1;
        trans_addr = 8'h0A;
        #10;
        cmd_en = 0;
        slv_o_valid = 0;
		assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 1);
        assert(dut.cmd_rd_valid === 0);
        if (slv_i_rd_data !== 32'hDEADBEEF) begin
            $fatal("AHB Read failed: Expected 0xDEADBEEF, Got 0x%h", slv_i_rd_data);
        end
        $display("AHB Read test passed.");
    endtask

    // Task: Test FSM read transaction
    task test_fsm_read;
        cmd_rd_en = 1;
        cmd_addr = 8'h0A;
        #10;
        cmd_rd_en = 0;
		assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 0);
        assert(dut.cmd_rd_valid === 1);
        if (cmd_out !== {32'h00000000, 32'hDEADBEEF}) begin
            $fatal("FSM Read failed: Got 0x%h", cmd_out);
        end
        $display("FSM Read test passed.");
    endtask

    // Task: Test boundary conditions
    task test_boundary_conditions;
        trans_addr = BUFFER_DEPTH - 1;
        slv_o_valid = 1;
        slv_o_wr_data = 32'hCAFECAFE;
        slv_o_rd0_wr1 = 1;
        cmd_en = 1;
        #10;
        cmd_en = 0;
        slv_o_valid = 0;
		assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 0);
        assert(dut.cmd_rd_valid === 0);
        if (dut.cmd_mem[trans_addr] !== 32'hCAFECAFE) begin
            $fatal("Boundary Write failed at last address.");
        end
        $display("Boundary conditions test passed.");
    endtask

	// Task: Test FSM and AHB simultaneous access
    task test_fsm_ahb_simultaneous_access;
        // Initialize memory for testing
        slv_o_valid = 1;
        slv_o_wr_data = 32'hDEADBEEF;
        slv_o_rd0_wr1 = 1;
        cmd_en = 1;
        trans_addr = 8'h0B;
        #10;
        slv_o_valid = 0;
        cmd_en = 0;
		
	    assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 0);
        assert(dut.cmd_rd_valid === 0);

        // Simulate FSM read while AHB write is ongoing
        cmd_rd_en = 1;
        cmd_addr = 8'h0B;
        slv_o_valid = 1;
        slv_o_wr_data = 32'hCAFEBABE;
        slv_o_rd0_wr1 = 1;
        cmd_en = 1;
        #10;

        // Check the priority and data integrity
        cmd_rd_en = 0;
        slv_o_valid = 0;
        cmd_en = 0;
		
		assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 0);
        assert(dut.cmd_rd_valid === 0);

        if (dut.cmd_mem[trans_addr] !== 32'hCAFEBABE) begin
            $fatal("Simultaneous Access failed: Expected 0xCAFEBABE in memory, Got 0x%h", dut.cmd_mem[trans_addr]);
        end

        if (cmd_out !== 64'b0) begin
            $fatal("Simultaneous Access failed: FSM read inconsistent data 0x%h", cmd_out);
        end

        $display("FSM and AHB Simultaneous Access test passed.");
    endtask

	// Task: Perform multiple write transactions with random addresses and data
    task test_multiple_random_writes;
        int num_transactions = 10; // Number of random write transactions to perform
        int random_addr;
        int random_data;

        for (int i = 0; i < num_transactions; i++) begin
            // Generate random address and data
            random_addr = $urandom_range(0, 255); // Random address within 256 locations
            random_data = $urandom;             // Random 32-bit data

            // Perform write transaction
            slv_o_valid = 1;
            slv_o_wr_data = random_data;
            slv_o_rd0_wr1 = 1; // Indicate write operation
            cmd_en = 1;
            trans_addr = random_addr;

            #10; // Wait for one clock cycle
		    assert(dut.slv_i_ready === 1);
            assert(dut.slv_i_rd_valid === 0);
            assert(dut.cmd_rd_valid === 0);
			
            // Disable signals after transaction
            slv_o_valid = 0;
            cmd_en = 0;

            // Validate the write
            if (dut.cmd_mem[random_addr] !== random_data) begin
                $fatal("Write failed at address %0d: Expected 0x%h, Got 0x%h", 
                        random_addr, random_data, dut.cmd_mem[random_addr]);
            end

            $display("Write transaction %0d passed: Address = %0d, Data = 0x%h", 
                      i, random_addr, random_data);
        end

        $display("All multiple random write transactions passed.");
    endtask
	
	// Task: Perform FSM and AHB read transactions simultaneously
    task test_fsm_ahb_simultaneous_reads;
        int fsm_read_addr;
        int ahb_read_addr;
        reg [CMD_WIDTH-1:0] expected_fsm_data;
        reg [DATA_WIDTH-1:0] expected_ahb_data;

        // Initialize memory with known values
        for (int i = 0; i < BUFFER_DEPTH; i++) begin
            dut.cmd_mem[i] = i; // Set memory[i] = i for easy validation
        end

        // Case 1: FSM and AHB read the same address
        fsm_read_addr = 8'h10;
        ahb_read_addr = 8'h10;
        expected_fsm_data = {dut.cmd_mem[fsm_read_addr + 8'h1][1:0] ,dut.cmd_mem[fsm_read_addr + 8'h1][31:2] ,dut.cmd_mem[fsm_read_addr]};
        expected_ahb_data = dut.cmd_mem[ahb_read_addr];

        cmd_rd_en = 1;
        cmd_addr = fsm_read_addr;
        cmd_en = 1;
        trans_addr = ahb_read_addr;
        slv_o_valid = 1;
        slv_o_rd0_wr1 = 0; // Indicate AHB read

        #10; // Wait for one clock cycle
	    assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 1);
        assert(dut.cmd_rd_valid === 1);

        // Validate outputs
        if (cmd_out !== expected_fsm_data) begin
            $fatal("FSM read failed for address %0d: Expected 0x%h, Got 0x%h", 
                   fsm_read_addr, expected_fsm_data, cmd_out);
        end

        if (slv_i_rd_data !== expected_ahb_data) begin
            $fatal("AHB read failed for address %0d: Expected 0x%h, Got 0x%h", 
                   ahb_read_addr, expected_ahb_data, slv_i_rd_data);
        end

        $display("Case 1: FSM and AHB read same address passed.");

        // Case 2: FSM and AHB read different addresses
        fsm_read_addr = 8'h20;
        ahb_read_addr = 8'h30;
        expected_fsm_data = {dut.cmd_mem[fsm_read_addr + 8'h1][1:0] ,dut.cmd_mem[fsm_read_addr + 8'h1][31:2] ,dut.cmd_mem[fsm_read_addr]};
        expected_ahb_data = dut.cmd_mem[ahb_read_addr];

        cmd_rd_en = 1;
        cmd_addr = fsm_read_addr;
        cmd_en = 1;
        trans_addr = ahb_read_addr;
        slv_o_valid = 1;
        slv_o_rd0_wr1 = 0; // Indicate AHB read

        #10; // Wait for one clock cycle
	    assert(dut.slv_i_ready === 1);
        assert(dut.slv_i_rd_valid === 1);
        assert(dut.cmd_rd_valid === 1);

        // Validate outputs
        if (cmd_out !== expected_fsm_data) begin
            $fatal("FSM read failed for address %0d: Expected 0x%h, Got 0x%h", 
                   fsm_read_addr, expected_fsm_data, cmd_out);
        end

        if (slv_i_rd_data !== expected_ahb_data) begin
            $fatal("AHB read failed for address %0d: Expected 0x%h, Got 0x%h", 
                   ahb_read_addr, expected_ahb_data, slv_i_rd_data);
        end

        $display("Case 2: FSM and AHB read different addresses passed.");

        // Cleanup
        cmd_rd_en = 0;
        cmd_en = 0;
        slv_o_valid = 0;

        $display("FSM and AHB Simultaneous Read Transactions test passed.");
    endtask

	
endmodule
