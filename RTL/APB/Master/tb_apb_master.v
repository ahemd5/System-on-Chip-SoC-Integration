module tb_apb_master;

  // Parameters
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;

  // Signal declarations
  reg                 clk;
  reg                 rstn;
  reg                 valid;
  wire                ready;
  reg [ADDR_WIDTH-1:0] addr;
  reg                 rd0_wr1;  // 0 for read, 1 for write
  reg [DATA_WIDTH-1:0] wr_data;
  wire                rd_valid;
  wire [DATA_WIDTH-1:0] rd_data;

  // APB interface signals
  wire                psel;
  wire                penable;
  wire                pwrite;
  wire [ADDR_WIDTH-1:0] paddr;
  wire [DATA_WIDTH-1:0] pwdata;
  reg [DATA_WIDTH-1:0] prdata;
  reg                 pready;
  reg                 pslverr;

  // Instantiate DUT
  apb_master #(
      .addr_width(ADDR_WIDTH),
      .data_width(DATA_WIDTH)
  ) DUT (
      .i_clk_apb(clk),
      .i_rstn_apb(rstn),
      .i_valid(valid),
      .o_ready(ready),
      .o_psel(psel),
      .o_penable(penable),
      .o_pwrite(pwrite),
      .o_paddr(paddr),
      .o_pwdata(pwdata),
      .i_prdata(prdata),
      .i_pready(pready),
      .i_pslverr(pslverr),
      .i_addr(addr),
      .i_rd0_wr1(rd0_wr1),
      .i_wr_data(wr_data),
      .o_rd_valid(rd_valid),
      .o_rd_data(rd_data)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Testbench tasks

  // Task for reset
  task reset();
    begin
      rstn = 0;
      #20;
      rstn = 1;
    end
  endtask

  // Task for write operation
  task apb_write(input [ADDR_WIDTH-1:0] write_addr, input [DATA_WIDTH-1:0] write_data);
    begin
      valid = 1;
      addr = write_addr;
      rd0_wr1 = 1;  // 1 for write
      wr_data = write_data;
      @(posedge clk);
      while (!ready) begin
        @(posedge clk);
      end
      valid = 0;
      @(posedge clk);  // Wait one more clock cycle for the transaction to complete
    end
  endtask

  // Task for read operation
  task apb_read(input [ADDR_WIDTH-1:0] read_addr);
    begin
      valid = 1;
      addr = read_addr;
      rd0_wr1 = 0;  // 0 for read
      @(posedge clk);
      while (!ready) begin
        @(posedge clk);
      end
      valid = 0;
      @(posedge clk);  // Wait for the data to be read
    end
  endtask

  // Initialize and run tests
  initial begin
    // Initialize inputs
    clk = 0;
    rstn = 1;
    valid = 0;
    addr = 0;
    rd0_wr1 = 0;
    wr_data = 0;
    prdata = 32'h0;
    pready = 0;
    pslverr = 0;

    // Apply reset
    reset();
	
    /****************** test 1 ************************/
	// Simulate APB write signal for write transaction without wait state 
    pready = 1;
	
    // Write operation example
    $display("Starting write operation...");
    apb_write(32'hA0000000, 32'h12345678);
    #10;

	/****************** test 2 ************************/
    // Simulate APB ready signal for read transaction
    pready = 1;
    prdata = 32'hABCD1234;

    // Read operation example
    $display("Starting read operation...");
    apb_read(32'hA1000000);
    #10;
	
	/****************** test 3 ************************/
	// Simulate APB write signal for write transaction with wait state 
    pready = 0;
	
	// Write operation example
    $display("Starting read operation...");
    apb_write(32'hA1000500, 32'ha2535614);
    #10;
	
    pready = 1;
	#10;

    // Finish simulation
    $finish;
  end

endmodule
