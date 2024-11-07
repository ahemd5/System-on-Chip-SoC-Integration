// APB (Advanced Peripheral Bus) Slave Module
module apb_slave #(
    parameter ADDR_WIDTH = 32,     // Address width parameter
              DATA_WIDTH = 32      // Data width parameter
)(
    input  logic                  i_clk_apb,      // APB clock signal
    input  logic                  i_rstn_apb,     // APB active-low reset signal
	
    // APB protocol interface signals
    input  logic                  i_pwrite,       // Write enable signal (1 for write, 0 for read)
    input  logic [DATA_WIDTH-1:0] i_pwdata,       // Write data input
    input  logic [ADDR_WIDTH-1:0] i_paddr,        // Address input
    input  logic                  i_psel,         // Peripheral select (active high)
    input  logic                  i_penable,      // Enable signal for APB transaction
    output logic [DATA_WIDTH-1:0] o_prdata,       // Read data output
    output logic                       o_pslverr,      // Slave error indicator
    output reg                    o_pready,       // Ready signal from slave to master 
	
    // Handshaking interface signals
    output reg                    o_valid,        // Valid transaction signal
    input  logic                  i_ready,        // Ready to new transaction
	
    // Transaction signals
    output reg   [ADDR_WIDTH-1:0] o_addr,         // Address for transaction
    output reg                    o_rd0_wr1,      // Read/write indicator (0 for read, 1 for write)
    output reg   [DATA_WIDTH-1:0] o_wr_data,      // Data to write in write transactions
    input  logic                  i_rd_valid,     // Read valid signal indicating read data is valid  
    input  logic [DATA_WIDTH-1:0] i_rd_data       // Data from read transaction
);

    // FSM states definition
    typedef enum logic [1:0] {
        IDLE   = 2'b00, // Idle state
        READ   = 2'b01, // Read transaction state
        WRITE  = 2'b10  // Write transaction state
    } state_t;

    state_t state, next_state; // Current and next states for FSM
	
    // Default output assignments
    assign o_pslverr = 1'b0;        // Always OKAY, no error response
    assign o_prdata  = (i_rd_valid) ? i_rd_data : 32'b0; // Read data output based on read validity

    // State Machine: sequential logic for state transitions
    always @(posedge i_clk_apb or negedge i_rstn_apb) begin
        if (!i_rstn_apb)
            state <= IDLE;          // Reset to IDLE state
        else
            state <= next_state;    // Move to next state on rising edge clock 
    end

    // State Machine: combinational logic for state decisions
    always @(*) begin

        case (state)
            IDLE: begin
                if (i_psel) begin // If peripheral is selected
                    o_pready = 1'b0;
                    o_addr = i_paddr;         // Capture address
                    o_rd0_wr1 = i_pwrite;

                    if (i_pwrite) begin  // Write transaction
                        o_wr_data = i_pwdata;
                        o_valid = 1'b1;       // Indicate valid transaction
                        next_state = (i_ready) ? WRITE : IDLE;
                    end else begin // Read transaction
                        o_wr_data = i_pwdata; // Don't care in read
                        o_valid = 1'b1;       // Indicate valid transaction
                        next_state = (i_ready) ? READ : IDLE;
                    end
                end else begin // If peripheral is not selected
				    // Ready without valid transaction
                    o_pready = 1'b1; 
					o_valid = 1'b0;
                    o_addr = i_paddr;
                    o_rd0_wr1 = i_pwrite;
                    o_wr_data = i_pwdata;
					next_state = IDLE ;       // Return to idle state
                end
            end

            READ: begin
                o_addr = i_paddr;
                o_rd0_wr1 = i_pwrite;
                o_wr_data = i_pwdata;  // Write data not used in read (Don't care)
                o_valid = 1'b1;        // valid transaction
				
                if (i_rd_valid && i_penable) begin // If read data is valid and enabled
                    o_pready = 1'b1;   // Transaction completed
                    next_state = IDLE; // Return to idle state
                end else begin
                    o_pready = 1'b0;   // Transaction not yet complete
                    next_state = READ; // Return to read state (wait state)
                end
            end

            WRITE: begin
                o_addr = i_paddr;
                o_rd0_wr1 = i_pwrite;
                o_wr_data = i_pwdata;
                o_valid = 1'b1;         // valid transaction

                if (i_penable) begin // Transaction enabled
                    o_pready = 1'b1;    // Transaction completed
                    next_state = IDLE;  // Return to idle state
                end else begin
                    o_pready = 1'b0;    // Transaction not yet complete
                    next_state = WRITE; // Return to write state (wait state)
                end
            end
			
            default: next_state = IDLE; // Default to IDLE state
        endcase
    end

endmodule
