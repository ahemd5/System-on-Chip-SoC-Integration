module APB_interface #(parameter DATA_WIDTH = 8,
	ADDR_WIDTH = 32, APB_dataW = 32)(
	// apb signals 
	input wire PRESETn,     			// APB active-low reset signal
	input wire PCLK,					// APB clock
	input wire PSEL	,					// Peripheral select signal
	input wire PENABLE,					// Enable signal for APB transaction
	input wire PWRITE,					// Read (0) or Write (1) operation
	input wire [ADDR_WIDTH-1:0] PADDR,	// Address bus
	input wire [APB_dataW -1:0] PWDATA,	// Write data bus
	output reg [APB_dataW -1:0] PRDATA,	// Read data bus
	output reg PREADY,					// Ready signal for handshake
	output reg PSLVERR,					// Error signal
	
	// Translated signals
	input wire [DATA_WIDTH-1:0] Rx_data,
	output reg [DATA_WIDTH-1:0] Tx_data,// forward to fifo
	output reg [31:0] control_reg,
	
	// FIFOS
	input wire tx_fifo_empty,
	input wire tx_fifo_full,
	input wire rx_fifo_empty,
	input wire rx_fifo_full,
	output reg tx_fifo_rst,
	output reg rx_fifo_rst,
	output reg tx_fifo_wr_en,
	output reg rx_fifo_rd_en,
	
	input wire parity_error,
	input wire frame_error,
	input wire overrun_error,
	output reg [DATA_WIDTH-1:0] baud_rate
	);    
	      
	reg [DATA_WIDTH-1:0] status_reg;
	reg [DATA_WIDTH-1:0] fifo_ctrl_reg;
	reg [DATA_WIDTH-1:0] int_enable_reg;
	reg [DATA_WIDTH-1:0] INT_status;
	
	// control_reg = {prescale(8), TX_EN, RX_EN, par_en, par_type, LOOPBACK}
	always @(posedge PCLK or negedge PRESETn) 
	begin
		if (!PRESETn) begin
			status_reg <= 0;
			control_reg <= 0;
			baud_rate <= 0;
			fifo_ctrl_reg <= 0;
			int_enable_reg <= 0;
			INT_status <= 0;
			PSLVERR <= 1'b0;
			PREADY <= 1'b0;
			PRDATA <= 32'd0;
			tx_fifo_wr_en <=0;
			rx_fifo_rd_en <= 0;
			rx_fifo_rst <= 0;
			tx_fifo_rst <= 0;
		end else begin 
			INT_status = {4'd0,
							(parity_error & int_enable_reg[3]),
							(frame_error & int_enable_reg[2]),
							(overrun_error & int_enable_reg[1]),
							(tx_fifo_empty & int_enable_reg[0])};
			status_reg = {2'd0, 
							parity_error, frame_error,
							overrun_error,
							rx_fifo_full, rx_fifo_empty,
							tx_fifo_empty, tx_fifo_full};
			if(PSEL && PENABLE) begin 
				// defaults
				Tx_data <= 0;
				tx_fifo_wr_en <=0; 
				rx_fifo_rd_en <= 0;
				PSLVERR <= 1'b0;
				PRDATA <= 0;
				case(PADDR[4:0]) 
					5'h00 : begin 	// write only
						if(!tx_fifo_full && PWRITE) begin 
							tx_fifo_wr_en <= 1;
							Tx_data <= PWDATA[DATA_WIDTH-1:0];		// valid 
						end else begin 
							// error 
							tx_fifo_wr_en <= 0;
							PSLVERR <= 1'b1; 	// read only
						end
					end 
					
					5'h04 : begin 	// read only
						if(!PWRITE && !rx_fifo_empty) begin 
							rx_fifo_rd_en <= 1;
							PRDATA <= {24'd0,Rx_data};
						end else begin 
							PSLVERR <= 1'b1; 	// write not allowed 
						end 
					end
					
					5'h08 : begin 	// read only 
						if(!PWRITE) begin 
							PRDATA <= {24'd0,status_reg};
						end 
						else 
							PSLVERR <= 1'b1; 	// write not allowed 
					end
					
					5'h0c :begin 	// read-write
						if(PWRITE)
							control_reg <= PWDATA;
						else 	
							PRDATA <= {control_reg};
					end 
					
					5'h10 : begin 	// read-write
						if(PWRITE) begin 
							baud_rate <= PWDATA[DATA_WIDTH-1:0];
						end 
						else 	
							PRDATA <= {24'd0, baud_rate};
					end 
					
					5'h14 : begin 	// fifo control (, rx_fifo_rst, Tx_fifo_rst)
						if(PWRITE) begin 
							fifo_ctrl_reg <= PWDATA[DATA_WIDTH-1:0];
							tx_fifo_rst = fifo_ctrl_reg[0];
							rx_fifo_rst = fifo_ctrl_reg[1];
						end 
						else 
							PRDATA <= {24'd0,fifo_ctrl_reg};	
					end 
					
					5'h18 : begin // int status 
						if(!PWRITE) begin 
							PRDATA <= INT_status;
						end else 
							PSLVERR <= 1'b1; 	// write not allowed
					end
					
					5'h1c : begin 
						if(PWRITE) begin 
							int_enable_reg <= PWDATA[DATA_WIDTH-1:0];
						end else begin 
							PRDATA <= {24'd0, int_enable_reg};
						end 
					end 
					
					default : begin 
						PSLVERR <= 1'b1; // Undefined address
					end 
				endcase 
			end
			else begin 
				Tx_data <= 0;
				tx_fifo_wr_en <= 0; 
				rx_fifo_rd_en <= 0;
				rx_fifo_rst <= 0;
				tx_fifo_rst <= 0;
				PSLVERR <= 1'b0;
				PRDATA <= 0;
			end 
		end 
	end

endmodule	
		