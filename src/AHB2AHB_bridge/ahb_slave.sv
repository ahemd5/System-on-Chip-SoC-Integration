module ahb_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input  logic                  i_clk_ahb,
    input  logic                  i_rstn_ahb,

    input  logic                  i_hready,
    input  logic                  i_htrans,
    input  logic [2:0]            i_hsize,
    input  logic                  i_hwrite,
    input  logic [ADDR_WIDTH-1:0] i_haddr,
    input  logic [DATA_WIDTH-1:0] i_hwdata,
    input  logic                  i_hselx,

    input  logic                  i_ready,
    input  logic                  i_rd_valid,
    input  logic [DATA_WIDTH-1:0] i_rd_data,

    output reg                    o_hreadyout,
    output reg                    o_hresp,
    output reg [DATA_WIDTH-1:0]   o_hrdata,

    output reg                    o_valid,
    output reg                    o_rd0_wr1,
    output reg [DATA_WIDTH-1:0]   o_wr_data,
    output reg [ADDR_WIDTH-1:0]   o_addr
);

    typedef enum logic {
        IDLE = 1'b0,
        NONSEQ = 1'b1
    } state_t;

    state_t current_state, next_state;
    reg active_phase,valid_buffer;
    reg [ADDR_WIDTH-1:0] addr_buffer,addr_buffer_comb;
    reg                  write_buffer,write_buffer_comb;

    always @(posedge i_clk_ahb or negedge i_rstn_ahb) begin
        if (!i_rstn_ahb) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
			write_buffer <= write_buffer_comb;
            addr_buffer <= addr_buffer_comb;
        end
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (i_hselx && i_htrans) begin
                    next_state = NONSEQ;					
                end else begin
                    next_state = IDLE;
                end
            end

            NONSEQ: begin
                if (i_hselx && i_htrans) begin
                    next_state = NONSEQ;	
                end else begin
                    next_state = IDLE;
                end
            end
        endcase
    end

    always @(*) begin     
        case (current_state)         
            IDLE: begin
				o_hresp = 0;
                if (i_hselx && i_htrans) begin									
					o_hreadyout = 1'b1;
                    o_hrdata    = 'b0;
					o_wr_data   = 'b0;
					o_rd0_wr1   = i_hwrite;                    
					o_hresp = 1'b0;
                    addr_buffer_comb = i_haddr;
                    write_buffer_comb = i_hwrite;
                    
                    active_phase = 1'b1;				
					
					if (i_hwrite) begin
                        o_valid = 1'b0;
                        o_addr  = i_haddr;
                    end else begin
                        o_valid = 1'b1;
                        o_addr = i_haddr;
                    end
					
                end else begin				
					o_hreadyout  = 1'b1;
                    o_hrdata     = 'b0;
                    o_valid      = 1'b0;
                    o_rd0_wr1    = 1'b0;
                    o_wr_data    = 'b0;
                    o_addr       = 'b0;					
					active_phase = 1'b0;
					addr_buffer_comb  = 'b0;
                    write_buffer_comb = 1'b0;
					o_hresp = 1'b0;
                end			
            end
			
            NONSEQ: begin                  
                if (i_hselx && write_buffer && i_hready && i_ready) begin            
                    o_wr_data = i_hwdata;
                    o_rd0_wr1 = write_buffer;
                    o_addr    = addr_buffer;
                    o_hrdata  = 'b0;
					write_buffer_comb = i_hwrite;
                    addr_buffer_comb  = i_haddr;
                    o_hreadyout  = 1'b1;
                    o_valid      = 1'b1;
                    active_phase = 1'b1; 
					o_hresp 	 = 1'b0;						
                end else if (i_hselx && write_buffer && (!i_hready || !i_ready)) begin 
				    o_wr_data = 32'b0;
                    o_rd0_wr1 = write_buffer;
                    o_addr    = addr_buffer;
                    o_hrdata  = 'b0;
                    write_buffer_comb = write_buffer;
                    addr_buffer_comb  = addr_buffer;
                    o_hreadyout = 1'b0;
                    o_valid     = 1'b1;
					active_phase = 1'b1;
                end else if (i_hselx && !write_buffer && i_rd_valid && i_hready && i_ready) begin               
                    o_wr_data = 'b0;
					o_rd0_wr1 = write_buffer;
                    o_addr    = addr_buffer;					
					o_hrdata = i_rd_data;
					write_buffer_comb = i_hwrite;
                    addr_buffer_comb  = i_haddr;
                    o_hreadyout = 1'b1;
                    o_valid = 1'b1; 
					active_phase = 1'b1;
					o_hresp = 0;
                end else if (i_hselx && !write_buffer && active_phase && !i_ready) begin
                    o_wr_data = 'b0;
					o_rd0_wr1 = write_buffer;
                    o_addr    = addr_buffer;	
					o_hrdata = 'b0;
                    write_buffer_comb = write_buffer;
                    addr_buffer_comb  = addr_buffer;
					o_valid     = 1'b0;
                    o_hreadyout = 1'b0;        
					active_phase = 1'b1;
                 end else if (i_hselx && !write_buffer && active_phase && !i_rd_valid ) begin
                    o_wr_data = 'b0;
					o_rd0_wr1 = write_buffer;
                    o_addr    = addr_buffer;	
					o_hrdata = 'b0;
                    write_buffer_comb = write_buffer;
                    addr_buffer_comb  = addr_buffer;
					o_valid     = 1'b1;
                    o_hreadyout = 1'b1;        
					active_phase = 1'b1;
                end else begin
                    if (i_hselx && i_htrans) begin									
					o_hreadyout = 1'b1;
                    o_hrdata    = 'b0;
					o_wr_data   = 'b0;
					o_rd0_wr1   = i_hwrite;                    
					
                    addr_buffer_comb = i_haddr;
                    write_buffer_comb = i_hwrite;
					o_hresp = 0;
                    active_phase = 1'b1;				
					o_addr = i_haddr;
					if (i_hwrite) begin
                        o_valid = 1'b0;
                    end else begin
                        o_valid = 1'b1;
                    end
					
                    end else begin				
					    o_hreadyout  = 1'b1;
                        o_hrdata     = 'b0;
                        o_valid      = 1'b0;
                        o_rd0_wr1    = 1'b0;
                        o_wr_data    = 'b0;
                        o_addr       = 'b0;					
					    active_phase = 1'b0;
					    addr_buffer_comb  = 'b0;
                        write_buffer_comb = 1'b0;
                    end
                end
            end
        endcase
    end
endmodule
