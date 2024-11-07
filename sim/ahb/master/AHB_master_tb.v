`timescale 1us/1ps
module AHB_master_tb ();
parameter period = 10;
parameter DATA_WIDTH = 32;
parameter ADDR = 32;
reg 					i_clk_ahb_tb;
reg 					i_rstn_ahb_tb;	
// Standard signals
reg 					i_hready_tb;	// from slave 
reg 					i_hresp_tb;		// transfer status from slave // low > okay, high > error
reg [DATA_WIDTH-1:0] 	i_hrdata_tb; 	// read from slave 
// Transaction signals
reg 					i_valid_tb;		
reg [ADDR-1:0] 			i_addr_tb;
reg [DATA_WIDTH-1:0] 	i_wr_data_tb;
reg 					i_rd0_wr1_tb; 	// type of the transaction, if 0 => read, if 1 => write

// Standard signals
wire [ADDR-1:0] 		o_haddr_tb;
wire [2:0] 				o_hburst_tb;
wire 					o_hmastlock_tb;
wire [3:0] 				o_hprot_tb;
wire [2:0] 				o_hsize_tb;
wire 					o_htrans_tb;
wire [DATA_WIDTH-1:0] 	o_hwdata_tb;
wire 					o_hwrite_tb;
// Transaction signals
wire [DATA_WIDTH-1:0] 	o_rd_data_tb;
wire 					o_rd_valid_tb;
wire 					o_ready_tb;

localparam IDLE = 0,
		   NONSEQ = 1;

reg [31:0] temp;
integer i;

initial 
begin 
	$dumpfile("AHB_master1.vcd");
    $dumpvars;
    inititalize();
    reset();
		
	write(32'hA1A2A3A4,32'h5);			// data,address A 
    @(posedge o_htrans_tb);
	check_address(32'h5);				// address phase 1 check 
	
	#(period);
	read(32'hABCD1234,32'h7);			// read address B ( read from slave ) 
	 
	
	#(period);
	write(32'hB1B2B3B4,32'h6); 			// data,address C
	i_hready_tb = 0; 					// busy state ( 2nd input )
	check_write(32'hA1A2A3A4);			// data phase A check 
	check_address(32'h7);				// address phase B check 
	
	#(period);							// busy cycles
	i_hready_tb = 1; 	
	check_address(32'h6);				// address phase C check 
	
	#(period);
	check_read(32'hABCD1234);			// data phase B check 
	read(32'h12345678,32'h22);			// input address 4 ( read from slave )
	
	#(period);
	check_write(32'hB1B2B3B4);			// data phase C check 
	i_addr_tb = 0;
	i_valid_tb = 'b0;					// end Transaction
	check_address(32'h22);				// address phase C check 
	
	#(period);
	check_read(32'h12345678);			// data phase B check 
	
	#20;
    $stop;

end

task check_read ; 
	input [31:0] data;
	begin 
		if(o_rd_data_tb == data && o_rd_valid_tb)
			$display( "passed expected %h got %h",data, o_rd_data_tb );
		else 
			$display( "failed expected %h got %h", data, o_rd_data_tb);
	end
endtask

task read;
	input [31:0] data;
	input [31:0] address;
	begin 
		i_wr_data_tb = 'h0;
		i_rd0_wr1_tb = 'b0; 				// read
		i_hrdata_tb = data;	
		i_addr_tb = address; 	
	end 
endtask

task write ; 
	input [31:0] data;
	input [31:0] address;
	begin 
		i_hrdata_tb = 0;
		i_wr_data_tb = data;		
		i_addr_tb = address;  	
		i_valid_tb = 'b1; 					// valid Transaction data  
		i_rd0_wr1_tb = 'b1;  				// write 	
	end
endtask

task check_address ; 
input [31:0] address;
	begin 

		if(o_haddr_tb == address) 
			$display("Passed: address %0d",i);
		else 
			$display("Failed: address %0d",i);
		
		i=i+1	;	
	end
endtask

task check_write ; 
	input [31:0] data;
	begin 
		
		if( o_hwdata_tb == data)
			$display( "Passed: expected %h got %h", data, o_hwdata_tb );
		else 
			$display( "Failed: expected %h got %h", data, o_hwdata_tb );
	end
endtask

task inititalize;
	begin 
	i_clk_ahb_tb = 'b0;
	i_hready_tb = 'b1;					// if 0 >> busy state 
	i_hresp_tb = IDLE;
	i_hrdata_tb = 'b0;
	i_valid_tb = 'b0; 
	i_addr_tb = 'b0; 
	i_wr_data_tb = 'b0;
	i_rd0_wr1_tb = 'b0; 
	i = 1;
	end
endtask

task reset;
	begin 
	i_rstn_ahb_tb = 1'b1;
	#(period);
	i_rstn_ahb_tb = 1'b0;
	#(period);
	i_rstn_ahb_tb = 1'b1;
	end
endtask

always #5 i_clk_ahb_tb = ~i_clk_ahb_tb;

AHB_master DUT(  
.i_clk_ahb(i_clk_ahb_tb),
.i_rstn_ahb(i_rstn_ahb_tb),
.i_hready(i_hready_tb),
.i_hresp(i_hresp_tb),
.i_hrdata(i_hrdata_tb),
.i_valid(i_valid_tb),
.i_addr(i_addr_tb),
.i_wr_data(i_wr_data_tb),
.i_rd0_wr1(i_rd0_wr1_tb),
.o_haddr(o_haddr_tb),
.o_hburst(o_hburst_tb),
.o_hmastlock(o_hmastlock_tb),
.o_hprot(o_hprot_tb),
.o_hsize(o_hsize_tb),
.o_htrans(o_htrans_tb),
.o_hwdata(o_hwdata_tb),
.o_hwrite(o_hwrite_tb),
.o_rd_data(o_rd_data_tb),
.o_rd_valid(o_rd_valid_tb),
.o_ready(o_ready_tb)
);

endmodule 