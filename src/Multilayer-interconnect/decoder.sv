module decoder #(
	parameter 						NUM_SLAVES = 2,
	parameter						ADDR_WIDTH = 32
)(
	input	[ADDR_WIDTH-1:0]	START_ADDR	[NUM_SLAVES-1:0],
	input	[ADDR_WIDTH-1:0]	END_ADDR	[NUM_SLAVES-1:0],

	input	wire	[ADDR_WIDTH-1:0] i_haddr,	   //address from the master
	output	reg		[NUM_SLAVES-1:0] o_hsel 	   //decoded_slave(select for master mux)
);

integer i;

always @(*) begin

		for(i = 0 ; i < NUM_SLAVES ; i = i+1) begin
				o_hsel[i] = 0;
		end
		
		for(i = 0 ; i < NUM_SLAVES ; i = i+1) begin
			if(i_haddr >= START_ADDR[i] && i_haddr <= END_ADDR[i]) begin
				o_hsel[i] = 1'b1;
			end else begin 
			    o_hsel[i] = 1'b0;
			end 
		end
end

endmodule