interface slave_arb_if (input logic i_clk_apb);

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;
///////////// right side ///////////////////////
logic [DATA_WIDTH-1:0] o_wr_data;
logic [ADDR_WIDTH-1:0] o_addr;
logic i_rstn_apb, o_valid, o_rd0_wr1;
logic [DATA_WIDTH-1:0] i_rd_data;
logic i_rd_valid, i_ready;

////////// left side /////////////
logic [DATA_WIDTH-1:0] i_pwdata;
logic [ADDR_WIDTH-1:0] i_paddr;
logic i_psel, i_penable, i_pwrite;
logic [DATA_WIDTH-1:0] o_prdata;
logic o_pslverr, o_pready;



  modport TEST (output o_valid, i_clk_apb, i_rstn_apb ,o_rd0_wr1, o_addr,o_wr_data,o_prdata,o_pready,o_pslverr,
                input i_rd_data, i_rd_valid, i_ready,i_pwrite,i_penable,i_psel,i_paddr,i_pwdata);
  modport DUT (input o_valid, i_clk_apb, i_rstn_apb ,o_rd0_wr1, o_addr,o_wr_data,o_prdata,o_pready,o_pslverr,
                output i_rd_data, i_rd_valid, i_ready,i_pwrite,i_penable,i_psel,i_paddr,i_pwdata);
 

endinterface

