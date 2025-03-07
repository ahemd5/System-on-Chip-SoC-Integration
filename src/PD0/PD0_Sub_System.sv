`timescale 1ns/1ps

module pd0_sub_system (
    input  wire clk,       // Possibly the main system clock
    input  wire reset_n    // Main system reset (active-low)
    // Other top-level I/Os as needed
);

    //---------------------------------------------------------------------
    // 1) APB Master signals (driven by some external master or testbench)
    //---------------------------------------------------------------------
    wire [31:0] PADDR_M;
    wire        PWRITE_M;
    wire        PSEL_M;
    wire        PENABLE_M;
    wire [31:0] PWDATA_M;
    wire [31:0] PRDATA_M;
    wire        PREADY_M;
    wire        PSLVERR_M;

    //---------------------------------------------------------------------
    // 2) APB Bus Slave Interfaces
    //---------------------------------------------------------------------
    // Slave 0 (AON/regfile)
    wire        PSEL_S0;
    wire        PENABLE_S0;
    wire [31:0] PADDR_S0;
    wire        PWRITE_S0;
    wire [31:0] PWDATA_S0;
    wire [31:0] PRDATA_S0;
    wire        PREADY_S0;
    wire        PSLVERR_S0;

    // Slave 1 (Power Controller)
    wire        PSEL_S1;
    wire        PENABLE_S1;
    wire [31:0] PADDR_S1;
    wire        PWRITE_S1;
    wire [31:0] PWDATA_S1;
    wire [31:0] PRDATA_S1;
    wire        PREADY_S1;
    wire        PSLVERR_S1;

    // Slave 2 (AON Timer)
    wire        PSEL_S2;
    wire        PENABLE_S2;
    wire [3:0]  PADDR_S2;  // Could be 32 bits, but using 4 here
    wire        PWRITE_S2;
    wire [31:0] PWDATA_S2;
    wire [31:0] PRDATA_S2;
    wire        PREADY_S2;
    wire        PSLVERR_S2;

    // Slave 3 (BrownOut Detector)
    wire        PSEL_S3;
    wire        PENABLE_S3;
    wire [31:0] PADDR_S3;
    wire        PWRITE_S3;
    wire [31:0] PWDATA_S3;
    wire [31:0] PRDATA_S3;
    wire        PREADY_S3;
    wire        PSLVERR_S3;

    //---------------------------------------------------------------------
    // 3) APB Bus
    //---------------------------------------------------------------------
    // Make sure your 'apb_bus' module has 4 slave ports (S0..S3).
    apb_bus u_apb_bus (
        // Bus clock/reset
        .PCLK         (clk),
        .PRESETn      (reset_n),

        // APB Master
        .PADDR_M      (PADDR_M),
        .PWRITE_M     (PWRITE_M),
        .PSEL_M       (PSEL_M),
        .PENABLE_M    (PENABLE_M),
        .PWDATA_M     (PWDATA_M),
        .PRDATA_M     (PRDATA_M),
        .PREADY_M     (PREADY_M),
        .PSLVERR_M    (PSLVERR_M),

        // Slave 0 - AON Regfile
        .PSEL_S0      (PSEL_S0),
        .PENABLE_S0   (PENABLE_S0),
        .PADDR_S0     (PADDR_S0),
        .PWRITE_S0    (PWRITE_S0),
        .PWDATA_S0    (PWDATA_S0),
        .PRDATA_S0    (PRDATA_S0),
        .PREADY_S0    (PREADY_S0),
        .PSLVERR_S0   (PSLVERR_S0),

        // Slave 1 - Power Controller
        .PSEL_S1      (PSEL_S1),
        .PENABLE_S1   (PENABLE_S1),
        .PADDR_S1     (PADDR_S1),
        .PWRITE_S1    (PWRITE_S1),
        .PWDATA_S1    (PWDATA_S1),
        .PRDATA_S1    (PRDATA_S1),
        .PREADY_S1    (PREADY_S1),
        .PSLVERR_S1   (PSLVERR_S1),

        // Slave 2 - AON Timer
        .PSEL_S2      (PSEL_S2),
        .PENABLE_S2   (PENABLE_S2),
        .PADDR_S2     (PADDR_S2),
        .PWRITE_S2    (PWRITE_S2),
        .PWDATA_S2    (PWDATA_S2),
        .PRDATA_S2    (PRDATA_S2),
        .PREADY_S2    (PREADY_S2),
        .PSLVERR_S2   (PSLVERR_S2),

        // Slave 3 - BrownOut Detector
        .PSEL_S3      (PSEL_S3),
        .PENABLE_S3   (PENABLE_S3),
        .PADDR_S3     (PADDR_S3),
        .PWRITE_S3    (PWRITE_S3),
        .PWDATA_S3    (PWDATA_S3),
        .PRDATA_S3    (PRDATA_S3),
        .PREADY_S3    (PREADY_S3),
        .PSLVERR_S3   (PSLVERR_S3)
    );

    //---------------------------------------------------------------------
    // 4) Power Controller signals
    //---------------------------------------------------------------------
    wire [2:0] wakeup_src     = 3'b000; 
    wire [1:0] hw_sleep_ack   = 2'b00;  
    wire [1:0] pwr_on_ack     = 2'b00;  

    // Outputs from Power Controller
    wire        dcdc_enable;
    wire [1:0]  top_hw_sleep_req;
    wire [1:0]  top_pwr_on_req;
    wire [1:0]  top_clk_en;
    wire [1:0]  top_iso;
    wire [1:0]  top_ret;
    wire [1:0]  top_rstn;

    //---------------------------------------------------------------------
    // 5) PMU Model (Now with BOD-related signals)
    //---------------------------------------------------------------------
    wire pmu_dcdc_ready;
    wire VDD_AON;
    wire VDD_SOC;

    // Low-power clock outputs
    wire clk_32k_rc;
    wire clk_32k_xtal;
    wire clk_rc_prog;

    // Brownout / Reset signals
    wire [7:0] V_TH1_CFG;      // from bod_ctrl
    wire [7:0] V_TH2_CFG;      // from bod_ctrl
    wire pmu_vwarn;            // to bod_ctrl
    wire bor_event_int;        // optional debug or NMI
    wire bor_event_int_clr;    // from bod_ctrl
    wire soc_por_rst_n;        // combined power-on reset
    wire soc_por_sw_ctrl = 1'b0; // example tie-off for SW-driven reset

    pmu_model u_pmu_model (
        // Power Control
        .pmu_dcdc_en       (dcdc_enable),
        .pmu_dcdc_ready    (pmu_dcdc_ready),

        // Power Supplies
        .VDD_AON           (VDD_AON),
        .VDD_SOC           (VDD_SOC),

        // Clock Control
        .clk_32k_xtal_en   (1'b1),      // always enable for example
        .clk_rc_prog_en    (1'b0),      // disabled for example
        .clk_rc_prog_freq  (3'b010),    // ~1MHz in the model

        .clk_32k_rc        (clk_32k_rc),
        .clk_32k_xtal      (clk_32k_xtal),
        .clk_rc_prog       (clk_rc_prog),

        // Brownout Detection & Reset
        .V_TH1_CFG         (V_TH1_CFG),       // from bod_ctrl registers
        .V_TH2_CFG         (V_TH2_CFG),       // from bod_ctrl registers
        .pmu_vwarn         (pmu_vwarn),       // to bod_ctrl
        .bor_event_int     (bor_event_int),   // optional debug or NMI
        .bor_event_int_clr (bor_event_int_clr), 
        .soc_por_rst_n     (soc_por_rst_n),
        .soc_por_sw_ctrl   (soc_por_sw_ctrl)
    );

    //---------------------------------------------------------------------
    // 6) AON Clock/Reset Generator
    //---------------------------------------------------------------------
    wire [1:0] aon_clk_sel = 2'b01; // 00=rc, 01=xtal, 10=rc_prog, etc.
    wire       aon_clk_en  = 1'b1;  // 1=enabled

    wire clk_aon;
    wire reset_aon_n; // active-low AON reset

    aon_clkreset_gen u_aon_clkreset_gen (
        // Low-power clock inputs
        .i_clk_32k_rc      (clk_32k_rc),
        .i_clk_32k_xtal    (clk_32k_xtal),
        .i_clk_rc_prog     (clk_rc_prog),

        // Resets in
        .i_reset_n         (reset_n),
        .i_soc_por_rst_n   (soc_por_rst_n),

        // Control
        .i_clk_sel         (aon_clk_sel),
        .i_clk_en          (aon_clk_en),

        // Outputs
        .o_clk_aon         (clk_aon),
        .o_reset_aon_n     (reset_aon_n)
    );

    //---------------------------------------------------------------------
    // 7) Power Controller (APB Slave 1), in the AON domain
    //---------------------------------------------------------------------
    top_powcntrl #(
        .N(2),
        .M(3),
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) u_top_powcntrl (
        // APB Interface
        .i_pwrite_top   (PWRITE_S1),
        .i_pwdata_top   (PWDATA_S1),
        .i_paddr_top    (PADDR_S1),
        .i_psel_top     (PSEL_S1),
        .i_penable_top  (PENABLE_S1),
        .o_prdata_top   (PRDATA_S1),
        .o_pslverr_top  (PSLVERR_S1),
        .o_pready_top   (PREADY_S1),

        // AON clock/reset
        .i_aon_clk      (clk_aon),
        // If the internal logic is active-high reset, invert here:
        .i_soc_pwr_on_rst(~reset_aon_n),

        // Wakeup & power ack
        .i_wakeup_src   (wakeup_src),
        .i_hw_sleep_ack (hw_sleep_ack),
        .i_pwr_on_ack   (pwr_on_ack),

        // Outputs
        .o_dcdc_enable  (dcdc_enable),
        .o_hw_sleep_req (top_hw_sleep_req),
        .o_pwr_on_req   (top_pwr_on_req),
        .o_clk_en       (top_clk_en),
        .o_iso          (top_iso),
        .o_ret          (top_ret),
        .o_rstn         (top_rstn)
    );

    //---------------------------------------------------------------------
    // 8) AON Regfile (APB Slave 0), in the AON domain
    //---------------------------------------------------------------------
    aon_regfile #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) u_aon_regfile (
        .PCLK      (clk_aon),
        .PRESETn   (reset_aon_n),
        .PSEL      (PSEL_S0),
        .PENABLE   (PENABLE_S0),
        .PWRITE    (PWRITE_S0),
        .PADDR     (PADDR_S0),
        .PWDATA    (PWDATA_S0),
        .PRDATA    (PRDATA_S0),
        .PREADY    (PREADY_S0),
        .PSLVERR   (PSLVERR_S0)
    );

    //---------------------------------------------------------------------
    // 9) AON Timer (APB Slave 2), in the AON domain
    //---------------------------------------------------------------------
    aon_timer #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(4)
    ) u_aon_timer (
        .PCLK      (clk_aon),
        .PRESETn   (reset_aon_n),
        .PSEL      (PSEL_S2),
        .PENABLE   (PENABLE_S2),
        .PWRITE    (PWRITE_S2),
        .PADDR     (PADDR_S2),
        .PWDATA    (PWDATA_S2),
        .PRDATA    (PRDATA_S2),
        .PREADY    (PREADY_S2),
        .PSLVERR   (PSLVERR_S2)
    );

    //---------------------------------------------------------------------
    // 10) BrownOut Detector (BOD) Digital Control Logic (APB Slave 3)
    //---------------------------------------------------------------------
    wire bod_int;  // optional CPU interrupt from BOD

    bod_ctrl u_bod_ctrl (
        // AON clock/reset
        .CLK    (clk_aon),
        .RST_N  (reset_aon_n),

        // APB Slave Interface
        .psel   (PSEL_S3),
        .penable(PENABLE_S3),
        .pwrite (PWRITE_S3),
        .paddr  (PADDR_S3),
        .pwdata (PWDATA_S3),
        .prdata (PRDATA_S3),
        .pready (PREADY_S3),
        .pslverr(PSLVERR_S3),

        // BOD-specific
        .PMU_VWARN         (pmu_vwarn),         // from PMU
        .BOD_INT           (bod_int),           // route to CPU if desired
        .BOR_EVENT_INT_CLR (bor_event_int_clr), // to PMU
        .V_TH1_CFG         (V_TH1_CFG),         // to PMU
        .V_TH2_CFG         (V_TH2_CFG)          // to PMU
    );

endmodule
