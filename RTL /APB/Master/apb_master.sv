/////////////////////////////////////////////////////////////////////////////////////
// Engineer: - Mohamed Ahmed 
//           - Mostafa Akram 
//
// Create Date:    20/10/2024 
// Design Name:    apb_slave
// Module Name:    apb - Behavioral 
// Project Name:   System-on-Chip (SoC) Integration
// Tool versions:  Questa Sim-64 2021.1
// Description:     
//                 APB Slave module for System-on-Chip Integration project.
//
// Additional Comments: 
//
/////////////////////////////////////////////////////////////////////////////////////
module apb_master #(
    parameter addr_width = 32,  // Address width parameter
    parameter data_width = 32   // Data width parameter
) ( 
    input logic                 i_clk_apb,    // APB clock
    input logic                 i_rstn_apb,   // Active-low reset
    input logic                 i_valid,      // Transaction valid signal
    output reg                  o_ready,      // Master ready signal

    // APB Interface signals
    output reg                  o_psel,       // Peripheral select
    output reg                  o_penable,    // Peripheral enable
    output reg                  o_pwrite,     // Write enable (1 for write, 0 for read)
    output reg [addr_width-1:0] o_paddr,      // Address for APB transaction
    output reg [data_width-1:0] o_pwdata,     // Write data for APB
    input logic [data_width-1:0] i_prdata,    // Read data from APB slave
    input logic                 i_pready,     // Ready signal from APB slave
    input logic                 i_pslverr,    // Slave error signal
    
    // Control Interface signals
    input logic [addr_width-1:0]  i_addr,     // Address from external source
    input logic                 i_rd0_wr1,    // Read/Write control (0 for read, 1 for write)
    input logic [data_width-1:0]  i_wr_data,  // Write data from external source
    output reg                  o_rd_valid,   // Read data valid signal
    output reg [data_width-1:0] o_rd_data     // Read data output
);

reg i_rd0_wr1_reg ;
reg [addr_width-1:0] i_addr_reg ;
reg [data_width-1:0] i_wr_data_reg ; 

    // FSM states
    typedef enum logic [1:0] {
        IDLE   = 2'b00,  // Idle state
        SETUP  = 2'b01,  // Setup state
        ACCESS = 2'b10   // Access state (read/write operation)
    } state_t;

    state_t state, next_state;

    // State transition logic (Sequential block)
    always @(posedge i_clk_apb or negedge i_rstn_apb) begin
        if (!i_rstn_apb) begin
            state <= IDLE;  // Reset state is IDLE
        end 
        else begin
            state <= next_state;  // Move to the next state on each clock cycle
        end
    end
	
	always @(posedge i_clk_apb or negedge i_rstn_apb) begin
        if (!i_rstn_apb) begin
            i_rd0_wr1_reg <= 'b0;
			i_addr_reg <= 'b0;
			i_wr_data_reg <= 'b0;
        end else if (o_ready && i_valid) begin
            i_rd0_wr1_reg <= i_rd0_wr1;
			i_addr_reg <= i_addr;
			i_wr_data_reg <= i_wr_data;
        end
    end

    // Combinational logic block for FSM and output logic
    always @(*) begin
	
        case (state)
            IDLE: begin
			    // Default values for all outputs
                o_psel = 1'b0;
                o_penable = 1'b0;
                o_pwrite = 1'b0;
                o_rd_valid = 1'b0;
                o_rd_data = 32'b0;
                o_paddr = 32'b0;
                o_pwdata = 32'b0;
                o_ready = 1'b1;  // Master is ready by default
                // In IDLE, wait for valid transaction
                if (i_valid) begin
                    next_state = SETUP;  // Move to SETUP when transaction is valid
                end
                else begin
                    next_state = IDLE;  // Stay in IDLE if no valid transaction
                end
            end

            SETUP: begin
                // In SETUP, configure APB signals for read/write operation
                o_penable = 1'b0;
                o_rd_valid = 1'b0;
                o_rd_data = 32'b0;
                o_psel = 1'b1;                  // Select the peripheral
                o_pwrite = i_rd0_wr1_reg;       // Set write/read based on control signal
                o_paddr = i_addr_reg;           // Set address for transaction
				if (i_rd0_wr1_reg == 1'b1) begin
                    o_pwdata = i_wr_data_reg;   // Set write data if it's a write operation
				end else begin
				    o_pwdata = 'b0 ;
				end 
                o_ready = 1'b0;           // Master is busy now
                next_state = ACCESS;      // Move to ACCESS phase
            end

            ACCESS: begin
                // In ACCESS, enable peripheral and check for completion
                o_penable = 1'b1;          // Enable the peripheral for data transfer
                o_ready = 1'b0;            // Master is still busy
                o_psel = 1'b1;             // Select the peripheral
				o_pwrite = i_rd0_wr1_reg;  // Set write/read based on control signal
                o_paddr = i_addr_reg;      // Set address for transaction
                if (i_pready) begin        // Wait for slave to be ready
                    if (i_rd0_wr1_reg == 1'b0) begin
                        o_rd_data = i_prdata;   // Capture read data from slave
						o_pwdata = 'b0 ;
                        o_rd_valid = 1'b1;      // Indicate valid read data
                    end else begin
					    o_rd_data = 'b0 ;
                        o_pwdata = i_wr_data_reg;   // Set write data if it's a write operation
					    o_rd_valid = 1'b0;      
				    end
                    if (i_valid) begin
					    o_ready = 1'b1;         // Master is ready for next transaction
                        next_state = SETUP;     // Move to SETUP if a new valid transaction is present 
                    end
                    else begin
					    o_ready = 1'b0;
                        next_state = IDLE;      // Return to IDLE after transaction completes
                    end
                end
                else begin
				    o_rd_data = 'b0;   // Capture read data from slave
				    o_pwdata = 'b0 ;
                    o_rd_valid = 1'b0;      // Indicate valid read data
                    next_state = ACCESS;        // Stay in ACCESS if slave is not ready yet
                end
            end

            default: begin
                next_state = IDLE;              // Default state is IDLE
            end
        endcase
    end

endmodule