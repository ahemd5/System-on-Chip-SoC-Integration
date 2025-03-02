`timescale 1ns/1ps

//======================================================================
// Classic Clock Gating Cell Module
//======================================================================
module gated_clk_cell(
    input  logic clk,   // Original clock
    input  logic en,    // Clock enable signal
    output logic gated_clk  // Gated clock output
);
    // Classic clock gating: clock is enabled only when 'en' is high
    assign gated_clk = clk & en;
endmodule

//======================================================================
// Programmable APB Register File with Specialized Behaviors
//======================================================================
module apb_register_file #(
    parameter ADDR_WIDTH = 32,  // Address bus width
    parameter DATA_WIDTH = 32,  // Data bus width
    parameter NUM_REGS   = 8    // Number of configurable registers
) (
    //==================================================================
    // APB Interface
    //==================================================================
    input  logic                    i_pclk,         // APB clock
    input  logic                    i_presetn,      // APB reset (active low)
    input  logic                    i_psel,         // Peripheral select
    input  logic                    i_penable,      // Enable signal for APB transaction
    input  logic                    i_pwrite,       // Write (1) / Read (0) indicator
    input  logic [ADDR_WIDTH-1:0]   i_paddr,        // Address bus
    input  logic [DATA_WIDTH-1:0]   i_pwdata,       // Write data bus
    output logic [DATA_WIDTH-1:0]   o_prdata,       // Read data bus
    output logic                    o_pready,       // Ready signal for handshake
    output logic                    o_pslverr,      // Error signal
    //==================================================================
    // Hardware Interface
    //==================================================================
    input  logic                    i_status_hw_en, // Enable for hardware update of STATUS
    input  logic [DATA_WIDTH-1:0]   i_status_hw,    // Hardware update data for STATUS
    input  logic                    i_toggle_event  // Toggle event signal for TOGGLE register
);

    //------------------------------------------------------------------
    // Address Map Definitions
    //------------------------------------------------------------------
    localparam REG0_ADDR       = 32'h00;  // REG0: RW
    localparam REG1_ADDR       = 32'h04;  // REG1: RW
    localparam STATUS_ADDR     = 32'h08;  // STATUS: SW-R/HW-W (SW writes ignored)
    localparam CONTROL_ADDR    = 32'h0C;  // CONTROL: SW-W/HW-R (read returns 0)
    localparam INT_ENABLE_ADDR = 32'h10;  // INT_ENABLE: RW
    localparam INT_STATUS_ADDR = 32'h14;  // INT_STATUS: W1C (Write 1 clears bits)
    localparam W1S_ADDR        = 32'h18;  // W1S: Write-1-to-Set
    localparam TOGGLE_ADDR     = 32'h1C;  // TOGGLE: HW toggles

    //------------------------------------------------------------------
    // Register Storage
    //------------------------------------------------------------------
    // Using a register array to store the values. Mapping:
    //   [0] -> REG0, [1] -> REG1, [2] -> STATUS, [3] -> CONTROL,
    //   [4] -> INT_ENABLE, [5] -> INT_STATUS, [6] -> W1S, [7] -> TOGGLE.
    logic [DATA_WIDTH-1:0] registers [0:NUM_REGS-1];

    //------------------------------------------------------------------
    // APB Ready Signal: Always ready for single-cycle access.
    //------------------------------------------------------------------
    assign o_pready = 1'b1;

    //------------------------------------------------------------------
    // Error Signal Logic: Only defined addresses are valid.
    //------------------------------------------------------------------
    logic error;
    always_comb begin
        error = 1'b0;
        if (i_psel && i_penable) begin
            if (i_pwrite) begin // Write transaction
                case (i_paddr)
                    REG0_ADDR,
                    REG1_ADDR,
                    CONTROL_ADDR,       // Allowed: SW writes CONTROL.
                    INT_ENABLE_ADDR,
                    INT_STATUS_ADDR,    // Allowed: W1C.
                    W1S_ADDR:           error = 1'b0; // Valid write addresses.
                    STATUS_ADDR,        // Not allowed: SW cannot write STATUS.
                    TOGGLE_ADDR:        error = 1'b1; // Not allowed: SW cannot write TOGGLE.
                    default:            error = 1'b1; // Invalid address.
                endcase
            end else begin // Read transaction
                case (i_paddr)
                    REG0_ADDR,
                    REG1_ADDR,
                    STATUS_ADDR,
                    INT_ENABLE_ADDR,
                    INT_STATUS_ADDR,
                    W1S_ADDR,
                    TOGGLE_ADDR:        error = 1'b0; // Valid read addresses.
                    CONTROL_ADDR:       error = 1'b1; // Not allowed: SW cannot read CONTROL.
                    default:            error = 1'b1; // Invalid address.
                endcase
            end
        end else begin
            error = 1'b0;
        end
    end
    assign o_pslverr = error;

    //------------------------------------------------------------------
    // Clock Gating for Software Write Operations
    //------------------------------------------------------------------
    // The gated clock is active only during valid SW write transactions.
    wire apb_write_en;
    assign apb_write_en = i_psel && i_penable && i_pwrite;
    wire gated_clk;
    gated_clk_cell u_gated_clk_cell (
        .clk(i_pclk),
        .en(apb_write_en),
        .gated_clk(gated_clk)
    );

    //------------------------------------------------------------------
    // Software Write Logic with Specialized Behaviors
    //------------------------------------------------------------------
    always_ff @(posedge gated_clk or negedge i_presetn) begin
        if (!i_presetn) begin
            // Reset all registers to 0.
            for (int i = 0; i < NUM_REGS; i++)
                registers[i] <= '0;
        end else if (apb_write_en && i_paddr < NUM_REGS * 4) begin
            case (i_paddr)
                REG0_ADDR: registers[0] <= i_pwdata; // REG0: RW
                REG1_ADDR: registers[1] <= i_pwdata; // REG1: RW
                STATUS_ADDR: begin
                    // STATUS is SW-R/HW-W. Ignore SW writes.
                end
                CONTROL_ADDR: registers[3] <= i_pwdata; // CONTROL: SW write accepted
                INT_ENABLE_ADDR: registers[4] <= i_pwdata; // INT_ENABLE: RW
                INT_STATUS_ADDR: begin
                    // INT_STATUS: W1C behavior.
                    // Clear bits where a '1' is written.
                    registers[5] <= registers[5] & ~i_pwdata;
                end
                W1S_ADDR: begin
                    // W1S: Write-1-to-Set behavior.
                    registers[6] <= registers[6] | i_pwdata;
                end
                default: ; // Do nothing for STATUS and TOGGLE.
            endcase
        end
    end

    //------------------------------------------------------------------
    // Hardware Update Logic for STATUS Register (SW-R/HW-W)
    //------------------------------------------------------------------
    always_ff @(posedge i_pclk or negedge i_presetn) begin
        if (!i_presetn)
            registers[2] <= '0;  // STATUS reset
        else if (i_status_hw_en)
            registers[2] <= i_status_hw; // Hardware updates STATUS
    end

    //------------------------------------------------------------------
    // Hardware Toggle Logic for TOGGLE Register (HW Toggles)
    //------------------------------------------------------------------
    always_ff @(posedge i_pclk or negedge i_presetn) begin
        if (!i_presetn)
            registers[7] <= '0;  // TOGGLE reset
        else if (i_toggle_event)
            registers[7] <= ~registers[7]; // Toggle register value
    end

    //------------------------------------------------------------------
    // APB Read Logic with Specialized Behaviors
    //------------------------------------------------------------------
    always_comb begin
        if (i_psel && i_penable && !i_pwrite) begin
            case (i_paddr)
                REG0_ADDR:       o_prdata = registers[0];
                REG1_ADDR:       o_prdata = registers[1];
                STATUS_ADDR:     o_prdata = registers[2];
                CONTROL_ADDR:    o_prdata = '0;           // CONTROL read returns 0.
                INT_ENABLE_ADDR: o_prdata = registers[4];
                INT_STATUS_ADDR: o_prdata = registers[5];
                W1S_ADDR:        o_prdata = registers[6];
                TOGGLE_ADDR:     o_prdata = registers[7];
                default:         o_prdata = '0;
            endcase
        end else begin
            o_prdata = '0;
        end
    end

endmodule
