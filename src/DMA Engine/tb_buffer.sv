module tb_buffer;

  // Parameters
  parameter DATA_WIDTH = 32;
  parameter DEPTH = 16;

  // Signals
  logic                    clk, rst;
  logic                    i_rd0_wr1, i_valid;
  logic  [DATA_WIDTH-1:0]  i_data;
  logic  [DATA_WIDTH-1:0]  o_data;
  logic                    o_valid;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
  end

  // Testbench logic
  initial begin
    // Initialize inputs
    rst = 0;
    i_rd0_wr1 = 0;
    i_valid = 0;
    i_data = 0;


    // Reset and initialization
    #10 rst = 1; // Release reset after 10ns

    // Write operations
    #15 in_write(32'hAAAAAAAA);
    #10 in_write(32'hBBBBBBBB);
    #10 in_write(32'hCCCCCCCC);
    #10 in_write(32'hDDDDDDDD);
    #10 in_write(32'hEEEEEEEE);
    #10 in_write(32'hFFFFFFF);
    #10 in_write(32'hAAAAAAAA);
    #10 in_write(12'hCCC);


     #10
    // Read operations
    #10 in_read;
    #10 in_read;
    #10 in_read;
    #10 in_read;
    #10 in_read;
    #10 in_read;
    #10 in_read;
    #10 in_read;
    #10 i_valid = 0;

    // Wrap up simulation
    #100 $stop;
  end

  // Write task
  task in_write(input [DATA_WIDTH-1:0] data);
    begin
      i_rd0_wr1 = 1; // Write mode
      i_valid = 1;
      i_data = data;
      #10; // Ensure the operation occurs over one clock cycle
      i_valid = 0;
    end
  endtask

  // Read task
  task in_read;
    begin
      i_rd0_wr1 = 0; // Read mode
      i_valid = 1;
      #10; // Wait for read operation to complete
      i_valid = 0;
      $display("Read Data: %h, Valid: %b", 
               o_data, o_valid);
    end
  endtask

  // DUT Instantiation
  buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
  ) DUT (
    .clk(clk),
    .rst(rst),
    .i_rd0_wr1(i_rd0_wr1),
    .i_valid(i_valid),
    .i_data(i_data),
    .o_data(o_data),
    .o_valid(o_valid)
  );

endmodule

