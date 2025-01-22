module tb_apb_master;

  // Parameters
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;

  // Signal declarations
  reg                 clk;
  reg                 rstn;
  reg                 i_valid;
  wire                o_ready;
  reg [ADDR_WIDTH-1:0] i_addr;
  reg                 i_rd0_wr1;  // 0 for read, 1 for write
  reg [DATA_WIDTH-1:0] i_wr_data;
  wire                o_rd_valid;
  wire [DATA_WIDTH-1:0] o_rd_data;

  // APB interface signals
  wire                o_psel;
  wire                o_penable;
  wire                o_pwrite;
  wire [ADDR_WIDTH-1:0] o_paddr;
  wire [DATA_WIDTH-1:0] o_pwdata;
  reg [DATA_WIDTH-1:0] i_prdata;
  reg                 i_pready;
  reg                 pslverr;

  // Instantiate DUT
  apb_master #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH)
  ) DUT (
      .i_clk_apb(clk),
      .i_rstn_apb(rstn),
      .i_valid(i_valid),
      .o_ready(o_ready),
      .o_psel(o_psel),
      .o_penable(o_penable),
      .o_pwrite(o_pwrite),
      .o_paddr(o_paddr),
      .o_pwdata(o_pwdata),
      .i_prdata(i_prdata),
      .i_pready(i_pready),
      .i_pslverr(pslverr),
      .i_addr(i_addr),
      .i_rd0_wr1(i_rd0_wr1),
      .i_wr_data(i_wr_data),
      .o_rd_valid(o_rd_valid),
      .o_rd_data(o_rd_data)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Testbench tasks

  // Task for reset
  task reset();
    begin
      rstn = 0;
      #17;
      rstn = 1;
    end
  endtask

  // Task for write operation
  task apb_write(input [ADDR_WIDTH-1:0] write_addr, input [DATA_WIDTH-1:0] write_data);
    begin
      i_valid = 1;
      i_addr = write_addr;
      i_rd0_wr1 = 1;  // 1 for write
      i_wr_data = write_data;
      @(posedge clk);
      while (!o_ready) begin
        @(posedge clk);
      end
      i_valid = 0;
      i_addr = 0;
      i_rd0_wr1 = 0;  
      i_wr_data = 0;
      
    end
  endtask

  // Task for read operation
  task apb_read(input [ADDR_WIDTH-1:0] read_addr);
    begin
      i_valid = 1;
      i_addr = read_addr;
      i_rd0_wr1 = 0;  // 0 for read
      @(posedge clk);
      while (!o_ready) begin
        @(posedge clk);
      end
      i_valid = 0;
      i_addr = 0;
      i_rd0_wr1 = 0;  
      i_wr_data = 0;
    end
  endtask

  // Initialize and run tests
  initial begin
    // Initialize inputs
    clk = 0;
    rstn = 1;
    i_valid = 0;
    i_addr = 0;
    i_rd0_wr1 = 0;
    i_wr_data = 0;
    i_prdata = 32'h0;
    i_pready = 0;
    pslverr = 0;

    // Apply reset
    reset();
	
    /****** test 1 ********/
	// Simulate APB write signal for write transaction without wait state 
    i_pready = 1;
	
    // Write operation example
    $display("Starting write operation...");
    apb_write(32'hA0000040, 32'h12345678);
    #32;

	/****** test 2 ********/
    // Simulate APB ready signal for read transaction
    i_pready = 1;
    

    // Read operation example
    $display("Starting read operation...");
    apb_read(32'hA1000000);
    #10;
    i_prdata = 32'hABCD1234;
    
    #22;
     i_prdata = 32'h0;
	
	/****** test 3 ********/
	// Simulate APB write signal for write transaction with wait states 
    i_pready = 0;
	
	// Write operation example
    $display("Starting read operation...");
    apb_write(32'hA1000500, 32'ha2535614);
    #30;
	
    i_pready = 1;
	#10;
	#42;
	
	/****** test 4 ********/
    // Simulate APB ready signal for read transaction WITH WAIT STATE
    i_pready = 0;
    

    // Read operation example
    $display("Starting read operation...");
    apb_read(32'hA111A000);
    #40;
    i_pready = 1;
    i_prdata = 32'hEBBDF764;
    
    #10;
     i_prdata = 32'h0;
     #32;
        /****** test 5 ********/
	// Simulate APB two write signals without idle between them  
    i_pready = 1;
	
    // Write operation example
    $display("Starting write operation...");
    apb_write(32'hA0B00E40, 32'h17745C78);
    apb_write(32'hA0C04EC0, 32'hAB755678);
    #32;
    #30;
         /****** test 6 ********/
	// Simulate APB two write signals without idle between them  and with wait states  
    i_pready = 0;
	
    // Write operation example
    $display("Starting write operation...");
    fork 
    begin 
    apb_write(32'hA0BB0E40, 32'h88745C78);
    apb_write(32'hA0C05EC0, 32'hDD755678);
  end 
    begin 
     #60;
    i_pready = 1;
  end
    join 
    
    #32;
    #20;
     

    // Finish simulation
    $finish;
  end

endmodule