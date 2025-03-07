module top_powcntrl #(
    parameter N          = 2,
    parameter M          = 3,
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    // Interface signals (from powcntrl_intf dut modport)
    input  wire                  i_aon_clk,
    input  wire                  i_soc_pwr_on_rst,
    input  wire [M-1:0]          i_wakeup_src,
    input  wire [N-1:0]          i_hw_sleep_ack,
    input  wire [N-1:0]          i_pwr_on_ack,
    input  wire                  i_pwrite_top,
    input  wire [DATA_WIDTH-1:0] i_pwdata_top,
    input  wire [ADDR_WIDTH-1:0] i_paddr_top,
    input  wire                  i_psel_top,
    input  wire                  i_penable_top,
    output wire [DATA_WIDTH-1:0] o_prdata_top,
    output wire                  o_pslverr_top,
    output wire                  o_pready_top,
    output wire                  o_dcdc_enable,
    output wire [N-1:0]          o_hw_sleep_req,
    output wire [N-1:0]          o_pwr_on_req,
    output wire [N-1:0]          o_clk_en,
    output wire [N-1:0]          o_iso,
    output wire [N-1:0]          o_ret,
    output wire [N-1:0]          o_rstn
);

    // Internal signals
    logic [N-1:0] o_pwr_on_req_fsm;
    logic [2:0]   c_s, c_s_2; 
    logic         dcdc_enable;  // Local signal coming from fsm_pd1

    // Interface between APB slave and Regfile
    logic                 o_valid, i_ready;      
    logic [ADDR_WIDTH-1:0] o_addr;      
    logic                 o_rd0_wr1;   
    logic [DATA_WIDTH-1:0] o_wr_data;    
    logic                 i_rd_valid;    
    logic [DATA_WIDTH-1:0] i_rd_data; 

    // Interface between Regfile and FSM1/2
    logic                 pwrgate_enable;
    logic [N-1:0]         o_sleep_req;
    logic [N-1:0]         domain_status, wakeup_req;
    logic [M*N-1:0]       wakeup_enable; // Note: original declaration used (M* N)-1:0

    // Interface between FSM1 and FSM2
    logic pwr_off_req2;

    // Interface between FSM and counter
    logic [N-1:0] iso, ret, rstn, clk_en;

    // Interface between Regfile and counter (delays)
    logic [3:0] pwr_on_seq_delay, pwr_off_seq_delay; // Delays between control events
    logic [7:0] pwr_on_delay;   // Delay before asserting o_dcdc_enable during power-on.
    logic [7:0] pwr_off_delay;  // Delay before deasserting o_dcdc_enable during power-off.

    // Generate wakeup requests (example: using bits [2:0] and [5:3])
    assign wakeup_req[0] = |(wakeup_enable[2:0] & i_wakeup_src);
    assign wakeup_req[1] = |(wakeup_enable[5:3] & i_wakeup_src);

    // Instance of the APB slave module
    apb_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u0_apb_slave (
        .o_wr_data(o_wr_data),
        .o_addr(o_addr),
        .i_rstn_apb(!i_soc_pwr_on_rst),
        .i_clk_apb(i_aon_clk), 
        .o_valid(o_valid), 
        .o_rd0_wr1(o_rd0_wr1),
        .i_rd_data(i_rd_data),
        .i_rd_valid(i_rd_valid), 
        .i_ready(i_ready),
        .i_pwdata(i_pwdata_top),
        .i_paddr(i_paddr_top),
        .i_psel(i_psel_top),
        .i_penable(i_penable_top), 
        .i_pwrite(i_pwrite_top),
        .o_prdata(o_prdata_top),
        .o_pslverr(o_pslverr_top), 
        .o_pready(o_pready_top)
    );

    // Instance of the aon_regfile module
    aon_regfile #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(N),
        .M(M)
    ) u1_rf (
        .i_aon_clk             (i_aon_clk),
        .i_soc_pwr_on_rst      (i_soc_pwr_on_rst),
        .slv_o_valid           (o_valid),
        .slv_o_wr_data         (o_wr_data),
        .slv_o_addr            (o_addr),
        .slv_o_rd0_wr1         (o_rd0_wr1),
        .slv_i_ready           (i_ready),
        .slv_i_rd_data         (i_rd_data),
        .slv_i_rd_valid        (i_rd_valid),
        .rf_o_sleep_req        (o_sleep_req),
        .rf_o_wakeup_enable    (wakeup_enable),
        .rf_o_pwrgate_enable   (pwrgate_enable),
        .fsm_o_d_status        (domain_status),
        .rf_o_pwr_on_seq_delay (pwr_on_seq_delay),
        .rf_o_pwr_off_seq_delay(pwr_off_seq_delay),
        .rf_o_pwr_on_delay     (pwr_on_delay),
        .rf_o_pwr_off_delay    (pwr_off_delay),
        .o_iso                 (o_iso[0]),
        .o_ret                 (o_ret[0]),
        .o_rstn                (o_rstn[0]),
        .o_clk_en              (o_clk_en[0])
    );

    // Instance of FSM for power domain 1
    fsm_pd1 u2_fsm_pd1 (
        .i_aon_clk         (i_aon_clk),
        .i_soc_pwr_on_rst  (i_soc_pwr_on_rst),
        .i_wakeup_req_1    (wakeup_req[0]),
        .i_wakeup_req_2    (wakeup_req[1]),
        .i_sleep_req       (o_sleep_req[0]),
        .i_pwrgate_en      (pwrgate_enable),
        .i_hw_sleep_ack    (i_hw_sleep_ack[0]),
        .i_pwr_on_ack      (i_pwr_on_ack[0]),
        .i_pwr_on_ack_2    (i_pwr_on_ack[1]),
        .o_d_status        (domain_status[0]),
        .o_pwr_off_req2    (pwr_off_req2),
        .o_dcdc_enable     (dcdc_enable),
        .o_hw_sleep_req    (o_hw_sleep_req[0]),
        .o_pwr_on_req      (o_pwr_on_req_fsm[0]),
        .o_clk_en          (clk_en[0]),
        .o_iso             (iso[0]),
        .o_ret             (ret[0]),
        .o_rstn            (rstn[0]),
        .c_s               (c_s)
    );

    // Instance of FSM for power domain 2
    fsm_pd2 u3_fsm_pd2 (
        .i_aon_clk         (i_aon_clk),
        .i_soc_pwr_on_rst  (i_soc_pwr_on_rst),
        .i_wakeup_req      (wakeup_req[1]),
        .i_sleep_req       (o_sleep_req[1]),
        .i_pwr_on_ack      (i_pwr_on_ack[1]),
        .i_hw_sleep_ack    (i_hw_sleep_ack[1]),
        .i_pwr_off_req2    (pwr_off_req2),
        .o_d_status        (domain_status[1]),
        .o_pwr_on_req      (o_pwr_on_req_fsm[1]),
        .o_hw_sleep_req    (o_hw_sleep_req[1]),
        .o_clk_en          (clk_en[1]),
        .o_iso             (iso[1]),
        .o_ret             (ret[1]),
        .o_rstn            (rstn[1]),
        .c_s_2             (c_s_2)
    );

    // Counter instance for FSM1 outputs
    counter_PD1 #(.N(N)) counter_inst1 (
        .i_aon_clk         (i_aon_clk),
        .i_soc_pwr_on_rst  (i_soc_pwr_on_rst),
        .pwr_off_seq_delay (pwr_off_seq_delay),
        .pwr_on_seq_delay  (pwr_on_seq_delay),
        .i_pwr_on_ack      (i_pwr_on_ack[0]),
        .sleep_req         (o_sleep_req[0]),
        .i_hw_sleep_ack    (i_hw_sleep_ack[0]),
        .o_pwr_on_req_fsm  (o_pwr_on_req_fsm[0]),
        .o_pwr_on_req      (o_pwr_on_req[0]),
        .i_iso             (iso[0]),
        .i_ret             (ret[0]),
        .i_rstn            (rstn[0]),
        .i_clk_en          (clk_en[0]),
        .o_iso             (o_iso[0]),
        .o_ret             (o_ret[0]),
        .o_rstn            (o_rstn[0]),
        .o_clk_en          (o_clk_en[0])
    );

    // Counter instance for FSM2 outputs
    counter_PD2 #(.N(N)) counter_inst2 (
        .i_aon_clk         (i_aon_clk),
        .i_soc_pwr_on_rst  (i_soc_pwr_on_rst),
        .pwr_off_seq_delay (pwr_off_seq_delay),
        .pwr_on_seq_delay  (pwr_on_seq_delay),
        .i_pwr_on_ack      (i_pwr_on_ack[1]),
        .i_hw_sleep_ack    (i_hw_sleep_ack[1]),
        .sleep_req         (o_sleep_req[1]),
        .o_pwr_on_req_fsm  (o_pwr_on_req_fsm[1]),
        .o_pwr_on_req      (o_pwr_on_req[1]),
        .i_iso             (iso[1]),
        .i_ret             (ret[1]),
        .i_rstn            (rstn[1]),
        .i_clk_en          (clk_en[1]),
        .o_iso             (o_iso[1]),
        .o_ret             (o_ret[1]),
        .o_rstn            (o_rstn[1]),
        .o_clk_en          (o_clk_en[1]),
        .wakeup_req        (wakeup_req[1])
    );

    // Instance of the DCDC enable module
    dcdc_enable dcdc_enable_inst (
        .i_aon_clk        (i_aon_clk),
        .i_soc_pwr_on_rst (i_soc_pwr_on_rst),
        .pwr_on_delay     (pwr_on_delay),
        .pwr_off_delay    (pwr_off_delay),
        .i_pwr_on_ack     (i_pwr_on_ack[0]),
        .i_hw_sleep_ack   (i_hw_sleep_ack[0]),
        .i_dcdc_enable    (dcdc_enable),
        .sleep_req        (o_sleep_req[0]),
        .o_dcdc_enable    (o_dcdc_enable)
    );

endmodule
