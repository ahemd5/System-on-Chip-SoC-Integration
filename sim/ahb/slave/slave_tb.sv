
module AHB_slave_TB;
parameter DATA_WIDTH = 32;
parameter ADDR = 32;
parameter period = 10;
reg                     i_clk_ahb_tb;
reg                     i_rstn_ahb_tb;
reg                     i_hready_tb;
reg                     i_hmastlock_tb;
reg 	                i_htrans_tb;
reg [3:0]               i_hprot_tb;
reg [2:0]               i_hburst_tb;
reg [2:0]               i_hsize_tb;
reg                     i_hwrite_tb;
reg [ADDR-1:0]          i_haddr_tb;
reg [DATA_WIDTH-1:0]    i_hwdata_tb;
reg                     i_hselx_tb;
reg                     i_ready_tb;
reg                     i_rd_valid_tb;
reg [DATA_WIDTH-1:0]    i_rd_data_tb;

// mux 
wire                    o_hreadyout_tb;
wire                    o_hresp_tb;
wire [DATA_WIDTH-1:0]   o_hrdata_tb;
// memory 
wire                    o_valid_tb;
wire                    o_rd0_wr1_tb;
wire [DATA_WIDTH-1:0]   o_wr_data_tb;
wire [ADDR-1:0]         o_addr_tb;
	
reg [31:0] data;
integer i;
   always @(o_hreadyout_tb) begin
        i_hready_tb = o_hreadyout_tb;         
    end

//initial block
initial
	begin

		inititalize();
		reset();
		
	
		
		
		
		// write 
		// first transaction
		address(32'hA,1);	
		fork 
		address(32'hB,0);	
		write(32'haaaa_aaaa);
		join		
		fork
		address(32'hC,1);	
		read(32'hbbbb_bbbb);
		join 
		write(32'hcccc_cccc);
		@ (posedge i_clk_ahb_tb);
		#1;
		  i_htrans_tb = 0;
		i_hselx_tb = 0;
	//second transaction 
		address(32'h38,1);	
		fork 
		address(32'h3C,1);	
		write(32'h38);
		notready();
		join		
		fork
		address(32'h30,1);	
		write(32'h3C);
		join 
		fork
		address(32'h34,1);	
		write(32'h30);
		join 
		write(32'h34);
		@ (posedge i_clk_ahb_tb);
		#1;
		  i_htrans_tb = 0;
	   	i_hselx_tb = 0;
	
	
		
		#100;
		$stop;
	end

task inititalize;
	begin 
	i_htrans_tb = 0;
	i_clk_ahb_tb = 'b0;
	 
	i_hwrite_tb = 'b0;
	i_haddr_tb = 'b0;
	i_hwdata_tb = 'b0;
	i_hselx_tb = 'b0;
	i_ready_tb = 1'b1;				// default memory is ready 
	i_rd_valid_tb  = 'b0;
	i_rd_data_tb  = 'b0;
	i_hburst_tb = 'b000;			// no burst
	i_hmastlock_tb = 'b0;         	// optional feature
	i_hprot_tb = 'b0011;          	// no protection control 'b0011
	i_hsize_tb = 'b010;           	// one word 'b010
	i = 1;
	end
endtask	


task reset;
	begin
		i_rstn_ahb_tb = 1'b1;
		#(period);
		i_rstn_ahb_tb = 1'b0;
		#(4);
		i_rstn_ahb_tb = 1'b1;
	end
endtask
task notready;
  begin 
       @ (posedge i_clk_ahb_tb);
	     #1;
	     i_ready_tb=0;
	      @ (posedge i_clk_ahb_tb);
	      #1;
	       i_ready_tb=1;
	     
  end 
endtask

task address;
	input [31:0] data ;
	input rd_wr;	
	begin 
	   @ (posedge i_clk_ahb_tb);
	   #1;
	  i_htrans_tb = 1;
		i_hselx_tb = 1;
		i_hwrite_tb = rd_wr;
		i_haddr_tb = data;
		  while (o_hreadyout_tb!= 1) begin 
       @ (negedge i_clk_ahb_tb);  
    end  
	end
endtask
task write;
  input [31:0] data ;
  begin 
       @ (posedge i_clk_ahb_tb);
	   #1;
	    i_rd_data_tb = 0;
    	i_rd_valid_tb = 0;	
		i_hwdata_tb = data;
		#1;
				  	if(o_wr_data_tb == data) 
			$display( "Passed Case %0d : expected %h got %h", i, data, o_wr_data_tb );
		else 
			$display( "Failed Case %0d : expected %h got %h", i, data, o_wr_data_tb );
	       	i = i + 1;
		
		  while (o_hreadyout_tb!= 1) begin 
       @ (negedge i_clk_ahb_tb);  
    end
  end 
endtask
task read;
  input [31:0] data ;
  begin 
    
     @ (posedge i_clk_ahb_tb);
     #1;
       i_rd_data_tb = 0;
      	i_rd_valid_tb = 0;	
       while (o_hreadyout_tb!= 1) begin 
       @ (negedge i_clk_ahb_tb);  
    end 
    i_rd_data_tb = data;
    	i_rd_valid_tb = 1;	
    	#1;
    		  		if(o_hrdata_tb  == data)
			$display( "Passed Case %0d : expected %h got %h", i, data, o_hrdata_tb);
		else 
			$display( "Failed Case %0d : expected %h got %h", i, data, o_hrdata_tb);
		i = i + 1; 
  end 
endtask
  


always #5 i_clk_ahb_tb =~ i_clk_ahb_tb;

// Instantiate the AHB_slave module
ahb_slave #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR)) DUT (
.i_clk_ahb(i_clk_ahb_tb),
.i_rstn_ahb(i_rstn_ahb_tb),
.i_hready(i_hready_tb),
.i_hmastlock(i_hmastlock_tb),
.i_htrans(i_htrans_tb),
.i_hprot(i_hprot_tb),
.i_hburst(i_hburst_tb),
.i_hsize(i_hsize_tb),
.i_hwrite(i_hwrite_tb),
.i_haddr(i_haddr_tb),
.i_hwdata(i_hwdata_tb),
.i_hselx(i_hselx_tb),
.i_ready(i_ready_tb),
.i_rd_valid(i_rd_valid_tb),
.i_rd_data(i_rd_data_tb),
.o_hreadyout(o_hreadyout_tb),
.o_hresp(o_hresp_tb),
.o_hrdata(o_hrdata_tb),
.o_valid(o_valid_tb),
.o_rd0_wr1(o_rd0_wr1_tb),
.o_wr_data(o_wr_data_tb),
.o_addr(o_addr_tb)
);


endmodule