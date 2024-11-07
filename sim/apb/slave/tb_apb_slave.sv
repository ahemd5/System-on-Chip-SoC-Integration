module tb_apb_slave;
    // Parameters
    parameter addr_width = 32;
    parameter data_width = 32;
	
    // Signals
    reg                     i_clk_apb;
    reg                     i_rstn_apb;
    reg                     i_pwrite;
    reg  [data_width-1:0]   i_pwdata;
    reg  [addr_width-1:0]   i_paddr;
    reg                     i_psel;
    reg                     i_penable;
    logic [data_width-1:0]  o_prdata;
    logic                   o_pslverr;
    logic                   o_pready;

    logic                   o_valid;
    reg                     i_ready;
    logic [addr_width-1:0]  o_addr;
    logic                   o_rd0_wr1;
    logic [data_width-1:0]  o_wr_data;
    reg                     i_rd_valid;
    reg   [data_width-1:0]  i_rd_data;

    // Instantiate APB Slave
    apb_slave #(
        .addr_width(addr_width),
        .data_width(data_width)
    )uut (
        .i_clk_apb(i_clk_apb),
        .i_rstn_apb(i_rstn_apb),
        .i_pwrite(i_pwrite),
        .i_pwdata(i_pwdata),
        .i_paddr(i_paddr),
        .i_psel(i_psel),
        .i_penable(i_penable),
        .o_prdata(o_prdata),
        .o_pslverr(o_pslverr),
        .o_pready(o_pready),
        .o_valid(o_valid),
        .i_ready(i_ready),
        .o_addr(o_addr),
        .o_rd0_wr1(o_rd0_wr1),
        .o_wr_data(o_wr_data),
        .i_rd_valid(i_rd_valid),
        .i_rd_data(i_rd_data)
    );

    // Clock Generation
    always #5 i_clk_apb = ~i_clk_apb;

    // Task for Reset
    task reset;
        begin
            i_rstn_apb = 0;
            #10;
            i_rstn_apb = 1;
        end
    endtask

    // Task for Write Transaction
    task write_transaction(input [31:0] addr, input [31:0] data);
        begin
            @(negedge i_clk_apb);
            i_pwrite = 1;
            i_pwdata = data;
            i_paddr = addr;
            i_psel = 1;
            i_penable = 1;
            #10 i_ready = 1;
            @(posedge i_clk_apb);
            i_ready = 0;
            i_psel = 0;
            i_penable = 0;
            #10;
        end
    endtask

    // Task for Read Transaction
    task read_transaction(input [31:0] addr, output [31:0] data);
        begin
            @(negedge i_clk_apb);
            i_pwrite = 0;
            i_paddr = addr;
            i_psel = 1;
            i_penable = 1;
            #10 i_ready = 1;
            @(posedge i_clk_apb);
            i_rd_valid = 1;
            data = i_rd_data;  // Capture read data
            @(posedge i_clk_apb);
            i_rd_valid = 0;
            i_ready = 0;
            i_psel = 0;
            i_penable = 0;
            #10;
        end
    endtask
    
	reg [31:0] read_data;
            
    // Test Sequence
    initial begin
        // Initialize signals
        i_clk_apb = 0;
        i_pwrite = 0;
        i_pwdata = 32'b0;
        i_paddr = 32'b0;
        i_psel = 0;
        i_penable = 0;
        i_ready = 0;
        i_rd_valid = 0;
        i_rd_data = 32'hA5A5A5A5;  // Set read data

        // Reset the DUT
        reset;

        // Test Write Transaction
        write_transaction(32'h0000_1000, 32'hDEADBEEF);

        // Test Read Transaction
        read_transaction(32'h0000_1000, read_data);

        // Check the read data
        if (read_data === 32'hA5A5A5A5) begin
            $display("Read Transaction Successful. Data = %h", read_data);
        end else begin
            $display("Read Transaction Failed. Data = %h", read_data);
        end

        // End simulation
        #50;
        $finish;
    end

endmodule