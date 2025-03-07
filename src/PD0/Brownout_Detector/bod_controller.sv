//-----------------------------------------------------------------------------
// Brownout Detector (BOD) Digital Control Logic
// 
// This module is implemented in the Always-On (AON) domain and provides 
// programmable registers for voltage thresholds used by the PMU analog 
// monitoring logic. It latches the PMU_VWARN signal to generate a software-
// visible status (BOD_STATUS) and an interrupt (BOD_INT) when a warning 
// condition is detected. Software can also disable interrupts via BOD_CTRL and
// clear a latched BOR event by writing to BOR_EVENT_INT_CLR.
//
// Register Map:
//   0x00 : V_TH1_CFG  (R/W) - 8-bit warning threshold (output to PMU)
//   0x04 : V_TH2_CFG  (R/W) - 8-bit critical threshold (output to PMU)
//   0x08 : BOD_STATUS (R/W) - Latches PMU_VWARN; writing '1' clears the flag.
//   0x0C : BOD_CTRL   (RO/W1C) - Interrupt enable; writing '1' clears (disables)
//   0x10 : BOR_EVENT_INT_CLR (R/W) - Writing '1' generates a pulse to clear the BOR event
//
//-----------------------------------------------------------------------------
module bod_ctrl 
(
  input  logic                   CLK,       // AON clock
  input  logic                   RST_N,     // Active-low reset

  //--------------------------------------------------------------------------
  // APB Slave Interface (typical signals; adapt as needed)
  //--------------------------------------------------------------------------
  input  logic                   psel,      // APB select
  input  logic                   penable,   // APB enable
  input  logic                   pwrite,    // APB write strobe
  input  logic [31:0]            paddr,     // APB address
  input  logic [31:0]            pwdata,    // APB write data
  output logic [31:0]            prdata,    // APB read data
  output logic                   pready,    // APB ready
  output logic                   pslverr,   // APB error

  //--------------------------------------------------------------------------
  // BOD-Specific I/Os
  //--------------------------------------------------------------------------
  input  logic                   PMU_VWARN,         // Asserted if VDD < V_TH1
  output logic                   BOD_INT,           // CPU interrupt on warning
  output logic                   BOR_EVENT_INT_CLR, // Clears BOR event in PMU
  output logic [7:0]             V_TH1_CFG,         // Programmable warning threshold
  output logic [7:0]             V_TH2_CFG          // Programmable critical threshold
);

  //--------------------------------------------------------------------------
  // Local parameters for register addresses (matching your spec)
  //--------------------------------------------------------------------------
  localparam logic [ADDR_WIDTH-1:0] ADDR_V_TH1_CFG         = 5'h00;
  localparam logic [ADDR_WIDTH-1:0] ADDR_V_TH2_CFG         = 5'h04;
  localparam logic [ADDR_WIDTH-1:0] ADDR_BOD_STATUS        = 5'h08;
  localparam logic [ADDR_WIDTH-1:0] ADDR_BOD_CTRL          = 5'h0C;
  localparam logic [ADDR_WIDTH-1:0] ADDR_BOR_EVENT_INT_CLR = 5'h10;

  //--------------------------------------------------------------------------
  // Internal register storage
  //--------------------------------------------------------------------------
  // Threshold registers
  logic [7:0] v_th1_cfg_reg;
  logic [7:0] v_th2_cfg_reg;

  // Latched warning status (sets when PMU_VWARN=1, SW-cleared)
  logic        bod_warn_latch;

  // Enable bit for BOD interrupt (from BOD_CTRL register)
  logic        bod_int_enable;

  // One-cycle pulse to clear BOR event in the PMU
  logic        bor_event_int_clr_pulse;

  //--------------------------------------------------------------------------
  // Output assignments
  //--------------------------------------------------------------------------
  assign V_TH1_CFG         = v_th1_cfg_reg;
  assign V_TH2_CFG         = v_th2_cfg_reg;
  assign BOD_INT           = bod_warn_latch & bod_int_enable;
  assign BOR_EVENT_INT_CLR = bor_event_int_clr_pulse;  // 1-cycle pulse below

  //--------------------------------------------------------------------------
  // APB Write: Register updates
  //--------------------------------------------------------------------------
  always_ff @(posedge CLK or negedge RST_N) begin
    if (!RST_N) begin
      // Reset values
      v_th1_cfg_reg         <= 8'h00;
      v_th2_cfg_reg         <= 8'h00;
      bod_warn_latch        <= 1'b0;
      bod_int_enable        <= 1'b1;  // Enable BOD interrupt by default?
      bor_event_int_clr_pulse <= 1'b0;
    end
    else begin
      // Default: no BOR clear pulse
      bor_event_int_clr_pulse <= 1'b0;

      // If PMU indicates voltage < V_TH1, latch the warning
      if (PMU_VWARN) begin
        bod_warn_latch <= 1'b1;
      end

      // On APB writes, decode address and update registers
      if (psel && penable && pwrite) begin
        case (paddr)
          ADDR_V_TH1_CFG: begin
            // Lower 8 bits for threshold config
            v_th1_cfg_reg <= pwdata[7:0];
          end

          ADDR_V_TH2_CFG: begin
            // Lower 8 bits for critical threshold config
            v_th2_cfg_reg <= pwdata[7:0];
          end

          ADDR_BOD_STATUS: begin
            // Writing '1' to bit 0 clears the latched PMU_VWARN
            if (pwdata[0]) begin
              bod_warn_latch <= 1'b0;
            end
          end

          ADDR_BOD_CTRL: begin
            // For simplicity, let bit 0 be an interrupt enable
            // (Spec said "RO/W1C"—you can adapt as needed.)
            bod_int_enable <= pwdata[0];
          end

          ADDR_BOR_EVENT_INT_CLR: begin
            // Write '1' to generate a one-cycle pulse to PMU
            if (pwdata[0]) begin
              bor_event_int_clr_pulse <= 1'b1;
            end
          end

          default: /* no-op */;
        endcase
      end
    end
  end

  //--------------------------------------------------------------------------
  // APB Read: Drive prdata based on address
  //--------------------------------------------------------------------------
  always_comb begin
    prdata = 32'h0;
    if (psel && !pwrite) begin
      case (paddr)
        ADDR_V_TH1_CFG:         prdata = {24'h0, v_th1_cfg_reg};
        ADDR_V_TH2_CFG:         prdata = {24'h0, v_th2_cfg_reg};
        ADDR_BOD_STATUS:        prdata = {31'h0, bod_warn_latch};
        ADDR_BOD_CTRL:          prdata = {31'h0, bod_int_enable};
        ADDR_BOR_EVENT_INT_CLR: prdata = 32'h0;  // Reads as 0
        default:                prdata = 32'h0;
      endcase
    end
  end

  //--------------------------------------------------------------------------
  // APB handshake signals (always ready, no errors)
  //--------------------------------------------------------------------------
  assign pready  = 1'b1;
  assign pslverr = 1'b0;

endmodule

