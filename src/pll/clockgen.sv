
module clock_generator_model (
    input real period, // Frequency scaling factor (e.g., 2.0 means double, 0.5 means half)
    output reg clk_out
);


    initial clk_out = 0;

    always #(5.0 * period) clk_out = ~clk_out; // Toggle at half the period
endmodule
