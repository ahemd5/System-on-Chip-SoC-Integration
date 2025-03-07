module aon_timer #(
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
    // Simple Timer Example:
    //   - LOAD register at address offset 0
    //   - CONTROL register at address offset 1 (bit 0 = enable)
    //   - COUNTER register at address offset 2 (read-only)
    //-------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] load_reg;
    reg [DATA_WIDTH-1:0] ctrl_reg;
    reg [DATA_WIDTH-1:0] count_reg;

    // Always ready, no error in this simple example
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // Timer enable (bit 0 of ctrl_reg)
    wire timer_enable = ctrl_reg[0];

    // Write logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            load_reg  <= {DATA_WIDTH{1'b0}};
            ctrl_reg  <= {DATA_WIDTH{1'b0}};
            count_reg <= {DATA_WIDTH{1'b0}};
        end
        else begin
            // APB write
            if (PSEL && PENABLE && PWRITE) begin
                case (PADDR[3:2])
                    2'b00: load_reg <= PWDATA;   // LOAD register
                    2'b01: ctrl_reg <= PWDATA;   // CONTROL register
                    // We generally don't allow writing the counter directly
                    default: /* no-op */;
                endcase
            end

            // Timer counting logic
            if (timer_enable) begin
                // If counter is 0, reload
                if (count_reg == 0)
                    count_reg <= load_reg;
                else
                    count_reg <= count_reg - 1'b1;
            end
        end
    end

    // Read logic
    always @(*) begin
        if (PSEL && !PWRITE) begin
            case (PADDR[3:2])
                2'b00: PRDATA = load_reg;
                2'b01: PRDATA = ctrl_reg;
                2'b10: PRDATA = count_reg;
                default: PRDATA = 32'hDEADBEEF;
            endcase
        end
        else begin
            PRDATA = {DATA_WIDTH{1'b0}};
        end
    end

endmodule
