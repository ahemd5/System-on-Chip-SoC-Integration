module apb_bus (
    // Clock and Reset
    input  wire        PCLK,
    input  wire        PRESETn,
    
    // APB Master Interface
    input  wire [31:0] PADDR_M,
    input  wire        PWRITE_M,
    input  wire        PSEL_M,
    input  wire        PENABLE_M,
    input  wire [31:0] PWDATA_M,
    output wire [31:0] PRDATA_M,
    output wire        PREADY_M,
    output wire        PSLVERR_M,
    
    // APB Slave Interface 0 - AON/regfile
    output wire        PSEL_S0,
    output wire        PENABLE_S0,
    output wire [31:0] PADDR_S0,
    output wire        PWRITE_S0,
    output wire [31:0] PWDATA_S0,
    input  wire [31:0] PRDATA_S0,
    input  wire        PREADY_S0,
    input  wire        PSLVERR_S0,
    
    // APB Slave Interface 1 - Power controller
    output wire        PSEL_S1,
    output wire        PENABLE_S1,
    output wire [31:0] PADDR_S1,
    output wire        PWRITE_S1,
    output wire [31:0] PWDATA_S1,
    input  wire [31:0] PRDATA_S1,
    input  wire        PREADY_S1,
    input  wire        PSLVERR_S1,
    
    // APB Slave Interface 2 - Aon Timer 
    output wire        PSEL_S2,
    output wire        PENABLE_S2,
    output wire [3:0]  PADDR_S2,
    output wire        PWRITE_S2,
    output wire [31:0] PWDATA_S2,
    input  wire [31:0] PRDATA_S2,
    input  wire        PREADY_S2,
    input  wire        PSLVERR_S2,
	
	// APB Slave Interface 3 - BrownOut Detector
    output wire        PSEL_S3,
    output wire        PENABLE_S3,
    output wire [3:0]  PADDR_S3,
    output wire        PWRITE_S3,
    output wire [31:0] PWDATA_S3,
    input  wire [31:0] PRDATA_S3,
    input  wire        PREADY_S3,
    input  wire        PSLVERR_S3
    
);

    // Address decoding parameters
    // Address range: 0x60000000 - 0x6FFFFFFF
    // Each slave gets a segment of the address space
    localparam BASE_ADDR = 32'h60000000;
    localparam ADDR_MASK = 32'h63FFFFFF; // To check if in APB address range
    
    // Address windows for slaves (each gets 0x2000_0000 / 7 = approximately 0x4B0_0000 bytes)
    localparam S0_LOW  = 32'h64000000;  // AON/regfile
    localparam S0_HIGH = 32'h67FFFFFF;
    
    localparam S1_LOW  = 32'h68000000;  // Power controller
    localparam S1_HIGH = 32'h6BFFFFFF;
    
    localparam S2_LOW  = 32'h6C000000;  // Aon Timer 
    localparam S2_HIGH = 32'h6FFFFFFF;
    
    
    // Slave selection logic
    wire [3:0] slave_sel;
    wire addr_in_range;
    
    // Check if address is in valid APB range
    assign addr_in_range = ((PADDR_M & ADDR_MASK) == BASE_ADDR);
    
    // Decode slave select signals based on address ranges
    assign slave_sel[0] = addr_in_range && (PADDR_M >= S0_LOW) && (PADDR_M <= S0_HIGH);
    assign slave_sel[1] = addr_in_range && (PADDR_M >= S1_LOW) && (PADDR_M <= S1_HIGH);
    assign slave_sel[2] = addr_in_range && (PADDR_M >= S2_LOW) && (PADDR_M <= S2_HIGH);
    assign slave_sel[3] = addr_in_range && (PADDR_M >= S3_LOW) && (PADDR_M <= S3_HIGH);
    
    // APB Slave select signals
    assign PSEL_S0 = slave_sel[0] && PSEL_M;
    assign PSEL_S1 = slave_sel[1] && PSEL_M;
    assign PSEL_S2 = slave_sel[2] && PSEL_M;
    assign PSEL_S3 = slave_sel[3] && PSEL_M;
    
    // Common signals to all slaves
    assign PENABLE_S0 = PENABLE_M;
    assign PENABLE_S1 = PENABLE_M;
    assign PENABLE_S2 = PENABLE_M;
    assign PENABLE_S3 = PENABLE_M;
    
    assign PADDR_S0 = PADDR_M;
    assign PADDR_S1 = PADDR_M;
    assign PADDR_S2 = PADDR_M;
    assign PADDR_S3 = PADDR_M;
    
    assign PWRITE_S0 = PWRITE_M;
    assign PWRITE_S1 = PWRITE_M;
    assign PWRITE_S2 = PWRITE_M;
    assign PWRITE_S3 = PWRITE_M;
    
    assign PWDATA_S0 = PWDATA_M;
    assign PWDATA_S1 = PWDATA_M;
    assign PWDATA_S2 = PWDATA_M;
    assign PWDATA_S3 = PWDATA_M;
    
    // Mux for read data back to master
    reg [31:0] prdata_mux;
    always @(*) begin
        case (1'b1) // One-hot mux
            slave_sel[0]: prdata_mux = PRDATA_S0;
            slave_sel[1]: prdata_mux = PRDATA_S1;
            slave_sel[2]: prdata_mux = PRDATA_S2;
			slave_sel[3]: prdata_mux = PRDATA_S3;
            default:      prdata_mux = 32'h0; // Default value when no slave is selected
        endcase
    end
    
    assign PRDATA_M = prdata_mux;
    
    // Mux for PREADY and PSLVERR signals
    reg pready_mux, pslverr_mux;
    always @(*) begin
        case (1'b1) // One-hot mux
            slave_sel[0]: begin
                pready_mux = PREADY_S0;
                pslverr_mux = PSLVERR_S0;
            end
            slave_sel[1]: begin
                pready_mux = PREADY_S1;
                pslverr_mux = PSLVERR_S1;
            end
            slave_sel[2]: begin
                pready_mux = PREADY_S2;
                pslverr_mux = PSLVERR_S2;
            end
			slave_sel[3]: begin
                pready_mux = PREADY_S3;
                pslverr_mux = PSLVERR_S3;
            end
            default: begin
                pready_mux = 1'b1;  // Default ready when no slave is selected
                pslverr_mux = 1'b1; // Error when no slave is selected
            end
        endcase
    end
    
    assign PREADY_M = pready_mux;
    assign PSLVERR_M = pslverr_mux;

endmodule
