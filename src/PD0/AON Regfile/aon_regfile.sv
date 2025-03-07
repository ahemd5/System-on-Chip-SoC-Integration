module aon_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    // APB Interface
    input  wire                PCLK,
    input  wire                PRESETn,
    input  wire                PSEL,
    input  wire                PENABLE,
    input  wire                PWRITE,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire [DATA_WIDTH-1:0] PWDATA,
    output reg  [DATA_WIDTH-1:0] PRDATA,
    output wire                PREADY,
    output wire                PSLVERR
);

    //-------------------------------------------------------------------------
    // Simple Register File: 2 x 32-bit registers (REG0, REG1) as an example
    //-------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] reg0;
    reg [DATA_WIDTH-1:0] reg1;

    // Always ready, no error in this simple example
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // Write logic
    // Write occurs on PSEL & PENABLE & PWRITE = 1
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            reg0 <= {DATA_WIDTH{1'b0}};
            reg1 <= {DATA_WIDTH{1'b0}};
        end
        else if (PSEL && PENABLE && PWRITE) begin
            // Decode a small portion of PADDR, e.g. bits [3:2]
            // Adjust as needed for your address map
            case (PADDR[3:2])
                2'b00: reg0 <= PWDATA;
                2'b01: reg1 <= PWDATA;
                // Add more registers/cases as needed
                default: /* no-op */;
            endcase
        end
    end

    // Read logic
    // Read occurs on PSEL & !PWRITE
    always @(*) begin
        if (PSEL && !PWRITE) begin
            case (PADDR[3:2])
                2'b00: PRDATA = reg0;
                2'b01: PRDATA = reg1;
                // Add more registers/cases as needed
                default: PRDATA = 32'hDEADBEEF; // default read
            endcase
        end
        else begin
            PRDATA = {DATA_WIDTH{1'b0}};
        end
    end

endmodule
