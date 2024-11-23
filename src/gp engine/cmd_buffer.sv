//----------------------------------------------------------------------------------------------------------
// Module Name: cmd_buffer
//
// Description: 
// This module implements a command buffer to manage command storage, retrieval, and debugging in a system. 
// It interacts with an AHB-Lite interface for data transfers, stores commands in memory, 
// and provides access to the commands for execution by a Finite State Machine (FSM). 
// The buffer also supports debugging through read-back operations of stored commands.
//-------------------------------------------------------------------------------------------------------------
module cmd_buffer #( 
    parameter CMD_WIDTH = 64,         // Width of each command (64 bits)
    parameter CMD_DEPTH = 128,        // Number of commands (memory depth)
    parameter ADDR_WIDTH = 32,        // Address width for the commands
    parameter DATA_WIDTH = 32         // Data width for each write transaction
)(
    // Clock and Reset
    input wire                  clk,       // Clock signal
    input wire                  rst_n,     // Active-low reset

    // Interface with FSM (Finite State Machine)
    input wire                  cmd_rd_en,    // Enable signal for FSM to read command
    input wire [ADDR_WIDTH-1:0] cmd_addr,     // Address from FSM to read command
    output reg                  cmd_rd_valid, // Indication that the read operation is valid
    output reg [CMD_WIDTH-1:0]  cmd_out,      // Command sent to FSM for execution

    // Interface with Address Decoder
    input wire                  cmd_en,       // Enable signal from Address Decoder

    // Interface with AHB Slave
    input wire                  slv_o_valid,  // Valid transaction from AHB Slave
    input wire [ADDR_WIDTH-1:0] slv_o_addr,   // Address from AHB Slave
    input wire [DATA_WIDTH-1:0] slv_o_wr_data,// Write data from AHB Slave
    input wire                  slv_o_rd0_wr1,// Read/write indicator (1 = write)
    output reg                  slv_i_ready,  // CMD Buffer ready for new transaction
    output reg [DATA_WIDTH-1:0] slv_i_rd_data,// Data read for debugging
    output reg                  slv_i_rd_valid// Debug read valid signal
);

    // **Key Features**
    // 1. **Command Storage**: Stores up to `CMD_DEPTH` commands, each `CMD_WIDTH` wide, for execution by an FSM.
    // 2. **AHB-Lite Interface**: Supports word-aligned read and write transactions with a 32-bit data width.
    // 3. **Sequenced Writes**: Commands are stored in two phases (transaction , data and address fields).
    // 4. **proper sequence**: commands should terminate by WRITE if not reset buffer , RWM followed by RWM
    // 5. **Debugging Capability**: Allows reading back commands in 32-bit chunks for validation or debugging.
    // 6. **Reset Functionality**: Clears the command buffer and resets all internal flags upon system reset.
   
   localparam [1:0] RWM = 2'b01 , WRITE = 2'b00;
	
    // **Internal Registers and Memory**
    reg reset_mode;       // Indicates CMD Buffer is in reset mode.
    reg store_mode;       // Indicates CMD Buffer is in the command storage mode.
    reg debug_mode;       // Indicates CMD Buffer is in the debugging mode.
    reg [CMD_WIDTH-1:0] cmd_mem [0:CMD_DEPTH-1]; // Command memory (64-bit entries).
    reg [1:0] pre_transaction_field; // Tracks previous transaction type for sequencing.
    reg [ADDR_WIDTH-1:0] wr_addr;    // Write pointer for the command buffer.
    reg [DATA_WIDTH-1:0] temp_data;  // Temporary storage for the first phase of a write.
    reg data_written;     // Tracks whether the first phase of a two-step write is complete.
    reg readed_data;      // Tracks the phase of read operations for debugging.

    // **Always Block**: Handles reset, mode switching, command storage, and debugging logic.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic: Clear command memory and reset flags
            reset_mode <= 1'b1;
            store_mode <= 1'b0;
            debug_mode <= 1'b0;
            wr_addr <= 32'h0;
            slv_i_ready <= 1'b1;
            data_written <= 1'b0;
            readed_data <= 1'b0;

            // Clear all commands in memory
		for (int i = 0; i < CMD_DEPTH; i = i + 1) begin
                cmd_mem[i] <= {CMD_WIDTH{1'b0}};
            end
        end else begin
            // **Mode Control**
            reset_mode <= 1'b0;
            store_mode <= cmd_en && slv_o_valid && slv_o_rd0_wr1; // Active for valid write transactions.
            debug_mode <= cmd_en && !slv_o_rd0_wr1; // Active for debug read transactions.

            // **Write Logic**: Two-phase write sequence (data field first, full command next).
	   if (store_mode && !data_written && wr_addr != 32'h0000_04A0) begin
                // First phase: Write the data field (temporary storage for next phase)
                temp_data <= slv_o_wr_data;
                data_written <= 1'b1; // Indicate data has been written
	    end else if (store_mode && data_written && pre_transaction_field == RWM && slv_o_wr_data[1:0] == WRITE) begin
                // Second phase: Store the full command (address + data)
                cmd_mem[wr_addr] <= {slv_o_wr_data[31:2], temp_data , slv_o_wr_data[1:0]}; // Store full command
                pre_transaction_field <= slv_o_wr_data[1:0]; // Store the transaction type (RWM or WRITE)
                wr_addr <= wr_addr + 32'h4; // Increment address for next command
                data_written <= 1'b0; // Reset data written flag for next write
	    end else if (store_mode && data_written && pre_transaction_field == RWM && !slv_o_wr_data[1:0] == WRITE) begin
		// Second phase: Store the full command (address + data)   
		cmd_mem[wr_addr] <= {CMD_WIDTH{1'b0}}; // Store full command
                pre_transaction_field <= slv_o_wr_data[1:0]; // Store the transaction type (RWM or WRITE)    
                wr_addr <= wr_addr; // Keep current address if no update
                data_written <= 1'b0; // Reset data written flag
	    end else if (store_mode && data_written) begin
                // Second phase: Store the full command (address + data)
                cmd_mem[wr_addr] <= {slv_o_wr_data[31:2], temp_data , slv_o_wr_data[1:0]}; // Store full command
                pre_transaction_field <= slv_o_wr_data[1:0]; // Store the transaction type (RWM or WRITE)
                wr_addr <= wr_addr + 32'h4; // Increment address for next command
                data_written <= 1'b0; // Reset data written flag for next write    
	    end else if ( (!cmd_en || wr_addr == 32'h0000_04A0) && pre_transaction_field == WRITE)begin
                // End of storing mode: Reset write address and ready for next transaction
                wr_addr <= {ADDR_WIDTH{1'b0}}; // Reset address to 0 if WRITE mode is completed
                slv_i_ready <= 1'b1; // Ready for next transaction
            end else begin
		reset_mode <= 1'b1;  // not a valid sequece of commands 
                wr_addr <= {ADDR_WIDTH{1'b0}}; // Keep current address if no update
                data_written <= 1'b0; // Reset flag for next write
                slv_i_ready <= 1'b1; // Ready for next transaction
            end

	    // **FSM Read Logic**
		if (cmd_rd_en && reset_mode) begin
                cmd_out <= cmd_mem[cmd_addr]; // Send the command stored at the specified address
                cmd_rd_valid <= 1'b1; // Indicate that the command read is valid
            end else begin
                cmd_out <= {CMD_WIDTH{1'b0}}; // Send zero if no read is requested
                cmd_rd_valid <= 1'b0; // Indicate no valid read operation
            end
		
            // **Debugging Logic**: Allows read-back of commands in 32-bit chunks.
            if (debug_mode && !readed_data) begin
                slv_i_rd_data <= cmd_mem[slv_o_addr][31:0]; // Read the lower 32 bits (data field)
                readed_data <= 1'b1; // Indicate the lower half has been read
                slv_i_rd_valid <= 1'b1; // Indicate read is valid
            end else if (debug_mode && readed_data) begin
                slv_i_rd_data <= cmd_mem[slv_o_addr][63:32]; // Read the upper 32 bits (data field)
                slv_i_rd_valid <= 1'b1; // Indicate read is valid
                readed_data <= 1'b0; // Reset flag for next read
            end else begin
                slv_i_rd_data <= {DATA_WIDTH{1'b0}}; // Set output to 0 if not in debug mode
                slv_i_rd_valid <= 1'b0; // Indicate no valid read operation
                readed_data <= 1'b0; // Reset flag for debugging
            end
        end
    end

endmodule
