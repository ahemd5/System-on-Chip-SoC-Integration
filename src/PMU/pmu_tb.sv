module pmu_tb;
  // Test signals
  logic pmu_dcdc_en_tb;
  logic clk_32k_xtal_en_tb;
  logic clk_rc_prog_en_tb;
  logic [2:0] clk_rc_prog_freq_tb;
  logic [7:0] V_TH1_CFG_tb, V_TH2_CFG_tb;
  logic bor_event_int_clr_tb;
  logic soc_por_sw_ctrl_tb;

  // Outputs
  logic pmu_dcdc_ready_tb;
  logic VDD_AON_tb;
  logic VDD_SOC_tb;
  logic clk_32k_rc_tb;
  logic clk_32k_xtal_tb;
  logic clk_rc_prog_tb;
  logic pmu_vwarn_tb;
  logic bor_event_int_tb;
  logic soc_por_rst_n_tb;

  // DUT instantiation
  pmu_model u_pmu (
    .pmu_dcdc_en       (pmu_dcdc_en_tb),
    .pmu_dcdc_ready    (pmu_dcdc_ready_tb),
    .VDD_AON           (VDD_AON_tb),
    .VDD_SOC           (VDD_SOC_tb),

    .clk_32k_xtal_en   (clk_32k_xtal_en_tb),
    .clk_rc_prog_en    (clk_rc_prog_en_tb),
    .clk_rc_prog_freq  (clk_rc_prog_freq_tb),
    .clk_32k_rc        (clk_32k_rc_tb),
    .clk_32k_xtal      (clk_32k_xtal_tb),
    .clk_rc_prog       (clk_rc_prog_tb),

    .V_TH1_CFG         (V_TH1_CFG_tb),
    .V_TH2_CFG         (V_TH2_CFG_tb),
    .pmu_vwarn         (pmu_vwarn_tb),
    .bor_event_int     (bor_event_int_tb),
    .bor_event_int_clr (bor_event_int_clr_tb),
    .soc_por_rst_n     (soc_por_rst_n_tb),
    .soc_por_sw_ctrl   (soc_por_sw_ctrl_tb)
  );

  // Simple test scenario
  initial begin
    // Initialize inputs
    pmu_dcdc_en_tb       = 1'b0;
    clk_32k_xtal_en_tb   = 1'b0;
    clk_rc_prog_en_tb    = 1'b0;
    clk_rc_prog_freq_tb  = 3'b010; // default 1MHz
    V_TH1_CFG_tb         = 8'd150;
    V_TH2_CFG_tb         = 8'd100;
    bor_event_int_clr_tb = 1'b0;
    soc_por_sw_ctrl_tb   = 1'b0;

    // Wait some time
    #100_000ns;

    // Enable DC-DC
    pmu_dcdc_en_tb = 1'b1;
    // Wait for DC-DC ready
    @(posedge pmu_dcdc_ready_tb);
    $display("INFO: DC-DC is ready. VDD_SOC is stable.");

    // Enable 32K XTAL
    clk_32k_xtal_en_tb = 1'b1;

    // Enable programmable RC oscillator
    clk_rc_prog_en_tb = 1'b1;

    // Wait 200us
    #200_000ns;

    // Force a software reset
    soc_por_sw_ctrl_tb = 1'b1;
    #10;
    soc_por_sw_ctrl_tb = 1'b0;
    #50_000ns;

    // Clear BOR interrupt if set
    bor_event_int_clr_tb = 1'b1;
    #10;
    bor_event_int_clr_tb = 1'b0;

    // Done
    #200_000ns;
    $finish;
  end

endmodule
