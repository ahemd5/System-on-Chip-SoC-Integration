module AHB_interconnect #(
    parameter NUM_MASTERS = 2,
    parameter NUM_SLAVES  = 2,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // System signals
    input  logic                    i_clk,          
    input  logic                    i_reset_n,      

    // Inputs from slaves
    input  logic                    i_hreadyout [NUM_SLAVES-1:0], 
    input  logic [DATA_WIDTH-1:0]   i_hrdata    [NUM_SLAVES-1:0], 
    input  logic                    i_hresp     [NUM_SLAVES-1:0],

    // Inputs from masters
    input  logic [2:0]              i_hsize     [NUM_MASTERS-1:0],
    input  logic [1:0]              i_htrans    [NUM_MASTERS-1:0],          
    input  logic                    i_hwrite    [NUM_MASTERS-1:0],          
    input  logic [ADDR_WIDTH-1:0]   i_haddr     [NUM_MASTERS-1:0],          
    input  logic [DATA_WIDTH-1:0]   i_hwdata    [NUM_MASTERS-1:0],
    
    // Address range inputs
    input  logic [ADDR_WIDTH-1:0]   START_ADDR  [NUM_SLAVES-1:0],
    input  logic [ADDR_WIDTH-1:0]   END_ADDR    [NUM_SLAVES-1:0],

    // Outputs to slaves
    output logic [2:0]              o_hsize     [NUM_SLAVES-1:0],
    output logic                    o_shready   [NUM_SLAVES-1:0],                   
    output logic [1:0]              o_htrans    [NUM_SLAVES-1:0],                                               
    output logic                    o_hwrite    [NUM_SLAVES-1:0],           
    output logic [ADDR_WIDTH-1:0]   o_haddr     [NUM_SLAVES-1:0],           
    output logic [DATA_WIDTH-1:0]   o_hwdata    [NUM_SLAVES-1:0],           
    output logic                    o_hselx     [NUM_SLAVES-1:0],

    // Outputs to masters
    output logic [DATA_WIDTH-1:0]   o_hrdata    [NUM_MASTERS-1:0],           
    output logic                    o_hresp     [NUM_MASTERS-1:0],
    output logic                    o_mhready   [NUM_MASTERS-1:0]
);

    wire [NUM_MASTERS-1:0] arbiter_req   [NUM_SLAVES-1:0];
    wire [NUM_MASTERS-1:0] arbiter_grant [NUM_SLAVES-1:0];
    wire [NUM_SLAVES-1:0]  decoder_hsel  [NUM_MASTERS-1:0];

    // Decoder instantiations
    genvar i, k;
    generate
        for (i = 0; i < NUM_MASTERS; i = i + 1) begin      
            decoder #(
                .NUM_SLAVES(NUM_SLAVES)
            ) decoder_Ui (
                .START_ADDR(START_ADDR),
                .END_ADDR(END_ADDR),
                .i_haddr(i_haddr[i]),
                .o_hsel(decoder_hsel[i])
            ); 
            // Map decoder outputs to arbiter requests
            for (k = 0; k < NUM_SLAVES; k = k + 1) begin : slave_loop
                assign arbiter_req[k][i] = decoder_hsel[i][k];
            end 
        end
    endgenerate

    // Master mux instantiations
    generate
        for (i = 0; i < NUM_MASTERS; i = i + 1) begin 
            master_mux #(
                .NUM_SLAVES(NUM_SLAVES),
                .DATA_WIDTH(DATA_WIDTH)
            ) master_mux_Ui (
                .i_shrdata(i_hrdata),
                .i_shresp(i_hresp),
                .i_hsel(decoder_hsel[i]),    
                .i_hreadyout(i_hreadyout),
                .o_mhrdata(o_hrdata[i]),
                .o_mhresp(o_hresp[i]),
                .o_mhready(o_mhready[i])
            );
        end
    endgenerate

    // Arbiter instantiations for each slave
    genvar j;
    generate
        for (j = 0; j < NUM_SLAVES; j = j + 1) begin : arbiters
            arbiter #(
                .NUM_MASTERS(NUM_MASTERS)
            ) arbiter_Uj (
                .i_clk(i_clk),
                .i_reset_n(i_reset_n),
                .i_req(arbiter_req[j]),
                .o_grant(arbiter_grant[j])
            );
        end
    endgenerate

    // Slave MUX instantiations controlled by arbiters
    generate
        for (j = 0; j < NUM_SLAVES; j = j + 1) begin 
            slave_mux #(
                .NUM_MASTERS(NUM_MASTERS),
                .DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) slave_mux_Uj (
                .i_htrans(i_htrans),
                .i_hwrite(i_hwrite),
                .i_haddr(i_haddr),
                .i_hwdata(i_hwdata),
                .i_hsize(i_hsize),
                .i_hreadyout(i_hreadyout[j]),
                .bus_grant(arbiter_grant[j]),
                .o_htrans(o_htrans[j]),
                .o_hwrite(o_hwrite[j]),
                .o_haddr(o_haddr[j]),
                .o_hsize(o_hsize[j]),
                .o_hwdata(o_hwdata[j]),
                .o_hselx(o_hselx[j]),
                .o_shready(o_shready[j])
            );
        end
    endgenerate

endmodule