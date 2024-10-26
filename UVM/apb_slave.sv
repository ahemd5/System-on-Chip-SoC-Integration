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
module apb_slave (slave_arb_if.DUT slv_inter);
   
	// FSM states
    typedef enum logic [1:0] {
        IDLE   = 2'b00, // Idle state
        READ  = 2'b01,  // read state
        WRITE = 2'b10   // write state 
    } state_t;

    state_t state, next_state;
	
    // Default outputs
    assign slv_inter.o_pslverr = 1'b0;        // Always OKAY, no error
    // assign slv_inter.o_pready  = (state == IDLE) ? 1'b0 : 1'b1;
    assign slv_inter.o_prdata  = (slv_inter.i_rd_valid) ? slv_inter.i_rd_data : 32'b0;

    // State Machine
    always @(posedge slv_inter.i_clk_apb or negedge slv_inter.i_rstn_apb) begin
        if (!slv_inter.i_rstn_apb)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        slv_inter.o_valid = 1'b0;
        slv_inter.o_addr = 32'b0;
        slv_inter.o_rd0_wr1 = 1'b0;
        slv_inter.o_wr_data = 32'b0;
        case (state)
            IDLE: begin
                slv_inter.o_pready = 1'b1;
				if (slv_inter.i_psel) begin
                    slv_inter.o_addr = slv_inter.i_paddr;
                    slv_inter.o_valid = 1'b1;
                    if (slv_inter.i_pwrite) begin
                        slv_inter.o_rd0_wr1 = 1'b1; // Write operation
                        slv_inter.o_wr_data = slv_inter.i_pwdata;
                        next_state = (slv_inter.i_ready) ? WRITE : IDLE;
                    end else begin
                        slv_inter.o_rd0_wr1 = 1'b0; // Read operation
                        next_state = (slv_inter.i_ready) ? READ : IDLE;
                    end
                end
            end

            READ: begin
                if (slv_inter.i_rd_valid && slv_inter.i_penable) begin
				    slv_inter.o_pready = 1'b1;
                    slv_inter.o_valid = 1'b0;
                    next_state = IDLE;
                end else begin
				    slv_inter.o_pready = 1'b0;
                    slv_inter.o_valid = 1'b1;
                end
            end

            WRITE: begin
                if (slv_inter.i_ready && slv_inter.i_penable) begin
				    slv_inter.o_pready = 1'b1;
                    slv_inter.o_valid = 1'b0;
                    next_state = IDLE;
                end else begin
                    slv_inter.o_valid = 1'b1;
					slv_inter.o_pready = 1'b0;
                end
            end

            default: next_state = IDLE;
        endcase
    end

endmodule
