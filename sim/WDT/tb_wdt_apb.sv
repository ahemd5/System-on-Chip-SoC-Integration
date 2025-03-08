`timescale 1ns/1ps

module tb_wdt_apb;

  //-------------------------------------------------------------------------
  // Local parameters for APB register addresses (must match DUT)
  //-------------------------------------------------------------------------
  localparam ADDR_WDT_CTRL     = 8'h00;
  localparam ADDR_WDT_TIMEOUT  = 8'h04;
  localparam ADDR_WDT_STATUS   = 8'h08;
  localparam ADDR_WDT_FEED     = 8'h0C;
  localparam ADDR_WDT_INT_EN   = 8'h10;
  localparam ADDR_WDT_INT_STAT = 8'h14;

  //-------------------------------------------------------------------------
  // Signals for the APB interface and watchdog outputs
  //-------------------------------------------------------------------------
  logic         pclk;
  logic         presetn;
  logic         psel;
  logic         penable;
  logic         pwrite;
  logic  [7:0]  paddr;
  logic  [31:0] pwdata;
  logic  [31:0] prdata;
  logic         pready;
  logic         pslverr;
  logic         wdt_reset;
  logic         wdt_int;
  logic         debug_mode;

  //-------------------------------------------------------------------------
  // Instantiate the WDT module (DUT)
  //-------------------------------------------------------------------------
  wdt_apb dut (
    .pclk       (pclk),
    .presetn    (presetn),
    .psel       (psel),
    .penable    (penable),
    .pwrite     (pwrite),
    .paddr      (paddr),
    .pwdata     (pwdata),
    .prdata     (prdata),
    .pready     (pready),
    .pslverr    (pslverr),
    .wdt_reset  (wdt_reset),
    .wdt_int    (wdt_int),
    .debug_mode (debug_mode)
  );

  //-------------------------------------------------------------------------
  // Clock generation: pclk with a 10 ns period
  //-------------------------------------------------------------------------
  initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;
  end

  //-------------------------------------------------------------------------
  // Reset generation: active low reset (presetn)
  //-------------------------------------------------------------------------
  initial begin
    presetn = 0;
    #20;        // Hold reset for 20 ns
    presetn = 1;
  end

  //-------------------------------------------------------------------------
  // APB Write Task
  // This task simulates an APB write transaction.
  //-------------------------------------------------------------------------
  task apb_write(input [7:0] addr, input [31:0] data);
    begin
      @(negedge pclk);
      psel    = 1'b1;
      penable = 1'b0;
      pwrite  = 1'b1;
      paddr   = addr;
      pwdata  = data;
      @(negedge pclk);
      penable = 1'b1;
      @(negedge pclk);
      // End of transaction
      psel    = 1'b0;
      penable = 1'b0;
      pwrite  = 1'b0;
    end
  endtask

  //-------------------------------------------------------------------------
  // APB Read Task
  // This task simulates an APB read transaction.
  //-------------------------------------------------------------------------
  task apb_read(input [7:0] addr, output [31:0] data);
    begin
      @(negedge pclk);
      psel    = 1'b1;
      penable = 1'b0;
      pwrite  = 1'b0;
      paddr   = addr;
      @(negedge pclk);
      penable = 1'b1;
      @(negedge pclk);
      data = prdata;
      // End of transaction
      psel    = 1'b0;
      penable = 1'b0;
    end
  endtask

  //-------------------------------------------------------------------------
  // Test Sequences
  //-------------------------------------------------------------------------
  initial begin
    // Initialize APB signals
    psel    = 1'b0;
    penable = 1'b0;
    pwrite  = 1'b0;
    paddr   = 8'd0;
    pwdata  = 32'd0;
    debug_mode = 1'b0;

    // Wait for reset to complete
    wait (presetn == 1);
    $display("[%0t] Reset complete", $time);

    //-------------------------------------------------------------------------
    // Test 1: Basic configuration
    // Enable WDT, no window mode, soft reset, clock gating disabled.
    //-------------------------------------------------------------------------
    $display("[%0t] Test 1: Basic configuration", $time);
    apb_write(ADDR_WDT_CTRL, 32'h00000001);  // Bit0=enable; others 0.
    // Set a timeout value (e.g., 50 cycles)
    apb_write(ADDR_WDT_TIMEOUT, 32'd50);
    // Enable pre-timeout interrupt (bit0 of interrupt enable)
    apb_write(ADDR_WDT_INT_EN, 32'h00000001);

    #200; // Let counter run a while

    //-------------------------------------------------------------------------
    // Test 2: Feed operation in non-windowed mode
    //-------------------------------------------------------------------------
    $display("[%0t] Test 2: Feed operation in non-window mode", $time);
    apb_write(ADDR_WDT_FEED, 32'h0); // Feed watchdog to reset the counter
    #100;

    //-------------------------------------------------------------------------
    // Test 3: Window mode feed: feed early (should be rejected)
    // Enable window mode: set bit1 in WDT_CTRL (along with enable).
    //-------------------------------------------------------------------------
    $display("[%0t] Test 3: Early feed in window mode (feed should be ignored)", $time);
    apb_write(ADDR_WDT_CTRL, 32'h00000003);  // Bit0 (enable) and Bit1 (window mode)
    // Wait a short time so that the counter is below half the timeout (timeout is 50, so half = 25)
    #50;
    $display("[%0t] Attempting early feed", $time);
    apb_write(ADDR_WDT_FEED, 32'h0);
    #100;

    //-------------------------------------------------------------------------
    // Test 4: Valid feed in window mode
    // Wait until counter is in valid window (>= 25)
    //-------------------------------------------------------------------------
    $display("[%0t] Test 4: Valid feed in window mode", $time);
    #150;  // Wait so that counter >= (50/2)
    apb_write(ADDR_WDT_FEED, 32'h0);
    #100;

    //-------------------------------------------------------------------------
    // Test 5: Pre-timeout interrupt generation
    // The pre-timeout interrupt is generated when counter reaches (timeout - margin)
    // (Margin is 10, so interrupt at counter==40 for timeout==50).
    //-------------------------------------------------------------------------
    $display("[%0t] Test 5: Pre-timeout interrupt generation", $time);
    #100;  // Wait until the counter nears 40
    if (wdt_int)
      $display("[%0t] Pre-timeout interrupt asserted as expected", $time);
    else
      $display("[%0t] Pre-timeout interrupt NOT asserted", $time);
    #50;

    //-------------------------------------------------------------------------
    // Test 6: Watchdog timeout and reset generation
    // Do not feed; let the counter reach the timeout value.
    //-------------------------------------------------------------------------
    $display("[%0t] Test 6: Watchdog timeout and reset", $time);
    #200;  // Allow counter to reach timeout
    if (wdt_reset)
      $display("[%0t] Watchdog reset asserted as expected", $time);
    else
      $display("[%0t] Watchdog reset NOT asserted", $time);
    #50;

    //-------------------------------------------------------------------------
    // Test 7: Debug mode pause functionality
    // Enable debug pause (bit2) and assert debug_mode.
    //-------------------------------------------------------------------------
    $display("[%0t] Test 7: Debug mode pause", $time);
    // Write WDT_CTRL with enable (bit0) and debug pause enabled (bit2)
    apb_write(ADDR_WDT_CTRL, 32'h00000005); // 0x5: Bit0 and Bit2 set.
    // Set a longer timeout value (e.g., 100 cycles)
    apb_write(ADDR_WDT_TIMEOUT, 32'd100);
    // Ensure debug_mode is initially deasserted.
    debug_mode = 1'b0;
    #100;
    // Assert debug mode: the counter should pause.
    debug_mode = 1'b1;
    $display("[%0t] Debug mode asserted: counter should pause", $time);
    #200;
    // Deassert debug mode to resume counting.
    debug_mode = 1'b0;
    $display("[%0t] Debug mode deasserted: counter resumes", $time);
    #200;

    //-------------------------------------------------------------------------
    // Test 8: Clock gating functionality
    // Enable clock gating (bit4) along with WDT enable.
    //-------------------------------------------------------------------------
    $display("[%0t] Test 8: Clock gating functionality", $time);
    apb_write(ADDR_WDT_CTRL, 32'h00000011); // 0x11: Bit0 (enable) and Bit4 (clock gating) set.
    // Set timeout to a higher value (e.g., 200 cycles)
    apb_write(ADDR_WDT_TIMEOUT, 32'd200);
    #500;

    $display("[%0t] All tests complete. Ending simulation.", $time);
    $finish;
  end

endmodule
