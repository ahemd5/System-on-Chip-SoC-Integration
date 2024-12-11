// ***********************************************************************
// Module: APB (Advanced Peripheral Bus) Master Module
// Description:
//             This module implements an APB master interface that supports both read and write operations.
//             It follows the APB protocol and uses a finite state machine (FSM) to manage the transaction phases:
//             IDLE, SETUP, and ACCESS. The design supports configurable address and data widths and ensures
//             seamless communication with an APB slave device.
// Parameters:
//   - DATA_WIDTH: Width of the data bus (default 32 bits).
//   - ADDR_WIDTH: Width of the address bus (default 32 bits). 
// Key Features:
// - FSM-based control for protocol-compliant transactions.
// - Handshaking mechanism for transaction initiation and completion.
// - Read and write functionality with ready/valid signaling.
// ***********************************************************************

module apb_master #(
    parameter ADDR_WIDTH = 32,  // Address width parameter
    parameter DATA_WIDTH = 32   // Data width parameter
) (
    input logic                 i_clk_apb,    // APB clock
    input logic                 i_rstn_apb,   // Active-low reset

    // APB protocol interface signals
    output reg                  o_psel,       // Peripheral select signal
    output reg                  o_penable,    // Peripheral enable signal
    output reg                  o_pwrite,     // Write enable signal (1 for write, 0 for read)
    output reg [ADDR_WIDTH-1:0] o_paddr,      // Address for APB transaction
    output reg [DATA_WIDTH-1:0] o_pwdata,     // Write data for APB
    input logic [DATA_WIDTH-1:0] i_prdata,    // Read data from APB slave
    input logic                 i_pready,     // Ready signal from APB slave
    input logic                 i_pslverr,    // Slave error signal

    // Handshaking interface signals
    input logic                 i_valid,      // Transaction valid signal
    output reg                  o_ready,      // Master ready signal

    // Transaction signals
    input logic [ADDR_WIDTH-1:0]  i_addr,     	// Address from external source
    input logic                   i_rd0_wr1,    // Read/Write control (0 for read, 1 for write)
    input logic [DATA_WIDTH-1:0]  i_wr_data,  	// Write data from external source
    output reg                    o_rd_valid,   // Read data valid signal
    output reg [DATA_WIDTH-1:0]   o_rd_data     // Read data output
);

reg i_rd0_wr1_reg;                   // Registered Read/Write control signal
reg [ADDR_WIDTH-1:0] i_addr_reg;     // Registered address for transaction
reg [DATA_WIDTH-1:0] i_wr_data_reg;  // Registered write data

// FSM (Finite State Machine) states
typedef enum logic [1:0] {
    IDLE   = 2'b00,  // Idle state
    SETUP  = 2'b01,  // Setup state
    ACCESS = 2'b10   // Access state (read/write operation)
} state_t;

state_t state, next_state; // Current and next state variables

// State transition logic (Sequential block)
always @(posedge i_clk_apb or negedge i_rstn_apb) begin
    if (!i_rstn_apb) begin
        state <= IDLE;  // Reset state is IDLE
    end 
    else begin
        state <= next_state;  // Update to the next state on each clock cycle
    end
end

// Registering input signals when transaction is valid and master is ready
always @(posedge i_clk_apb or negedge i_rstn_apb) begin
    if (!i_rstn_apb) begin
        i_rd0_wr1_reg <= 1'b0;          // Reset Read/Write control
        i_addr_reg <= 32'b0;            // Reset address register
        i_wr_data_reg <= 32'b0;         // Reset write data register
    end else if (o_ready && i_valid) begin
        i_rd0_wr1_reg <= i_rd0_wr1;     // Latch Read/Write control
        i_addr_reg <= i_addr;           // Latch address
        i_wr_data_reg <= i_wr_data;     // Latch write data
    end
end

// Combinational logic block for FSM and output logic
always @(*) begin
    case (state)
        IDLE: begin
            // Default values for all outputs
            o_psel = 1'b0;             // Deselect the peripheral
            o_penable = 1'b0;          // Disable the peripheral
            o_pwrite = 1'b0;           // Default to read operation
            o_rd_valid = 1'b0;         // Default to invalid read data
            o_rd_data = 32'b0;         // Default read data to zero
            o_paddr = 32'b0;           // Default address to zero
            o_pwdata = 32'b0;          // Default write data to zero
            o_ready = 1'b1;            // Master is ready for new transaction
            if (i_valid) begin
                next_state = SETUP;    // Move to SETUP state if a valid transaction is present
            end
            else begin
                next_state = IDLE;     // Remain in IDLE if no valid transaction
            end
        end

        SETUP: begin
            // Prepare for APB transaction
            o_penable = 1'b0;          // Peripheral remains disabled in SETUP phase
            o_rd_valid = 1'b0;         // Default to invalid read data
            o_rd_data = 32'b0;         // Default read data to zero
            o_psel = 1'b1;             // Select the peripheral
            o_pwrite = i_rd0_wr1_reg;  // Set write/read operation
            o_paddr = i_addr_reg;      // Set address for the transaction
            if (i_rd0_wr1_reg) begin
                o_pwdata = i_wr_data_reg; // Provide write data if write operation
            end else begin
                o_pwdata = 32'b0;      // No write data for read operation
            end 
            o_ready = 1'b0;            // Master is busy during SETUP phase
            next_state = ACCESS;       // Transition to ACCESS state
        end

        ACCESS: begin
            // Handle APB transaction in ACCESS phase
            o_penable = 1'b1;          // Enable the peripheral
            o_psel = 1'b1;             // Keep peripheral selected
            o_pwrite = i_rd0_wr1_reg;  // Maintain write/read control
            o_paddr = i_addr_reg;      // Maintain address
            if (i_pready) begin        // Wait for slave to be ready
                if (i_rd0_wr1_reg == 1'b0) begin // Read operation
                    o_rd_data = i_prdata;       // Capture read data
                    o_rd_valid = 1'b1;          // Indicate valid read data
                    o_pwdata = 32'b0;           // No write data in read operation
                end else begin                  // Write operation
                    o_pwdata = i_wr_data_reg;   // Maintain write data
                    o_rd_data = 32'b0;          // No read data in write operation
                    o_rd_valid = 1'b0;          // Invalid read data in write operation
                end
                o_ready = 1'b1;                // Master ready for next transaction
                if (i_valid) begin
                    next_state = SETUP;        // Transition to SETUP if new transaction is valid
                end
                else begin
                    next_state = IDLE;         // Transition to IDLE if no new transaction
                end
            end else begin                     // Wait state if slave is not ready
                o_ready = 1'b0;                // Master remains busy
                o_rd_valid = 1'b0;             // Read data is invalid
                o_pwdata = i_wr_data_reg;      // Maintain write data
                next_state = ACCESS;           // Stay in ACCESS state
            end
        end

        default: begin
            next_state = IDLE;                // Default state is IDLE
        end
    endcase
end

endmodule

// ***********************************************************************
// Sign-off: The APB Master design is complete and ready for simulation 
//           and integration into larger systems.The design
//           ensures seamless interaction with slave devices, supporting
//           robust and reliable read/write transactions.
// ***********************************************************************
