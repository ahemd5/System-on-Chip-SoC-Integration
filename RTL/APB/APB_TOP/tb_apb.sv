module tb_apb;

    // Parameters
    parameter addr_width = 32;
    parameter data_width = 32;

    // Clock and Reset
    reg i_clk_apb;
    reg i_rstn_apb;

    // Master signals
    reg i_valid;
    reg [addr_width-1:0] i_addr;
    reg i_rd0_wr1;
    reg [data_width-1:0] i_wr_data;
    logic o_ready;
    logic o_rd_valid;
    logic [data_width-1:0] o_rd_data;

    // Slave signals
    logic o_valid;
    logic [addr_width-1:0] o_addr;
    logic o_rd0_wr1;
    logic [data_width-1:0] o_wr_data;
    reg i_ready;
    reg i_rd_valid;
    reg [data_width-1:0] i_rd_data;

    // DUT instantiation
    apb #(
        .addr_width(addr_width),
        .data_width(data_width)
    ) apb_inst (
        .i_clk_apb(i_clk_apb),
        .i_rstn_apb(i_rstn_apb),
        .i_valid(i_valid),
        .i_addr(i_addr),
        .i_rd0_wr1(i_rd0_wr1),
        .i_wr_data(i_wr_data),
        .o_ready(o_ready),
        .o_rd_valid(o_rd_valid),
        .o_rd_data(o_rd_data),
        .o_valid(o_valid),
        .o_addr(o_addr),
        .o_rd0_wr1(o_rd0_wr1),
        .o_wr_data(o_wr_data),
        .i_ready(i_ready),
        .i_rd_valid(i_rd_valid),
        .i_rd_data(i_rd_data)
    );

    // Clock generation
    always #5 i_clk_apb = ~i_clk_apb;

    // Tasks
    task reset;
        begin
            i_rstn_apb = 0;
            #10;
            i_rstn_apb = 1;
        end
    endtask

    task write_transaction(input [addr_width-1:0] addr, input [data_width-1:0] data);
        begin
            i_valid = 1;
            i_addr = addr;
            i_rd0_wr1 = 1;          // Write transaction
            i_wr_data = data;

            // Wait for transaction to complete
            @(posedge o_ready);
            i_valid = 1;
            #10;
        end
    endtask

    task read_transaction(input [addr_width-1:0] addr, output [data_width-1:0] data);
        begin
            i_valid = 1;
            i_addr = addr;
            i_rd0_wr1 = 0;          // Read transaction

            // Wait for read data valid signal
            @(posedge o_rd_valid);
            data = o_rd_data;
            i_valid = 1;
            #10;
        end
    endtask
	
    reg [data_width-1:0] read_data;
	
    // Initial block for test sequence
    initial begin
        // Initialize signals
        i_clk_apb = 0;
        i_ready = 1;
        i_rd_valid = 0;
        i_rd_data = 0;

        // Apply reset
        reset;

        // Test write transaction
        write_transaction(32'hA5A5A5A5, 32'hDEADBEEF);

        // Test read transaction
        read_transaction(32'hA5A5A5A5, read_data);
        $display("Read Data: %h", read_data);

        // End of simulation
        #10;
        $finish;
    end

    // Slave response for read data
    always @(posedge i_clk_apb) begin
        if (o_valid && i_ready) begin
            if (!o_rd0_wr1) begin
                i_rd_valid <= 1;
                i_rd_data <= 32'hCAFEBABE;
            end
        end else begin
            i_rd_valid <= 0;
        end
    end

endmodule
