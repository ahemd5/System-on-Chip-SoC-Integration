module reg_file (
    input wire i_clk_ahb,               // Clock input (renamed from clk)
    input wire [31:0] i_address,        // 32-bit input address
    input wire i_rd0_wr1,               // Read (0) / Write (1) signal
    input wire [31:0] i_wr_data,        // Data to be written into memory
    input wire I_valid,                 // Valid signal for transaction
    output reg [31:0] o_rd_data,        // Data read from memory
    output reg o_rd_valid,              // Read valid signal
    output wire o_ready,                // Ready signal, always asserted

    // Second interface signals
    input logic [0:0] reg_24,           // Input to be written into memory at address 0x24, bit 0
    output logic [3:0] reg_00,          // Output from memory address 0x00, bits [3:0]
    output logic [23:0] reg_04,         // Output from memory address 0x04, bits [23:0] written
    output logic [23:0] reg_08,         // Output from memory address 0x08, bits [23:0]
    output logic [31:0] reg_0C,         // Output from memory addresses 0x0C-0x0F
    output logic [25:0] reg_1C,         // Output from memory address 0x1C, bits [25:0]
    output logic [31:0] reg_10,         // Output from memory addresses 0x10-0x13
    output logic [31:0] reg_14,         // Output from memory addresses 0x14-0x17
    output logic [31:0] reg_18,         // Output from memory addresses 0x18-0x1B
    output logic [0:0] reg_20           // Output from memory address 0x20, bit 0
);

    // Declare memory as a 10x32-bit array
    reg [31:0] memory_array [0:9];
    wire [31:0] addr ;
    assign addr=i_address/4;
    // Assign o_ready to 1, always asserted
    assign o_ready = 1;

    always @(posedge i_clk_ahb) begin
      // Write input reg_24 to memory at address 0x24 (bit 0 in byte 0x24)
    memory_array[9][0]<= reg_24;              // Address 0x24, bit 0
        if (I_valid) begin
            if (i_rd0_wr1) begin
                // Write operation: write data to memory
                memory_array[addr[3:0]] <= i_wr_data; 
                o_rd_valid <= 0; // No read valid signal during write
            end else begin
                // Read operation: read data from memory
                o_rd_data <= memory_array[addr[3:0]]; 
                o_rd_valid <= 1; // Assert read valid
            end
        end else begin
            // No valid transaction
            o_rd_valid <= 0; // Deassert read valid
        end
    end

    // Second interface: Assign memory contents based on specified addresses
    assign reg_00 = memory_array[0][3:0];             // Address 0x00, bits [3:0]
     assign reg_04 = memory_array[1][23:0];           // Address 0x08, bits [23:0]
    assign reg_08 = memory_array[2][23:0];           // Address 0x08, bits [23:0]
    assign reg_0C = {memory_array[3]};               // Addresses 0x0C-0x0F, full 32 bits
    assign reg_1C = memory_array[7][25:0];           // Address 0x1C, bits [25:0]
    assign reg_10 = memory_array[4];                 // Addresses 0x10-0x13, full 32 bits
    assign reg_14 = memory_array[5];                 // Addresses 0x14-0x17, full 32 bits
    assign reg_18 = memory_array[6];                 // Addresses 0x18-0x1B, full 32 bits
    assign reg_20 = memory_array[8][0];              // Address 0x20, bit [0]

    

endmodule

