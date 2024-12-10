module fsm_pd2 (
    // Interface with AON domain
    input  logic       i_aon_clk,                // Always-on running clock
    input  logic       i_soc_pwr_on_rst,         // Active-high SoC reset
    // Interface with RF
    input  logic       i_wakeup_req,           // Wakeup request for PD2
    input  logic       i_sleep_req,              // Sleep request register for PD2
    input  logic       i_pwrgate_en,             // Power gating enable
    // Interface with PD1 FSM
    input  logic        i_pwr_off_req2,          // Power-off req from PD1
    // Interface with PD2
    input  logic       i_pwr_on_ack,           // Power-on acknowledgment from PD2
    input  logic       i_hw_sleep_ack,         // Sleep acknowledgment from PD2
    output logic       o_pwr_on_req,           // Power-on request for PD2
    output logic       o_hw_sleep_req,         // Sleep request for PD2
    output logic       o_clk_en,               // Clock enable for PD2 modules
    output logic       o_iso,                  // Isolation enable for PD2 outputs
    output logic       o_ret,                  // Retention enable for PD2 flip-flops
    output logic       o_rstn                  // Active-low reset for PD2
);

typedef enum logic [2:0] {
    RESETT      = 3'b000,
    IDLE_OFF    = 3'b001, // PD2 powered off
    RUN_INIT    = 3'b010, // Wakeup initialization
    RUN_ON      = 3'b011, // PD2 running/on
    SLEEP_INIT  = 3'b100 // Sleep initialization
} state_t;

// State variables
state_t current_state, next_state;

assign o_d_status =(i_hw_sleep_ack && ~i_pwr_on_ack) ? 1'b0: 1'b1;


// State transition logic
always @(posedge i_aon_clk or posedge i_soc_pwr_on_rst) begin
    if (i_soc_pwr_on_rst) begin
        current_state <= RESET;
    end else begin
        current_state <= next_state;
    end
end

// Next state logic
always @(*) begin
    case (current_state)
       RESET: begin
        next_state = IDLE_OFF;
       end
        IDLE_OFF: begin
            //  PD1 is powered on first
            if (i_wakeup_req && ~i_pwr_off_req2 && ~i_sleep_req && ~i_pwr_on_ack)
                next_state = RUN_INIT;
            else 
                next_state = IDLE_OFF;
        end
        RUN_INIT: begin
            if (i_pwr_on_ack)
                next_state = RUN_ON;
            else 
                next_state = RUN_INIT;
        end
        RUN_ON: begin
            if ((i_sleep_req || i_pwr_off_req2) && ~i_hw_sleep_ack)
                next_state = SLEEP_INIT;
            else 
                next_state = RUN_ON;
        end
        SLEEP_INIT: begin
            if (i_hw_sleep_ack)
                next_state = IDLE_OFF;
            else 
                next_state = SLEEP_INIT;
        end

        default: next_state = IDLE_OFF;
    endcase
end

// Output logic
always @(*) begin
    case (current_state)
        RESET: begin
            o_pwr_on_req = 1'b0;
            o_hw_sleep_req = 1'b1;
            o_clk_en = 1'b0;
            o_iso = 1'b0;
            o_ret = 1'b0;
            o_rstn = 1'b0;
        end
        IDLE_OFF: begin
            o_pwr_on_req = 1'b0;
            o_hw_sleep_req = 1'b1;
            o_clk_en = 1'b0;
            o_iso=1'b1;
            o_ret=1'b1;
            o_rstn = 1'b0;
        end
        RUN_INIT: begin
            //toogle
            o_pwr_on_req = 1'b1;  
            //no change 
            o_hw_sleep_req = 1'b1;
            o_clk_en = 1'b0;
            o_iso=1'b1;
            o_ret=1'b1;
            o_rstn = 1'b0;
        end
        RUN_ON: begin
            //toggle
            o_clk_en = 1'b1;     
            o_rstn = 1'b1; 
            o_iso = 1'b0;       
            o_ret = 1'b0; 
            o_hw_sleep_req=1'b0;
            //no change
            o_pwr_on_req=1'b1;

        end
        SLEEP_INIT: begin
            //toggle
            o_hw_sleep_req = 1'b1; 
            //no change
            o_pwr_on_req=1'b1;
            o_clk_en = 1'b1;     
            o_rstn = 1'b1; 
            o_iso = 1'b0;       
            o_ret = 1'b0; 
        end
        default : begin
            o_pwr_on_req = 1'b0;
            o_hw_sleep_req = 1'b1;
            o_clk_en = 1'b0;
            o_iso=1'b1;
            o_ret=1'b1;
            o_rstn = 1'b0;
        end


    endcase
end
endmodule
  