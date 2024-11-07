// APB (Advanced Peripheral Bus) Master Module
module apb_master #(
    parameter ADDR_WIDTH = 32,  // Address width parameter
    parameter DATA_WIDTH = 32   // Data width parameter
) (
    input logic                 i_clk_apb,    // APB clock
    input logic                 i_rstn_apb,   // Active-low reset

    // APB protocol interface signals
    output reg                  o_psel,       // Peripheral select
    output reg                  o_penable,    // Peripheral enable
    output reg                  o_pwrite,     // Write enable (1 for write, 0 for read)
    output reg [ADDR_WIDTH-1:0] o_paddr,      // Address for APB transaction
    output reg [DATA_WIDTH-1:0] o_pwdata,     // Write data for APB
    input logic [DATA_WIDTH-1:0] i_prdata,    // Read data from APB slave
    input logic                 i_pready,     // Ready signal from APB slave
    input logic                 i_pslverr,    // Slave error signal
	
    // Handshaking interface signals
    input logic                 i_valid,      // Transaction valid signal
    output reg                  o_ready,      // Master ready signal
    
    // Transaction signals
    input logic [ADDR_WIDTH-1:0]  i_addr,     // Address from external source
    input logic                 i_rd0_wr1,    // Read/Write control (0 for read, 1 for write)
    input logic [DATA_WIDTH-1:0]  i_wr_data,  // Write data from external source
    output reg                  o_rd_valid,   // Read data valid signal
    output reg [DATA_WIDTH-1:0] o_rd_data     // Read data output
);

reg i_rd0_wr1_reg;                   // registered Read/Write control
reg [ADDR_WIDTH-1:0] i_addr_reg;     // registered address for transaction
reg [DATA_WIDTH-1:0] i_wr_data_reg;  // registered write data

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
	
    // registered input signals when transaction is valid and master is ready
    always @(posedge i_clk_apb or negedge i_rstn_apb) begin
        if (!i_rstn_apb) begin
            i_rd0_wr1_reg <= 1'b0;
            i_addr_reg <= 32'b0;
            i_wr_data_reg <= 32'b0;
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
                    o_pwdata = 32'b0;
                end 
                o_ready = 1'b0;           // Master is busy now
                next_state = ACCESS;      // Move to ACCESS phase
            end

            ACCESS: begin
                // In ACCESS, enable peripheral and check for completion
                o_penable = 1'b1;          // Enable the peripheral for data transfer
                o_psel = 1'b1;             // Select the peripheral
                o_pwrite = i_rd0_wr1_reg;  // Set write/read based on control signal
                o_paddr = i_addr_reg;      // Set address for transaction
				
                if (i_pready) begin        // Wait for slave to be ready
                    if (i_rd0_wr1_reg == 1'b0) begin // read transaction
                        o_rd_data = i_prdata;   // Capture read data from slave
                        o_pwdata = 32'b0;
                        o_rd_valid = 1'b1;      // Indicate valid read data
                    end else begin // Write transaction
                        o_rd_data = 32'b0;
                        o_pwdata = i_wr_data_reg;   // Set write data if it's a write operation
                        o_rd_valid = 1'b0;      
                    end
					
					o_ready = 1'b1;         // Master is ready for next transaction
                    
					if (i_valid) begin // master diver not ready to send new transaction
                        next_state = SETUP;     // Move to SETUP if a new valid transaction is present 
                    end
                    else begin
                        next_state = IDLE;      // Return to IDLE after transaction completes as master driver not valid 
                    end
                end
                else begin
				    o_ready = 1'b0;            // Master is still busy
                    o_rd_data = 32'b0;      // no Capture read data from slave
                    o_pwdata = i_wr_data_reg;
                    o_rd_valid = 1'b0;      // Indicate invalid read data
                    next_state = ACCESS;    // Stay in ACCESS if slave is not ready yet (wait state)
                end
            end

            default: begin
                next_state = IDLE;          // Default state is IDLE
            end
        endcase
    end

endmodule
