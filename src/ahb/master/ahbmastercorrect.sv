
module AHB_master   #(parameter DATA_WIDTH = 32,ADDR_WIDTH = 32)(

input  logic [DATA_WIDTH-1:0] i_wr_data,
input  logic [ADDR_WIDTH-1:0] i_addr,
input  logic i_rstn_ahb,i_clk_ahb, i_valid, i_rd0_wr1,
output logic [DATA_WIDTH-1:0] o_rd_data,
output logic o_rd_valid, o_ready,

////////// right side /////////////
output logic [DATA_WIDTH-1:0] o_hwdata,
output logic [ADDR_WIDTH-1:0] o_haddr,
output logic o_hwrite , o_htrans,
input  logic [DATA_WIDTH-1:0] i_hrdata,
input  logic i_hresp, i_hready


    
);
   
    logic i_rd0_wr1_reg;                   // registered Read/Write control
    logic [31:0] i_addr_reg;     // registered address for transaction
    logic [31:0] i_wr_data_reg;  // registered write data

    // FSM States
    typedef enum reg [1:0] {
        IDLE = 2'b00,
        NONSEQ = 2'b01
    } state_t;

    state_t state, next_state;

	
    // FSM Implementation
    always @(posedge  i_clk_ahb or negedge  i_rstn_ahb) begin
        if (! i_rstn_ahb) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

	
    // Outputs Logic
    always @(*) begin
            // default outputs
             o_haddr      = 32'b0;
             o_hwdata     = 32'b0;
             o_hwrite     = 1'b0;
             o_htrans     = 2'b00;   // IDLE
             o_ready    = 1'b1;
             o_rd_valid = 1'b0;
             o_rd_data  = 32'b0;
            case (state)
                IDLE: begin
                     o_ready = 1'b1; 
                    if ( i_valid) begin
					    i_rd0_wr1_reg =  i_rd0_wr1;
                        i_addr_reg =  i_addr;
                        i_wr_data_reg =  i_wr_data;
                         o_haddr   =  i_addr;
                         o_hwrite  =  i_rd0_wr1;
                         o_htrans  = 2'b01;   // NONSEQ
                         o_rd_valid = 1'b0;
						next_state = NONSEQ;
                    end else begin
                        next_state = IDLE;
                    end
                end

                NONSEQ: begin
                    if (!i_rd0_wr1_reg &&  i_hready && ! i_valid) begin 
                         o_rd_data =  i_hrdata;
                         o_rd_valid = 1'b1;
                         o_haddr   = i_addr_reg;
                         o_hwrite  = i_rd0_wr1_reg;
                         o_htrans  = 2'b10;   // NONSEQ
                         o_ready = 1'b1;    
						next_state = NONSEQ;
                    end else if (i_rd0_wr1_reg &&  i_hready && ! i_valid) begin 
                         o_rd_valid = 1'b0;
						 o_ready = 1'b1; 
                         o_haddr   = i_addr_reg;
                         o_hwrite  = i_rd0_wr1_reg;
                         o_hwdata  = i_wr_data_reg;
                         o_htrans  = 2'b01;   // NONSEQ
                         o_ready = 1'b1;    
						 next_state = NONSEQ;
					end else if (!i_rd0_wr1_reg &&  i_hready &&  i_valid) begin 
                         o_rd_data =  i_hrdata;
                         o_rd_valid = 1'b1;
                         o_haddr   =  i_addr;
                         o_hwrite  =  i_rd0_wr1;
                         o_htrans  = 2'b10;   // NONSEQ
                         o_ready = 1'b1;    
						i_rd0_wr1_reg =  i_rd0_wr1;
                        i_addr_reg =  i_addr;
                        i_wr_data_reg =  i_wr_data;
						next_state = NONSEQ;
                    end else if (i_rd0_wr1_reg &&  i_hready &&  i_valid) begin 
                         o_rd_valid = 1'b0;
                         o_haddr   =  i_addr;
                         o_hwrite  =  i_rd0_wr1;
                         o_hwdata  = i_wr_data_reg;
                         o_htrans  = 2'b01;   // NONSEQ
                         o_ready = 1'b1;    
						i_rd0_wr1_reg =  i_rd0_wr1;
                        i_addr_reg =  i_addr;
                        i_wr_data_reg =  i_wr_data;
						next_state = NONSEQ;
                    end else if (! i_hready && ! i_valid) begin 
						 o_ready = 1'b0; 
                         o_haddr   = i_addr_reg;
                         o_hwrite  = i_rd0_wr1_reg;
                         o_htrans  = 2'b01;    
						 next_state = NONSEQ;
					end else if (! i_hready &&  i_valid) begin 
						 o_ready = 1'b0; 
                         o_haddr   = i_addr_reg;
                         o_hwrite  = i_rd0_wr1_reg;
                         o_htrans  = 2'b01;     
						i_rd0_wr1_reg =  i_rd0_wr1;
                        i_addr_reg =  i_addr;
                        i_wr_data_reg =  i_wr_data;
						 next_state = NONSEQ;
					end else begin 
					    // Return to IDLE if no new transaction is valid
                         o_htrans = 2'b00;    // Set to IDLE after transaction
                         o_ready = 1'b1;    // Ready for next transaction
					end 
                end
                default: next_state = IDLE;
            endcase
    end
endmodule