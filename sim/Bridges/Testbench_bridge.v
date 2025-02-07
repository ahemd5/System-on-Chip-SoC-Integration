`timescale 1ns/1ps
module bridge_tb ();
	parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, DEPTH = 4, P_SIZE = 3, F_DEPTH = 4;
	parameter period_src = 10;
	parameter period_sink = 10.5;
	reg i_clk_src_tb;
	reg i_rstn_src_tb;
	reg i_src_sleep_req_tb;
	wire o_src_sleep_ack_tb;
	reg i_clk_sink_tb;
	reg i_rstn_sink_tb;
	reg i_sink_sleep_req_tb;
	wire o_sink_sleep_ack_tb;
	// slave interface 
	reg        				i_hready_sink_tb;      
    reg        				i_htrans_tb;
    reg  [2:0] 				i_hsize_tb;
    reg        				i_hwrite_tb;
    reg  [ADDR_WIDTH-1:0] 	i_haddr_tb;
    reg  [DATA_WIDTH-1:0] 	i_hwdata_tb;
    reg        				i_hselx_tb;
	wire       				o_hreadyout_tb;
    wire       				o_hresp_tb;
    wire [DATA_WIDTH-1:0] 	o_hrdata_tb;
	// master interface 
	reg 					i_hready_src_tb;
    reg 					i_hresp_tb;
	reg [DATA_WIDTH-1:0] 	i_hrdata_tb;
    wire 					o_hwrite_tb;
    wire 					o_htrans_tb;
    wire [2:0] 				o_hsize_tb;
    wire [ADDR_WIDTH-1:0] 	o_haddr_tb;
    wire [DATA_WIDTH-1:0] 	o_hwdata_tb;
	
	
	initial 
	begin 
		// inital no trasactions
		initialize();
		reset();
		
		// Start transactions
		#(period_src);
		i_src_sleep_req_tb = 0;
		i_sink_sleep_req_tb = 0;
		// source side
		i_hready_sink_tb = 1;
		i_htrans_tb = 1;
		i_hwrite_tb = 1;
		i_haddr_tb = 'ha;
		i_hwdata_tb = 'h0;
		i_hselx_tb = 1;
		// sink side
		i_hready_src_tb = 1;
		i_hrdata_tb = 0;
		
		#(period_src);
		i_src_sleep_req_tb = 0;
		i_sink_sleep_req_tb = 0;
		// source side
		i_hready_sink_tb = 1;
		i_htrans_tb = 1;
		i_hwrite_tb = 1;
		i_haddr_tb = 'hb;
		i_hwdata_tb = 'haaaa;
		i_hselx_tb = 1;
		// sink side
		i_hready_src_tb = 1;
		i_hrdata_tb = 0;
		
		#(period_src);
		i_src_sleep_req_tb = 0;
		i_sink_sleep_req_tb = 0;
		// source side
		i_hready_sink_tb = 1;
		i_htrans_tb = 1;
		i_hwrite_tb = 1;
		i_haddr_tb = 'hc;
		i_hwdata_tb = 'hbbbb;
		i_hselx_tb = 1;
		// sink side
		i_hready_src_tb = 1;
		i_hrdata_tb = 0;
		
		#(period_src);
		i_src_sleep_req_tb = 0;
		i_sink_sleep_req_tb = 0;
		// source side
		i_hready_sink_tb = 1;
		i_htrans_tb = 1;
		i_hwrite_tb = 0;
		i_haddr_tb = 'hd;
		i_hwdata_tb = 'hcccc;
		i_hselx_tb = 1;
		// sink side
		i_hready_src_tb = 1;
		i_hrdata_tb = 0;

		#(period_src);
		i_src_sleep_req_tb = 0;
		i_sink_sleep_req_tb = 0;
		// source side
		i_hready_sink_tb = 1;
		i_htrans_tb = 1;
		i_hwrite_tb = 1;
		i_haddr_tb = 'he;
		i_hwdata_tb = 'h0;
		i_hselx_tb = 1;
		// sink side
		i_hready_src_tb = 1;
		i_hrdata_tb = 0;
		
		#(period_src);
		i_src_sleep_req_tb = 0;
		i_sink_sleep_req_tb = 0;
		// source side
		i_hready_sink_tb = 1;
		i_htrans_tb = 1;
		i_hwrite_tb = 1;
		i_haddr_tb = 'he;
		i_hwdata_tb = 'h0;
		i_hselx_tb = 1;
		// sink side
		i_hready_src_tb = 1;
		i_hrdata_tb = 0;
		
		#(period_src);
		i_src_sleep_req_tb = 1;
		i_sink_sleep_req_tb = 0;
		// source side
		i_hready_sink_tb = 1;
		i_htrans_tb = 1;
		i_hwrite_tb = 1;
		i_haddr_tb = 'he;
		i_hwdata_tb = 'h0;
		i_hselx_tb = 1;
		// sink side
		i_hready_src_tb = 1;
		i_hrdata_tb = 0;
		
		wait(o_haddr_tb == 'hd);
		#(period_sink);
		i_hrdata_tb = 'hdddd;
		
		wait(o_hrdata_tb == 'hdddd);
		#(period_src);
		i_hwdata_tb = 'heeee;
		
		#(10*period_src);
		$stop;
	end

	
	task reset;
	begin 
		// reset 
		#(period_src);
		i_rstn_src_tb = 0;
		i_rstn_sink_tb = 0;
		#(period_src);
		i_rstn_src_tb = 1;
		i_rstn_sink_tb = 1;
	end 
	endtask
	
	task initialize;
	begin 
		i_clk_src_tb = 1;
		i_clk_sink_tb = 1;
		i_rstn_src_tb = 1;
		i_rstn_sink_tb = 1;
		i_src_sleep_req_tb = 0;
		i_sink_sleep_req_tb = 0;
		// source side
		i_hready_sink_tb = 0;			//
		i_htrans_tb = 0;				//
		i_hsize_tb = 'b010;
		i_hwrite_tb = 1;
		i_haddr_tb = 0;
		i_hwdata_tb = 0;
		i_hselx_tb = 1;					//
		// sink side
		i_hready_src_tb = 0;			//
		i_hresp_tb = 0;
		i_hrdata_tb = 0;
	end
	endtask
	
	always #(period_sink/2.0) i_clk_sink_tb = ~i_clk_sink_tb;
	
	always #(period_src/2.0) i_clk_src_tb = ~i_clk_src_tb; 
	
	AHB_AHB_bridge DUT (
	.i_clk_src(i_clk_src_tb),
	.i_rstn_src(i_rstn_src_tb),
	.i_rstn_sink(i_rstn_sink_tb),
	.i_clk_sink(i_clk_sink_tb),
	.i_sink_sleep_req(i_sink_sleep_req_tb),
	.i_src_sleep_req(i_src_sleep_req_tb),
	.o_src_sleep_ack(o_src_sleep_ack_tb),
	.o_sink_sleep_ack(o_sink_sleep_ack_tb),
	
	.i_hready_sink(i_hready_sink_tb),
	.i_htrans(i_htrans_tb),
	.i_hsize(i_hsize_tb),
	.i_hwrite(i_hwrite_tb),
	.i_haddr(i_haddr_tb),
	.i_hwdata(i_hwdata_tb),
	.i_hselx(i_hselx_tb),
	.o_hreadyout(o_hreadyout_tb),
	.o_hresp(o_hresp_tb),
	.o_hrdata(o_hrdata_tb),
	
	.i_hready_src(i_hready_src_tb),
	.i_hresp(i_hresp_tb),
	.i_hrdata(i_hrdata_tb),
	.o_hwrite(o_hwrite_tb),
	.o_htrans(o_htrans_tb),
	.o_hsize(o_hsize_tb),
	.o_haddr(o_haddr_tb),
	.o_hwdata(o_hwdata_tb)
	);
	
endmodule