// mohamed 
`timescale 1ns / 1ps

module tb_ahb_master;
    // Clock and reset signals
    reg i_clk_ahb;
    reg i_rstn_ahb;

    // AHB interface signals
    wire [31:0] HADDR;
    wire [31:0] HWDATA;
    wire        HWRITE;
    wire [2:0]  HSIZE;
    wire [1:0]  HTRANS;
    wire        HMASTLOCK;
    reg         HREADY;  
    reg [31:0]  HRDATA;
    reg         HRESP;

    // Transaction interface signals
    reg [31:0]  i_addr;
    reg         i_rd0_wr1;
    reg [31:0]  i_wr_data;
    reg         i_valid;

    wire        o_ready;
    wire        o_rd_valid;
    wire [31:0] o_rd_data;

    // Instantiate the AHB master module
    ahb_master uut (
        .i_clk_ahb(i_clk_ahb),
        .i_rstn_ahb(i_rstn_ahb),
        .HADDR(HADDR),
        .HWDATA(HWDATA),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HTRANS(HTRANS),
        .HMASTLOCK(HMASTLOCK),
        .HREADY(HREADY),
        .HRDATA(HRDATA),
        .HRESP(HRESP),
        .i_addr(i_addr),
        .i_rd0_wr1(i_rd0_wr1),
        .i_wr_data(i_wr_data),
        .i_valid(i_valid),
        .o_ready(o_ready),
        .o_rd_valid(o_rd_valid),
        .o_rd_data(o_rd_data)
    );

    // Clock generation
    initial begin
        i_clk_ahb = 0;
        forever #5 i_clk_ahb = ~i_clk_ahb;  // 100 MHz clock
    end

    // Test sequence
    initial begin
        // Initialize signals
        i_rstn_ahb = 0;
        i_addr = 32'h0;
        i_rd0_wr1 = 0;
        i_wr_data = 32'h0;
        i_valid = 1;
        HREADY = 1;
        HRESP = 0;
        HRDATA = 32'h0;
        
        // Reset the AHB master
        #10 i_rstn_ahb = 1;
        
        // Start transactions to match the waveform pattern
        // Transaction 1: Write to address 0x20
        @(posedge i_clk_ahb);
        i_addr = 32'h20;
        i_wr_data = 32'hDEADBEEF;
        i_rd0_wr1 = 1;  // Write transaction
        i_valid = 1;
        @(posedge i_clk_ahb);
		// Transaction 2: Read from address 0x24
		i_addr = 32'h24;
		i_rd0_wr1 = 0;  // Read transaction
        i_valid = 1;

        @(posedge i_clk_ahb);
        i_valid = 1;
        HRDATA = 32'hCAFEBABE;  // Example read data
		check_read_data(32'hCAFEBABE);
		// Transaction 3: Write to address 0x28
		i_addr = 32'h28;
        i_wr_data = 32'hFEEDFACE;
        i_rd0_wr1 = 1;  // Write transaction
        @(posedge i_clk_ahb);
        // Transaction 4: Read from address 0x2C (with wait state)
		i_addr = 32'h2C;
        i_rd0_wr1 = 0;  // Read transaction
		i_valid = 1;
        
        @(posedge i_clk_ahb);
        i_valid = 1;
		HRDATA = 32'hBABEFACE;  // Example read data
		HREADY = 0;
		// Transaction 5: Write to address 0x28
		i_addr = 32'h30;
        i_wr_data = 32'hFEE8788A;
        i_rd0_wr1 = 1;  // Write transaction
        @(posedge i_clk_ahb);
        i_valid = 1;
		HREADY = 1;
		check_read_data(32'hBABEFACE);
              
        // End simulation after transactions
        #40 $stop;
    end

	 // Helper task to check read data
    task check_read_data(input [31:0] expected_data);
	    #1;
        if (o_rd_valid) begin
            if (o_rd_data !== expected_data) begin
                $display("Read Data Mismatch: Expected %h, got %h", expected_data, o_rd_data);
            end else begin
                $display("Test Passed: Read Data is correct: %h", o_rd_data);
            end
        end else begin
            $display("Test Failed: o_rd_valid was not asserted");
        end
    endtask

endmodule
