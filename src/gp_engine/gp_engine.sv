module gp_engine #(
    parameter DATA_WIDTH = 32,           // Width of data being transferred (default: 32-bit)
    parameter ADDR_WIDTH = 32,           // Address width (default: 32-bit)
    parameter TRANS_ADDR_WIDTH = 8,      // Width for address translation (default: 8-bit)
    parameter CMD_WIDTH  = 64,           // Command width (default: 64-bit)
    parameter NO_TRIG_SR = 4,             // Number of trigger sources (default: 4)
	parameter BUFFER_WIDTH = 32,         // Width of command buffer
    parameter BUFFER_DEPTH = 256        // command buffer depth
)(
    
    // Clock and Reset signals
    input logic i_clk,                  // Clock signal
    input logic i_rstn,                 // Active low reset signal
    
    // AHB-Lite Slave Interface (Incoming)
    input logic i_hready_slave,        // ready signal for handshaking interface 
    input logic i_htrans_slave,        // AHB slave transfer type (IDLE, NONSEQ)
    input logic [2:0] i_hsize_slave,   // Size of the transfer (byte, halfword, word)
    input logic i_hwrite_slave,        // Write control signal (1 = write, 0 = read)
    input logic [ADDR_WIDTH-1:0] i_haddr_slave,  // Address for address decoder
    input logic [DATA_WIDTH-1:0] i_hwdata_slave, // Write data
    input logic i_hselx_slave,         // Slave select signal
    output reg o_hreadyout_slave,      
    output reg o_hresp_slave,          // Response signal for the slave always ok and equal zero 
    output reg [DATA_WIDTH-1:0] o_hrdata_slave, 
    
    // Trigger Inputs (4 triggers)
    input logic [NO_TRIG_SR-1:0] i_str_trig,    // Trigger signal (for 4 sources)
    
    // AHB-Lite Master Interface (Outgoing)
    input  logic i_hready_master,                 // intrconnect ready signal, indicates the bus is ready for transfer
    input  logic i_hresp_master,                   // intrconnect response signal (assumed always OKAY in this design)
    output reg   o_hwrite_master,                  // Write control signal (1 for write, 0 for read)
    output reg   o_htrans_master,                  // Transfer type (IDLE, NONSEQ)
    output reg   [2:0] o_hsize_master,             // Size of the transfer (32 bit word-aligned)
    input  logic [DATA_WIDTH-1:0] i_hrdata_master, // Data received during a read operation
    output reg   [ADDR_WIDTH-1:0] o_haddr_master,  // Address for the current transfer
    output reg   [DATA_WIDTH-1:0] o_hwdata_master  // Data sent during a write operation
);

    // Internal Signals
	logic                  slv_o_valid;     // Valid transaction from AHB Slave
    logic [DATA_WIDTH-1:0] slv_o_wr_data;   // Write data from AHB Slave
    logic                  slv_o_rd0_wr1;   // Read/write indicator (1 = write)
    logic                  slv_i_ready_cmd;     // CMD Buffer or reg file ready for new transaction
    logic [DATA_WIDTH-1:0] slv_i_rd_data_cmd;   // Data read for debugging
    logic                  slv_i_rd_valid_cmd;   // Buffer or reg file sent read valid signal
	
	logic                  slv_i_ready_reg;     // CMD Buffer or reg file ready for new transaction
    logic [DATA_WIDTH-1:0] slv_i_rd_data_reg;   // Data read for debugging
    logic                  slv_i_rd_valid_reg;   // Buffer or reg file sent read valid signal
	
	logic [ADDR_WIDTH-1:0]       slv_o_addr;   // 32-bit AHB SLAVE Address  
    logic [TRANS_ADDR_WIDTH-1:0] trans_addr;   // Translated address (offset)
    logic                        reg_en;       // Enable signal for Register File
    logic                        cmd_en;        // Enable signal for Command Buffer
	

    logic [DATA_WIDTH-1:0]  rd_trig_s1_config; // Config for trigger source 1
    logic [DATA_WIDTH-1:0]  rd_trig_s2_config; // Config for trigger source 2
    logic [DATA_WIDTH-1:0]  rd_trig_s3_config; // Config for trigger source 3
    logic [DATA_WIDTH-1:0]  rd_trig_s4_config; // Config for trigger source 4
    logic                   reg_rd_valid;      // Register read valid
    logic                   reg_rd_en;         // Register read enable

    logic [CMD_WIDTH-1:0]          cmd_out;   // Command data
    logic                     cmd_rd_valid;   // Command read valid
    logic                        cmd_rd_en;   // Command read enable
    logic [TRANS_ADDR_WIDTH-1:0]  cmd_addr;   // Command address

    logic                  fsm_i_ready;      // Master ready signal
    logic [DATA_WIDTH-1:0] fsm_i_rd_data;    // Data read from master
    logic                  fsm_i_rd_valid;   // Read valid signal from master
    logic                  fsm_o_valid;      // Output valid signal to master
    logic [DATA_WIDTH-1:0] fsm_o_wr_data;    // Data to write to master
    logic [ADDR_WIDTH-1:0] fsm_o_addr;       // Address for master transaction
    logic                  fsm_o_rd_wr;       // Read (0) / Write (1) select
	

    // Address Decoder
    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .TRANS_ADDR_WIDTH(TRANS_ADDR_WIDTH)
    ) u_address_decoder (
        .slv_o_addr(slv_o_addr),
        .trans_addr(trans_addr),
        .reg_en(reg_en),
        .cmd_en(cmd_en)
    );

    // Register File
    register_file #(
        .DATA_WIDTH(DATA_WIDTH),
        .TRANS_ADDR_WIDTH(TRANS_ADDR_WIDTH)
    ) u_register_file (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .slv_o_valid(slv_o_valid),
        .slv_o_wr_data(slv_o_wr_data),
        .slv_o_rd0_wr1(slv_o_rd0_wr1),
        .slv_i_ready(slv_i_ready_reg),
        .slv_i_rd_data(slv_i_rd_data_reg),
        .slv_i_rd_valid(slv_i_rd_valid_reg),
        .reg_en(reg_en),
        .reg_rd_en(reg_rd_en),
        .rd_trig_s1_config(rd_trig_s1_config),
        .rd_trig_s2_config(rd_trig_s2_config),
        .rd_trig_s3_config(rd_trig_s3_config),
        .rd_trig_s4_config(rd_trig_s4_config),
        .reg_rd_valid(reg_rd_valid),
        .trans_addr(trans_addr)
    );

    // Instantiate DUT
    cmd_buffer #(
        .CMD_WIDTH(CMD_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BUFFER_WIDTH(BUFFER_WIDTH),
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .TRANS_ADDR_WIDTH(TRANS_ADDR_WIDTH)
    ) u_cmd_buffer (
        .i_clk(i_clk),
        .i_rst_n(i_rstn),
        .cmd_rd_en(cmd_rd_en),
        .cmd_addr(cmd_addr),
        .cmd_rd_valid(cmd_rd_valid),
        .cmd_out(cmd_out),
        .cmd_en(cmd_en),
        .trans_addr(trans_addr),
        .slv_o_valid(slv_o_valid),
        .slv_o_wr_data(slv_o_wr_data),
        .slv_o_rd0_wr1(slv_o_rd0_wr1),
        .slv_i_ready(slv_i_ready_cmd),
        .slv_i_rd_data(slv_i_rd_data_cmd),
        .slv_i_rd_valid(slv_i_rd_valid_cmd)
    );

    fsm #(
        .CMD_ADDR(TRANS_ADDR_WIDTH),       // Command address width
        .ADDR_WIDTH(ADDR_WIDTH),           // Address width
        .DATA_WIDTH(DATA_WIDTH),           // Data width
        .CMD_WIDTH(CMD_WIDTH),             // Command width
        .NO_TRIG_SR(NO_TRIG_SR)            // Number of trigger sources
    ) fsm_inst (
        .i_clk(i_clk),                // Clock signal
        .i_rstn(i_rstn),              // Reset signal
        .i_str_trig(i_str_trig),      // Trigger signals
        .rd_trig_s1_config(rd_trig_s1_config), // Config for trigger 1
        .rd_trig_s2_config(rd_trig_s2_config), // Config for trigger 2
        .rd_trig_s3_config(rd_trig_s3_config), // Config for trigger 3
        .rd_trig_s4_config(rd_trig_s4_config), // Config for trigger 4
        .reg_rd_valid(reg_rd_valid),   // Register read valid signal
        .reg_rd_en(reg_rd_en),         // Register read enable signal
        .cmd_out(cmd_out),            // Command output
        .cmd_rd_valid(cmd_rd_valid),   // Command read valid signal
        .cmd_rd_en(cmd_rd_en),         // Command read enable signal
        .cmd_addr(cmd_addr),           // Command address output
        .fsm_i_ready(fsm_i_ready),       // Master ready signal
        .fsm_i_rd_data(fsm_i_rd_data),   // Data from master
        .fsm_i_rd_valid(fsm_i_rd_valid), // Read valid signal from master
        .fsm_o_valid(fsm_o_valid),      // FSM output valid signal
        .fsm_o_wr_data(fsm_o_wr_data),  // Data to write to master
        .fsm_o_addr(fsm_o_addr),        // Address for master transaction
        .fsm_o_rd_wr(fsm_o_rd_wr)       // Read/write select signal
    );

    // AHB Master
    ahb_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_ahb_master (
        .i_clk_ahb(i_clk),
        .i_rstn_ahb(i_rstn),
        .i_hready(i_hready_master),
        .i_hresp(i_hresp_master),
        .i_hrdata(i_hrdata_master),
        .i_valid(fsm_o_valid),
        .i_rd0_wr1(fsm_o_rd_wr),
        .i_addr(fsm_o_addr),
        .i_wr_data(fsm_o_wr_data),
        .o_hwrite(o_hwrite_master),
        .o_htrans(o_htrans_master),
        .o_hsize(o_hsize_master),
        .o_haddr(o_haddr_master),
        .o_hwdata(o_hwdata_master),
        .o_ready(fsm_i_ready),
        .o_rd_valid(fsm_i_rd_valid),
        .o_rd_data(fsm_i_rd_data)
    );

    // AHB Slave
    ahb_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_ahb_slave (
        .i_clk_ahb(i_clk),
        .i_rstn_ahb(i_rstn),
        .i_hready(i_hready_slave),
        .i_htrans(i_htrans_slave),
        .i_hsize(i_hsize_slave),
        .i_hwrite(i_hwrite_slave),
        .i_haddr(i_haddr_slave),
        .i_hwdata(i_hwdata_slave),
        .i_hselx(i_hselx_slave),
        .i_ready(slv_i_ready_cmd | slv_i_ready_reg),
        .i_rd_valid(slv_i_rd_valid_cmd | slv_i_rd_valid_reg),
        .i_rd_data(slv_i_rd_data_cmd | slv_i_rd_data_reg),
        .o_hreadyout(o_hreadyout_slave),
        .o_hresp(o_hresp_slave),
        .o_hrdata(o_hrdata_slave),
        .o_valid(slv_o_valid),
        .o_rd0_wr1(slv_o_rd0_wr1),
        .o_wr_data(slv_o_wr_data),
        .o_addr(slv_o_addr)
    );
	

endmodule
