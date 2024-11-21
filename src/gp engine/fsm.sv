///////////////////////////////////////////////////////////////////////////////
// Module: GP-Engine FSM
// Description: 
//   GP Engine FSM acts as the master driver for an AHB master. It controls the
//   interaction between the FSM and other modules such as the register file
//   and CMD buffer, handling various transactions like read, write, and poll.
//
// Parameters:
//   - ADDR_WIDTH: Width of the address field (default: 32 bits)
//   - DATA_WIDTH: Width of the data field (default: 32 bits)
//   - COMMAND_WIDTH: Width of the command buffer (default: 64 bits)
//
// Key Features:
//   - State-based transaction handling (e.g., WRITE, RMW, POLL_1, POLL_0).
//   - Detects rising and falling edges for trigger inputs.
//   - Interfaces with a CMD buffer to fetch and process commands.
///////////////////////////////////////////////////////////////////////////////

module fsm #(
    parameter ADDR_WIDTH = 32,
              DATA_WIDTH = 32,
              COMMAND_WIDTH = 64
)(
    input logic                      i_clk,            // Clock signal
    input logic                      i_rstn,           // Reset signal (active low)

    // Trigger signals from hardware
    input logic [3:0]                i_str_trig,       // Trigger inputs

    // Interface with (FSM → Reg File)
    input logic [DATA_WIDTH-1:0]     rd_trig_s1_config, // Trigger 1 config from reg file
    input logic [DATA_WIDTH-1:0]     rd_trig_s2_config, // Trigger 2 config from reg file
    input logic [DATA_WIDTH-1:0]     rd_trig_s3_config, // Trigger 3 config from reg file
    input logic [DATA_WIDTH-1:0]     rd_trig_s4_config, // Trigger 4 config from reg file
    input logic                      reg_rd_valid,     // Register read valid
    output reg                       reg_rd_en,        // Register read enable

    // Interface with (FSM → CMD Buffer)
    input logic [COMMAND_WIDTH-1:0]  cmd_out,          // Command from CMD buffer
    input logic                      cmd_rd_valid,     // Command read valid
    output reg                       cmd_rd_en,        // Command read enable
    output reg [ADDR_WIDTH-1:0]      cmd_addr,         // Current command address

    // Interface with (FSM → CMD Buffer)
    input logic                      fsm_i_ready,      // Ready signal
    input logic [DATA_WIDTH-1:0]     fsm_i_rd_data,    // Read data from master
    input logic                      fsm_i_rd_valid,   // Read data valid
    output reg                       fsm_o_valid,      // Output valid
    output reg [DATA_WIDTH-1:0]      fsm_o_wr_data,    // Write data to master
    output reg [ADDR_WIDTH-1:0]      fsm_o_addr,       // Address to master
    output reg                       fsm_o_rd_wr       // Read/Write select
);

    // FSM state definitions
    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        FETCH_CMD = 3'b001,
        WRITE     = 3'b010,
        RMW       = 3'b011,
        POLL_1    = 3'b100,
        POLL_0    = 3'b101,
        DONE      = 3'b110
    } state_t;

    state_t current_state, next_state, previous_state, previous_state_reg;

    // Trigger configuration
    reg [3:0] trig_en;                // Enable bits for triggers
    reg [3:0] trig_edge;              // Edge selection for triggers

    // Command and transaction fields
    reg [1:0] txn_type;               // Transaction type
    reg [ADDR_WIDTH-1:0] addr_field;  // Address field from command
    reg [DATA_WIDTH-1:0] data_field;  // Data field from command

    // RWM internal signals
    reg [DATA_WIDTH-1:0] read_value, modified_value, mask; // RMW computation
    reg [DATA_WIDTH-1:0] modified_value_reg, mask_reg;

    // Trigger edge detection
    reg [3:0] i_str_trig_prev;        // Previous trigger state
    reg [ADDR_WIDTH-1:0] current_cmd_addr; // Current CMD address

    reg [3:0] trigger_rising_edge;    // Detected rising edges
    reg [3:0] trigger_falling_edge;   // Detected falling edges
    reg [3:0] active_triggers;        // Active triggers based on config

    // FSM state update
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            current_state <= IDLE;
            i_str_trig_prev <= 4'b0;  // Reset trigger state
        end else begin
            current_state <= next_state;
            i_str_trig_prev <= i_str_trig; // Update trigger state
            modified_value_reg <= modified_value;
            mask_reg <= mask;
            previous_state_reg <= previous_state;
            cmd_addr <= current_cmd_addr;
        end
    end

    // FSM combinational logic
    always @(*) begin
        // Default assignments
        cmd_rd_en   = 'b0;
        current_cmd_addr = 'b0;

        fsm_o_valid = 'b0;
        fsm_o_rd_wr = 'b0;
        fsm_o_addr  = 'b0;
        fsm_o_wr_data = 'b0;

        reg_rd_en = 'b0;

        trig_en = 'b0;
        trig_edge = 'b0;
        trigger_rising_edge = 'b0;
        trigger_falling_edge = 'b0;
        active_triggers = 'b0;

        txn_type = 'b0;
        addr_field = 'b0;
        data_field = 'b0;

        read_value = 'b0;
        mask = 'b0;
        modified_value = 'b0;
        previous_state = IDLE;

        case (current_state)
            IDLE: begin
                // Idle state - wait for a trigger event and read configuration
                reg_rd_en = 1; // Enable reading of the configuration register
                
                if (reg_rd_valid) begin
                    // Extract trigger enable and edge settings from configuration
                    trig_en = {rd_trig_s1_config[0], rd_trig_s2_config[0], rd_trig_s3_config[0], rd_trig_s4_config[0]};
                    trig_edge = {rd_trig_s1_config[1], rd_trig_s2_config[1], rd_trig_s3_config[1], rd_trig_s4_config[1]};
                    
                    // Detect trigger edges
                    trigger_rising_edge = i_str_trig & ~i_str_trig_prev;  // High transition detection
                    trigger_falling_edge = ~i_str_trig & i_str_trig_prev; // Low transition detection

                    // Determine which triggers are active based on edge type and enable flags
                    active_triggers = (trig_edge) ? 
                                      (trigger_rising_edge & trig_en) : 
                                      (trigger_falling_edge & trig_en);
                end else begin
                    // No valid register read; default all trigger signals to zero
                    trig_en = 'b0;
                    trig_edge = 'b0;
                    active_triggers = 'b0;
                end

                // Determine the next state based on active triggers
                if (active_triggers[3]) begin
                    cmd_rd_en = 1; // Enable command read
                    current_cmd_addr = {rd_trig_s1_config[31:2], 2'b00}; // Set command address for trigger 1
                    next_state = FETCH_CMD; // Transition to command fetch state
                end else if (active_triggers[2]) begin
                    cmd_rd_en = 1;
                    current_cmd_addr = {rd_trig_s2_config[31:2], 2'b00}; // Trigger 2
                    next_state = FETCH_CMD;
                end else if (active_triggers[1]) begin
                    cmd_rd_en = 1;
                    current_cmd_addr = {rd_trig_s3_config[31:2], 2'b00}; // Trigger 3
                    next_state = FETCH_CMD;
                end else if (active_triggers[0]) begin
                    cmd_rd_en = 1;
                    current_cmd_addr = {rd_trig_s4_config[31:2], 2'b00}; // Trigger 4
                    next_state = FETCH_CMD;
                end else begin
                    // No active triggers; remain in IDLE
                    cmd_rd_en = 0;
                    current_cmd_addr = 32'b0;
                    next_state = IDLE;
                end
            end

            FETCH_CMD: begin
                // Fetch command from the command buffer
                if (cmd_rd_valid) begin
                    // Parse command fields
                    txn_type = cmd_out[63:62];          // Transaction type
                    addr_field = {cmd_out[61:32], 2'b00}; // Address field
                    data_field = cmd_out[31:0];        // Data field
                    
                    // Determine the next state based on the transaction type
                    if (cmd_out == 64'b0) begin
                        next_state = DONE;            // End of commands
                    end else if (txn_type == 2'b00) begin
                        next_state = WRITE;           // Write operation
                    end else if (txn_type == 2'b01) begin
                        next_state = RMW;             // Read-modify-write operation
                    end else if (txn_type == 2'b10) begin
                        next_state = POLL_1;          // Poll for 1 operation
                    end else if (txn_type == 2'b11) begin
                        next_state = POLL_0;          // Poll for 0 operation
                    end else begin
                        next_state = IDLE;            // Unknown command; return to idle
                    end
                end else begin
                    // No valid command data; remain in FETCH_CMD state
                    next_state = FETCH_CMD;
                end
            end

            WRITE: begin
                // Handle write operations
                if (previous_state_reg != RMW) begin
                    // Standard write
                    fsm_o_valid = 1;                   // Indicate valid FSM operation
                    fsm_o_rd_wr = 1;                   // Specify write operation
                    fsm_o_addr = addr_field;           // Write address
                    fsm_o_wr_data = data_field;        // Write data
                    
                    if (fsm_i_ready) begin
                        // Write completed successfully; fetch the next command
                        cmd_rd_en = 1;
                        current_cmd_addr = cmd_addr + 32'h4; // Increment command address
                        next_state = FETCH_CMD;
                    end else begin
                        // Write not completed; retry
                        cmd_rd_en = 0;
                        current_cmd_addr = cmd_addr;
                        next_state = WRITE;
                    end
                end else begin
                    // Write as part of a read-modify-write operation
                    fsm_o_valid = 1;
                    fsm_o_rd_wr = 1;
                    fsm_o_addr = addr_field; // Write address
                    fsm_o_wr_data = modified_value_reg | (data_field & mask_reg); // Write modified data
                    
                    if (fsm_i_ready) begin
                        // Write completed; proceed to fetch the next command
                        cmd_rd_en = 1;
                        current_cmd_addr = cmd_addr + 32'h4;
                        next_state = FETCH_CMD;
                    end else begin
                        // Write not completed; retry
                        cmd_rd_en = 0;
                        current_cmd_addr = cmd_addr;
                        next_state = WRITE;
                    end
                end
            end

            RMW: begin
                // Read-modify-write operation
                fsm_o_valid = 1;                     // Indicate valid operation
                fsm_o_rd_wr = 0;                     // Set to read operation
                fsm_o_addr  = addr_field;            // Address to read
                if (fsm_i_rd_valid & fsm_i_ready) begin
                    cmd_rd_en = 1;                   // Enable command read
                    read_value = fsm_i_rd_data;      // Store read data
                    mask = data_field;               // Apply mask from data field
                    modified_value = read_value & (~mask); // Compute modified value
                    previous_state = RMW;            // Save state for later
                    current_cmd_addr = cmd_addr + 32'h4; // Increment command address
                    next_state = FETCH_CMD;          // Move to next command
                end else begin
                    cmd_rd_en = 0;                   // No command read
                    read_value = 32'b0;              // Clear read value
                    mask = data_field;               // Maintain mask value
                    modified_value = read_value & ~mask; // Compute modified value
                    previous_state = RMW;            // Maintain state
                    current_cmd_addr = cmd_addr;
                    next_state = RMW;                // Stay in RMW state
                end
            end

            POLL_1: begin
                // Poll for 1 operation
                fsm_o_valid = 1;                     // Indicate valid operation
                fsm_o_rd_wr = 0;                     // Set to read operation
                fsm_o_addr = addr_field;             // Address to poll
                if (fsm_i_ready && fsm_i_rd_valid && ((fsm_i_rd_data & data_field) == data_field)) begin
                    cmd_rd_en = 1;                   // Enable command read
                    current_cmd_addr = cmd_addr + 32'h4; // Increment command address
                    next_state = FETCH_CMD;          // Move to next command
                end else if (fsm_i_ready && fsm_i_rd_valid && ((fsm_i_rd_data & data_field) == 32'hFFFF_FFFF)) begin
                    cmd_rd_en = 1;                   // Enable command read
                    current_cmd_addr = cmd_addr + 32'h4; // Increment command address
                    next_state = FETCH_CMD;          // Move to next command
                end else begin
                    cmd_rd_en = 0;                   // No command read
                    current_cmd_addr = cmd_addr;
                    next_state = POLL_1;             // Stay in POLL_1 state
                end
            end

            POLL_0: begin
                // Poll for 0 operation
                fsm_o_valid = 1;                     // Indicate valid operation
                fsm_o_rd_wr = 0;                     // Set to read operation
                fsm_o_addr = addr_field;             // Address to poll
                if (fsm_i_ready && fsm_i_rd_valid && ((fsm_i_rd_data & data_field) == data_field)) begin
                    cmd_rd_en = 1;                   // Enable command read
                    current_cmd_addr = cmd_addr + 32'h4; // Increment command address
                    next_state = FETCH_CMD;          // Move to next command
                end else if (fsm_i_ready && fsm_i_rd_valid && ((fsm_i_rd_data & data_field) == 32'h0000_0000)) begin
                    cmd_rd_en = 1;                   // Enable command read
                    current_cmd_addr = cmd_addr + 32'h4; // Increment command address
                    next_state = FETCH_CMD;          // Move to next command
                end else begin
                    cmd_rd_en = 0;                   // No command read
                    current_cmd_addr = cmd_addr;
                    next_state = POLL_0;             // Stay in POLL_0 state
                end
            end

            DONE: begin
                // Terminal state
                next_state = DONE;                   // Stay in DONE state
            end

            default: begin
                // Default state handling
                next_state = IDLE;                   // Transition to IDLE
            end
        endcase
    end
endmodule

// output reg  [ADDR_WIDTH-1:0] o_addr_trig_src,



