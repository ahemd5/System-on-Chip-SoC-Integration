module fsm_pd1  // M= wakeup srcs
(   //interface with AON domain
    input  logic       i_aon_clk,                // Always-on running clock
    input  logic       i_soc_pwr_on_rst,         // Active-high main reset signal for the SoC
    //interface with RF
    input  logic       i_wakeup_req_1,           // wakeup request for PD1 
    input  logic       i_wakeup_req_2,           // wakeup req for PD2 ; necessary to be checked if both PDs are off
    input  logic       i_sleep_req,              // bit[0] sleep request resgister 
    input  logic       i_pwrgate_en,             // Power Gating Enable Register 
    output logic       o_d_status,               // current power status of domain 1
    //interface with PD2 FSM 
    input   logic      i_pwr_on_ack_2 ,     // indicate ON/OFF of PD2
    output  logic      o_pwr_off_req2,      // sleep req for PD2 incase of PD1 is off 
    //interface with PD1
    input   logic    i_hw_sleep_ack,        // Sleep ack from PDs that are in IDLE
    input   logic    i_pwr_on_ack,          // Active-high acknowledgment signals from power switches of domain[N]
    output  logic    o_dcdc_enable,         // Asserted during SoC power-ON or when waking up from sleep mode, after a programmable delay
    output  logic    o_hw_sleep_req,        // Sleep request  for each PD to transition into IDLE state 
    output  logic    o_pwr_on_req ,         // Active-high power-on request to enable pow switch for each domain
    output  logic    o_clk_en,              // Active-high signals enabling clocks for all modules within a PD
    output  logic    o_iso,                 // Active-high isolation enable for all domain outputs
    output  logic    o_ret,                 // Active-high retention enable for flip-flops or memory within the PD
                                            // Rising edge: Trigger for save operation, Falling edge: Trigger for restore operation							
    output  logic    o_rstn ,               // Active-low global reset for each PD
	// for test 
	output  wire    [2:0] c_s  
);


assign o_d_status =(i_hw_sleep_ack && ~i_pwr_on_ack) ? 1'b0: 1'b1;


typedef enum logic [2:0] {
    RESET      = 3'b000,
    IDLE       = 3'b001,
    SLEEP_INIT = 3'b011,//waiting sleep ack
    SLEEP      = 3'b010,
    RUN_INIT   = 3'b110 //waiting wake up ack
} state_t;
state_t current_state, next_state;




always @(posedge i_aon_clk or posedge i_soc_pwr_on_rst) begin
    if(i_soc_pwr_on_rst) begin
        current_state <= RESET;
    end else begin
        current_state <= next_state;
    end
end



//next state logic:
always @(*) begin
    case(current_state)
    
		RESET: begin
		    next_state = IDLE;
		end
    
		IDLE: begin //PD1 is ON at idle case
			if(i_sleep_req && ~i_hw_sleep_ack) 
				next_state = SLEEP_INIT;
			else
			   next_state = IDLE;
		end

		SLEEP_INIT: begin
			if(i_hw_sleep_ack && ~i_pwr_on_ack_2 ) //PD2 completely off
				next_state = SLEEP;
			else 
				next_state = SLEEP_INIT;
		end

	    SLEEP: begin
			if(~i_pwr_on_ack && ~i_sleep_req && (i_wakeup_req_1 || i_wakeup_req_2) && i_pwrgate_en) begin
			// If PD1 & PD2 OFF, then wakeup src for PD2-only -> power-on PD1 first before power-on PD2
				next_state = RUN_INIT; 
			end else if(~i_sleep_req && (i_wakeup_req_1 || i_wakeup_req_2) && ~i_pwrgate_en) begin 
				next_state = IDLE; 
			end else if (~i_pwr_on_ack && i_sleep_req && (i_wakeup_req_1 || i_wakeup_req_2) && i_pwrgate_en) begin
			    next_state = RUN_INIT;
			end else if (i_pwr_on_ack) begin
				next_state = SLEEP; 
			end 	
	    end
	  
		RUN_INIT: begin
			if(i_pwr_on_ack) begin 
				next_state = IDLE; 
			end else 
				next_state = RUN_INIT; 
		end

        default : next_state = IDLE;
		
    endcase
end

// output logic:
always @(*) begin	  
    case(current_state)

        RESET: begin
			o_clk_en  =1'b1;
			o_iso = 1'b0;
			o_ret = 1'b0;
			o_rstn = 1'b0;         // to reset domain at first time soc on 
			o_pwr_on_req = 1'b1;
			o_dcdc_enable = 1'b1;
			
			o_pwr_off_req2 = 1'b1;
			o_hw_sleep_req = 1'b0;
        end
        
        IDLE: begin  //PD0 AON, PD1 ON , PD2 OFF
			//no change   
            o_clk_en=1'b1;
			o_iso=1'b0;
			o_ret=1'b0;
			//toggle
			o_rstn=1'b1;
			o_pwr_on_req=1'b1;
			o_dcdc_enable=1'b1;
			
			//PD2 ON/OFF
			if(~i_pwr_on_ack_2 && i_wakeup_req_2)
			    o_pwr_off_req2=1'b0;
			else
		 	    o_pwr_off_req2=1'b1;
			
			o_hw_sleep_req=1'b0;
        end

        SLEEP_INIT: begin   
			if(~i_pwr_on_ack_2) begin 
				o_pwr_off_req2=0;
				o_hw_sleep_req=1'b1; 
				o_dcdc_enable=1'b1;
				o_pwr_on_req=1'b1;
				o_rstn=1'b1;
				o_ret=1'b0;
				o_iso=1'b0;
				o_clk_en=1'b1;
			end else begin
			    o_pwr_off_req2=1;
				o_hw_sleep_req=1'b0;
				o_dcdc_enable=1'b1;
				o_pwr_on_req=1'b1;
				o_rstn=1'b1;
				o_ret=1'b0;
				o_iso=1'b0;
				o_clk_en=1'b1;
			end
         end
	  
		SLEEP: begin
			//no change from previous state
			o_hw_sleep_req = 1'b1; //to PD1
			o_pwr_off_req2 = 1;    //to PD2
			//toggle:
			o_clk_en=1'b0;
			o_rstn=1'b0;
			//No clock gating
			if(i_pwrgate_en) begin
				o_pwr_on_req=1'b0;
				o_iso=1'b1;
				o_ret=1'b1;
			end else begin //undergo clock gating and a reset cycle without being powered off.
				o_pwr_on_req=1'b1;
				o_ret=1'b0;
				o_iso=1'b0;
			end 
			o_dcdc_enable=1'b0; //De-asserted if and only-if SoC enters sleep mode & since PD1 OFF -> PD2 OFF
	    end
	  
		RUN_INIT: begin
			o_pwr_on_req=1'b1;
			 //no change in the following signals
			o_dcdc_enable=1'b0;
			o_clk_en=1'b0;
			o_iso=1'b1;
			o_ret=1'b1;
			o_rstn=1'b0;
			o_hw_sleep_req=1'b1;
			o_pwr_off_req2=1'b1;
		end
	  
		 default: begin //idle case
			o_dcdc_enable=1'b1;
			o_pwr_on_req=1'b1;
			o_hw_sleep_req=1'b0;
			o_pwr_off_req2=1'b1;
			o_rstn=1'b1;
			o_ret=1'b0;
			o_iso=1'b0;
			o_clk_en   =1'b1;
		 end
	  
    endcase
end  


// for test
assign c_s = current_state;
  
  
endmodule
