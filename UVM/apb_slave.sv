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

        case (state)
            IDLE: begin
                if (slv_inter.i_psel) begin // If peripheral is selected
                    slv_inter.o_pready = 1'b0;
                    slv_inter.o_addr = slv_inter.i_paddr;         // Capture address
                    slv_inter.o_rd0_wr1 = slv_inter.i_pwrite;

                    if (slv_inter.i_pwrite) begin  // Write transaction
                        slv_inter.o_wr_data = slv_inter.i_pwdata;
                        slv_inter.o_valid = 1'b1;       // Indicate valid transaction
                        next_state = (slv_inter.i_ready) ? WRITE : IDLE;
                    end else begin // Read transaction
                        slv_inter.o_wr_data = slv_inter.i_pwdata; // Don't care in read
                        slv_inter.o_valid = 1'b1;       // Indicate valid transaction
                        next_state = (slv_inter.i_ready) ? READ : IDLE;
                    end
                end else begin // If peripheral is not selected
                    // Ready without valid transaction
                    slv_inter.o_pready = 1'b1; 
                    slv_inter.o_valid = 1'b0;
                    slv_inter.o_addr = slv_inter.i_paddr;
                    slv_inter.o_rd0_wr1 = slv_inter.i_pwrite;
                    slv_inter.o_wr_data = slv_inter.i_pwdata;
                    next_state = IDLE ;       // Return to idle state
                end
            end

            READ: begin
                slv_inter.o_addr = slv_inter.i_paddr;
                slv_inter.o_rd0_wr1 = slv_inter.i_pwrite;
                slv_inter.o_wr_data = slv_inter.i_pwdata;  // Write data not used in read (Don't care)
                slv_inter.o_valid = 1'b1;        // valid transaction
                
                if (slv_inter.i_rd_valid && slv_inter.i_penable) begin // If read data is valid and enabled
                    slv_inter.o_pready = 1'b1;   // Transaction completed
                    next_state = IDLE; // Return to idle state
                end else begin
                    slv_inter.o_pready = 1'b0;   // Transaction not yet complete
                    next_state = READ; // Return to read state (wait state)
                end
            end

            WRITE: begin
                slv_inter.o_addr = slv_inter.i_paddr;
                slv_inter.o_rd0_wr1 = slv_inter.i_pwrite;
                slv_inter.o_wr_data = slv_inter.i_pwdata;
                slv_inter.o_valid = 1'b1;         // valid transaction

                if (slv_inter.i_penable) begin // Transaction enabled
                    slv_inter.o_pready = 1'b1;    // Transaction completed
                    next_state = IDLE;  // Return to idle state
                end else begin
                    slv_inter.o_pready = 1'b0;    // Transaction not yet complete
                    next_state = WRITE; // Return to write state (wait state)
                end
            end
            
            default: next_state = IDLE; // Default to IDLE state
        endcase
    end
//////////////////////////////////////////////
                //assertions
/////////////////////////////////////////////
property reset_behavior;
   @(posedge slv_inter.i_clk_apb) 
   !slv_inter.i_rstn_apb |-> (state == IDLE);
endproperty

assert property (reset_behavior) else 
   $error("State not IDLE after reset");

property valid_transition_from_idle;
   @(posedge slv_inter.i_clk_apb) disable iff (!slv_inter.i_rstn_apb)
   (state == IDLE && slv_inter.i_psel && slv_inter.i_ready) |-> (next_state == READ || next_state == WRITE);
endproperty

assert property (valid_transition_from_idle) else 
   $error("Invalid state transition from IDLE to non-READ/WRITE state");


property write_state_data_control;
   @(posedge slv_inter.i_clk_apb) disable iff (!slv_inter.i_rstn_apb)
   (state == WRITE &&slv_inter.i_penable) |-> (slv_inter.o_rd0_wr1 == 1'b1 && slv_inter.o_wr_data == slv_inter.i_pwdata);
endproperty

assert property (write_state_data_control) else 
   $error("WRITE state does not set o_rd0_wr1 to 1 or does not pass correct data");


property read_state_data_control;
   @(posedge slv_inter.i_clk_apb) disable iff (!slv_inter.i_rstn_apb)
   (state == READ && slv_inter.i_rd_valid) |-> (slv_inter.o_rd0_wr1 == 1'b0 && slv_inter.o_prdata == slv_inter.i_rd_data);
endproperty

assert property (read_state_data_control) else 
   $error("READ state does not set o_rd0_wr1 to 0 or does not pass correct read data");

property pready_assertion;
   @(posedge slv_inter.i_clk_apb) disable iff (!slv_inter.i_rstn_apb)
   ((state == READ && slv_inter.i_rd_valid && slv_inter.i_penable) || (state == WRITE && slv_inter.i_penable)) |-> (slv_inter.o_pready == 1'b1);
endproperty : pready_assertion

assert property (pready_assertion) else 
   $error("o_pready should only go high during transition to IDLE");


property valid_assertion_in_idle;
   @(posedge slv_inter.i_clk_apb) disable iff (!slv_inter.i_rstn_apb)
   (state == IDLE && slv_inter.i_psel) |-> (slv_inter.o_valid == 1'b1);
endproperty

assert property (valid_assertion_in_idle) else 
   $error("o_valid should be asserted only in IDLE state during transaction initiation");


cover property(reset_behavior);
cover property(valid_transition_from_idle);
cover property(write_state_data_control);
cover property(read_state_data_control);
cover property(pready_assertion);
cover property(valid_assertion_in_idle);

endmodule
