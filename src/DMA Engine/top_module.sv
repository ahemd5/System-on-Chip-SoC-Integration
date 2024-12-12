module top_module #(parameter DATA_WIDTH = 32, BUFFER_DEPTH = 16, ADDR_WIDTH = 32 )(

input  logic                       clk_top,
input  logic                       rst_top,
input  logic [DATA_WIDTH-1:0] i_pwdata_top,
input  logic [ADDR_WIDTH-1:0] i_paddr_top,
input  logic                  i_psel_top, 
input  logic                  i_penable_top, 
input  logic                  i_pwrite_top,
output logic [DATA_WIDTH-1:0] o_prdata_top,
output logic                  o_pslverr_top,  
output logic                  o_pready_top,
//////////////////////////////////////////////////
output logic [DATA_WIDTH-1:0] o_hwdata_top,
output logic [ADDR_WIDTH-1:0] o_haddr_top,
output logic                  o_hwrite_top,  
output logic                  o_htrans_top,
input  logic [DATA_WIDTH-1:0] i_hrdata_top,
input  logic                  i_hresp_top, 
input  logic                  i_hready_top,


output logic                  o_trig_end_top,
input  logic   [7:0]          i_dma_start_trig_top
);
///////////////////////////////////////////////////
logic    [DATA_WIDTH-1:0]     i_data_buff_fsm;
logic                         i_valid_buff_fsm;
logic                         o_rd0_wr1_buff_fsm;
logic                         o_valid_buff_fsm;
logic     [DATA_WIDTH-1:0]    o_data_buff_fsm;
//////////////////////////////////////////////////
logic                         sw_en_config_fsm;
logic    [7:0]                hw_en_config_fsm;
logic    [DATA_WIDTH-1:0]     src_addr_config_fsm;
logic    [DATA_WIDTH-1:0]     dist_addr_config_fsm;
logic    [DATA_WIDTH-1:0]     src_addr_type_config_fsm;
logic    [DATA_WIDTH-1:0]     dist_addr_type_config_fsm;
logic    [DATA_WIDTH-1:0]     src_data_width_config_fsm;
logic    [DATA_WIDTH-1:0]     dist_data_width_config_fsm;
logic    [DATA_WIDTH-1:0]     total_trans_config_fsm;
/////////////////////////////////////////////////////////
logic    [DATA_WIDTH-1:0]     i_rd_data_ahb_fsm;
logic                         i_ready_ahb_fsm;
logic                         i_rd_valid_ahb_fsm;
logic    [DATA_WIDTH-1:0]     o_wr_data_ahb_fsm;
logic    [ADDR_WIDTH-1:0]     o_addr_ahb_fsm;
logic                         o_valid_ahb_fsm; 
logic                         o_rd0_wr1_ahb_fsm;
////////////////////////////////////////////////////////
logic [DATA_WIDTH-1:0]        wr_data_apb_config;
logic [ADDR_WIDTH-1:0]        addr_apb_config;
logic                         valid_apb_config; 
logic                         o_rd0_wr1_apb_config;
logic [DATA_WIDTH-1:0]        rd_data_apb_config;
logic                         rd_valid_apb_config; 
logic                         i_ready_apb_config;
/////////////////////////////////////////////////////////////////////////////////////////////////////////

AHB_master #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  )u0_AHB_master(
.i_wr_data(o_wr_data_ahb_fsm),
.i_addr(o_addr_ahb_fsm),
.i_rstn_ahb(rst_top),
.i_clk_ahb(clk_top), 
.i_valid(o_valid_ahb_fsm), 
.i_rd0_wr1(o_rd0_wr1_ahb_fsm),
.o_rd_data(i_rd_data_ahb_fsm),
.o_rd_valid(i_rd_valid_ahb_fsm), 
.o_ready(i_ready_ahb_fsm),

.o_hwdata(o_hwdata_top),
.o_haddr(o_haddr_top),
.o_hwrite(o_hwrite_top), 
.o_htrans(o_htrans_top),
.i_hrdata(i_hrdata_top),
.i_hresp(i_hresp_top), 
.i_hready(i_hready_top)
);

apb_slave #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  )u1_apb_slave (
.o_wr_data(wr_data_apb_config),
.o_addr(addr_apb_config),
.i_rstn_apb(rst_top),
.i_clk_apb(clk_top), 
.o_valid(valid_apb_config), 
.o_rd0_wr1(o_rd0_wr1_apb_config),
.i_rd_data(rd_data_apb_config),
.i_rd_valid(rd_valid_apb_config), 
.i_ready(i_ready_apb_config),

.i_pwdata(i_pwdata_top),
.i_paddr(i_paddr_top),
.i_psel(i_psel_top),
.i_penable(i_penable_top), 
.i_pwrite(i_pwrite_top),
.o_prdata(o_prdata_top),
.o_pslverr(o_pslverr_top), 
.o_pready(o_pready_top)
);

buffer #(
    .DATA_WIDTH(DATA_WIDTH),
    .BUFFER_DEPTH(BUFFER_DEPTH)
  )u2_buffer (
.clk(clk_top),
.rst(rst_top),
.i_rd0_wr1(o_rd0_wr1_buff_fsm),
.i_valid(o_valid_buff_fsm),
.i_data(o_data_buff_fsm),
.o_data(i_data_buff_fsm),
.o_valid(i_valid_buff_fsm)
);

RegFile #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  )u3_RegFile (
.clk(clk_top),
.rst(rst_top),
.i_rd0_wr1(o_rd0_wr1_apb_config),
.i_valid(valid_apb_config),
.i_trig_end_fsm(o_trig_end_top),
.i_dma_start_trig(i_dma_start_trig_top),
.i_addr(addr_apb_config),
.i_data(wr_data_apb_config),
.o_rd_data(rd_data_apb_config),
.o_rd_valid(rd_valid_apb_config),
.o_ready(i_ready_apb_config),
.o_sw_en(sw_en_config_fsm),
.o_hw_en(hw_en_config_fsm),
.o_src_addr(src_addr_config_fsm),
.o_dist_addr(dist_addr_config_fsm),
.o_src_addr_type(src_addr_type_config_fsm),
.o_dist_addr_type(dist_addr_type_config_fsm),
.o_src_data_width(src_data_width_config_fsm),
.o_dist_data_width(dist_data_width_config_fsm),
.o_total_trans(total_trans_config_fsm)
);

fsm #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
	.BUFFER_DEPTH(BUFFER_DEPTH)
  )u3_fsm (
.clk(clk_top),
.rst(rst_top),
.i_data_buff(i_data_buff_fsm),
.i_valid_buff(i_valid_buff_fsm),
.o_rd0_wr1_buff(o_rd0_wr1_buff_fsm),
.o_valid_buff(o_valid_buff_fsm),
.o_data_buff(o_data_buff_fsm),
//////////////////////////REG_FILE SIGNALS//////////////////////////////////////////////////////////////////
.i_sw_en_config(sw_en_config_fsm),
.i_hw_en_config(hw_en_config_fsm),
.i_src_addr_config(src_addr_config_fsm),
.i_dist_addr_config(dist_addr_config_fsm),
.i_src_addr_type_config(src_addr_type_config_fsm),
.i_dist_addr_type_config(dist_addr_type_config_fsm),
.i_src_data_width_config(src_data_width_config_fsm),
.i_dist_data_width_config(dist_data_width_config_fsm),
.i_total_trans_config(total_trans_config_fsm),
//////////////////////////AHB SIGNALS//////////////////////////////////////////////////////////////////
.i_rd_data_ahb(i_rd_data_ahb_fsm),
.i_ready_ahb(i_ready_ahb_fsm),
.i_rd_valid_ahb(i_rd_valid_ahb_fsm),
.o_wr_data_ahb(o_wr_data_ahb_fsm),
.o_addr_ahb(o_addr_ahb_fsm),
.o_valid_ahb(o_valid_ahb_fsm), 
.o_rd0_wr1_ahb(o_rd0_wr1_ahb_fsm),
.o_trig_end(o_trig_end_top)
);

endmodule



