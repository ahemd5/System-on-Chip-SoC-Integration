module gpio_controller_apb (
    // APB Interface Signals
    input wire PCLK,          // APB Clock
    input wire PRESETn,       // APB Reset (active low)
    input wire PSEL,          // Peripheral Select
    input wire PENABLE,       // Enable Signal
    input wire PWRITE,        // Write Enable (1 = Write, 0 = Read)
    input wire [31:0] PADDR,  // Address Bus
    input wire [31:0] PWDATA, // Write Data Bus
    output reg [31:0] PRDATA, // Read Data Bus
    output reg PREADY,        // Ready Signal
    output reg PSLVERR,       // Error Signal

    // GPIO Signals
   input  wire  [31:0] gpio_in,
   output reg [31:0] gpio_out,
   output  reg [31:0] gpio_oe,
    output wire [31:0] GPIO_INT // Interrupt Output
);

    // Internal Registers
    reg [31:0] GPIO_DATA;
    reg [31:0] GPIO_DIR;
    reg [31:0] GPIO_PULL_CTRL;
    reg [31:0] GPIO_INT_EN;
    reg [31:0] GPIO_INT_STAT1;
    reg [31:0] GPIO_INT_STAT2;
    reg [31:0] GPIO_INT_STAT;
    reg [31:0] GPIO_INT_TYPE;
    reg [31:0] GPIO_INT_POLARITY;
    reg [31:0] GPIO_ALT_FUNC;
    reg [31:0] GPIO_DRIVE;     // Drive Strength Configuration
    reg [31:0] GPIO_CLK_EN;           // Clock Gating Control

    // Internal Signals
    
    reg [31:0] gpio_prev_state;

    // APB Interface Logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA <= 32'h0;
            PREADY <= 1'b0;
            PSLVERR <= 1'b0;
            GPIO_DATA <= 0; // Only update output bits
                         GPIO_DIR <= 0;
                         GPIO_PULL_CTRL <= 0;
                        GPIO_INT_EN <= 0;
                         GPIO_INT_STAT1 <= 32'hFFFFFFFF;
                         GPIO_INT_TYPE <= 0;
                         GPIO_INT_POLARITY <= 0;
                         GPIO_ALT_FUNC <= 0;
                     GPIO_DRIVE <= 0; // Drive strength register
                         GPIO_CLK_EN <= 0; // Clock gating control
            
            
        end else  begin
            PREADY <= 1'b1;
            PSLVERR <= 1'b0;
            GPIO_DATA <= (gpio_in & ~GPIO_DIR) | (GPIO_DATA & GPIO_DIR); ;

            if (PSEL && PENABLE) begin
                if (PWRITE) begin
                    case (PADDR[7:0])
                        8'h00: GPIO_DATA <= (gpio_in & ~GPIO_DIR) | (PWDATA & GPIO_DIR); // Only update output bits
                        8'h04: GPIO_DIR <= PWDATA;
                        8'h08: GPIO_PULL_CTRL <= PWDATA;
                        8'h0C: GPIO_INT_EN <= PWDATA;
                        8'h10: GPIO_INT_STAT2 <= PWDATA & GPIO_INT_STAT2 ;
                        8'h14: GPIO_INT_TYPE <= PWDATA;
                        8'h18: GPIO_INT_POLARITY <= PWDATA;
                        8'h1C: GPIO_ALT_FUNC <= PWDATA;
                        8'h20: GPIO_DRIVE <= PWDATA; // Drive strength register
                        8'h24: GPIO_CLK_EN <= PWDATA; // Clock gating control
                        default: PSLVERR <= 1'b1;
                    endcase
                end else begin
                    case (PADDR[7:0])
                        8'h00: PRDATA <= (gpio_in & ~GPIO_DIR) | (GPIO_DATA & GPIO_DIR); // Read real inputs for input pins
                        8'h04: PRDATA <= GPIO_DIR;
                        8'h08: PRDATA <= GPIO_PULL_CTRL;
                        8'h0C: PRDATA <= GPIO_INT_EN;
                        8'h10: PRDATA <= GPIO_INT_STAT;
                        8'h14: PRDATA <= GPIO_INT_TYPE;
                        8'h18: PRDATA <= GPIO_INT_POLARITY;
                        8'h1C: PRDATA <= GPIO_ALT_FUNC;
                        8'h20: PRDATA <= GPIO_DRIVE;
                        8'h24: PRDATA <= GPIO_CLK_EN;
                        default: PRDATA <= 32'h0;
                    endcase
                end
            end
        end
    end

    // GPIO Control Logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            gpio_out <= 32'h0;
            gpio_oe <= 32'h0;
         
            gpio_prev_state <= 32'h0;
            GPIO_INT_STAT2 <= 32'h0;
        end else  begin
            gpio_oe <= GPIO_DIR;
            gpio_out <= GPIO_DATA;
            
            gpio_prev_state <= gpio_in;

            for (integer i = 0; i < 32; i = i + 1) begin
                if (GPIO_INT_EN[i]) begin
                    case ({GPIO_INT_TYPE[i], GPIO_INT_POLARITY[i]})
                        2'b00: if ((gpio_in[i] ^ gpio_prev_state[i]) && gpio_in[i]) GPIO_INT_STAT2[i] <= 1'b1;
                        2'b01: if ((gpio_in[i] ^ gpio_prev_state[i]) && ~gpio_in[i]) GPIO_INT_STAT2[i] <= 1'b1;
                        2'b10: if (gpio_in[i]) GPIO_INT_STAT2[i] <= 1'b1;
                        2'b11: if (~gpio_in[i]) GPIO_INT_STAT2[i] <= 1'b1;
                    endcase
                end
            end
        end
    end


    // Interrupt Output
    assign  GPIO_INT_STAT= GPIO_INT_STAT2  ;
    assign GPIO_INT = GPIO_INT_STAT;

endmodule

