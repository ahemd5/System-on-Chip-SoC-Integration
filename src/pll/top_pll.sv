module top_pll_system (
    input  wire        i_clk_ahb,
    input  wire [31:0] i_address,
    input  wire        i_rd0_wr1,
    input  wire [31:0] i_wr_data,
    input  wire        I_valid,
    output wire [31:0] o_rd_data,
    output wire        o_rd_valid,
    output wire        o_ready,
    input  wire        xo_clk,
    input  wire        reset_n,
    output wire        pll_clk,
      output wire        soc_clk_select
);

    
    wire        pll_locked;
    wire        pll_error;
   
    wire        pll_enable;
    wire        pll_bypass;
    wire        pll_reset;
    wire [7:0]  pll_mul;
    wire [7:0]  pll_div;

    pll_model u_pll_model (
        .xo_clk(xo_clk),
        .reset_n(reset_n),
        .pll_enable(pll_enable),
        .pll_bypass(pll_bypass),
        .pll_reset(pll_reset),
        .pll_mul(pll_mul),
        .pll_div(pll_div),
        .pll_clk(pll_clk),
        .pll_locked(pll_locked),
        .pll_error(pll_error)
    );

    pll_controller u_pll_controller (
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
        .pll_locked(pll_locked),
        .pll_error(pll_error),
      
        .soc_clk_select(soc_clk_select),
        .pll_enable(pll_enable),
        .pll_bypass(pll_bypass),
        .pll_reset(pll_reset),
        .pll_div(pll_div),
        .pll_mul(pll_mul)
    );

endmodule


