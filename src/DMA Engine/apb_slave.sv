
module apb_slave #(parameter DATA_WIDTH=32,ADDR_WIDTH=32)(
//////////// right side ///////////////////////
output logic [DATA_WIDTH-1:0] o_wr_data,
output logic [ADDR_WIDTH-1:0] o_addr,
input  logic i_rstn_apb,i_clk_apb, 
output logic o_valid, o_rd0_wr1,
input  logic [DATA_WIDTH-1:0] i_rd_data,
input  logic i_rd_valid, i_ready,

////////// left side /////////////
input  logic [DATA_WIDTH-1:0] i_pwdata,
input  logic [ADDR_WIDTH-1:0] i_paddr,
input  logic i_psel, i_penable, i_pwrite,
output logic [DATA_WIDTH-1:0] o_prdata,
output logic o_pslverr, o_pready

);
   
	// FSM states
    typedef enum logic [1:0] {
        IDLE   = 2'b00, // Idle state
        READ  = 2'b01,  // read state
        WRITE = 2'b10   // write state 
    } state_t;

    state_t state, next_state;
	
    // Default outputs
    assign  o_pslverr = 1'b0;        // Always OKAY, no error
    // assign  o_pready  = (state == IDLE) ? 1'b0 : 1'b1;
    assign  o_prdata  = ( i_rd_valid) ?  i_rd_data : 32'b0;

    // State Machine
    always @(posedge  i_clk_apb or negedge  i_rstn_apb) begin
        if (! i_rstn_apb)
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
				if ( i_psel) begin
                     o_addr =  i_paddr;
                     o_valid = 1'b1;
                    if ( i_pwrite) begin
                         o_rd0_wr1 = 1'b1; // Write operation
                         o_wr_data =  i_pwdata;
                        next_state = ( i_ready) ? WRITE : IDLE;
                    end else begin
                         o_rd0_wr1 = 1'b0; // Read operation
                        next_state = ( i_ready) ? READ : IDLE;
                    end
                end
            end

            READ: begin
                if ( i_rd_valid &&  i_penable) begin
				     o_pready = 1'b1;
                     o_valid = 1'b0;
                    next_state = IDLE;
                end else begin
				     o_pready = 1'b0;
                     o_valid = 1'b1;
                end
            end

            WRITE: begin
                if ( i_ready &&  i_penable) begin
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
