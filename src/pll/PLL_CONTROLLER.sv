

module pll_controller (

    input wire i_clk_ahb,               // Clock input (renamed from clk)
    input wire [31:0] i_address,        // 32-bit input address
    input wire i_rd0_wr1,               // Read (0) / Write (1) signal
    input wire [31:0] i_wr_data,        // Data to be written into memory
    input wire I_valid,                 // Valid signal for transaction
    output reg [31:0] o_rd_data,        // Data read from memory
    output reg o_rd_valid,              // Read valid signal
    output wire o_ready,                // Ready signal, always asserted

	


    input  wire         xo_clk,         // Reference clock (crystal oscillator)
    input  wire         reset_n,        // Active-low reset
    input  wire         pll_locked,     // PLL lock status
    input  wire         pll_error,      // PLL error signal
    input  wire [31:0]  pll_lock_timeout, // Timeout value for lock detection

    output reg          soc_clk_select, // Selects system clock (PLL or xo_clk)
    output reg          pll_enable,     // Enable PLL
    output reg          pll_bypass,     // Bypass PLL
    output reg          pll_reset,      // PLL reset
    output logic  [7:0]   pll_div,        // PLL division factor
    output logic   [7:0]   pll_mul         // PLL multiplication factor
);

  
	
	  
	// ahb slave intrrface 
	
	reg [31:0] memory_array [0:4];
	
	
    wire [31:0] addr ;
    assign addr=i_address/4;
 
    assign o_ready = 1;

    always @(posedge i_clk_ahb or negedge reset_n) begin
    
    
    
    
    
  
    
    
   
      
      
        memory_array[2][0] <= pll_locked;
       memory_array[2][1] <= pll_error;
       memory_array[4][0] <=0;
       
      
        if (I_valid) begin
            if (i_rd0_wr1) begin
                // Write operation: write data to memory
                memory_array[addr[3:0]] <= i_wr_data; 
                o_rd_valid <= 0; // No read valid signal during write
            end else begin
                // Read operation: read data from memory
                o_rd_data <= memory_array[addr[3:0]]; 
                o_rd_valid <= 1; // Assert read valid
            end
        end else begin // end ivalid
           
            o_rd_valid <= 0; // Deassert read valid
        end // else not i valid
        
        
        
     
        
        
        
    end
	
	


 RisingEdgeDetector dut (
        .i_clk_ahb(i_clk_ahb),
        .reg_20(memory_array[3][0]),
        .edge_detect(edge_detect)
    );
    

 
	
	
	
	assign pll_enable  =  memory_array[0][0];
    assign pll_bypass  = memory_array[0][1];
    assign pll_reset   = memory_array[0][2];
  //  assign pll_div     = (edge_detect)? memory_array[1][7:0] : pll_div;
   // assign pll_mul     = (edge_detect)? memory_array[1][15:8] :  pll_mul ;
   assign pll_mul    = (!reset_n)? 1: ((edge_detect)? memory_array[1][15:8] : pll_mul);
   assign pll_div     = (!reset_n)? 1: ((edge_detect)? memory_array[1][7:0] : pll_div);
   
	   assign soc_clk_select=(!pll_locked || edge_detect ||pll_error)? 0:1;
	
		
   

endmodule

