//`timescale 1ns / 1ps 
module tb_top_powcntrl;

  // Parameters
  parameter N = 2;
  parameter M = 3;
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 32;

  // Testbench signals
  logic i_aon_clk;
  logic i_soc_pwr_on_rst;
  logic [M-1:0] i_wakeup_src;
  logic [N-1:0] i_hw_sleep_ack;
  logic [N-1:0] i_pwr_on_ack;
  logic i_pwrite_top;
  logic [DATA_WIDTH-1:0] i_pwdata_top;
  logic [ADDR_WIDTH-1:0] i_paddr_top;
  logic i_psel_top;
  logic i_penable_top;
  logic [DATA_WIDTH-1:0] o_prdata_top;
  logic o_pslverr_top;
  logic o_pready_top;
  logic o_dcdc_enable;
  logic [N-1:0] o_hw_sleep_req;
  logic [N-1:0] o_pwr_on_req;
  logic [N-1:0] o_clk_en;
  logic [N-1:0] o_iso;
  logic [N-1:0] o_ret;
  logic [N-1:0] o_rstn;

  // Instantiate the DUT
  top_powcntrl #(.N(N), .M(M), .DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) dut (
    .i_aon_clk(i_aon_clk),
    .i_soc_pwr_on_rst(i_soc_pwr_on_rst),
    .i_wakeup_src(i_wakeup_src),
    .i_hw_sleep_ack(i_hw_sleep_ack),
    .i_pwr_on_ack(i_pwr_on_ack),
    .i_pwrite_top(i_pwrite_top),
    .i_pwdata_top(i_pwdata_top),
    .i_paddr_top(i_paddr_top),
    .i_psel_top(i_psel_top),
    .i_penable_top(i_penable_top),
    .o_prdata_top(o_prdata_top),
    .o_pslverr_top(o_pslverr_top),
    .o_pready_top(o_pready_top),
    .o_dcdc_enable(o_dcdc_enable),
    .o_hw_sleep_req(o_hw_sleep_req),
    .o_pwr_on_req(o_pwr_on_req),
    .o_clk_en(o_clk_en),
    .o_iso(o_iso),
    .o_ret(o_ret),
    .o_rstn(o_rstn)
  );

  // Clock generation
  initial begin
    i_aon_clk = 1;
    forever #5 i_aon_clk = ~i_aon_clk; 
  end

  // Testbench procedure
  initial begin
  
    // Initialize inputs
    i_soc_pwr_on_rst = 1;
	//----------------------
    i_wakeup_src = 0;
    i_hw_sleep_ack = 0;
    i_pwr_on_ack = 1;
	//----------------------
    i_pwrite_top = 0;
    i_pwdata_top = 0;
    i_paddr_top = 0;
    i_psel_top = 0;
    i_penable_top = 0;

    // Release reset 
    #10 i_soc_pwr_on_rst = 0;
 
    // Test Case 1: Register Configuration
    // Write and read all configuration registers
    write_register(32'h00, 2'b11);      // Sleep request register
	write_register(32'h04, 6'b111_111); // Wakeup sources enable register
	write_register(32'h08, 2'b1);      // Power gating enable register
	write_register(32'h10, 4'h2);       // power-on sequence delay register
    write_register(32'h14, 4'h1);       // power-off sequence delay register
    write_register(32'h18, 8'h1);      // power-on delay register
    write_register(32'h1c, 8'h1);      // power-off delay register
	
    read_register(32'h00); 
	read_register(32'h04);   
	read_register(32'h08);   
	read_register(32'h10);   
    read_register(32'h14);   
    read_register(32'h18);   
    read_register(32'h1c);   
	

	// Test Case 2: Power-Off Sequence
    // Simulate a sleep request for domain 1
	// made sure PD2 off then power off PD1
    #10;
	if (o_hw_sleep_req[1] == 1)
	    i_hw_sleep_ack[1] = 1;
		
	//@(o_rstn[1] == 1)  
	#40 i_pwr_on_ack[1] = 1'b0; 
	
	if(o_hw_sleep_req[0] == 1)
	    i_hw_sleep_ack[0] = 1;
    
	@(~o_pwr_on_req[0])  #10 i_pwr_on_ack[0] = 1'b0; 

	#100;
	
	// Test Case 3: Power-On Sequence
    // Simulate a wakeup request for domain 1 then domain 2
	i_wakeup_src = 1;
	
	@(o_pwr_on_req[0] == 1);
	#20 i_pwr_on_ack[0] = 1;
	
    @(o_hw_sleep_req[0] == 0) i_hw_sleep_ack[0] = 0;
	
	@(o_pwr_on_req[1] == 1)
	   #20 i_pwr_on_ack[1] = 1;

	@(o_hw_sleep_req[1] == 0) i_hw_sleep_ack[1] = 0;
	
	#400;
	
    // Test Case 2: Power-off Sequence for PD2
	write_register(32'h00, 2'b10);      // Sleep request register
    if (o_hw_sleep_req[1] == 1)
	    i_hw_sleep_ack[1] = 1;
		
	@(o_pwr_on_req[1] == 0)  #10 i_pwr_on_ack[1] = 1'b0; 
	
	// Test Case 3: Power-on Sequence for PD2
    @(o_pwr_on_req[1] == 1)
	   #20 i_pwr_on_ack[1] = 1;

	@(o_hw_sleep_req[1] == 0) i_hw_sleep_ack[1] = 0;
	
	#400;
	
    // Test Case 4: Power-off Sequence for PD2 without power gating 
	write_register(32'h00, 2'b11);      // Sleep request register
	write_register(32'h08, 1'b0);      // Power gating enable register
	
    if (o_hw_sleep_req[1] == 1)
	    i_hw_sleep_ack[1] = 1;
	
	@(o_pwr_on_req[1] == 0)  #10 i_pwr_on_ack[1] = 1'b0;
	
	#400;
	
	// Test Case 5: Power-off Sequence for PD1 without power gating 
	if(o_hw_sleep_req[0] == 1)
	    i_hw_sleep_ack[0] = 1;
    
    // End of test
    #400 $finish;
  end

  // Task to write to a register
  task write_register(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
    begin
      i_psel_top = 1;
      i_pwrite_top = 1;
      i_paddr_top = addr;
      i_pwdata_top = data;
      i_penable_top = 0;
	  #10;
	  i_penable_top = 1;
	  #10; 
	  i_penable_top = 0;
      i_psel_top = 0;
    end
  endtask

  // Task to read from a register
  task read_register(input [ADDR_WIDTH-1:0] addr);
    begin
      i_psel_top = 1;
      i_pwrite_top = 0;
      i_paddr_top = addr;
      i_penable_top = 0;
      #10; 
	  i_penable_top = 1;
	  #10;
	  i_penable_top = 0;
      i_psel_top = 0;
    end
  endtask

  // Task to check power-on sequence
  task check_power_on_sequence(input int domain);
    begin
      // Add checks for the sequence of signal assertions
      // Example: assert(o_pwr_on_req[domain] == 1) else $fatal("Power-on request failed!");
      // Add more assertions for o_rstn, o_ret, o_iso, o_clk_en
    end
  endtask

  // Task to check power-off sequence
  task check_power_off_sequence(input int domain);
    begin
      // Add checks for the sequence of signal assertions
      // Example: assert(o_hw_sleep_req[domain] == 1) else $fatal("Sleep request failed!");
      // Add more assertions for o_clk_en, o_iso, o_ret, o_rstn, o_pwr_on_req
    end
  endtask

  // Task to check clock gating only
  task check_clock_gating_only(input int domain);
    begin
      // Add checks to ensure only clock gating and reset occur
      // Example: assert(o_clk_en[domain] == 0) else $fatal("Clock gating failed!");
    end
  endtask

  // Monitor outputs
  initial begin
    $monitor("Time: %0t | o_dcdc_enable: %b | o_hw_sleep_req: %b | o_pwr_on_req: %b | o_clk_en: %b | o_iso: %b | o_ret: %b | o_rstn: %b",
             $time, o_dcdc_enable, o_hw_sleep_req, o_pwr_on_req, o_clk_en, o_iso, o_ret, o_rstn);
  end

endmodule