`timescale 1ns/1ps

module tb_PLL_top_ahb;

    // AHB Interface Signals
    logic                  i_clk_ahb;
    logic                  i_rstn_ahb;
    logic                  i_hready;
    logic [1:0]            i_htrans;
    logic [2:0]            i_hsize;
    logic                  i_hwrite;
    logic [31:0]           i_haddr;
    logic [31:0]           i_hwdata;
    logic                  i_hselx;
    logic                  i_hmastlock;
    logic [3:0]            i_hprot;
    logic [2:0]            i_hburst;

    // AHB Response Signals
    logic                  o_hreadyout;
    logic                  o_hresp;
    logic [31:0]           o_hrdata;

    // PLL System Interface Signals

 
    wire                   clk;

    // Instantiate the PLL_top_ahb module
    PLL_top_ahb uut (
        .i_clk_ahb(i_clk_ahb),
        .i_rstn_ahb(i_rstn_ahb),
        .i_hready(i_hready),
        .i_htrans(i_htrans),
        .i_hsize(i_hsize),
        .i_hwrite(i_hwrite),
        .i_haddr(i_haddr),
        .i_hwdata(i_hwdata),
        .i_hselx(i_hselx),
        .i_hmastlock(i_hmastlock),
        .i_hprot(i_hprot),
        .i_hburst(i_hburst),
        .o_hreadyout(o_hreadyout),
        .o_hresp(o_hresp),
        .o_hrdata(o_hrdata),
        .xo_clk(i_clk_ahb),
        .reset_n(i_rstn_ahb),
        .clk(clk)
    );

    // Clock generation
    always #5 i_clk_ahb = ~i_clk_ahb; // 100 MHz clock

    // Initial block for testbench stimulus
    initial begin
        // Initialize all inputs
        i_clk_ahb = 0;
        i_rstn_ahb = 0;
        i_hready = 0;
        i_htrans = 2'b00;
        i_hsize = 3'b000;
        i_hwrite = 0;
        i_haddr = 32'h00000000;
        i_hwdata = 32'h00000000;
        i_hselx = 0;
        i_hmastlock = 0;
        i_hprot = 4'b0000;
        i_hburst = 3'b000;

    
        #10 i_rstn_ahb = 1;

        // Wait for a few clock cycles
        #30;
        
        
        
        
   
		address(32'h0,1);	
		fork 
		address(32'h4,1);	
		write(32'h00000001);
		join		
		fork
		address(32'hC,1);	
		write({24'b1111, 8'b11});
		join 
		fork
		address(32'hC,1);	
		write(32'h0);
		join
		fork
		write(32'h1);
	idletransaction();
	  join
	
	   
	
		
		
		
		#100;
		 
              // test case bypass 
             //  configure_pll(, );
		// trabsaction
				address(32'h0,1);	
		fork 
		address(32'h4,1);	
		write(32'h00000001);
		join		
		fork
		address(32'hC,1);	
		write({24'b11, 8'b1111});
		join 
		fork
		address(32'hC,1);	
		write(32'h0);
		join
		fork
		write(32'h1);
	idletransaction();
	  join
	  #150;
		// trabsaction
				address(32'h0,1);	
		fork 
		address(32'h4,1);	
		write(32'b00000011);
		join		
		fork
		address(32'hC,1);	
		write({24'b11, 8'b1011});
		join 
		fork
		address(32'hC,1);	
		write(32'h0);
		join
		fork
		write(32'h1);
	idletransaction();
	  join
	  #200;
		$stop;
	end







task address;
	input [31:0] data ;
	input rd_wr;	
	begin 
	   @ (posedge i_clk_ahb);
	   #1;
	  i_htrans = 1;
		i_hselx= 1;
		i_hwrite = rd_wr;
		i_haddr = data;
		  while (o_hreadyout!= 1) begin 
       @ (negedge i_clk_ahb);  
    end  
	end
endtask
task write;
  input [31:0] data ;
  begin 
       @ (posedge i_clk_ahb);
	  
		i_hwdata = data;
		#1;

		
		  while (o_hreadyout!= 1) begin 
       @ (negedge i_clk_ahb);  
    end
  end 
endtask

task idletransaction;
  begin 
    	@ (posedge i_clk_ahb);
		#1;
		  i_htrans = 0;
	   	i_hselx = 0;
	
  end 
endtask
  

        
        
 

 
endmodule

