module Sync_FIFO #(
    parameter DATA_WIDTH = 32,  // Width of data in the FIFO
    parameter MEM_DEPTH = 16,   // Depth of the FIFO memory (number of entries)
    parameter PTR_WIDTH = $clog2(MEM_DEPTH)  // Width of pointer based on depth
) (
    input logic                   i_clk,         // Clock input
    input logic                   i_rstn,        // Active-low reset
    input logic  [DATA_WIDTH-1:0] i_wr_data,     // Data input for write operations
    input logic                   i_wr_en,       // Write enable
    input logic                   i_rd_en,       // Read enable
    output reg  [DATA_WIDTH-1:0] o_rd_data,      // Data output for read operations
    output logic                  o_full,        // FIFO full indicator
    output logic                  o_empty        // FIFO empty indicator
);

    // Internal FIFO memory array and pointers
    reg [DATA_WIDTH-1:0] fifo_mem [MEM_DEPTH-1:0]; // FIFO storage
    reg [PTR_WIDTH:0] w_ptr, r_ptr;                // Write and read pointers with extra bit for full/empty detection

    // Sequential logic for reset and FIFO operations
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            // Reset pointers and FIFO memory
            w_ptr <= 0;
            r_ptr <= 0;
            o_rd_data <= 0;
            // Reset FIFO memory to zero
            for (int i = 0; i < MEM_DEPTH; i++) begin
                fifo_mem[i] <= 0;
            end
        end else begin
            // Write operation: Store data and update write pointer if FIFO is not full
            if (i_wr_en && !o_full) begin
                fifo_mem[w_ptr[PTR_WIDTH-1:0]] <= i_wr_data;
                w_ptr <= w_ptr + 'b1;
            end

            // Read operation: Retrieve data and update read pointer if FIFO is not empty
            if (i_rd_en && !o_empty) begin
                o_rd_data <= fifo_mem[r_ptr[PTR_WIDTH-1:0]];
                r_ptr <= r_ptr + 'b1;
            end
        end
    end

    // Full condition: MSB of pointers differ, lower bits match
    assign o_full = ((w_ptr[PTR_WIDTH] != r_ptr[PTR_WIDTH]) &&
                     (r_ptr[PTR_WIDTH-1:0] == w_ptr[PTR_WIDTH-1:0]));

    // Empty condition: All bits of write and read pointers are identical
    assign o_empty = (w_ptr == r_ptr);
endmodule
