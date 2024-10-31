module apb #(
    // Parameters
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(	
    // Clock and Reset
    input logic i_clk_apb,
    input logic i_rstn_apb,

    // Master signals
    input logic i_valid,
    input logic [ADDR_WIDTH-1:0] i_addr,
    input logic i_rd0_wr1,
    input logic [DATA_WIDTH-1:0] i_wr_data,
    output reg o_ready,
    output reg o_rd_valid,
    output reg [DATA_WIDTH-1:0] o_rd_data,

    // Slave signals
    output reg o_valid,
    output reg [ADDR_WIDTH-1:0] o_addr,
    output reg o_rd0_wr1,
    output reg [DATA_WIDTH-1:0] o_wr_data,
    input logic i_ready,
    input logic i_rd_valid,
    input logic [DATA_WIDTH-1:0] i_rd_data
);

    // APB interface signals
    logic psel;
    logic penable;
    logic pwrite;
    logic [ADDR_WIDTH-1:0] paddr;
    logic [DATA_WIDTH-1:0] pwdata;
    logic [DATA_WIDTH-1:0] prdata;
    logic pready;
    logic pslverr;
	
	// DUT instantiation (APB Master)
    apb_master #(
        .addr_width(ADDR_WIDTH),
        .data_width(DATA_WIDTH)
    ) master_inst (
        .i_clk_apb(i_clk_apb),
        .i_rstn_apb(i_rstn_apb),
        .i_valid(i_valid),
        .o_ready(o_ready),
        .o_psel(psel),
        .o_penable(penable),
        .o_pwrite(pwrite),
        .o_paddr(paddr),
        .o_pwdata(pwdata),
        .i_prdata(prdata),
        .i_pready(pready),
        .i_pslverr(pslverr),
        .i_addr(i_addr),
        .i_rd0_wr1(i_rd0_wr1),
        .i_wr_data(i_wr_data),
        .o_rd_valid(o_rd_valid),
        .o_rd_data(o_rd_data)
    );

    // DUT instantiation (APB Slave)
    apb_slave #(
        .addr_width(ADDR_WIDTH),
        .data_width(DATA_WIDTH)
    ) slave_inst (
        .i_clk_apb(i_clk_apb),
        .i_rstn_apb(i_rstn_apb),
        .i_ready(i_ready),
        .i_rd_valid(i_rd_valid),
        .i_rd_data(i_rd_data),
        .o_rd0_wr1(o_rd0_wr1),
        .o_valid(o_valid),
        .o_addr(o_addr),
        .o_wr_data(o_wr_data),
        .i_pwrite(pwrite),
        .i_psel(psel),
        .i_pwdata(pwdata),
        .i_paddr(paddr),
        .i_penable(penable),
        .o_pready(pready),
        .o_pslverr(pslverr),
        .o_prdata(prdata)
    );
	
endmodule 	
