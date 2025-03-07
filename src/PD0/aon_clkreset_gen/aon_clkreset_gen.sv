module aon_clkreset_gen (
    // Low-power clock inputs from PMU or external sources
    input  wire i_clk_32k_rc,
    input  wire i_clk_32k_xtal,
    input  wire i_clk_rc_prog,

    // Reset inputs
    input  wire i_reset_n,        // main design reset (active-low)
    input  wire i_soc_por_rst_n,  // PMU’s power-on reset (active-low)

    // Control signals (could come from a register, for example)
    input  wire [1:0] i_clk_sel,  // 00=rc, 01=xtal, 10=rc_prog, etc.
    input  wire       i_clk_en,   // gate enable

    // Outputs
    output wire o_clk_aon,        // the “always-on” clock domain
    output wire o_reset_aon_n     // the “always-on” reset (active-low)
);

    //----------------------------------------------------------------
    // 1) Simple clock selection (MUX)
    //----------------------------------------------------------------
    reg selected_clk;
    always @(*) begin
        case (i_clk_sel)
            2'b00: selected_clk = i_clk_32k_rc;
            2'b01: selected_clk = i_clk_32k_xtal;
            2'b10: selected_clk = i_clk_rc_prog;
            default: selected_clk = i_clk_32k_xtal; 
        endcase
    end

    //----------------------------------------------------------------
    // 2) Optional clock gating
    //----------------------------------------------------------------
    // In a real ASIC flow, clock gating is typically done with library
    // gating cells, not simple logic.  This is just for demonstration.
    assign o_clk_aon = i_clk_en ? selected_clk : 1'b0;

    //----------------------------------------------------------------
    // 3) Combine resets
    //----------------------------------------------------------------
    // We generate an always-on reset by combining the top-level reset
    // and the PMU’s power-on reset. Both are active-low, so we AND them.
    assign o_reset_aon_n = i_reset_n & i_soc_por_rst_n;

endmodule
