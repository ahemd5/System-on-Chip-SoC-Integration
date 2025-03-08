module pll_model (
    input  wire        xo_clk,      // Reference clock
    input  wire        reset_n,     // Active-low reset
    input  wire        pll_enable,  // Enable PLL
    input  wire        pll_bypass,  // Bypass PLL
    input  wire        pll_reset,   // Reset PLL
    input  wire [7:0]  pll_mul,     // PLL multiplication factor
    input  wire [7:0]  pll_div,     // PLL division factor
    output reg         pll_clk,     // PLL output clock
    output reg         pll_locked,  // Lock indication
    output wire          pll_error    // Error signal
);


 wire conf;
reg [7:0] prev_mul;
reg [7:0] prev_div;
reg activ;
reg clockout;
assign conf = (    ( |(prev_mul ^ pll_mul))  || ( |(prev_div ^ pll_div)  )    )? 1:0;



    parameter LOCK_DELAY = 3;   // Simulated lock delay in cycles
    parameter LOCK_TIMEOUT = 5; // Timeout for lock failure

    reg [31:0] lock_counter;
    reg [31:0] counter =0; // Clock cycle counter
    localparam integer DEFAULT_DIVISOR = 1; // Default value to prevent division by zero

   real  divisor;
  //  assign divisor = (pll_div != 0) ? ( 1.0* pll_div /    pll_mul  ) : DEFAULT_DIVISOR;
	assign pll_error= ((pll_div==0) && pll_enable )? 1:0;  
	
	
	
	
	
	
	
	
	
clock_generator_model clk_gen (
       
       .period( ((1.0)* pll_div) /    pll_mul ),
        //.period(  (     (pll_div != 0) ? ( 1.0* pll_div /    pll_mul  ) : DEFAULT_DIVISOR  )   ),
       .clk_out(clockout)
    );
    



    
    
    
    
    
    



    // PLL Locking Process (Lock delay mechanism)
    always @(posedge xo_clk or negedge reset_n) begin
        if (!reset_n   ||  pll_reset ||conf ) begin
            pll_locked <= 0;
            lock_counter <= 0;
        end
		
		else if ((pll_enable && pll_bypass) ) begin 
		    pll_locked <= 1;
             
		
		end
		
		
		else if ((pll_enable && activ)) begin
            
            
                if (!pll_locked) begin
                    if (lock_counter < LOCK_DELAY) begin
                        lock_counter <= lock_counter + 1;
                    end else begin
                        pll_locked <= 1;
                        lock_counter <= 0; // for next configs
                    end
                end
            end

		
	
    end // ALWAYS 









   always @(*) begin
        if (!reset_n || pll_reset||  conf) begin
            pll_clk = 0;
        end 
        else begin
            if (pll_enable) begin
                if (pll_bypass) begin
                    pll_clk = xo_clk; // Bypass mode: Directly pass through reference clock
                end 
              else if (pll_locked  ) begin 
            
              //pll_clk =clockout;
              
pll_clk =clockout ;
              end 
                
            end // if penable
        end //else reset 
    end// always 



   
	

	
	   
	
	always @(posedge xo_clk or negedge reset_n) begin    
	prev_mul<= pll_mul;
	prev_div<=pll_div;
	if(conf)
begin
  activ=1;
end  
	end 
	
	

endmodule

