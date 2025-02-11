module counter_PD1 #(parameter N=2)(
    input  logic           i_aon_clk,      
    input  logic           i_soc_pwr_on_rst,  

    input  logic [3:0]     pwr_off_seq_delay, //Delay between control events during the power-of sequence       
    input  logic [3:0]     pwr_on_seq_delay, //Delay between control events during the power-on sequence
   
    input  logic   o_pwr_on_req_fsm, 
    input  logic   i_pwr_on_ack,
	input  logic   sleep_req,
    input  logic   i_hw_sleep_ack,
    input  logic   i_iso,          // Input for isolation enable
    input  logic   i_ret,          // Input for retention enable
    input  logic   i_rstn,         // Input for reset
    input  logic   i_clk_en,       // Input for clock enable
	
    output logic    o_iso,          // Delayed isolation enable
    output logic    o_ret,          // Delayed retention enable
    output logic    o_rstn,          // Delayed reset 
    output logic    o_clk_en,        // Delayed clock enable
	output  logic   o_pwr_on_req
);

    wire on_flag , off_flag , off_flag_npgate ;    

    // Registers to store the delay counters for each output
    logic [3:0] delay_counter;

    logic  delayed_iso;
    logic  delayed_ret;
    logic  delayed_rstn;
    logic  delayed_clk_en;
    logic  delayed_o_pwr_on_req;
	
	assign off_flag = (i_hw_sleep_ack /*&& sleep_req*/ && ~i_clk_en && i_iso && i_ret && ~i_rstn && ~o_pwr_on_req_fsm); 
    assign on_flag = (i_pwr_on_ack && ~sleep_req && i_clk_en && ~i_iso && ~i_ret && i_rstn); 
	assign off_flag_npgate = (i_hw_sleep_ack && ~i_clk_en && ~i_iso && ~i_ret && ~i_rstn ) ;
	
	
    always_ff @(posedge i_aon_clk or posedge i_soc_pwr_on_rst) begin
        if (i_soc_pwr_on_rst ) begin
			delay_counter <= 4'b0;
            delayed_iso <= 'b0;
            delayed_ret <= 'b0;
            delayed_rstn <= 'b1;
            delayed_clk_en <='b1;
            delayed_o_pwr_on_req <= 'b1;
        end 
		else if(~i_soc_pwr_on_rst && (off_flag || off_flag_npgate) && pwr_off_seq_delay == 1 && ~o_clk_en) begin		
			delayed_clk_en<=0;
			// Delay for o_iso
			if (delay_counter < pwr_off_seq_delay ) begin
				delayed_iso <= i_iso;
				delay_counter <= delay_counter + 1;
			// Delay for o_ret	
			end else if (delay_counter > pwr_off_seq_delay - 1 && delay_counter < 2*pwr_off_seq_delay ) begin
				delayed_ret <= i_ret;
				delay_counter <= delay_counter + 1;			
			// Delay for o_rstn
			end else if (delay_counter > 2*pwr_off_seq_delay -1 && delay_counter < 3*pwr_off_seq_delay ) begin
				delayed_rstn <= i_rstn;
				delay_counter <= delay_counter + 1;				
			end else if (delay_counter > 3*pwr_off_seq_delay -1 && delay_counter < 4*pwr_off_seq_delay ) begin
				delayed_o_pwr_on_req <= o_pwr_on_req_fsm;
				delay_counter <= 0 ;				
			end /*else if (delay_counter > 4*pwr_off_seq_delay -1 && delay_counter < 5*pwr_off_seq_delay ) begin
				delay_counter <= delay_counter + 1;
			end else if (delay_counter > 5*pwr_off_seq_delay -1 ) begin	
				delay_counter <= delay_counter + 1;
			end */	
	    end
        else if(~i_soc_pwr_on_rst && (off_flag || off_flag_npgate) ) begin		
			// Delay for o_clk_en	
			if (delay_counter < pwr_off_seq_delay ) begin
			    delayed_clk_en <= i_clk_en;
				delay_counter <= delay_counter + 1;
			// Delay for o_iso
			end else if (delay_counter > pwr_off_seq_delay - 1 && delay_counter < 2*pwr_off_seq_delay ) begin
				delayed_iso <= i_iso;
				delay_counter <= delay_counter + 1;
			// Delay for o_ret	
			end else if (delay_counter > 2*pwr_off_seq_delay -1 && delay_counter < 3*pwr_off_seq_delay ) begin
				delayed_ret <= i_ret;
				delay_counter <= delay_counter + 1;
			// Delay for o_rstn	
			end else if (delay_counter > 3*pwr_off_seq_delay -1 && delay_counter < 4*pwr_off_seq_delay ) begin
				delayed_rstn <= i_rstn;
				delay_counter <= delay_counter + 1;
			end else if (delay_counter > 4*pwr_off_seq_delay -1 && delay_counter < 5*pwr_off_seq_delay ) begin
				delayed_o_pwr_on_req <= o_pwr_on_req_fsm;
				delay_counter <= 0 ;
			end /*else if (delay_counter > 5*pwr_off_seq_delay -1 ) begin	
				delay_counter <= delay_counter + 1;
			end */	
	    end
		else if (~i_soc_pwr_on_rst && on_flag && pwr_on_seq_delay == 1 && o_rstn ) begin
			delayed_rstn <= 1'b1;
			// Delay for o_ret		
			if (delay_counter < pwr_on_seq_delay ) begin
				delayed_ret <= i_ret;
				delay_counter <= delay_counter + 1;			
			// Delay for o_iso
			end else if (delay_counter > pwr_on_seq_delay - 1 && delay_counter < 2*pwr_on_seq_delay  ) begin
				delayed_iso <= i_iso;
				delay_counter <= delay_counter + 1;
			// Delay for o_clk_en
			end else if (delay_counter > 2*pwr_on_seq_delay -1 && delay_counter < 3*pwr_on_seq_delay  ) begin
				delayed_clk_en <= i_clk_en;
				delay_counter <= 0;								
			end /*else if (delay_counter > 3*pwr_on_seq_delay -1 && delay_counter < 4*pwr_on_seq_delay  ) begin
				delay_counter <= delay_counter + 1;
			end else if (delay_counter > 4*pwr_on_seq_delay -1 && delay_counter < 5*pwr_on_seq_delay  ) begin
				delay_counter <= delay_counter + 1;
			end */		
        end		
		else if (~i_soc_pwr_on_rst && on_flag ) begin
			// Delay for o_rstn		
			if (delay_counter < pwr_on_seq_delay ) begin
				delayed_rstn <= i_rstn;
				delay_counter <= delay_counter + 1;
			// Delay for o_ret
			end else if (delay_counter > pwr_on_seq_delay - 1 && delay_counter < 2*pwr_on_seq_delay  ) begin
				delayed_ret <= i_ret;
				delay_counter <= delay_counter + 1;
			// Delay for o_iso
			end else if (delay_counter > 2*pwr_on_seq_delay -1 && delay_counter < 3*pwr_on_seq_delay  ) begin
				delayed_iso <= i_iso;
				delay_counter <= delay_counter + 1;
			// Delay for o_clk_en	
			end else if (delay_counter > 3*pwr_on_seq_delay -1 && delay_counter < 4*pwr_on_seq_delay  ) begin
				delayed_clk_en <= i_clk_en;
				delay_counter <= 0;
			end /*else if (delay_counter > 4*pwr_on_seq_delay -1 && delay_counter < 5*pwr_on_seq_delay  ) begin
				delay_counter <= delay_counter + 1;
			end */		
        end
		else if (~sleep_req) begin
            delayed_o_pwr_on_req <= o_pwr_on_req_fsm;
			delay_counter <= 0;
		end else begin		
		    delay_counter <= 0;
	    end
		
		/*if (~i_soc_pwr_on_rst && ~(off_flag || off_flag_npgate) && pwr_off_seq_delay == 1 && ~on_flag) begin
		    delayed_clk_en <= 'b0;
		end
		*/
		
    end
				
    assign o_iso = delayed_iso;
    assign o_ret = delayed_ret;
    assign o_rstn = (pwr_on_seq_delay == 1 && i_pwr_on_ack && i_clk_en && ~ off_flag && on_flag ) ? i_rstn : delayed_rstn;
    assign o_clk_en = (pwr_off_seq_delay == 1 && i_hw_sleep_ack && ~i_clk_en && ~ on_flag && off_flag) ? i_clk_en :delayed_clk_en;
	assign o_pwr_on_req = delayed_o_pwr_on_req;

endmodule
