module fifo_mem_write #(
	parameter D_SIZE = 16 ,                       // data size
	parameter F_DEPTH = 4 ,                       // fifo depth
	parameter P_SIZE = 4                          // pointer width
	)
	(   
	input               	 w_clk,              // write domian operating clock
	input               	 w_rstn,             // write domian active low reset       
	input               	 w_full,             // fifo buffer full flag
	input               	 w_inc,              // write control signal
	input  		[P_SIZE-2:0] w_addr,             // write address bus
	input  		[D_SIZE-1:0] w_data,             // write data bus
	output reg  [D_SIZE-1:0] FIFO_MEM [F_DEPTH-1:0]
	);
	
	reg [D_SIZE-1:0] FIFO_MEM_int [F_DEPTH-1:0];
	reg [F_DEPTH-1:0] i;
	
	// writing data
	always @(posedge w_clk or negedge w_rstn)
	begin
	if(!w_rstn)
		begin 
		for(i=0;i<F_DEPTH;i=i+1) 
			FIFO_MEM_int[i] <= {D_SIZE{1'b0}};
		end
	else if (!w_full && w_inc) begin 
		FIFO_MEM_int[w_addr] <= w_data;	
		end
	end
	
	genvar j;
	generate
		for (j = 0; j < F_DEPTH; j = j + 1) begin		
			assign FIFO_MEM[j] = FIFO_MEM_int[j];
		end
	endgenerate
	
	/*
	always @(*)
	begin
		fifo_1 = FIFO_MEM_int[0];
		fifo_2 = FIFO_MEM_int[1];
		fifo_3 = FIFO_MEM_int[2];
		fifo_4 = FIFO_MEM_int[3];	
	end
	*/	
endmodule