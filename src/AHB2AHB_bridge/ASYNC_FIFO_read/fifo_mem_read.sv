module fifo_mem_read #(
	parameter D_SIZE = 16 ,                       // data size
	parameter F_DEPTH = 4 ,                       // fifo depth
	parameter P_SIZE = 4                          // pointer width
	)
	(   
	input              r_clk,              // read domian operating clock
	input              r_rstn,             // read domian active low reset       
	input [P_SIZE-2:0] r_addr,             // synchronized read pointer bus
	input [D_SIZE-1:0] FIFO_MEM_sync [F_DEPTH-1:0],
	output [D_SIZE-1:0] r_data             // read data bus
	);
	
	reg [F_DEPTH-1:0] i ;
	reg [D_SIZE-1:0] FIFO_MEM_int [F_DEPTH-1:0] ;

	// copying fifo 
	/*
	always @(posedge r_clk or negedge r_rstn)
	begin
	if(!r_rstn) begin 
		for(i=0;i<F_DEPTH;i=i+1) 
			FIFO_MEM_int[i] <= {D_SIZE{1'b0}} ;
	    end
	else 
		FIFO_MEM_int[0] <= fifo_1_sync;
		FIFO_MEM_int[1] <= fifo_2_sync;
		FIFO_MEM_int[2] <= fifo_3_sync;
		FIFO_MEM_int[3] <= fifo_4_sync;
	end
	*/
	genvar j;
	generate
		for (j = 0; j < F_DEPTH; j = j + 1) begin 
			always@(posedge r_clk or negedge r_rstn) begin 
				if(!r_rstn) begin 
					FIFO_MEM_int[j] <= {D_SIZE{1'b0}};
				end 
				else begin 
					FIFO_MEM_int[j] <= FIFO_MEM_sync[j];
				end 
			end
		end
	endgenerate
	
	// reading domain
	assign r_data = FIFO_MEM_int[r_addr] ;

endmodule