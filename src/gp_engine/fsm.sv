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
    parameter CMD_ADDR = 8,       // command address	          
			  ADDR_WIDTH = 32,    // Address width
              DATA_WIDTH = 32,    // Data width
              CMD_WIDTH  = 64,    // Command width
              NO_TRIG_SR = 4      // Number of trigger sources
)(
    input logic                   i_clk,            // Clock signal
    input logic                   i_rstn,           // Active low reset signal

    // Trigger inputs from hardware
    input logic [NO_TRIG_SR-1:0]  i_str_trig,       // Trigger signals

    // Configuration data from the register file
    input logic [DATA_WIDTH-1:0]  rd_trig_s1_config, // Config for trigger source 1
    input logic [DATA_WIDTH-1:0]  rd_trig_s2_config, // Config for trigger source 2
    input logic [DATA_WIDTH-1:0]  rd_trig_s3_config, // Config for trigger source 3
    input logic [DATA_WIDTH-1:0]  rd_trig_s4_config, // Config for trigger source 4
    input logic                   reg_rd_valid,      // Register read valid
    output reg                    reg_rd_en,         // Register read enable

    // Command buffer interface
    input logic [CMD_WIDTH-1:0]   cmd_out,          // Command data
    input logic                   cmd_rd_valid,     // Command read valid
    output reg                    cmd_rd_en,        // Command read enable
    output reg  [CMD_ADDR-1:0]    cmd_addr,         // Command address

    // FSM interaction with the master interface
    input logic                   fsm_i_ready,      // Master ready signal
    input logic [DATA_WIDTH-1:0]  fsm_i_rd_data,    // Data read from master
    input logic                   fsm_i_rd_valid,   // Read valid signal from master
    output reg                    fsm_o_valid,      // Output valid signal to master
    output reg  [DATA_WIDTH-1:0]  fsm_o_wr_data,    // Data to write to master
    output reg  [ADDR_WIDTH-1:0]  fsm_o_addr,       // Address for master transaction
    output reg                    fsm_o_rd_wr       // Read (0) / Write (1) select
);
// State definitions for the FSM
    typedef enum logic [2:0] {
        IDLE         = 3'b000,        // Idle state
        FETCH_CMD    = 3'b001,        // Fetch command from buffer
        RMW          = 3'b010,        // Read-modify-write operation
        POLL_1       = 3'b011,        // Poll for a value of 1
        POLL_0       = 3'b100         // Poll for a value of 0
    } state_t;

    state_t current_state, next_state, previous_state, previous_state_reg; // FSM states

    // Trigger configuration and detection
    reg [NO_TRIG_SR-1:0] trig_en;                       // Enable bits for trig
    reg [NO_TRIG_SR-1:0] trig_edge;                     // Edge type for triggers
    reg [NO_TRIG_SR-1:0] i_str_trig_prev;               // Previous trigger states
    reg [NO_TRIG_SR-1:0] trig_rising_edge;              // Rising edge detection
    reg [NO_TRIG_SR-1:0] trig_falling_edge;             // Falling edge detection
    reg [NO_TRIG_SR-1:0] active_trig, active_trig_comb; // Active triggers

    // RMW operation registers
    reg [DATA_WIDTH-1:0] read_value, modified_value, mask; // RMW logic
    reg [DATA_WIDTH-1:0] modified_value_reg, mask_reg;     // RMW state registers

    // Address management for triggers
    reg [CMD_ADDR-1:0] trig_s1_str_addr, trig_s2_str_addr;
    reg [CMD_ADDR-1:0] trig_s3_str_addr, trig_s4_str_addr;
	reg [CMD_ADDR-1:0] trig_s1_str_addr_reg ,trig_s2_str_addr_reg ;
	reg [CMD_ADDR-1:0] trig_s3_str_addr_reg ,trig_s4_str_addr_reg ;
    reg [CMD_ADDR-1:0] current_cmd_addr; // Current command address
	
    // FSM state update
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            current_state <= IDLE;
            i_str_trig_prev <= 'b0;  // Reset trigger state
			cmd_addr <= 'b0;         // Reset command address
        end else begin
            mask_reg <= mask;                       // Save mask value
			current_state <= next_state;            // Update current state
			cmd_addr <= current_cmd_addr;           // Update command address
			i_str_trig_prev <= i_str_trig;          // Store previous trigger states
			active_trig <= active_trig_comb;        // Update active triggers flag 
            modified_value_reg <= modified_value;   // Save modified value
			previous_state_reg <= previous_state;   // Save previous state                     
			trig_s1_str_addr_reg <= trig_s1_str_addr;
	        trig_s2_str_addr_reg <= trig_s2_str_addr;
		    trig_s3_str_addr_reg <= trig_s3_str_addr;
		    trig_s4_str_addr_reg <= trig_s4_str_addr;
        end
    end
	
    // FSM combinational logic
    always @(*) begin
        // Default assignments
        trig_en = 'b0;
        trig_edge = 'b0;
        trig_rising_edge = 'b0;
        trig_falling_edge = 'b0;

        case (current_state)
            IDLE: begin
			    mask             = 'b0;
                modified_value   = 'b0;
                previous_state   = IDLE;
			    fsm_o_valid      = 'b0;
                fsm_o_rd_wr      = 'b0;
                fsm_o_addr       = 'b0;
                fsm_o_wr_data    = 'b0;
				
                // Idle state - wait for a trigger event and read configuration
                reg_rd_en = 1; // Enable reading of the configuration register
                
                if (reg_rd_valid) begin
                    // Extract trigger enable and edge settings from configuration
                    trig_en = {rd_trig_s4_config[0], rd_trig_s3_config[0], rd_trig_s2_config[0], rd_trig_s1_config[0]};
                    trig_edge = {rd_trig_s4_config[1], rd_trig_s3_config[1], rd_trig_s2_config[1], rd_trig_s1_config[1]};
                    
                    // Detect trigger edges
                    trig_rising_edge = i_str_trig & ~i_str_trig_prev;  // High transition detection
                    trig_falling_edge = ~i_str_trig & i_str_trig_prev; // Low transition detection

                    // Determine which triggers are active based on edge type and enable flags
                    active_trig_comb = (trig_edge) ? 
                                           (trig_rising_edge & trig_en) : 
                                           (trig_falling_edge & trig_en);
										   
					trig_s1_str_addr = rd_trig_s1_config[9:2]; 
					trig_s2_str_addr = rd_trig_s2_config[9:2];
					trig_s3_str_addr = rd_trig_s3_config[9:2];
					trig_s4_str_addr = rd_trig_s4_config[9:2];
					
                end else begin
                    // No valid register read; default all trigger signals to zero
                    trig_en = 'b0;
                    trig_edge = 'b0;
                    active_trig_comb = 'b0;
					trig_rising_edge = 'b0;  
                    trig_falling_edge= 'b0; 
					trig_s1_str_addr = trig_s1_str_addr_reg; 
				    trig_s2_str_addr = trig_s1_str_addr_reg;
				    trig_s3_str_addr = trig_s1_str_addr_reg;
				    trig_s4_str_addr = trig_s1_str_addr_reg;
                end
				
				// Determine the next state based on active triggers
                if (active_trig_comb[0] && current_cmd_addr == 'b0) begin
                    cmd_rd_en = 1;                        // Enable command read
                    current_cmd_addr = trig_s1_str_addr;  // Set command address for trigger 1
					active_trig_comb[0]= 0;
                    next_state = FETCH_CMD;               // Transition to command fetch state
                end else if (active_trig_comb[1] && current_cmd_addr == 'b0) begin
                    cmd_rd_en = 1;
                    current_cmd_addr = trig_s2_str_addr;  // Trigger 2
					active_trig_comb[1]= 0;
                    next_state = FETCH_CMD;
                end else if (active_trig_comb[2] && current_cmd_addr == 'b0) begin
                    cmd_rd_en = 1;
                    current_cmd_addr = trig_s3_str_addr;  // Trigger 3
					active_trig_comb[2]= 0;
                    next_state = FETCH_CMD;
                end else if (active_trig_comb[3] && current_cmd_addr == 'b0) begin
                    cmd_rd_en = 1;
                    current_cmd_addr = trig_s4_str_addr;  // Trigger 4
					active_trig_comb[3]= 0;
                    next_state = FETCH_CMD;
                end else begin
                    // No active trig; remain in IDLE
                    cmd_rd_en = 0;
                    current_cmd_addr = 8'b0;
                    next_state = IDLE;
                end
            end

            FETCH_CMD: begin
                reg_rd_en = 'b0;
				mask      = mask_reg;
                modified_value = modified_value_reg;
                previous_state = previous_state_reg;
                trig_s1_str_addr = trig_s1_str_addr_reg; 
				trig_s2_str_addr = trig_s1_str_addr_reg;
				trig_s3_str_addr = trig_s1_str_addr_reg;
				trig_s4_str_addr = trig_s1_str_addr_reg;			
                // Fetch command from the command buffer
                if (cmd_rd_valid && fsm_i_ready) begin               
                    // Determine the next state based on the transaction type
                    if (cmd_out == 64'b0) begin	
					    // end of sequence 
                        next_state    = IDLE;                
					    fsm_o_valid   = 'b0;                 
                        fsm_o_rd_wr   = 'b0;                
                        fsm_o_addr    = 'b0;                
                        fsm_o_wr_data = 'b0;                 
						cmd_rd_en     = 'b0;
						current_cmd_addr = 'b0; 
						active_trig_comb = 'b0;  
                    end else if (cmd_out[63:62] == 2'b00 && !previous_state_reg == RMW) begin          
						// Write operation
                        fsm_o_valid   = 1;                             // Indicate valid FSM operation
                        fsm_o_rd_wr   = 1;                             // Specify write operation
                        fsm_o_addr    = {cmd_out[61:32], 2'b00};       // Write address
                        fsm_o_wr_data = cmd_out[31:0];                 // Write data
                        // Write completed successfully; fetch the next command address is multiple trig sources activated
						// As write operation is the last operation in proper sequence for any trigger source
                        if (active_trig[1] && (cmd_addr + 32'h2) == trig_s2_str_addr_reg) begin                        
                            cmd_rd_en           = 1;
						    current_cmd_addr    = trig_s2_str_addr_reg; 
						    active_trig_comb[0] = active_trig[0];
					        active_trig_comb[1] = 0;
					        active_trig_comb[2] = active_trig[2];
					        active_trig_comb[3] = active_trig[3]; 
						    next_state          = FETCH_CMD;
					    end else if (active_trig[2] && (cmd_addr + 8'h2) == trig_s3_str_addr_reg) begin
					        cmd_rd_en           = 1;
						    current_cmd_addr    = trig_s3_str_addr_reg; 
					        active_trig_comb[0] = active_trig[0];
					        active_trig_comb[1] = active_trig[1];
					        active_trig_comb[2] = 0;
					        active_trig_comb[3] = active_trig[3];
						    next_state          = FETCH_CMD;
					    end else if (active_trig[3] && (cmd_addr + 8'h2) == trig_s4_str_addr_reg) begin
					        cmd_rd_en           = 1;
						    current_cmd_addr    = trig_s4_str_addr_reg; 
					        active_trig_comb[0] = active_trig[0];
					        active_trig_comb[1] = active_trig[1];
					        active_trig_comb[2] = active_trig[2];
					        active_trig_comb[3] = 0;
						    next_state          = FETCH_CMD;
					    end else begin
					        cmd_rd_en        = 1;
						    current_cmd_addr = cmd_addr + 8'h2;   // Increment command address
							active_trig_comb = active_trig;
						    next_state       = FETCH_CMD;
                        end
					end else if (cmd_out[63:62] == 2'b00 && previous_state_reg == RMW) begin 
					    // Write as part of a read-modify-write operation
                        fsm_o_valid = 1;
                        fsm_o_rd_wr = 1;
                        fsm_o_addr = {cmd_out[61:32], 2'b00}; // Write address
                        fsm_o_wr_data = modified_value_reg | (cmd_out[31:0] & mask_reg); // Write modified data
						if (active_trig[1] && (cmd_addr + 32'h2) == trig_s2_str_addr_reg) begin                        
                            cmd_rd_en           = 1;
						    current_cmd_addr    = trig_s2_str_addr_reg; 
						    active_trig_comb[0] = active_trig[0];
					        active_trig_comb[1] = 0;
					        active_trig_comb[2] = active_trig[2];
					        active_trig_comb[3] = active_trig[3];  
						    next_state          = FETCH_CMD;
					    end else if (active_trig[2] && (cmd_addr + 8'h2) == trig_s3_str_addr_reg) begin
					        cmd_rd_en           = 1;
						    current_cmd_addr    = trig_s3_str_addr_reg; 
					        active_trig_comb[0] = active_trig[0];
					        active_trig_comb[1] = active_trig[1];
					        active_trig_comb[2] = 0;
					        active_trig_comb[3] = active_trig[3];
						    next_state          = FETCH_CMD;
					    end else if (active_trig[3] && (cmd_addr + 8'h2) == trig_s4_str_addr_reg) begin
					        cmd_rd_en           = 1;
						    current_cmd_addr    = trig_s4_str_addr_reg; 
					        active_trig_comb[0] = active_trig[0];
					        active_trig_comb[1] = active_trig[1];
					        active_trig_comb[2] = active_trig[2];
					        active_trig_comb[3] = 0;
						    next_state          = FETCH_CMD;
					    end else begin
					        cmd_rd_en        = 1;
						    current_cmd_addr = cmd_addr + 8'h2;   // Increment command address
							active_trig_comb = active_trig;
						    next_state       = FETCH_CMD;
                        end
                    end else if (cmd_out[63:62] == 2'b01) begin
					    // reading value in address field 
                        next_state    = RMW;                          // Read-modify-write operation
						fsm_o_valid   = 1;                            // Indicate valid FSM operation
                        fsm_o_rd_wr   = 0;                            // Specify read operation
                        fsm_o_addr    = {cmd_out[61:32], 2'b00};      // Write address
                        fsm_o_wr_data = 32'b0;                        // Write data
						cmd_rd_en     = 'b0;
						current_cmd_addr = 'b0; 				
						active_trig_comb = active_trig;
                    end else if (cmd_out[63:62] == 2'b10) begin
					    // reading value in address field 
                        next_state    = POLL_1;                       // Poll for 1 operation
					    fsm_o_valid   = 1;                            // Indicate valid FSM operation
                        fsm_o_rd_wr   = 0;                            // Specify read operation
                        fsm_o_addr    = {cmd_out[61:32], 2'b00};      // Write address
                        fsm_o_wr_data = 32'b0;                        // Write data
						cmd_rd_en     = 'b0;
						current_cmd_addr = 'b0; 
						active_trig_comb = active_trig;
                    end else if (cmd_out[63:62] == 2'b11) begin
					    // reading value in address field 
                        next_state    = POLL_0;                        // Poll for 0 operation
					    fsm_o_valid   = 1;                             // Indicate valid FSM operation
                        fsm_o_rd_wr   = 0;                             // Specify read operation
                        fsm_o_addr    = {cmd_out[61:32], 2'b00};       // Write address
                        fsm_o_wr_data = 32'b0;                         // Write data
					    cmd_rd_en     = 'b0;
						current_cmd_addr = 'b0; 
						active_trig_comb = active_trig;
                    end else begin
                        next_state = IDLE;                // Unknown command; return to idle
	                    fsm_o_valid   = 'b0;                 
                        fsm_o_rd_wr   = 'b0;                
                        fsm_o_addr    = 'b0;                
                        fsm_o_wr_data = 'b0;                 
						cmd_rd_en     = 'b0;
						current_cmd_addr = 'b0; 
						active_trig_comb = 'b0;
                    end					
                end else begin
                    // No valid command data or Slave not ready ; remain in FETCH_CMD state
                    next_state = FETCH_CMD;
				    fsm_o_valid   = 'b0;                 
                    fsm_o_rd_wr   = 'b0;                
                    fsm_o_addr    = 'b0;                
                    fsm_o_wr_data = 'b0;                 
				    cmd_rd_en     = 'b1;
				    current_cmd_addr = cmd_addr; 
				    active_trig_comb = active_trig;
                end
            end

            RMW: begin
                // Read-modify-write operation
				reg_rd_en = 'b0;
				fsm_o_wr_data  = 'b0;
				trig_s1_str_addr = trig_s1_str_addr_reg; 
				trig_s2_str_addr = trig_s1_str_addr_reg;
				trig_s3_str_addr = trig_s1_str_addr_reg;
				trig_s4_str_addr = trig_s1_str_addr_reg;
				active_trig_comb = active_trig;	              			
                if (fsm_i_rd_valid && fsm_i_ready) begin 
				    fsm_o_valid = 'b0;                        // Indicate invalid operation
                    fsm_o_rd_wr = 'b0;                     
                    fsm_o_addr  = 'b0;                        // reset Address 
					cmd_rd_en   = 1'b1;                       // Enable command read
                    mask        = cmd_out[31:0];              // Apply mask from data field
                    modified_value   = fsm_i_rd_data & (~mask); // Compute modified value
                    previous_state   = RMW;                   // Save state for later	
					current_cmd_addr = cmd_addr + 8'h2; 						
                    next_state       = FETCH_CMD;             // Move to next command	
				// master not ready of read data not valid 	
                end else begin
			        fsm_o_valid = 'b0;                        // Indicate valid operation
                    fsm_o_rd_wr = 'b0;                        
                    fsm_o_addr  = 'b0;                        // reset Address 
                    cmd_rd_en   = 'b0;                        // No command read
                    mask        = cmd_out[31:0];              // Maintain mask value
                    modified_value   = 32'b0;                 // Compute modified value
                    previous_state   = RMW;                   // Maintain state
                    current_cmd_addr = cmd_addr;					
                    next_state       = RMW;                   // Stay in RMW state
                end
            end

            POLL_1: begin
			    // Poll for 1 operation
				reg_rd_en        = 'b0;
				mask             = 'b0;
                modified_value   = 'b0;
                previous_state   = IDLE;
			    fsm_o_wr_data    = 'b0;
			    trig_s1_str_addr = trig_s1_str_addr_reg; 
				trig_s2_str_addr = trig_s1_str_addr_reg;
				trig_s3_str_addr = trig_s1_str_addr_reg;
				trig_s4_str_addr = trig_s1_str_addr_reg;
				active_trig_comb = active_trig;
                if (fsm_i_ready && fsm_i_rd_valid && ((fsm_i_rd_data & cmd_out[31:0]) == cmd_out[31:0])) begin			
					cmd_rd_en        = 1;                     // Enable command read					
					current_cmd_addr = cmd_addr + 8'h2;       // Increment command address	
                    fsm_o_valid      = 0;                     // Indicate invalid operation
					fsm_o_rd_wr      = 0;                     // Set to read operation
                    fsm_o_addr       = 'b0;                   // reset Address
					next_state       = FETCH_CMD;             // Move to next command
                end else if (fsm_i_ready && fsm_i_rd_valid && ((fsm_i_rd_data & cmd_out[31:0]) == 32'hffff_ffff)) begin   				
					cmd_rd_en        = 1;                     // Enable command read								
					current_cmd_addr = cmd_addr + 8'h2;       // Increment command address
					fsm_o_valid      = 0;                     // Indicate invalid operation
					fsm_o_rd_wr      = 0;                     // Set to read operation
                    fsm_o_addr       = 'b0;                   // reset Address 
					next_state       = FETCH_CMD;             // Move to next command
			    // master not ready or read data not valid
				end else if (!fsm_i_ready || !fsm_i_rd_valid) begin				
					cmd_rd_en        = 0;                     // Enable command read								
					current_cmd_addr = cmd_addr;              // Increment command address
					fsm_o_valid      = 0;                     // Indicate invalid operation
					fsm_o_rd_wr      = 0;                     // Set to read operation
                    fsm_o_addr       = 'b0;                   // reset Address 
					next_state       = POLL_1;                // Move to next command		
				// polling 1 condition failed and master ready 
                end else begin
				    cmd_rd_en        = 0;                     // No command read	
					current_cmd_addr = cmd_addr;              // keep command address (same command)
					fsm_o_valid      = 1;                     // Indicate valid operation
                    fsm_o_rd_wr      = 0;                     // Set to read operation
                    fsm_o_addr       = {cmd_out[61:32], 2'b00};   // Address to poll  
                    next_state       = POLL_1;                // Stay in POLL_0 state					
                end				
            end

            POLL_0: begin	
				// Poll for 0 operation
				reg_rd_en        = 'b0;
				mask             = 'b0;
                modified_value   = 'b0;
                previous_state   = IDLE;
				fsm_o_wr_data    = 'b0;
				trig_s1_str_addr = trig_s1_str_addr_reg; 
				trig_s2_str_addr = trig_s1_str_addr_reg;
				trig_s3_str_addr = trig_s1_str_addr_reg;
				trig_s4_str_addr = trig_s1_str_addr_reg;
				active_trig_comb = active_trig;
                if (fsm_i_ready && fsm_i_rd_valid && ((fsm_i_rd_data & cmd_out[31:0]) == cmd_out[31:0])) begin
					cmd_rd_en        = 1;                     // Enable command read					
					current_cmd_addr = cmd_addr + 8'h2;       // Increment command address	
                    fsm_o_valid      = 0;                     // Indicate invalid operation
					fsm_o_rd_wr      = 0;                     // Set to read operation
                    fsm_o_addr       = 'b0;                   // reset Address
					next_state       = FETCH_CMD;             // Move to next command
                end else if (fsm_i_ready && fsm_i_rd_valid && ((fsm_i_rd_data & cmd_out[31:0]) == 32'h0000_0000)) begin   				
					cmd_rd_en        = 1;                     // Enable command read								
					current_cmd_addr = cmd_addr + 8'h2;       // Increment command address
					fsm_o_valid      = 0;                     // Indicate invalid operation
					fsm_o_rd_wr      = 0;                     // Set to read operation
                    fsm_o_addr       = 'b0;                   // reset Address 
					next_state       = FETCH_CMD;             // Move to next command
				// master not ready or read data not valid
				end else if (!fsm_i_ready || !fsm_i_rd_valid) begin				
					cmd_rd_en        = 0;                     // Enable command read								
					current_cmd_addr = cmd_addr;              // Increment command address
					fsm_o_valid      = 0;                     // Indicate invalid operation
					fsm_o_rd_wr      = 0;                     // Set to read operation
                    fsm_o_addr       = 'b0;                   // reset Address 
					next_state       = POLL_0;                // Move to next command		
				// polling 0 condition failed and master ready 
                end else begin
				    cmd_rd_en        = 0;                     // No command read	
					current_cmd_addr = cmd_addr;              // keep command address (same command)
					fsm_o_valid      = 1;                     // Indicate valid operation
                    fsm_o_rd_wr      = 0;                     // Set to read operation
                    fsm_o_addr       = {cmd_out[61:32], 2'b00};  // Address to poll  
                    next_state       = POLL_0;                // Stay in POLL_0 state					
                end				
            end

            default: begin
                // Default state handling
				mask             = 'b0;
                modified_value   = 'b0;
                previous_state   = IDLE;
				active_trig_comb = 'b0;
				reg_rd_en        = 'b0;
				cmd_rd_en        = 'b0;
                current_cmd_addr = 'b0;
				fsm_o_valid      = 'b0;
                fsm_o_rd_wr      = 'b0;
                fsm_o_addr       = 'b0;
                fsm_o_wr_data    = 'b0;
			    trig_s1_str_addr = 'b0;
	            trig_s2_str_addr = 'b0;
		        trig_s3_str_addr = 'b0;
		        trig_s4_str_addr = 'b0;
                next_state       = IDLE;                   // Transition to IDLE
            end
        endcase
    end
endmodule
