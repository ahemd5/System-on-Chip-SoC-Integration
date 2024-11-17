module ahb_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input  logic                  i_clk_ahb,        // AHB clock
    input  logic                  i_rstn_ahb,       // Active-low reset

    // Inputs from master
    input  logic                  i_hready,         // Master ready
    input  logic                  i_htrans,         // Master transaction type
    input  logic [2:0]            i_hsize,          // Master transfer size
    input  logic                  i_hwrite,         // Master write/read control
    input  logic [ADDR_WIDTH-1:0] i_haddr,          // Master address
    input  logic [DATA_WIDTH-1:0] i_hwdata,         // Master write data
    input  logic                  i_hselx,          // Slave select signal

    // Inputs from memory
    input  logic                  i_ready,          // Memory ready
    input  logic                  i_rd_valid,       // Memory read valid
    input  logic [DATA_WIDTH-1:0] i_rd_data,        // Memory read data

    // Outputs for master
    output reg                    o_hreadyout,      // Slave ready output
    output reg                    o_hresp,          // Slave response (OKAY)
    output reg [DATA_WIDTH-1:0]   o_hrdata,         // Read data to master

    // Outputs for memory
    output reg                    o_valid,          // Transaction valid
    output reg                    o_rd0_wr1,        // 0 = Read, 1 = Write
    output reg [DATA_WIDTH-1:0]   o_wr_data,        // Write data to memory
    output reg [ADDR_WIDTH-1:0]   o_addr            // Address to memory
);

    // States for pipelined transactions
    typedef enum logic {
        IDLE = 1'b0,
        NONSEQ = 1'b1
    } state_t;

    state_t current_state, next_state;
	
    // control signal
    reg active_phase;  // To distinguish between I'am in data phase or in address phase (0: address phase ,1: data phase)
	
    // Buffer to hold address and write data for pipelining
    reg [ADDR_WIDTH-1:0] addr_buffer;
    reg                  write_buffer;

    // Sequential logic for state transitions
    always @(posedge i_clk_ahb or negedge i_rstn_ahb) begin
        if (!i_rstn_ahb) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Next-state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (i_htrans) begin
                    next_state = NONSEQ;
                end else begin 
				    next_state = IDLE;
				end
            end
            NONSEQ: begin
                if (i_hselx && i_hready && i_ready && i_htrans) begin
                    next_state = NONSEQ; // Complete write transaction
				end else if (i_hselx && i_hready && !i_ready && i_htrans) begin // !!!!
                    next_state = NONSEQ; // not Complete write transaction	
				end else if (i_hselx && !i_hready && !i_ready && i_htrans) begin // wait 
                    next_state = NONSEQ; // not Complete write transaction
                end else if (i_hselx && i_hready && i_ready && i_htrans) begin
                    next_state = NONSEQ; // Complete read transaction
				end else if (i_hselx && i_hready && !i_ready && i_htrans) begin // !!!!
                    next_state = NONSEQ; // not Complete read transaction	
				end else if (i_hselx && !i_hready && !i_ready && i_htrans) begin // wait 
                    next_state = NONSEQ; // not Complete read transaction	
                end else begin
				    next_state = IDLE;
				end
            end
        endcase
    end

    // Output logic and data handling
    always @(*) begin
        o_hresp     = 1'b0; // Always OKAY
            case (current_state)
                IDLE: begin
                    if (i_htrans)begin 
					    o_hreadyout = 1'b1;
                        o_wr_data   = 'b0;
					    addr_buffer = i_haddr;
                        write_buffer = i_hwrite;
				        o_rd0_wr1 = i_hwrite;         
					    active_phase = 1'b1 ;  
					
                        if (i_hwrite) begin
                            o_valid = 1'b0; // write transaction not valid 
							o_addr  = 'b0;
                        end else begin
						    o_valid = 1'b1; // read transaction valid 
							o_addr = i_haddr;
				        end 
                    end else begin 
						o_hreadyout = 1'b1;                        
                        o_hrdata    = 'b0;
                        o_valid     = 1'b0;
                        o_rd0_wr1   = 1'b0;
                        o_wr_data   = 'b0;
                        o_addr      = 'b0;
				    end 
                end
				
                NONSEQ: begin
                    if (write_buffer && active_phase) begin 
					        o_wr_data = i_hwdata;
						    o_rd0_wr1 = write_buffer;
                            o_addr = addr_buffer;
						    o_valid = 1'b1;     // write transaction valid 
						
						    write_buffer = i_hwrite;
						    addr_buffer = i_haddr;
						
                            o_hreadyout = 1'b1; // Ready for next transaction
						    active_phase = 1'b1; 
                            o_hrdata    = 'b0;
							
                    end else if (!write_buffer && active_phase) begin  //!write_buffer
                            o_hrdata = i_rd_data; // Provide read data to master
						    o_rd0_wr1 = write_buffer;
                            o_addr = addr_buffer;
						    o_valid = 1'b1;      // read transaction valid 
						
						    write_buffer = i_hwrite;
						    addr_buffer = i_haddr;
							
						    if (i_rd_valid) begin
                                o_hreadyout = 1'b1;  // Ready for next transaction
						    end else begin 
						        o_hreadyout = 1'b0;  // not Ready for next transaction
						    end
							o_wr_data   = 'b0;
							active_phase = 1'b1 ; 
					end else begin
						if (i_htrans)begin 
					            o_hreadyout = 1'b1;
                                o_wr_data   = 'b0;
					            addr_buffer = i_haddr;
                                write_buffer = i_hwrite;
				                o_rd0_wr1 = i_hwrite;
                                o_addr = i_haddr;
					            active_phase = 1'b1 ;  
					
                            if (i_hwrite) begin
                                o_valid = 1'b0; // write transaction not valid 
                            end else begin
						        o_valid = 1'b1; // read transaction valid 
				            end 
                        end else begin 
						o_hreadyout = 1'b1;                        
                        o_hrdata    = 'b0;
                        o_valid     = 1'b0;
                        o_rd0_wr1   = 1'b0;
                        o_wr_data   = 'b0;
                        o_addr      = 'b0;
				        end 
				    end 
                end
            endcase
    end
endmodule
