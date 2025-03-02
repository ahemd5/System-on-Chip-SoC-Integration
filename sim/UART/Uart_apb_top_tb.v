module A_UART_TB;
	parameter baud_period = 320;
    reg PRSTn_tb, PCLK_tb, PSEL_tb, PENABLE, PWRITE;
    reg [31:0] PADDR, PWDATA;
    wire [31:0] PRDATA;
    wire PREADY, PSLVERR;
    reg Rx_s;
    wire Tx_s;
	
	reg [10:0] captured_data;

    integer pass_count = 0;
    integer fail_count = 0;
	integer i;

    initial begin
        // Initialize signals
        PRSTn_tb = 0; PSEL_tb = 0; PENABLE = 0; PWRITE = 0; PADDR = 0; PWDATA = 0;
        Rx_s = 1; // UART idle state
        #10 PRSTn_tb = 1; // Release reset
		
		// Set Baud Divisor
		#10 PENABLE = 1; PSEL_tb = 1; PWRITE = 1; PADDR = 32'h00000010; PWDATA = 'd32;
		#10 PENABLE = 0; PSEL_tb = 0;
		
        // ===============================
        // PHASE 1: REGISTER CONFIGURATION
        // ===============================
        // Write to Control Register  (prescale(8-bits), TX_EN, RX_EN, par_en, par_type, LOOPBACK}
        #20 PENABLE = 1; PSEL_tb = 1; PWRITE = 1; PADDR = 32'h0000000c; PWDATA = 32'h118;
        #10 PENABLE = 0; PSEL_tb = 0;
		
        // Read back Control Register
        #10 PENABLE = 1; PSEL_tb = 1; PWRITE = 0; PADDR = 32'h0000000c;
        #10 check_result(32'h118, PRDATA, "Control Register Write & Read"); PENABLE = 0;
		
        // Check Status Register (should indicate empty FIFOs)
        #10 PENABLE = 1; PSEL_tb = 1; PWRITE = 0; PADDR = 32'h00000008; 
        #10 check_result(32'h06, PRDATA, "Initial Status Register Check"); PENABLE = 0;
		// status_reg = {parity_error, frame_error, overrun_error, rx_fifo_empty, tx_fifo_empty, tx_fifo_full};
        
		// ===================================
        // PHASE 2: TX FIFO WRITE & TRANSMIT
        // ===================================
        // Write data to TX FIFO
        #10 PENABLE = 1; PSEL_tb = 1; PWRITE = 1; PADDR = 32'h0; PWDATA = 8'h43; // Data = 0xf0
        #10 PENABLE = 0; PSEL_tb = 0;
		
        // Check TX FIFO Status (should not be empty)
        #80 PENABLE = 1; PSEL_tb = 1; PWRITE = 0; PADDR = 32'h0000_0008; // Status Register
        #10 check_result(32'h0000_0004, PRDATA, "TX FIFO Status After Write");	PENABLE = 0;
			
        // Wait for TX to read from fifo 
        #(baud_period);
		
        // Check TX FIFO Empty Again (should be empty)
        #10 PENABLE = 1; PSEL_tb = 1; PWRITE = 0; PADDR = 32'h00000008;
        #10 check_result(32'h06, PRDATA, "TX FIFO Empty After Transmission"); PENABLE = 0;
		
		
		wait(Dut.U0_UART.TX_OUT_V == 1);
		captured_data = 0;
		for (i = 0; i < 10; i = i + 1) begin
			#(baud_period);
			captured_data = {captured_data, Tx_s};
		end	
		#(baud_period);
		$display("Captured Data: %b", captured_data); 
		check_result(8'b11000010, captured_data[8:1], "TX Serial data check");
		
        // =======================
        // PHASE 3: RX FIFO READ & RECEIVE
        // =======================
        // Simulate received data (force RX line to send 0x5A)
		#(baud_period) Rx_s = 0; #(baud_period) Rx_s = 1; 
		#(baud_period) Rx_s = 1; #(baud_period) Rx_s = 0; 
		#(baud_period) Rx_s = 0; #(baud_period) Rx_s = 0; 
		#(baud_period) Rx_s = 0; #(baud_period) Rx_s = 1; 
		#(baud_period) Rx_s = 0; #(baud_period) Rx_s = 1; 
		
        // Check RX FIFO Status (should not be empty)
        #(20*baud_period); PENABLE = 1; PSEL_tb = 1; PWRITE = 0; PADDR = 32'h00000008;
        #10 check_result(32'b10, PRDATA, "RX FIFO Status After Receive"); PENABLE = 0;
		
        // Read from RX FIFO
        #10 PSEL_tb = 1; PWRITE = 0; PADDR = 32'h04;
        #10 PENABLE = 1;
        #10 check_result(8'h43, PRDATA, "Received Data Check"); PENABLE = 0;

		// =======================
        // PHASE 4: Loobpack test
        // =======================
		// Enable loopback by setting bit 0 in control register
		#20 PENABLE = 1; PSEL_tb = 1; PWRITE = 1; PADDR = 32'h0000000c; PWDATA = 32'h119; // Set LOOPBACK bit
		#10 PENABLE = 0; PSEL_tb = 0;

		// Write data to TX FIFO
		#10 PENABLE = 1; PSEL_tb = 1; PWRITE = 1; PADDR = 32'h0; PWDATA = 8'h69; // Data = 0x55
		#10 PENABLE = 0; PSEL_tb = 0;

		// Wait for data to transmit and be received via loopback
		#(15*baud_period);

		// Read from RX FIFO - should contain the same data we sent
		#10 PSEL_tb = 1; PWRITE = 0; PADDR = 32'h04;
		#10 PENABLE = 1;
		#10 check_result(8'h69, PRDATA, "Loopback Data Check"); PENABLE = 0;
		
        // =======================
        // PRINT TEST SUMMARY
        // =======================
        #10 $display("\nTest Summary: %d PASSED, %d FAILED", pass_count, fail_count);
        #10 $finish;
    end
	
    // Task to check result and print pass/fail
    task check_result;
        input [31:0] expected;
        input [31:0] actual;
        input [255:0] test_name;
        begin
            if (expected === actual) begin
                $display("PASS: %s | Expected: %h, Got: %h", test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s | Expected: %h, Got: %h", test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Clock Generation
    initial begin
        PCLK_tb = 1;
        forever #5 PCLK_tb = ~PCLK_tb; // 10ns clock period
    end

	UART_apb_top Dut (  
	.PRSTn(PRSTn_tb), 
	.PCLK(PCLK_tb), 
	.PSEL(PSEL_tb),
	.PENABLE(PENABLE), 
	.PWRITE(PWRITE), 
	.PADDR(PADDR),
	.PWDATA(PWDATA), 
	.PRDATA(PRDATA), 
	.PREADY(PREADY),
	.PSLVERR(PSLVERR), 
	.Rx_s(Rx_s), 
	.Tx_s(Tx_s),
	.TX_FIFO_Empty(TX_FIFO_Empty),
	.RX_FIFO_Full(RX_FIFO_Full),
	.Parity_Error(Parity_Error),
	.Frame_Error(Frame_Error)
    );
	
endmodule
