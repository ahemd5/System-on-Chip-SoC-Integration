module ahb_slave #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32
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
    output reg                    o_valid,
    output reg                    o_rd0_wr1,
    output reg [DATA_WIDTH-1:0]   o_wr_data,
    output reg [ADDR_WIDTH-1:0]   o_addr,

    output reg                    o_hreadyout,
    
    output reg                    o_hresp,
    output reg [DATA_WIDTH-1:0]   o_hrdata
	);

    typedef enum logic {
        IDLE = 1'b0,
        NONSEQ = 1'b1
    } state_t;

    state_t current_state, next_state;
   
    reg [ADDR_WIDTH-1:0] addr_buffer,addr_buffer_comb;
	reg readyflag ;
    reg write_buffer,write_buffer_comb;
    reg flag,flagcomb;

    assign  o_hrdata =  (i_rd_valid)? i_rd_data : 0;
    assign  o_hreadyout = readyflag  && i_ready;
		             
    always @(posedge i_clk_ahb or negedge i_rstn_ahb) begin
        if (!i_rstn_ahb) begin
            current_state <= IDLE;
	    write_buffer <= 1'b0;
            addr_buffer <= 1'b0;
            readyflag<=1;
            flag<=0;
           
        end else if (i_ready) begin
            current_state <= next_state;
            
			write_buffer <= write_buffer_comb;
            addr_buffer <= addr_buffer_comb;
            flag<=flagcomb;
              if ((write_buffer && ! i_hwrite) )
            readyflag<=0;
          else 
            readyflag<=1;
          
        end
    end

    always @(*) begin
        next_state = current_state;
       if (i_htrans) begin
                    next_state = NONSEQ;					
                end else begin
                    next_state = IDLE;
                end
    end

    always @(*) begin
        o_hresp     = 1'b0; 
        o_rd0_wr1    = o_rd0_wr1;
        o_wr_data    = o_wr_data;
        o_addr       =  o_addr ;		
        o_valid= o_valid;			
		addr_buffer_comb  =  addr_buffer_comb;
        write_buffer_comb =  write_buffer_comb; 
        flagcomb=flagcomb;    
        case (current_state)         
            IDLE: begin
                o_rd0_wr1= 1'b1;
                flagcomb = 0;
                o_wr_data = 'b0;
                o_addr = 'b0;					
                o_valid = 0;
		        addr_buffer_comb = 'b0;
                write_buffer_comb = 1'b0;			                 
                if (i_htrans) begin			
                	if (i_hwrite) begin 		                 
						addr_buffer_comb = i_haddr;
						write_buffer_comb = i_hwrite; 
					end 
					else begin
						o_addr  = i_haddr;
						o_rd0_wr1   = i_hwrite;
						o_valid=1;  
					end				
                end 		
            end
			
            NONSEQ: begin                  
                if (i_hselx && i_htrans ) begin
					if (flag) begin 
						o_wr_data = i_hwdata; 
						o_rd0_wr1 = write_buffer;
						o_addr    = addr_buffer; 
						write_buffer_comb = i_hwrite;
						addr_buffer_comb  = i_haddr;
						o_valid=1; 
						flagcomb=1;
					end 
					else begin
                        case ({write_buffer, i_hwrite})  
							2'b00: begin
							   o_addr  = i_haddr;
							   o_rd0_wr1  = i_hwrite;
							   o_valid =1;  
							end 
							
							2'b01: begin
								write_buffer_comb = i_hwrite;
								addr_buffer_comb  = i_haddr; 
								o_valid=0;
							end  
							
							2'b10: begin
								o_wr_data = i_hwdata; 
								o_rd0_wr1 = write_buffer;
								o_addr    = addr_buffer; 
								write_buffer_comb = i_hwrite;
								addr_buffer_comb  = i_haddr;
							    o_valid=1; 
							    flagcomb=1;
							end  
							
							2'b11: begin 
								o_wr_data = i_hwdata; 
								o_rd0_wr1 = write_buffer;
								o_addr    = addr_buffer; 
								write_buffer_comb = i_hwrite;
								addr_buffer_comb  = i_haddr;
								o_valid=1; 
							end    
						endcase   
					end    
				end 
				else if (!i_htrans ) begin 
					if (write_buffer) 
					begin 
					    o_valid=1;
						o_wr_data = i_hwdata; 
						o_rd0_wr1 = write_buffer;
						o_addr    = addr_buffer; 
					end 
					else begin 
						o_rd0_wr1    = 1'b1;
						flagcomb=0;
						o_wr_data    = 'b0;
						o_addr       = 'b0;					
						o_valid=0;
						addr_buffer_comb  = 'b0;
						write_buffer_comb = 1'b0;
					end
				end 
            end
        endcase
    end
endmodule
