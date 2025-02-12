module sink_controller #(parameter ADDR_WIDTH = 32,
	DATA_WIDTH = 32, packet_width = 66 )( 
	input wire 						i_clk_sink,
	input wire 						i_rstn_sink,
	input wire 						i_sink_sleep_req,
	input wire 						source_sleep_status,
	input wire [packet_width-1:0]	i_packet,				// data read from req fifo 
	// master
	input wire [DATA_WIDTH-1:0] rd_data,
	input wire					rd_valid,
	input wire 					i_ready,
	output reg 					rd0_wr1,
	output reg [ADDR_WIDTH-1:0] addr,
	output reg 					valid,
	output reg [DATA_WIDTH-1:0] wr_data,
	// fifo
	input wire 					req_fifo_empty,
	input wire 					rsp_fifo_full,
	input wire 					rsp_fifo_empty,
	
	output reg 					o_sink_sleep_ack,
	output reg 					sink_sleep_status,
	output reg [DATA_WIDTH:0] 	o_packet,				
	output reg 					req_fifo_rd_en,
	output reg 					rsp_fifo_wr_en,
	
	output reg 					reset_flag
	);
	
	reg [DATA_WIDTH:0] packet;
	
	// fsm 
	parameter 	normal = 2'b00,
				sleep = 2'b01,
				idle = 2'b11;
				
	reg [1:0] current_state, next_state;
		
	always @(posedge i_clk_sink or negedge i_rstn_sink) begin
        if (!i_rstn_sink) begin
			current_state <= normal;
			reset_flag <= 0;	
        end 
		else begin 
			current_state <= next_state ;	
		end 
    end
	
	always @(*) begin
        case(current_state) 
			normal : begin
				if(i_sink_sleep_req || source_sleep_status) begin 
					next_state = sleep;
				end 
				else begin 
					next_state = normal;
				end
			end
			
			sleep : begin
				if (req_fifo_empty && rsp_fifo_empty && source_sleep_status) begin 
					next_state = idle;
				end 
				else begin 
					next_state = sleep;
				end
			end
			
			idle : begin 
				if(!source_sleep_status && !i_sink_sleep_req) begin 
					next_state = normal;
				end 
				else begin 
					next_state = idle;
				end  
			end
		endcase
    end
	
	always @(*) begin
		rd0_wr1 = 0;
		addr = 0;
		valid = 0;
		wr_data = 0;
		o_sink_sleep_ack = i_sink_sleep_req;
		sink_sleep_status = 0;
		o_packet = 0;
		req_fifo_rd_en = 0;
		rsp_fifo_wr_en = 0;
		reset_flag = i_rstn_sink;
		packet = {rd_valid, rd_data};
		case(current_state) 
			normal : begin		
				// for rsp
				rsp_fifo_wr_en = rd_valid;
				o_packet = packet;	
				
				// for req
				valid = i_packet[packet_width-2];
				if(i_ready && !req_fifo_empty && valid) begin
					req_fifo_rd_en = 1;
					rd0_wr1 = i_packet[packet_width-1];
					addr = i_packet[packet_width-3:DATA_WIDTH];
					wr_data = i_packet[DATA_WIDTH-1:0];
				end 
				else 
					valid = 0;
			end
			
			sleep : begin
				// for sleep 
				sink_sleep_status = i_sink_sleep_req;
				o_sink_sleep_ack = i_sink_sleep_req;
				
				// for rsp 
				rsp_fifo_wr_en = rd_valid;
				o_packet = packet;	
				
				// for req
				valid = i_packet[packet_width-2];
				if(i_ready && !req_fifo_empty && valid) begin
					req_fifo_rd_en = 1;
					rd0_wr1 = i_packet[packet_width-1];
					addr = i_packet[packet_width-3:DATA_WIDTH];
					wr_data = i_packet[DATA_WIDTH-1:0];
				end 
				else 
					valid = 0;
			end
			
			idle : begin
				sink_sleep_status = 1;
				o_sink_sleep_ack = 0;
				reset_flag = 0;
				// for rsp
				rsp_fifo_wr_en = 0;
				// for req
				req_fifo_rd_en = 0;
				
			end
		endcase
    end
endmodule	