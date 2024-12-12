
`timescale 1ns/1ps

module tb_top();

parameter DATA_WIDTH=32;
parameter ADDR_WIDTH=32;
parameter BUFFER_DEPTH=16;
/////////////////////////////////////////////////////////
//////////////////// DUT Signals ////////////////////////
/////////////////////////////////////////////////////////
logic                       clk;
logic                       rst;
logic [DATA_WIDTH-1:0] i_pwdata_apb;
logic [ADDR_WIDTH-1:0] i_paddr_apb;
logic                  i_psel_apb; 
logic                  i_penable_apb; 
logic                  i_pwrite_apb;
logic [DATA_WIDTH-1:0] o_prdata_apb;
logic                  o_pslverr_apb;  
logic                  o_pready_apb;
//////////////////////////////////////////////////
logic [DATA_WIDTH-1:0] o_hwdata_ahb;
logic [ADDR_WIDTH-1:0] o_haddr_ahb;
logic                  o_hwrite_ahb;  
logic                  o_htrans_ahb;
logic [DATA_WIDTH-1:0] i_hrdata_ahb;
logic                  i_hresp_ahb; 
logic                  i_hready_ahb;
logic                  o_trig_end_ahb;
logic   [7:0]          i_dma_start_trig_ahb;
////////////////////////////////////////////////////////
////////////////// initial block /////////////////////// 
////////////////////////////////////////////////////////
initial
begin
   $dumpfile("top_module.vcd"); // waveforms in this file      
   $dumpvars;     
    // Initialization
    initialize();
    // Reset
    reset();
////////////////////////configuration////////////////////////////////////////////////////
i_dma_start_trig_ahb = 'h1 ;
data_in_apb('h0, 'h0 , 1);
#10
data_in_apb('h0, 'd1 , 1);
#10
data_in_apb('h0, 'd2 , 1);
#10
data_in_apb('h1, 'd3 , 1);
#10
data_in_apb('d32, 'd4 , 1);
#10
data_in_apb('d8, 'd5 , 1);
#10
data_in_apb('d512, 'd6 , 1);
#10
data_in_apb('h1, 'd7 , 1);
#10
////////////////////////////ahb input data///////////////////////////////////////////////
#20

data_in_ahb('h87654321);
#10
data_in_ahb('h44442222);
#10
data_in_ahb('h44443333);
#10
data_in_ahb('h55554444);
#10
data_in_ahb('h66665555);
#10
data_in_ahb('h66666666);
#10
data_in_ahb('h77777777);
#10
data_in_ahb('h88888888);
#10
data_in_ahb('h99999999);
#10
data_in_ahb('haaaaaaaa);
#10
data_in_ahb('hbbbbbbbb);
#10
data_in_ahb('hcccccccc);
#10
data_in_ahb('hdddddddd);
#10
data_in_ahb('heeeeeeee);
#10
data_in_ahb('hffffffff);
#10
data_in_ahb('h11111111);
#210

#300
/*
//////////////////////////
data_in_ahb('h3311);
#10
data_in_ahb('h4422);
#10
data_in_ahb('h4433);
#10
data_in_ahb('h5544);
#10
data_in_ahb('h6655);
#10
data_in_ahb('h6666);
#10
data_in_ahb('h7777);
#10
data_in_ahb('h8888);
#10
data_in_ahb('h9999);
#10
data_in_ahb('haaaa);
#10
data_in_ahb('hbbbb);
#10
data_in_ahb('hcccc);
#10
data_in_ahb('hdddd);
#10
data_in_ahb('heeee);
#10
data_in_ahb('hffff);
#10
data_in_ahb('h1111);

/////////////////////////////
#210
*/
/*
//////////////////////////
data_in_ahb('d1);
#10
data_in_ahb('d2);
#10
data_in_ahb('d3);
#10
data_in_ahb('d4);
#10
data_in_ahb('d5);
#10
data_in_ahb('d6);
#10
data_in_ahb('d7);
#10
data_in_ahb('d8);
#10
data_in_ahb('d9);
#10
data_in_ahb('d10);
#10
data_in_ahb('d11);
#10
data_in_ahb('d12);
#10
data_in_ahb('d13);
#10
data_in_ahb('d14);
#10
data_in_ahb('d15);
#10
data_in_ahb('d16);
/////////////////////////////
#210
//////////////////////////
data_in_ahb('d1);
#10
data_in_ahb('d2);
#10
data_in_ahb('d3);
#10
*/
////////////////////////configuration////////////////////////////////////////////////////
/*i_dma_start_trig_ahb = 'h1 ;
data_in_apb('h0, 'h0 , 1);
#10
data_in_apb('h4, 'd1 , 1);
#10
data_in_apb('h0, 'd2 , 1);
#10
data_in_apb('h0, 'd3 , 1);
#10
data_in_apb('h8, 'd4 , 1);
#10
data_in_apb('h8, 'd5 , 1);
#10
data_in_apb('d128, 'd6 , 1);
#10
data_in_apb('h1, 'd7 , 1);
#10
////////////////////////////ahb input data///////////////////////////////////////////////
#20
data_in_ahb('d1);
#20
data_in_ahb('d2);
#20
data_in_ahb('d3);
#20
data_in_ahb('d4);
#20
data_in_ahb('d5);
#20
data_in_ahb('d6);
#20
data_in_ahb('d7);
#20
data_in_ahb('d8);
#20
data_in_ahb('d9);
#20
data_in_ahb('d10);
#20
data_in_ahb('d11);
#20
data_in_ahb('d12);
#20
data_in_ahb('d13);
#20
data_in_ahb('d14);
#20
data_in_ahb('d15);
#20
data_in_ahb('d16);
#10
*/
#300
    $stop;
end	
///////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
/////////////// Signals Initialization //////////////////////////////////
task initialize;
 
    clk = 1'b0;
    rst = 1'b1; // rst is deactivated
	i_pwdata_apb= 'b0;
    i_paddr_apb= 'b0;
    i_psel_apb= 'b0; 
    i_penable_apb= 'b0; 
    i_pwrite_apb= 'b0;
    i_hrdata_ahb= 'b0;
    i_hresp_ahb= 'b0; 
    i_hready_ahb= 'b1;
    i_dma_start_trig_ahb= 'b0;
  endtask

///////////////////////// RESET /////////////////////////////////////////////////////////////////////
task reset;
 
    #10
    rst = 1'b0; // rst is activated
    #10
    rst = 1'b1;
    #10;
  endtask

////////////////////////////////////////////////////////////////////////////////////////////////////
task data_in_apb(input [DATA_WIDTH-1:0] data1, input [ADDR_WIDTH-1:0] addr1, input rd0_wr1_en1);

    @(posedge clk)
      i_pwdata_apb =data1;
      i_paddr_apb = addr1;
      i_psel_apb =1; 
      i_pwrite_apb= rd0_wr1_en1;
    @(posedge clk)
	    i_penable_apb =1; 
   // #10
	
endtask 

////////////////////////////////////////////////////////////////////////////////////////////////////
task data_in_ahb(input [DATA_WIDTH-1:0] data2);
 
    @(posedge clk)
      i_hrdata_ahb =data2;
      i_hready_ahb =1; 
      i_hresp_ahb= 0;
   // #10
	
  
endtask

	
//////////////////////// Clock ///////////////////////////////////////////
always #5 clk = ~clk; 

top_module DUT (
.clk_top(clk),
.rst_top(rst),
.i_pwdata_top(i_pwdata_apb),
.i_paddr_top(i_paddr_apb),
.i_psel_top(i_psel_apb), 
.i_penable_top(i_penable_apb), 
.i_pwrite_top(i_pwrite_apb),
.o_prdata_top(o_prdata_apb),
.o_pslverr_top(o_pslverr_apb),  
.o_pready_top(o_pready_apb),
//////////////////////////////////////////////////
.o_hwdata_top(o_hwdata_ahb),
.o_haddr_top(o_haddr_ahb),
.o_hwrite_top(o_hwrite_ahb),  
.o_htrans_top(o_htrans_ahb),
.i_hrdata_top(i_hrdata_ahb),
.i_hresp_top(i_hresp_ahb), 
.i_hready_top(i_hready_ahb),
.o_trig_end_top(o_trig_end_ahb),
.i_dma_start_trig_top(i_dma_start_trig_ahb)
);


endmodule