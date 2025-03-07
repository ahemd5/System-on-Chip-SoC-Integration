`timescale 1ns/1ps

module pmu_model (
  // Power Control
  input  logic        pmu_dcdc_en,        // Enable DC-DC for main SoC power
  output logic        pmu_dcdc_ready,     // DC-DC stable indicator

  // Power Supplies (modeled as simple on/off in this example)
  output logic        VDD_AON,            // AON domain power
  output logic        VDD_SOC,            // Main SoC domain power

  // Clock Control
  input  logic        clk_32k_xtal_en,    // Enable 32K XTAL oscillator
  input  logic        clk_rc_prog_en,     // Enable programmable RC oscillator
  input  logic [2:0]  clk_rc_prog_freq,   // Frequency setting for RC oscillator

  output logic        clk_32k_rc,         // 32K RC oscillator output
  output logic        clk_32k_xtal,       // 32K XTAL oscillator output
  output logic        clk_rc_prog,        // Programmable RC oscillator output

  // Brownout Detection & Reset
  input  logic [7:0]  V_TH1_CFG,          // Warning threshold
  input  logic [7:0]  V_TH2_CFG,          // Critical threshold
  output logic        pmu_vwarn,          // Warning: voltage below TH1
  output logic        bor_event_int,      // Brownout reset event (NMI to CPU)
  input  logic        bor_event_int_clr,  // Clears bor_event_int
  output logic        soc_por_rst_n,      // SoC power-on-reset (active-low)
  input  logic        soc_por_sw_ctrl     // Software-driven PoR trigger
);

  // ------------------------------------------------------------------------
  // 1) Internal “supply” level tracking (for verification only)
  //    We model VDD_SOC as a numeric value that ramps up/down.
  //    For a purely functional test, many teams simply treat supplies as
  //    a boolean (0=off, 1=on). Here we do a trivial integer ramp.
  // ------------------------------------------------------------------------
  integer vdd_soc_level;       // Mock supply level (0..255 range)
  parameter integer RAMP_STEP = 5;    // How quickly supply ramps
  parameter integer VDD_ON_LEVEL = 200; // "Good" supply level
  parameter integer T_RAMP = 50;       // Delay for each ramp step (ns)

  // ------------------------------------------------------------------------
  // 2) AON supply is assumed always powered in a real design.
  //    For the model, we’ll just tie it high to represent “always on.”
  // ------------------------------------------------------------------------
  initial begin
    VDD_AON = 1'b1;  // AON domain always on
    vdd_soc_level = 0;      // Start main SoC domain at 0
    VDD_SOC      = 1'b0;    
  end

  // ------------------------------------------------------------------------
  // 3) DC-DC Enable / pmu_dcdc_ready logic
  //    - When pmu_dcdc_en goes high, we ramp up VDD_SOC.
  //    - When pmu_dcdc_en goes low, we ramp down VDD_SOC.
  //    - pmu_dcdc_ready goes high when VDD_SOC is above a “good” level.
  // ------------------------------------------------------------------------
  always @(pmu_dcdc_en) begin
    if (pmu_dcdc_en) begin
      // Ramp up
      fork
        begin : RAMP_UP
          while (vdd_soc_level < VDD_ON_LEVEL) begin
            #(T_RAMP);
            vdd_soc_level = vdd_soc_level + RAMP_STEP;
          end
        end
        begin : WAIT_UNTIL_DONE
          @ (posedge (vdd_soc_level >= VDD_ON_LEVEL));
          VDD_SOC       <= 1'b1;
          pmu_dcdc_ready <= 1'b1;
        end
      join
    end
    else begin
      // Ramp down
      fork
        begin : RAMP_DOWN
          while (vdd_soc_level > 0) begin
            #(T_RAMP);
            vdd_soc_level = vdd_soc_level - RAMP_STEP;
          end
        end
        begin : WAIT_UNTIL_OFF
          @ (posedge (vdd_soc_level == 0));
          VDD_SOC       <= 1'b0;
          pmu_dcdc_ready <= 1'b0;
        end
      join
    end
  end

  // ------------------------------------------------------------------------
  // 4) Brownout Detection
  //    - pmu_vwarn is asserted if vdd_soc_level < V_TH1_CFG
  //    - If vdd_soc_level < V_TH2_CFG => triggers BOR event & resets SoC
  // ------------------------------------------------------------------------
  always_comb begin
    pmu_vwarn = (vdd_soc_level < V_TH1_CFG);
  end

  // BOR event register
  logic bor_event_reg;

  // Asynchronous brownout check
  always @(vdd_soc_level or V_TH2_CFG) begin
    if (vdd_soc_level < V_TH2_CFG) begin
      // Trigger BOR event if we are powered at all
      if (VDD_SOC) begin
        bor_event_reg <= 1'b1;
      end
    end
  end

  // Clearing BOR event
  always @(posedge bor_event_int_clr) begin
    bor_event_reg <= 1'b0;
  end

  // Connect internal BOR register out to bor_event_int
  assign bor_event_int = bor_event_reg;

  // ------------------------------------------------------------------------
  // 5) SoC Power-on-Reset (soc_por_rst_n)
  //    - If BOR event occurs, force soc_por_rst_n low
  //    - If SW triggers a PoR (rising edge on soc_por_sw_ctrl), also assert reset
  //    - After a short delay, release reset if supply is stable
  // ------------------------------------------------------------------------
  reg  soc_por_rst_reg;
  wire sw_por_trigger;
  reg  soc_por_sw_ctrl_d;

  // Capture old value for edge detection
  always @(posedge clk_32k_rc) begin
    soc_por_sw_ctrl_d <= soc_por_sw_ctrl;
  end
  assign sw_por_trigger = (~soc_por_sw_ctrl_d & soc_por_sw_ctrl); // Rising edge

  // Simple PoR logic
  initial soc_por_rst_reg = 1'b0;  // Start in reset de-asserted (can invert if needed)

  always @* begin
    // If BOR or SW trigger => force reset low
    if (bor_event_reg || sw_por_trigger) begin
      soc_por_rst_reg = 1'b0;
    end
    else begin
      // Release reset if supply is stable
      if (pmu_dcdc_ready) soc_por_rst_reg = 1'b1;
    end
  end

  assign soc_por_rst_n = soc_por_rst_reg;

  // ------------------------------------------------------------------------
  // 6) Clock Generation
  //    For simplicity, we generate three separate clocks:
  //    - 32K RC always toggles at a fixed slow rate
  //    - 32K XTAL toggles if enabled
  //    - RC programmable toggles if enabled, with period determined by freq code
  // ------------------------------------------------------------------------
  
  // 6.1) 32K RC oscillator: fixed ~32kHz in real HW
  //      In the testbench we just toggle slowly for demonstration.
  reg clk_32k_rc_reg;
  initial clk_32k_rc_reg = 1'b0;
  always begin
    #15300; // ~32kHz half period in ns = 1/(32e3*2) seconds => 15.625us, approx
    clk_32k_rc_reg = ~clk_32k_rc_reg;
  end
  assign clk_32k_rc = clk_32k_rc_reg;

  // 6.2) 32K XTAL oscillator
  reg clk_32k_xtal_reg;
  initial clk_32k_xtal_reg = 1'b0;
  always begin
    if (clk_32k_xtal_en) begin
      #15300;
      clk_32k_xtal_reg = ~clk_32k_xtal_reg;
    end
    else begin
      // If disabled, hold at 0
      clk_32k_xtal_reg = 1'b0;
      @(posedge clk_32k_xtal_en); // wait until re-enabled
    end
  end
  assign clk_32k_xtal = clk_32k_xtal_reg;

  // 6.3) Programmable RC oscillator
  //     We create a function that returns half-period in ns based on freq code.
  function integer get_rc_prog_halfperiod(input [2:0] freq_sel);
    case(freq_sel)
      3'b000: get_rc_prog_halfperiod = 3906;  // ~128kHz => half T=3906ns
      3'b001: get_rc_prog_halfperiod = 977;   // ~512kHz => half T=977ns
      3'b010: get_rc_prog_halfperiod = 500;   // ~1MHz => half T=500ns
      3'b011: get_rc_prog_halfperiod = 125;   // ~4MHz => half T=125ns
      3'b100: get_rc_prog_halfperiod = 50;    // ~10MHz => half T=50ns
      3'b101: get_rc_prog_halfperiod = 25;    // ~20MHz => half T=25ns
      3'b110: get_rc_prog_halfperiod = 12;    // ~40MHz => half T=12.5ns
      3'b111: get_rc_prog_halfperiod = 6;     // ~80MHz => half T=6.25ns
      default: get_rc_prog_halfperiod = 500;  // default 1MHz
    endcase
  endfunction

  reg clk_rc_prog_reg;
  initial clk_rc_prog_reg = 1'b0;

  always begin
    if (clk_rc_prog_en) begin
      #(get_rc_prog_halfperiod(clk_rc_prog_freq));
      clk_rc_prog_reg = ~clk_rc_prog_reg;
    end
    else begin
      // If disabled, hold at 0
      clk_rc_prog_reg = 1'b0;
      @(posedge clk_rc_prog_en); // wait until re-enabled
    end
  end
  assign clk_rc_prog = clk_rc_prog_reg;

endmodule
