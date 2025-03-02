module source_controller #(parameter ADDR_WIDTH = 32,
	DATA_WIDTH = 32, packet_width = 66 )( 
	input wire 					i_clk_src,
	input wire 					i_rstn_src,
	input wire 					i_src_sleep_req,
	input wire 					sink_sleep_status,
	input wire [DATA_WIDTH:0]	i_read_packet,
	// slave interface
	input wire 					rd0_wr1,
	input wire [ADDR_WIDTH-1:0] addr,
	input wire 					valid,
	input wire [DATA_WIDTH-1:0] wr_data,
	output reg 					ready,
	output reg [DATA_WIDTH-1:0] rd_data,
	output reg					rd_valid,
	// fifo
	input wire 					req_fifo_full,
	input wire 					req_fifo_empty,
	input wire 					rsp_fifo_empty,
	
	output reg 					  o_src_sleep_ack,
	output reg 					  source_sleep_status,
	output reg [packet_width-1:0] o_packet,				// addr_width + data_width + 2 bit 
	output reg 					  req_fifo_wr_en,
	output reg 					  rsp_fifo_rd_en,
	
	output reg 					  reset_flag
	);
	
	reg [packet_width-1:0] packet;
	
	// fsm 
	parameter 	normal = 2'b00,
				sleep = 2'b01,
				read = 2'b10,
				idle = 2'b11;
				
	reg [1:0] current_state, next_state;
		
	always @(posedge i_clk_src or negedge i_rstn_src) begin
        if (!i_rstn_src) begin
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
				if(i_src_sleep_req || sink_sleep_status) begin 
					next_state = sleep;
				end 
				else if(!rd0_wr1)begin 
					next_state = read;
				end 
				else begin 
					next_state = normal;
				end 
			end
			
			read : begin 
				if(rd_valid) begin 
					next_state = normal;				
				end else begin 
					next_state = read;
				end 
			end 
			
			sleep : begin
				if (req_fifo_empty && rsp_fifo_empty && sink_sleep_status) begin 
					next_state = idle;
				end 
				else begin 
					next_state = sleep;
				end 
			end
			
			idle : begin
				if(!sink_sleep_status && !i_src_sleep_req) begin 
					next_state = normal;
				end 
				else begin 
					next_state = idle;
				end 
			end
	
		endcase
    end
	
	always @(*) begin
		req_fifo_wr_en = 0;
		rsp_fifo_rd_en = 0;
		source_sleep_status = 0;
		o_packet = 0;
		rd_data = 0;
		rd_valid = 0;
		reset_flag = i_rstn_src;
		packet = {rd0_wr1, valid, addr, wr_data};
		o_src_sleep_ack = i_src_sleep_req;
		case(current_state) 
			normal : begin
				// for req 
				ready = (req_fifo_full)? 0 : 1;
				req_fifo_wr_en = (valid)? 1 : 0;
				o_packet = packet;
 				
				// for rsp
				if(!rsp_fifo_empty) begin 
					rsp_fifo_rd_en = 1;
					rd_data = i_read_packet[DATA_WIDTH-1:0];
					rd_valid = i_read_packet[DATA_WIDTH];
				end // no else needed - defined before case
			end
			
			read : begin 
				// for req
				req_fifo_wr_en = 0;
				ready = 0;
				// for rsp
				rd_valid = i_read_packet[DATA_WIDTH];
				rsp_fifo_rd_en = (!rsp_fifo_empty && rd_valid)? 1 : 0;
				if(rsp_fifo_rd_en) begin 
					rd_data = i_read_packet[DATA_WIDTH-1:0];
					ready = 1;
				end
			end 
			
			sleep : begin
				// for req 
				req_fifo_wr_en = 0; 
				ready = 0;
				// for rsp
				if(!rsp_fifo_empty) begin 
					rsp_fifo_rd_en = 1;
					rd_data = i_read_packet[DATA_WIDTH-1:0];
					rd_valid = i_read_packet[DATA_WIDTH];
					ready = 1;
				end
				// sleep status
				o_src_sleep_ack = i_src_sleep_req;
				source_sleep_status = (req_fifo_empty && rsp_fifo_empty)? 1 : 0;
			end
			
			idle : begin
				reset_flag = 0;	
				o_src_sleep_ack = 0;
				source_sleep_status = 1;
				// for req 
				ready = 0;
				req_fifo_wr_en = 0;
				// for rsp 
				rsp_fifo_rd_en = 0;
			end
		endcase
    end
endmodule
	