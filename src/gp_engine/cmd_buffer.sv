// -----------------------------------------------------------------------------
// Module Name: cmd_buffer
//
// Description: 
// This module implements a command buffer that stores and retrieves commands. 
// It interfaces with a Finite State Machine (FSM), an address decoder, and an 
// AHB slave. The buffer stores commands received via the AHB interface and 
// allows the FSM to read back commands for execution.
//
// Key Features:
// 1. Command storage: Supports 256 location to save 128 commands, each location 32 bits wide.
// 2. AHB interface: Handles read and write operations to/from the buffer.
// 3. FSM interface: Provides stored commands to the FSM for execution.
// 4. Debugging support: Allows read-back of commands for verification.
// -----------------------------------------------------------------------------

module cmd_buffer #(
    parameter CMD_WIDTH = 64,         // Width of each command
    parameter DATA_WIDTH = 32,        // Data width for each write transaction
    parameter BUFFER_WIDTH = 32,      // Width of command buffer
    parameter BUFFER_DEPTH = 256,     // command buffer depth
    parameter TRANS_ADDR_WIDTH = 8    // Translated address width (8 bits for 256 locations)
)(
    // Clock and Reset
    input logic                  i_clk,           // Clock signal
    input logic                  i_rst_n,         // Active-low reset

    // Interface with FSM (Finite State Machine)
    input logic                        cmd_rd_en,     // Enable signal for FSM to read command
    input logic [TRANS_ADDR_WIDTH-1:0] cmd_addr,      // Address from FSM to read command
    output reg                         cmd_rd_valid,  // Indication that the read operation is valid
    output reg  [CMD_WIDTH-1:0]        cmd_out,       // Command sent to FSM for execution

    // Interface with Address Decoder
    input logic                        cmd_en,     // Enable signal from Address Decoder
    input logic [TRANS_ADDR_WIDTH-1:0] trans_addr, // Translated address (8 bits for 256 locations)

    // Interface with AHB Slave
    input logic                  slv_o_valid,   // Valid transaction from AHB Slave
    input logic [DATA_WIDTH-1:0] slv_o_wr_data, // Write data from AHB Slave
    input logic                  slv_o_rd0_wr1, // Read/write indicator (1 = write)
    output reg                   slv_i_ready,   // CMD Buffer ready for new transaction
    output reg  [DATA_WIDTH-1:0] slv_i_rd_data, // Data read for debugging
    output reg                   slv_i_rd_valid // Buffer sent read valid signal
);

    // Internal command memory to store 64-bit commands
    reg [BUFFER_WIDTH-1:0] cmd_mem [0:BUFFER_DEPTH-1]; // Command memory array

    // Always block: Handles reset, command storage, debugging, and FSM read
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            // Reset logic: Clear command memory and reset flags
            slv_i_ready <= 1'b1;                       // Indicate buffer is ready for new transactions			
            slv_i_rd_valid <= 1'b0;
			slv_i_rd_data <= {DATA_WIDTH{1'b0}};
            for (int i = 0; i < BUFFER_DEPTH; i = i + 1) begin
                cmd_mem[i] <= {BUFFER_WIDTH{1'b0}};       // Initialize all commands to 0
            end
        end else begin
            // AHB Write Transaction: Store command in memory
			slv_i_rd_valid <= 1'b0;
            if (cmd_en && slv_o_valid && slv_o_rd0_wr1) begin
                cmd_mem[trans_addr] <= slv_o_wr_data;  // Store 32-bit data in memory
                slv_i_ready <= 1'b1;                   // Indicate buffer is ready for new transactions
            end else if (~cmd_en || ~slv_o_valid && slv_o_rd0_wr1) begin 
                slv_i_ready <= 1'b1;                   // Indicate buffer is ready for new transactions
			end 
        end
		
		// FSM Read Transaction: Provide stored command to FSM
        if (cmd_rd_en && (!cmd_en || (cmd_en && !slv_o_rd0_wr1))) begin
			cmd_out <= {cmd_mem[cmd_addr + 8'h1][1:0] ,cmd_mem[cmd_addr + 8'h1][31:2] ,cmd_mem[cmd_addr]}; // Send 64-bit command
			cmd_rd_valid <= 1'b1; // Indicate valid read operation
			slv_i_ready <= 1'b1;
        end else begin
			// Default: Clear FSM read-related signals
			cmd_out <= {CMD_WIDTH{1'b0}};
			cmd_rd_valid <= 1'b0;
			slv_i_ready <= 1'b1;
        end
    end

	always @(*) begin 
	    if (cmd_en && slv_o_valid && !slv_o_rd0_wr1) begin
			slv_i_rd_data = cmd_mem[trans_addr]; // Read 32-bit data from memory
			slv_i_rd_valid = 1'b1;               // Indicate read data is valid
			slv_i_ready = 1'b1;                  // Indicate buffer is ready for new transactions
        end else if (~cmd_en || ~slv_o_valid && !slv_o_rd0_wr1) begin
			// if slave not valid or cmd not enabled 
			// don't change content of cmd buffer 
			// Default: Clear read-related signals
			slv_i_rd_data = {DATA_WIDTH{1'b0}};
			slv_i_rd_valid = 1'b0;
			slv_i_ready = 1'b1;
        end

	end 
	
endmodule
