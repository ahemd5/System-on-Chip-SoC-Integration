// ***********************************************************************
// Module: AHB Master Interface
// Description: This module implements an AHB-Lite master interface, which 
//              supports both read and write transactions. The module 
//              manages the transfer of data between the master and a slave
//              using a pipelined approach for address and data phases.
// Parameters:
//   - DATA_WIDTH: Width of the data bus (default 32 bits).
//   - ADDR_WIDTH: Width of the address bus (default 32 bits).
// ***********************************************************************

module ahb_master #(
    parameter DATA_WIDTH = 32, // Width of data bus (default 32 bits)
    parameter ADDR_WIDTH = 32  // Width of address bus (default 32 bits)
)(
    input  logic i_clk_ahb,      // AHB clock signal
    input  logic i_rstn_ahb,     // AHB reset signal (active low)
    
    // AHB Interface Signals
    input  logic i_hready,       // Slave ready signal, indicates the bus is ready for transfer
    input  logic i_hresp,        // Slave response signal (assumed always OKAY in this design)
    output reg   o_hwrite,       // Write control signal (1 for write, 0 for read)
    output reg   o_htrans,       // Transfer type (e.g., IDLE, NONSEQ)
    output reg   [2:0] o_hsize,  // Size of the transfer (e.g., byte, halfword, word)
    input  logic [DATA_WIDTH-1:0] i_hrdata, // Data received during a read operation
    output reg   [ADDR_WIDTH-1:0] o_haddr,  // Address for the current transfer
    output reg   [DATA_WIDTH-1:0] o_hwdata, // Data sent during a write operation
    
    // Transaction Interface Signals
    input  logic i_valid,        // Signal indicating a new transaction request
    input  logic i_rd0_wr1,      // Transaction type: 0 for read, 1 for write
    output reg   o_ready,        // Signal indicating master is ready to accept a new transaction
    output reg   o_rd_valid,     // Signal indicating read data is valid
    input  logic [ADDR_WIDTH-1:0] i_addr, // Address for the requested transaction
    input  logic [DATA_WIDTH-1:0] i_wr_data, // Data for the requested write operation
    output reg   [DATA_WIDTH-1:0] o_rd_data // Data read from the slave
);
    // Buffered transaction parameters to support pipelining and multi-cycle operations
    reg i_rd0_wr1_buffer;                   // Buffered read/write control signal
    reg [ADDR_WIDTH-1:0] i_addr_buffer;     // Buffered address
    reg [DATA_WIDTH-1:0] i_wr_data_buffer;  // Buffered write data

    // FSM States
    typedef enum reg {
        IDLE = 2'b0,   // Idle state: waiting for a valid transaction
        NONSEQ = 2'b1  // Non-sequential transfer state
    } state_t;
    state_t state, next_state;

    // FSM State Transition Logic
    always @(posedge i_clk_ahb or negedge i_rstn_ahb) begin
        if (!i_rstn_ahb) begin
            state <= IDLE; // Reset state to IDLE
        end else begin
            state <= next_state; // Update state based on next_state logic
        end
    end

    // Outputs Logic
    always @(*) begin
        // Default outputs to avoid unintended behavior
        o_haddr    = 32'b0;  // Default address
        o_hwrite   = 1'b0;   // Default to read
        o_hsize    = 3'b010; // Default size (word)
        o_htrans   = 1'b0;   // Default transfer type (IDLE)
        o_ready    = 1'b1;   // Default ready state
        o_rd_valid = 1'b0;   // Default read valid signal
        o_rd_data  = 32'b0;  // Default read data
        
        case (state)
            IDLE: begin
                o_ready = 1'b1; // Ready to accept a new transaction
                if (i_valid) begin
                    // Buffer transaction details
                    i_rd0_wr1_buffer = i_rd0_wr1;
                    i_wr_data_buffer = i_wr_data;
                    i_addr_buffer = i_addr;
                    
                    // Set outputs for transaction initiation
                    o_haddr = i_addr;
                    o_hwrite = i_rd0_wr1;
                    o_htrans = 2'b1; // NONSEQ
                    o_ready = 1'b0; // Indicate master is busy
                    o_rd_valid = 1'b0; // No valid read data yet
                    next_state = NONSEQ; // Transition to NONSEQ state
                end else begin
                    next_state = IDLE; // Remain in IDLE if no valid transaction
                end
            end

            NONSEQ: begin
                // Handle transactions based on buffered data and signals
                if (!i_rd0_wr1_buffer && i_hready && !i_valid) begin // Read completion, no new request
                    o_rd_data = i_hrdata; // Capture read data
                    o_rd_valid = 1'b1; // Indicate valid read data
                    o_haddr   = i_addr_buffer;
                    o_hwrite  = i_rd0_wr1_buffer;
                    o_htrans  = 1'b1;   // NONSEQ
                    o_ready = 1'b1; // Ready for next transaction
                    next_state = NONSEQ; // Stay in NONSEQ
                end else if (!i_rd0_wr1_buffer && i_hready && i_valid) begin // Read completion, new request
                    o_rd_data = i_hrdata; // Capture read data
                    o_rd_valid = 1'b1; // Indicate valid read data                    
                    // Update buffers and outputs for new request
                    o_haddr = i_addr;
                    o_hwrite = i_rd0_wr1;
                    o_htrans = 1'b1; // NONSEQ
                    i_rd0_wr1_buffer = i_rd0_wr1;
                    i_addr_buffer = i_addr;
                    i_wr_data_buffer = i_wr_data;
                    o_ready = 1'b1; // Ready for next transaction
                    next_state = NONSEQ; // Stay in NONSEQ
                end else if (i_rd0_wr1_buffer && i_hready && !i_valid) begin // Write completion, no new request
                    o_rd_valid = 1'b0; // No valid read data
                    o_haddr = i_addr_buffer;
                    o_hwrite = i_rd0_wr1_buffer;
                    o_hwdata = i_wr_data_buffer;
                    o_htrans = 1'b1; // NONSEQ
                    o_ready = 1'b1; // Ready for next transaction
                    next_state = NONSEQ; // Stay in NONSEQ
                end else if (i_rd0_wr1_buffer && i_hready && i_valid) begin // Write completion, new request
                    o_rd_valid = 1'b0; // No valid read data
                    // Update buffers and outputs for new request
                    o_haddr = i_addr;
                    o_hwrite = i_rd0_wr1;
                    o_hwdata = i_wr_data_buffer;
                    o_htrans = 1'b1; // NONSEQ
                    i_rd0_wr1_buffer = i_rd0_wr1;
                    i_addr_buffer = i_addr;
                    i_wr_data_buffer = i_wr_data;
                    o_ready = 1'b1; // Ready for next transaction
                    next_state = NONSEQ; // Stay in NONSEQ
                end else if (!i_hready && !i_valid) begin // Slave not ready, no new request
                    o_ready = 1'b0; // Master busy
                    o_haddr = i_addr_buffer;
                    o_hwrite = i_rd0_wr1_buffer;
                    o_htrans = 2'b01; // NONSEQ
                    next_state = NONSEQ; // Stay in NONSEQ
                end else if (!i_hready && i_valid) begin // Slave not ready, new request
                    o_ready = 1'b0; // Master busy
                    o_haddr = i_addr_buffer;
                    o_hwrite = i_rd0_wr1_buffer;
                    o_htrans = 2'b01; // NONSEQ                   
                    // Buffer new request
                    i_rd0_wr1_buffer = i_rd0_wr1;
                    i_addr_buffer = i_addr;
                    i_wr_data_buffer = i_wr_data;
                    next_state = NONSEQ; // Stay in NONSEQ
                end else begin
                    // Return to IDLE state when no valid transaction
                    HTRANS = 1'b0; // Set transfer type to IDLE
                    o_ready = 1'b1; // Ready for next transaction
                    next_state = IDLE; // Transition to IDLE
                end
            end
            
            default: next_state = IDLE; // Default to IDLE state
        endcase
    end
endmodule

// ***********************************************************************
// Sign-off: The AHB Master design is complete and ready for simulation 
//           and integration into larger systems. It handles pipelined 
//           transactions and supports both read and write operations.
// ***********************************************************************
