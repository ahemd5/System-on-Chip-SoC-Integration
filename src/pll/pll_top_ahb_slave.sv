
module PLL_top_ahb (
    // AHB Interface Signals
    input  logic                  i_clk_ahb,
    input  logic                  i_rstn_ahb,
    input  logic                  i_hready,
    input  logic [1:0]            i_htrans,
    input  logic [2:0]            i_hsize,
    input  logic                  i_hwrite,
    input  logic [31:0]           i_haddr,
    input  logic [31:0]           i_hwdata,
    input  logic                  i_hselx,
    input  logic                  i_hmastlock,
    input  logic [3:0]            i_hprot,
    input  logic [2:0]            i_hburst,

    // AHB Response Signals
    output logic                  o_hreadyout,
    output logic                  o_hresp,
    output logic [31:0]           o_hrdata,

    // PLL System Interface Signals
    input  wire                   xo_clk,
    input  wire                   reset_n,
    output wire                   clk
   
);
    wire soc_clk_select;
    // Internal signals for connecting top_pll_system and ahb_slave
    wire [31:0]                   i_address;
    wire                          i_rd0_wr1;
    wire [31:0]                   i_wr_data;
    wire                          I_valid;
    wire [31:0]                   o_rd_data;
    wire                          o_rd_valid;
    wire                          o_ready;

    // Instantiate the top_pll_system module
    top_pll_system u_top_pll_system (
        .i_clk_ahb(i_clk_ahb),
        .i_address(i_address),
        .i_rd0_wr1(i_rd0_wr1),
        .i_wr_data(i_wr_data),
        .I_valid(I_valid),
        .o_rd_data(o_rd_data),
        .o_rd_valid(o_rd_valid),
        .o_ready(o_ready),
        .xo_clk(xo_clk),
        .reset_n(reset_n),
        .pll_clk(pll_clk),
        .soc_clk_select(soc_clk_select)
        
    );

    // Instantiate the ahb_slave module
    ahb_slave #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) u_ahb_slave (
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
        .i_ready(o_ready),
        .i_rd_valid(o_rd_valid),
        .i_rd_data(o_rd_data),
        .o_valid(I_valid),
        .o_rd0_wr1(i_rd0_wr1),
        .o_wr_data(i_wr_data),
        .o_addr(i_address),
        .o_hreadyout(o_hreadyout),
        .o_hresp(o_hresp),
        .o_hrdata(o_hrdata)
    );

    
  assign clk=(soc_clk_select)? xo_clk:pll_clk;

endmodule
