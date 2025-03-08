
`timescale 1ns/1ps
module tb_top_pll;

    reg         i_clk_ahb;
    reg [31:0]  i_address;
    reg         i_rd0_wr1;
    reg [31:0]  i_wr_data;
    reg         I_valid;
    wire [31:0] o_rd_data;
    wire        o_rd_valid;
    wire        o_ready;
    reg         xo_clk;
    reg         reset_n;
       wire        pll_clk;
    wire        soc_clk_select;
    
   
    

    top_pll_system uut (
        .i_clk_ahb(i_clk_ahb),
        .i_address(i_address),
        .i_rd0_wr1(i_rd0_wr1),
        .i_wr_data(i_wr_data),
        .I_valid(I_valid),
        .o_rd_data(o_rd_data),
        .o_rd_valid(o_rd_valid),
        .o_ready(o_ready),
        .xo_clk(xo_clk),
        .reset_n(reset_n),
        .pll_clk(pll_clk),
        .soc_clk_select(soc_clk_select)
    );

    // Clock Generation
    initial begin
        i_clk_ahb = 0;
        forever #5 i_clk_ahb = ~i_clk_ahb; // 10ns period
    end

    initial begin
        xo_clk = 0;
        forever #5 xo_clk = ~xo_clk; // Same as AHB clock
    end

    // Testbench Initialization
    initial begin
        i_address = 0;
        i_rd0_wr1 = 0;
        i_wr_data = 0;
        I_valid = 0;
      
        
         reset_n = 0;
        #10 reset_n = 1;
        #40 ; //wait for lock time 
        // test case 1  6/3 xoclock
          configure_pll(32'h00000001, {24'b1111, 8'b11});
            #60;
            configure_pll(32'h00000001, {24'b11, 8'b1111});
              #200
              // test case bypass 
               configure_pll(32'b00000011, {24'b11, 8'b1011});
                  #200
                  
              $stop;
    end

    // PLL Configuration Task
    task configure_pll(
        input [31:0] PLL_CTRL,
        input [31:0] PLL_CFG
    );
        begin
            @(negedge i_clk_ahb);
            i_address = 0;
            i_rd0_wr1 = 1;
            I_valid = 1;
            i_wr_data = PLL_CTRL;
            @(negedge i_clk_ahb);
            i_wr_data[2] = 0;
            @(negedge i_clk_ahb);
            
            i_address = i_address + 4;
            i_wr_data = PLL_CFG;
            @(negedge i_clk_ahb);
            i_address = i_address + 8;
            i_wr_data = 32'b0;
            @(negedge i_clk_ahb);
            i_wr_data = 32'b1;
            @(negedge i_clk_ahb);
            I_valid = 0;
        end
    endtask

endmodule

