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
module apb_slave #(
     parameter addr_width = 32,     // Address width parameter
               data_width = 32      // Data width parameter
)(
    input  logic                  i_clk_apb,
    input  logic                  i_rstn_apb,
    input  logic                  i_pwrite,
    input  logic [data_width-1:0] i_pwdata,
    input  logic [addr_width-1:0] i_paddr,
    input  logic                  i_psel,
    input  logic                  i_penable,
    output       [data_width-1:0] o_prdata,
    output                        o_pslverr,
    output reg                    o_pready,

    output reg                    o_valid,
    input  logic                  i_ready,
    output reg   [addr_width-1:0] o_addr,
    output reg                    o_rd0_wr1,
    output reg   [data_width-1:0] o_wr_data,
    input  logic                  i_rd_valid,
    input  logic [data_width-1:0] i_rd_data
);

	// FSM states
    typedef enum logic [1:0] {
        IDLE   = 2'b00, // Idle state
        READ  = 2'b01,  // read state
        WRITE = 2'b10   // write state 
    } state_t;

    state_t state, next_state;
	
    // Default outputs
    assign o_pslverr = 1'b0;        // Always OKAY, no error
    assign o_prdata  = (i_rd_valid) ? i_rd_data : 32'b0;

    // State Machine
    always @(posedge i_clk_apb or negedge i_rstn_apb) begin
        if (!i_rstn_apb)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        o_valid = 1'b0;
        o_addr = 32'b0;
        o_rd0_wr1 = 1'b0;
        o_wr_data = 32'b0;
        case (state)
            IDLE: begin
                o_pready = 1'b1;
				if (i_psel) begin
                    o_addr = i_paddr;
                    o_valid = 1'b1;
                    if (i_pwrite) begin
                        o_rd0_wr1 = 1'b1; // Write operation
                        o_wr_data = i_pwdata;
                        next_state = (i_ready) ? WRITE : IDLE;
                    end else begin
                        o_rd0_wr1 = 1'b0; // Read operation
                        next_state = (i_ready) ? READ : IDLE;
                    end
                end
            end

            READ: begin
                if (i_rd_valid && i_penable) begin
				    o_pready = 1'b1;
                    o_valid = 1'b0;
                    next_state = IDLE;
                end else begin
				    o_pready = 1'b0;
                    o_valid = 1'b1;
                end
            end

            WRITE: begin
                if (i_ready && i_penable) begin
				    o_pready = 1'b1;
                    o_valid = 1'b0;
                    next_state = IDLE;
                end else begin
                    o_valid = 1'b1;
					o_pready = 1'b0;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
