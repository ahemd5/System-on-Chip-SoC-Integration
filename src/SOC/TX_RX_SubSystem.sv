module TX_RX_SubSystem #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BUS_WIDTH  = 8
)(
    input  logic i_clk,
    input  logic i_rstn,

    // ---------------------------------------------------------------------
    // Master #0 (AHB to AHB bridge) interface
    // ---------------------------------------------------------------------
    output  logic                  m0_hready,
    output  logic                  m0_hresp,
    output  logic [DATA_WIDTH-1:0] m0_hrdata,
    input   logic                  m0_hwrite,
    input   logic [1:0]            m0_htrans,
    input   logic [2:0]            m0_hsize,
    input   logic [ADDR_WIDTH-1:0] m0_haddr,
    input   logic [DATA_WIDTH-1:0] m0_hwdata,

    // ---------------------------------------------------------------------
    // ADC/DAC connections
    // (Brought out at subsystem level so you can drive/test externally)
    // ---------------------------------------------------------------------
    input  bit                    clk_adc,
    input  real                   i_analog_in,
    output real                   o_analog_out,
    
    // ---------------------------------------------------------------------
    // interrupt from DSP --> CPU 
    // ---------------------------------------------------------------------
    output logic                  o_irq,
    
    // ---------------------------------------------------------------------
    // interrupt from DSP --> CPU 
    // ---------------------------------------------------------------------
    input logic [3:0]            gp_trig
    
);

   // ================== ADC/DAC connections for DSP=====================
    wire [BUS_WIDTH-1:0] adc_data;
    wire [BUS_WIDTH-1:0] dac_data;


    // ======================= Slave #0: gp_engine ========================
    wire                   s0_hreadyout;
    wire                   s0_hresp;
    wire [DATA_WIDTH-1:0]  s0_hrdata;
    wire                   s0_hsel;
    wire [ADDR_WIDTH-1:0]  s0_haddr_s;
    wire [DATA_WIDTH-1:0]  s0_hwdata_s;
    wire                   s0_hwrite;
    wire [2:0]             s0_hsize;
    wire [1:0]             s0_htrans;
    wire                   s0_hready;

    // ======================= Slave #1: dsp =============================
    wire                   s1_hreadyout;
    wire                   s1_hresp;
    wire [DATA_WIDTH-1:0]  s1_hrdata;
    wire                   s1_hsel;
    wire [ADDR_WIDTH-1:0]  s1_haddr_s;
    wire [DATA_WIDTH-1:0]  s1_hwdata_s;
    wire                   s1_hwrite;
    wire [2:0]             s1_hsize;
    wire [1:0]             s1_htrans;
    wire                   s1_hready;

    // ======================= Slave #2: data_xfer_memory ================
    wire                   s2_hreadyout;
    wire                   s2_hresp;
    wire [DATA_WIDTH-1:0]  s2_hrdata;
    wire                   s2_hsel;
    wire [ADDR_WIDTH-1:0]  s2_haddr_s;
    wire [DATA_WIDTH-1:0]  s2_hwdata_s;
    wire                   s2_hwrite;
    wire [2:0]             s2_hsize;
    wire [1:0]             s2_htrans;
    wire                   s2_hready;

    // ======================= Master #1: gp_engine ======================
    wire                   m1_hready;
    wire                   m1_hresp;
    wire [DATA_WIDTH-1:0]  m1_hrdata;
    wire                   m1_hwrite;
    wire [1:0]             m1_htrans;
    wire [2:0]             m1_hsize;
    wire [ADDR_WIDTH-1:0]  m1_haddr;
    wire [DATA_WIDTH-1:0]  m1_hwdata;

    // ---------------------------------------------------------------------
    // Address ranges for the 3 slaves (adjust to your memory map)
    //   Slave #0 (gp_engine):  0x7000_0000 -> 0x7554_B97F
    //   Slave #1 (dsp):        0x7554_B980 -> 0x7A9A_52FF
    //   Slave #2 (memory):     0x7A9A_5300 -> 0x7FFE_2B3F
    // ---------------------------------------------------------------------
    localparam [ADDR_WIDTH-1:0] start_addr_s0 = 32'h7000_0000;
    localparam [ADDR_WIDTH-1:0] end_addr_s0   = 32'h7554_B97F;

    localparam [ADDR_WIDTH-1:0] start_addr_s1 = 32'h7554_B980;
    localparam [ADDR_WIDTH-1:0] end_addr_s1   = 32'h7A9A_52FF;

    localparam [ADDR_WIDTH-1:0] start_addr_s2 = 32'h7A9A_5300;
    localparam [ADDR_WIDTH-1:0] end_addr_s2   = 32'h7FFE_2B3F;

    // ---------------------------------------------------------------------
    // 1) AHB Interconnect (2 Masters, 3 Slaves)
    // ---------------------------------------------------------------------
    AHB_interconnect #(
        .NUM_MASTERS (2),
        .NUM_SLAVES  (3),
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_ahb_interconnect (
        .i_clk      (i_clk),
        .i_reset_n  (i_rstn),

        // =========== Slave Inputs ==============
        .i_hreadyout({s2_hreadyout, s1_hreadyout, s0_hreadyout}),
        .i_hrdata   ({s2_hrdata,    s1_hrdata,    s0_hrdata   }),
        .i_hresp    ({s2_hresp,     s1_hresp,     s0_hresp    }),

        // =========== Master Inputs =============
        .i_hsize    ({m1_hsize,     m0_hsize    }),
        .i_htrans   ({m1_htrans,    m0_htrans   }),
        .i_hwrite   ({m1_hwrite,    m0_hwrite   }),
        .i_haddr    ({m1_haddr,     m0_haddr    }),
        .i_hwdata   ({m1_hwdata,    m0_hwdata   }),
        .i_hprot    ({4'b0011,      4'b0011     }), // default HPROT

        // =========== Address Ranges ============
        .START_ADDR ({start_addr_s2, start_addr_s1, start_addr_s0}),
        .END_ADDR   ({end_addr_s2,   end_addr_s1,   end_addr_s0}),

        // =========== Outputs to Slaves =========
        .o_hsize    ({s2_hsize,  s1_hsize,  s0_hsize }),
        .o_shready  ({s2_hready, s1_hready, s0_hready}),
        .o_htrans   ({s2_htrans, s1_htrans, s0_htrans}),
        .o_hwrite   ({s2_hwrite, s1_hwrite, s0_hwrite}),
        .o_haddr    ({s2_haddr_s, s1_haddr_s, s0_haddr_s}),
        .o_hwdata   ({s2_hwdata_s, s1_hwdata_s, s0_hwdata_s}),
        .o_hselx    ({s2_hsel,   s1_hsel,   s0_hsel  }),
        .o_hprot    (/* unused */),

        // =========== Outputs to Masters ========
        .o_hrdata   ({m1_hrdata, m0_hrdata}),
        .o_hresp    ({m1_hresp,  m0_hresp }),
        .o_mhready  ({m1_hready, m0_hready})
    );

    // ---------------------------------------------------------------------
    // 2) gp_engine (Slave #0 + Master #1)
    // ---------------------------------------------------------------------
    gp_engine #(
        .DATA_WIDTH       (DATA_WIDTH),
        .ADDR_WIDTH       (ADDR_WIDTH),
        .TRANS_ADDR_WIDTH (8),
        .CMD_WIDTH        (64),
        .NO_TRIG_SR       (4),
        .BUFFER_WIDTH     (32),
        .BUFFER_DEPTH     (256)
    ) u_gp_engine (
        .i_clk            (i_clk),
        .i_rstn           (i_rstn),

        // Slave #0 side
        .i_hready_slave   (s0_hready),
        .i_htrans_slave   (s0_htrans[1]), // single‐bit in gp_engine
        .i_hsize_slave    (s0_hsize),
        .i_hwrite_slave   (s0_hwrite),
        .i_haddr_slave    (s0_haddr_s),
        .i_hwdata_slave   (s0_hwdata_s),
        .i_hselx_slave    (s0_hsel),
        .o_hreadyout_slave(s0_hreadyout),
        .o_hresp_slave    (s0_hresp),
        .o_hrdata_slave   (s0_hrdata),

        // Example triggers
        .i_str_trig       (gp_trig),

        // Master #1 side
        .i_hready_master  (m1_hready),
        .i_hresp_master   (m1_hresp),
        .o_hwrite_master  (m1_hwrite),
        .o_htrans_master  (m1_htrans[1]), // single bit
        .o_hsize_master   (m1_hsize),
        .i_hrdata_master  (m1_hrdata),
        .o_haddr_master   (m1_haddr),
        .o_hwdata_master  (m1_hwdata)
    );

    // ---------------------------------------------------------------------
    // 3) dsp (Slave #1)
    // ---------------------------------------------------------------------
    dsp #(
        .DATA_WIDTH  (DATA_WIDTH),
        .D_SIZE      (16),
        .TAP_SIZE    (4),
        .BUS_WIDTH   (BUS_WIDTH)
    ) u_dsp (
        .clk_ahb      (i_clk),
        .rst_ahb      (i_rstn),
        .clk_adc      (clk_adc),
        .rst_adc      (i_rstn),

        // AHB Slave #1
        .i_hready     (s1_hready),
        .i_htrans     (s1_htrans[1]),
        .i_hsize      (s1_hsize),
        .i_hwrite     (s1_hwrite),
        .i_haddr      (s1_haddr_s),
        .i_hwdata     (s1_hwdata_s),
        .i_hselx      (s1_hsel),
        .o_hreadyout  (s1_hreadyout),
        .o_hresp      (s1_hresp),
        .o_hrdata     (s1_hrdata),

        // ADC / DAC connections
        .i_adc_data   (adc_data),
        .o_dac_data   (dac_data),

        // Interrupt
        .irq        (o_irq)
    );

    // ---------------------------------------------------------------------
    // 4) data_xfer_memory (Slave #2)
    // ---------------------------------------------------------------------
    data_xfer_memory #(
        .ADDR_WIDTH  (ADDR_WIDTH),
        .DATA_WIDTH  (DATA_WIDTH),
        .WAIT_STATES (0)
    ) u_data_xfer_memory (
        .HCLK         (i_clk),
        .HRESETn      (i_rstn),
        .HSEL         (s2_hsel),
        .HADDR        (s2_haddr_s),
        .HWDATA       (s2_hwdata_s),
        .HWRITE       (s2_hwrite),
        .HTRANS       (s2_htrans),
        .HREADY       (s2_hready),
        .HRDATA       (s2_hrdata),
        .HREADYOUT    (s2_hreadyout),
        .HRESP        (s2_hresp)
    );
    
    // -----------------------------------------------------------------
    // 5) ADC/DAC Models (8-bit)
    // -----------------------------------------------------------------
    // ADC model
    adc_model u_adc_model (
        .adc_clk   (clk_adc),
        .analog_in (i_analog_in),
        .adc_data  (adc_data)
    );

    // DAC model
    dac_model u_dac_model (
        .dac_clk    (clk_adc),
        .dac_data   (dac_data),
        .analog_out (o_analog_out)
    );

endmodule

