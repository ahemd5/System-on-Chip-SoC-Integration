module synchronizer_logic # ( 
	parameter NUM_STAGES = 2 ,
	parameter BUS_WIDTH = 66,
	parameter F_DEPTH = 4,
	parameter P_SIZE = 3    // log2(FIFO_DEPTH)+1
	)(
	input wire              CLK,
	input wire              RST,
	input wire [P_SIZE-1:0] async_gray_ptr,
	output reg [P_SIZE-1:0] sync_gray_ptr,
	
	input [BUS_WIDTH-1:0] input_mem [F_DEPTH-1:0], 
    output reg [BUS_WIDTH-1:0] my_mem [F_DEPTH-1:0]
	);
	
	reg [NUM_STAGES-1:0] sync_reg [BUS_WIDTH-1:0] ;
	reg [P_SIZE-1:0] prev_synced_gray;
	integer I,i;
	
	//----------------- Multi flop synchronizer ---------------//
	
	always @(posedge CLK or negedge RST)
	begin
		if(!RST)
		begin
			for (I=0; I < P_SIZE; I=I+1)
				sync_reg[I] <= 'b0;
		end
		else begin
		for (I=0; I < P_SIZE; I=I+1)
			sync_reg[I] <= {sync_reg[I][NUM_STAGES-2:0],async_gray_ptr[I]};
		end  
	end
	
	always @(*)
	begin
		for (I=0; I<P_SIZE; I=I+1) begin 
			prev_synced_gray[I] = sync_gray_ptr[I];
			sync_gray_ptr[I] = sync_reg[I][NUM_STAGES-1]; 
		end
	end  
	
	//================================================================//
	// 						Memory Copy Logic
	//================================================================//
	always @(posedge CLK or negedge RST) begin
		if (!RST) begin
			for (i = 0; i < F_DEPTH; i = i + 1) begin
				my_mem[i] <= {BUS_WIDTH{1'b0}};
			end
		end
		else begin 
			if (sync_gray_ptr != prev_synced_gray) begin
				for (i = 0; i < F_DEPTH; i = i + 1) begin
					my_mem[i] <= input_mem[i];
				end
			end
		end
	end
	
endmodule