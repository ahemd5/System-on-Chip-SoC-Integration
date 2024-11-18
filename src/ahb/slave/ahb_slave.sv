module ahb_slave #(
    parameter DATA_WIDTH = 32,  // Data width for the AHB bus (32-bit by default)
    parameter ADDR_WIDTH = 32   // Address width for the AHB bus (32-bit by default)
)(
    input  logic                  i_clk_ahb,        // AHB clock input
    input  logic                  i_rstn_ahb,       // Active-low reset input for the slave

    // Inputs from the AHB master
    input  logic                  i_hready,         // Master ready signal (indicates master is ready for the next phase)
    input  logic                  i_htrans,         // Master transaction type (whether there is a valid transaction)
    input  logic [2:0]            i_hsize,          // Master transfer size (for defining the transfer width)
    input  logic                  i_hwrite,         // Master write/read control signal (1 = write, 0 = read)
    input  logic [ADDR_WIDTH-1:0] i_haddr,          // Address of the current transfer (from master)
    input  logic [DATA_WIDTH-1:0] i_hwdata,         // Data being written by the master (only used during write)
    input  logic                  i_hselx,          // Slave select signal (indicates which slave is being accessed)

    // Inputs from memory
    input  logic                  i_ready,          // Memory ready signal (indicates memory is ready for operation)
    input  logic                  i_rd_valid,       // Memory read valid signal (indicates valid read data is available from memory)
    input  logic [DATA_WIDTH-1:0] i_rd_data,        // Data read from memory (provided to the master for a read operation)

    // Outputs to the AHB master
    output reg                    o_hreadyout,      // Slave ready output (indicates whether the slave is ready for the next transaction)
    output reg                    o_hresp,          // Slave response (always OKAY for this basic example)
    output reg [DATA_WIDTH-1:0]   o_hrdata,         // Data read to the master (used for read transactions)

    // Outputs to memory
    output reg                    o_valid,          // Transaction valid signal (indicates the transaction is valid and being processed)
    output reg                    o_rd0_wr1,        // Read (0) or write (1) transaction indicator (to memory)
    output reg [DATA_WIDTH-1:0]   o_wr_data,        // Write data to memory (used only for write operations)
    output reg [ADDR_WIDTH-1:0]   o_addr            // Address to memory (the address for the memory operation)
);

    // Define the states for the pipelined AHB slave (IDLE and NONSEQ)
    typedef enum logic {
        IDLE = 1'b0,  // Idle state: No active transaction is occurring
        NONSEQ = 1'b1  // Non-sequential state: An active transaction is in progress
    } state_t;

    // Current and next state for state machine control
    state_t current_state, next_state;

    // Control signal to differentiate between address and data phases (0 = address phase, 1 = data phase)
    reg active_phase;

    // Buffers to store the address and write data temporarily for pipelining
    reg [ADDR_WIDTH-1:0] addr_buffer;  // Holds the address of the current transaction
    reg                  write_buffer; // Holds the write flag (1 if write, 0 if read)

    // Sequential logic for updating the current state based on clock and reset signals
    always @(posedge i_clk_ahb or negedge i_rstn_ahb) begin
        if (!i_rstn_ahb) begin
            current_state <= IDLE;  // If reset is asserted, go to IDLE state
        end else begin
            current_state <= next_state;  // Otherwise, update to the next state
        end
    end

    // Next-state logic: Defines how the state machine transitions based on inputs
    always @(*) begin
        next_state = current_state;  // Default to stay in the current state
        
        case (current_state)
            IDLE: begin
                if (i_htrans) begin  // If there is a valid transaction from the master
                    next_state = NONSEQ;  // Transition to NONSEQ state to start processing the transaction
                end else begin
                    next_state = IDLE;  // Stay in IDLE if no transaction
                end
            end

            NONSEQ: begin
                // Check if all conditions are met for completing the transaction (ready signals, master select, etc.)
                if (i_hselx && i_hready && i_ready && i_htrans) begin
                    next_state = NONSEQ;  // Continue processing the current transaction (write or read)
                end else if (i_hselx && i_hready && !i_ready && i_htrans) begin
                    next_state = NONSEQ;  // If memory is not ready but transaction is still ongoing, continue processing
                end else if (i_hselx && !i_hready && !i_ready && i_htrans) begin
                    next_state = NONSEQ;  // Wait if not ready for the next phase
                end else begin
                    next_state = IDLE;  // Transition back to IDLE if no active transaction is detected
                end
            end
        endcase
    end

    // Output logic: Defines how the outputs are driven based on the current state and inputs
    always @(*) begin
        o_hresp     = 1'b0;  // Default slave response (always OKAY)
        
        case (current_state)
            IDLE: begin
                if (i_htrans) begin  // If a transaction is detected from the master
                    o_hreadyout = 1'b1;  // Slave is ready to accept the transaction
                    o_wr_data   = 'b0;    // No write data during IDLE state
                    addr_buffer = i_haddr;  // Store address for future use
                    write_buffer = i_hwrite;  // Store the write flag (1 for write, 0 for read)
                    o_rd0_wr1 = i_hwrite;  // Indicate whether the transaction is a read or write                    
                    active_phase = 1'b1;  // Set active phase to indicate the start of the address phase
                    
                    if (i_hwrite) begin
                        o_valid = 1'b0;  // Write transaction is not valid yet
                        o_addr  = i_haddr;    //  Provide the write address to memory
                    end else begin
                        o_valid = 1'b1;  // Read transaction is valid
                        o_addr = i_haddr;  // Provide the read address to memory
                    end
                end else begin
                    o_hreadyout = 1'b1;  // Slave remains ready
                    o_hrdata    = 'b0;    // No data to send to master
                    o_valid     = 1'b0;   // No active transaction
                    o_rd0_wr1   = 1'b0;   // No read/write operation
                    o_wr_data   = 'b0;    // No write data
                    o_addr      = 'b0;    // No valid address
                end
            end
            
            NONSEQ: begin
                // If a write operation is being performed
                if (write_buffer && active_phase) begin
                    o_wr_data = i_hwdata;  // Provide the write data from the master
                    o_rd0_wr1 = write_buffer;  // Indicate a write transaction to memory
                    o_addr = addr_buffer;  // Provide the address to memory
                    o_valid = 1'b1;  // Mark write transaction as valid
                    
                    // Update the buffers for the next transaction
                    write_buffer = i_hwrite;
                    addr_buffer = i_haddr;
                    
                    o_hreadyout = 1'b1;  // Slave is ready for the next transaction
                    active_phase = 1'b1;  // Continue the active phase (data phase)
                    o_hrdata    = 'b0;    // No read data during write transaction
                end
                
                // If a read operation is being performed
                else if (!write_buffer && active_phase) begin
                    o_hrdata = i_rd_data;  // Provide the read data from memory to the master
                    o_rd0_wr1 = write_buffer;  // Indicate a read transaction to memory
                    o_addr = addr_buffer;  // Provide the address to memory
                    o_valid = 1'b1;  // Mark read transaction as valid
                    
                    // Update buffers for the next cycle
                    write_buffer = i_hwrite;
                    addr_buffer = i_haddr;
                    
                    if (i_rd_valid) begin
                        o_hreadyout = 1'b1;  // If read data is valid, indicate readiness for the next transaction
                    end else begin
                        o_hreadyout = 1'b0;  // Wait until the read data is valid
                    end
                    o_wr_data   = 'b0;    // No write data during read transaction
                    active_phase = 1'b1;  // Continue the active phase (data phase)
                end else begin
                    if (i_htrans) begin  // If a new transaction starts
                        o_hreadyout = 1'b1;  // Slave is ready to accept the new transaction
                        o_wr_data   = 'b0;    // No write data during IDLE state
                        addr_buffer = i_haddr;  // Store the new address for future use
                        write_buffer = i_hwrite;  // Store the new write flag
                        o_rd0_wr1 = i_hwrite;  // Indicate the type of transaction (read or write)
                        o_addr = i_haddr;  // Provide the address to memory
                        active_phase = 1'b1;  // Set active phase (address phase)
                        
                        if (i_hwrite) begin
                            o_valid = 1'b0;  // Write transaction is not valid yet
                        end else begin
                            o_valid = 1'b1;  // Read transaction is valid
                        end
                    end else begin
                        o_hreadyout = 1'b1;  // Slave remains ready
                        o_hrdata    = 'b0;    // No data during IDLE state
                        o_valid     = 1'b0;   // No active transaction
                        o_rd0_wr1   = 1'b0;   // No read/write operation
                        o_wr_data   = 'b0;    // No write data
                        o_addr      = 'b0;    // No valid address
                    end
                end
            end
        endcase
    end
endmodule
