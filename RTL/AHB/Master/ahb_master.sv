// Mohamed 
module ahb_master (
    input             i_clk_ahb,
    input             i_rstn_ahb,
    
    // AHB Interface Signals
    output reg [31:0] HADDR,
    output reg [31:0] HWDATA,
    output reg        HWRITE,
    output reg [2:0]  HSIZE,
    output reg [1:0]  HTRANS,
    output reg        HMASTLOCK,
    input             HREADY,  
    input  [31:0]     HRDATA,
    input             HRESP,   // Assume always OKAY, as per simplification
    
    // Transaction Interface Signals
    input  [31:0]     i_addr,
    input             i_rd0_wr1,
    input  [31:0]     i_wr_data,
    input             i_valid,
    
    output reg        o_ready,
    output reg        o_rd_valid,
    output reg [31:0] o_rd_data
);

    reg i_rd0_wr1_reg;                   // registered Read/Write control
    reg [31:0] i_addr_reg;     // registered address for transaction
    reg [31:0] i_wr_data_reg;  // registered write data

    // FSM States
    typedef enum reg [1:0] {
        IDLE = 2'b00,
        NONSEQ = 2'b01
    } state_t;

    state_t state, next_state;

	// registered input signals when transaction is valid and master is ready
    always @(posedge i_clk_ahb or negedge i_rstn_ahb) begin
        if (!i_rstn_ahb) begin
            i_rd0_wr1_reg <= 1'b0;
            i_addr_reg <= 32'b0;
            i_wr_data_reg <= 32'b0;
        end else if (o_ready && i_valid) begin
            i_rd0_wr1_reg <= i_rd0_wr1;
            i_addr_reg <= i_addr;
            i_wr_data_reg <= i_wr_data;
        end
    end
	
    // FSM Implementation
    always @(posedge i_clk_ahb or negedge i_rstn_ahb) begin
        if (!i_rstn_ahb) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Outputs Logic
    always @(*) begin
            // default outputs
            HADDR      = 32'b0;
            HWDATA     = 32'b0;
            HWRITE     = 1'b0;
            HSIZE      = 3'b010;  // Word size
            HTRANS     = 2'b00;   // IDLE
            HMASTLOCK  = 1'b0;
            o_ready    = 1'b1;
            o_rd_valid = 1'b0;
            o_rd_data  = 32'b0;
            case (state)
                IDLE: begin
                    o_ready = 1'b1;  // Ready to accept a new transaction
                    if (i_valid) begin
                        HADDR   = i_addr_reg;
                        HWRITE  = i_rd0_wr1_reg;
                        HWDATA  = i_wr_data_reg;
                        HTRANS  = 2'b01;   // NONSEQ
                        o_ready = 1'b0;    // Busy after transaction initiation
                        o_rd_valid = 1'b0;
                        next_state = NONSEQ;
                    end else begin
                        next_state = IDLE;
                    end
                end

                NONSEQ: begin
                    if (!i_rd0_wr1_reg && HREADY && i_valid) begin //011
                        o_rd_data = HRDATA;
                        o_rd_valid = 1'b1;
						// New transaction accepted immediately after the previous one
                        HADDR   = i_addr_reg;
                        HWRITE  = i_rd0_wr1_reg;
                        HWDATA  = i_wr_data_reg;
                        HTRANS  = 2'b10;   // NONSEQ
                        o_ready = 1'b1;    
                        next_state = NONSEQ;
                    end else if (i_rd0_wr1_reg && HREADY && i_valid) begin // 111
                        o_rd_valid = 1'b0;
						o_ready = 1'b1; 
						// New transaction accepted immediately after the previous one
                        HADDR   = i_addr_reg;
                        HWRITE  = i_rd0_wr1_reg;
                        HWDATA  = i_wr_data_reg;
                        HTRANS  = 2'b01;   // NONSEQ
                        o_ready = 1'b1;    
                        next_state = NONSEQ;
                    end else if (!HREADY && i_valid) begin // x01
					    next_state = NONSEQ;  // wait state 
						o_ready = 1'b0; 
						// New transaction accepted immediately after the previous one
                        HADDR   = i_addr_reg;
                        HWRITE  = i_rd0_wr1_reg;
                        HWDATA  = i_wr_data_reg;
                        HTRANS  = 2'b01;   
                        o_ready = 1'b0;    
					end else begin //xx0
					    // Return to IDLE if no new transaction is valid
                        HTRANS = 2'b00;    // Set to IDLE after transaction
                        o_ready = 1'b1;    // Ready for next transaction
                        next_state = IDLE;
					end 
                end
                default: next_state <= IDLE;
            endcase
    end
endmodule
