module interconnect_top_module #(
	parameter	NUM_MASTERS = 2,
	parameter	NUM_SLAVES  = 2,
	parameter	ADDR_WIDTH  = 32,
	parameter   DATA_WIDTH  = 32,
	parameter	[31:0]	START_ADDR	[0:NUM_SLAVES-1],
	parameter	[31:0]	END_ADDR	[0:NUM_SLAVES-1]
)(
	input  wire                   i_clk,          // System clock
    input  wire                   i_reset_n,      // Active-low reset
	//inputs from slaves
	input  wire                     i_hreadyout [NUM_SLAVES-1:0], 
    input  wire [DATA_WIDTH-1:0]    i_hrdata  	[NUM_SLAVES-1:0], 
    input  wire                     i_hresp   	[NUM_SLAVES-1:0],	
	//inputs from master
	input wire						i_hready	[NUM_MASTERS-1:0],		// from arbiter			
	input wire						i_htrans	[NUM_MASTERS-1:0],			
	input wire 						i_hwrite	[NUM_MASTERS-1:0],			
	input wire  [ADDR_WIDTH-1:0]	i_haddr		[NUM_MASTERS-1:0],			
	input wire	[DATA_WIDTH-1:0]	i_hwdata	[NUM_MASTERS-1:0],
	
	//outputs to slave
	output wire						o_hready	[NUM_SLAVES],					
	output wire						o_htrans	[NUM_SLAVES],												
	output wire 					o_hwrite	[NUM_SLAVES],			
	output wire [ADDR_WIDTH-1:0]	o_haddr		[NUM_SLAVES],			
	output wire	[DATA_WIDTH-1:0]	o_hwdata	[NUM_SLAVES],			
	output wire 					o_hselx		[NUM_SLAVES],
	//outputs to master
	output reg	[DATA_WIDTH-1:0]	o_hrdata [NUM_MASTERS]	,       	//hrdata to master 							
	output reg						o_hresp	 [NUM_MASTERS]  ,
	output reg  [NUM_MASTERS-1:0] 	o_mhready [NUM_SLAVES]
);
 
	wire [NUM_SLAVES-1:0]  arbiter_req	[NUM_MASTERS-1:0] ;
    wire [NUM_MASTERS-1:0] arbiter_grant  [NUM_SLAVES];
    
	
    wire [NUM_SLAVES-1:0]  decoder_hsel    [NUM_MASTERS];
	
	
	// Decoder instantiations
    genvar i,k;
    generate
        for (i = 0; i < NUM_MASTERS; i = i + 1) begin 
			  
                assign arbiter_req[i] = decoder_hsel[i]; // Request from master to each slave

            decoder #(.NUM_SLAVES(NUM_SLAVES),.START_ADDR(START_ADDR),.END_ADDR(END_ADDR)) decoder_Ui(
			.i_haddr(i_haddr[i]),
			.o_hsel(decoder_hsel[i])
			
            ); 
        end
		
    endgenerate
	
	
	// masters mux instantiations
    generate
        for (i = 0; i < NUM_MASTERS; i = i + 1) begin 
            master_mux #(.NUM_SLAVES(NUM_SLAVES),.DATA_WIDTH(DATA_WIDTH)) master_mux_Ui (
			.i_shrdata(i_hrdata),
			.i_shresp(i_hresp),
			.i_hsel(decoder_hsel[i]), 
			.o_mhrdata(o_hrdata[i]),
			.o_mhresp(o_hresp[i])
            );
        end
    endgenerate
	
	
    // Arbiter instantiations for each slave
    genvar j;
    generate
        for (j = 0; j < NUM_SLAVES; j = j + 1) begin : arbiters
            arbiter #(.NUM_MASTERS(NUM_MASTERS),.NUM_SLAVES(NUM_SLAVES)) 
            arbiter_Uj (
            .i_clk(i_clk),
            //.i_reset_n(i_reset_n),
            .s(j),
            .i_req(arbiter_req),
            .i_hreadyout(i_hreadyout[j]),
            .o_grant(arbiter_grant[j]),
            .o_mhready(o_mhready[j]),
			.o_shready(o_hready[j]),
			.o_hselx(o_hselx[j])
            );
        end
    endgenerate

    

    // Slave MUX instantiations controlled by arbiters
    generate
        for (j = 0; j < NUM_SLAVES; j = j + 1) begin 
            slave_mux #(.NUM_MASTERS(NUM_MASTERS),.DATA_WIDTH(DATA_WIDTH)) slave_mux_Uj (
			
                .i_htrans(i_htrans),
                .i_hwrite(i_hwrite),
                .i_haddr(i_haddr),
                .i_hwdata(i_hwdata),
                .bus_grant(arbiter_grant[j]),
                .o_htrans(o_htrans[j]),
                .o_hwrite(o_hwrite[j]),
                .o_haddr(o_haddr[j]),
                .o_hwdata(o_hwdata[j])
            );
        end
    endgenerate

endmodule
