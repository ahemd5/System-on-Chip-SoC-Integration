interface master_arb_if (input logic i_clk_apb);

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;
///////////// left side ///////////////////////
logic [DATA_WIDTH-1:0] i_wr_data;
logic [ADDR_WIDTH-1:0] i_addr;
logic i_rstn_apb, i_valid, i_rd0_wr1;
logic [DATA_WIDTH-1:0] o_rd_data;
logic o_rd_valid, o_ready;

////////// right side /////////////
logic [DATA_WIDTH-1:0] o_pwdata;
logic [ADDR_WIDTH-1:0] o_paddr;
logic o_psel, o_penable, o_pwrite;
logic [DATA_WIDTH-1:0] i_prdata;
logic i_pslverr, i_pready;



  modport TEST (output i_valid, i_clk_apb, i_rstn_apb ,i_rd0_wr1, i_addr,i_wr_data,i_prdata,i_pready,i_pslverr,
                input o_rd_data, o_rd_valid, o_ready,o_pwrite,o_penable,o_psel,o_paddr,o_pwdata);
  modport DUT (input i_valid, i_clk_apb, i_rstn_apb ,i_rd0_wr1, i_addr,i_wr_data,i_prdata,i_pready,i_pslverr,
                output o_rd_data, o_rd_valid, o_ready,o_pwrite,o_penable,o_psel,o_paddr,o_pwdata);
 

endinterface


