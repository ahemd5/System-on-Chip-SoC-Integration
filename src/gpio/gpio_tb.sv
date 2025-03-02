`timescale 1ns/1ps

module gpio_apb_tb;
    
    // Clock and Reset
    reg PCLK;
    reg PRESETn;
    
    // APB Signals
    reg PSEL;
    reg PENABLE;
    reg PWRITE;
    reg [31:0] PADDR;
    reg [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire PREADY;
    wire PSLVERR;
    
    // GPIO Signals
    reg [31:0] gpio_in;
    wire [31:0] gpio_out;
    wire [31:0] gpio_oe;
    wire [31:0] GPIO_INT;
    
    // Instantiate DUT
    gpio_controller_apb dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .GPIO_INT(GPIO_INT)
    );
    
    // Clock Generation
    always #5 PCLK = ~PCLK;
    
    // APB Write Task
    task apb_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge PCLK);
            PSEL = 1'b1;
            PENABLE = 1'b0;
            PWRITE = 1'b1;
            PADDR = addr;
            PWDATA = data;
            @(posedge PCLK);
            PENABLE = 1'b1;
            @(posedge PCLK);
            PSEL = 1'b0;
            PENABLE = 1'b0;
        end
    endtask
    
    // APB Read Task
    task apb_read(input [31:0] addr);
        begin
            @(posedge PCLK);
            PSEL = 1'b1;
            PENABLE = 1'b0;
            PWRITE = 1'b0;
            PADDR = addr;
            @(posedge PCLK);
            PENABLE = 1'b1;
            @(posedge PCLK);
            PSEL = 1'b0;
            PENABLE = 1'b0;
        end
    endtask
    
    // Test Procedure
    initial begin
        // Initialize signals
        PCLK = 0;
        PRESETn = 0;
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 0;
        PWDATA = 0;
        gpio_in = 0;
        
        // Reset the DUT
        #10 PRESETn = 1;
        apb_write(32'h04, 32'h0); // Set all GPIOs to input
        
        // Enable interrupts on bits 1 and 2
        apb_write(32'h0C, 32'h00000006); // Enable interrupts for bits 1 and 2
        apb_write(32'h14, 32'h00000000); // Set bits 1 and 2 as edge-sensitive
        apb_write(32'h18, 32'h00000004); // Set bit 1 as positive edge, bit 2 as negative edge
        
        // Test each interrupt case for bits 1 and 2
        
        
       
           @(posedge PCLK);
            gpio_in = 32'h00000002;
       
       wait (GPIO_INT[1]==1);
     
         apb_write(32'h10, 32'hFFFFFFFD);
        
        
        // Negative edge on bit 2
        gpio_in = 32'h00000004;
        
        @(posedge PCLK);
         gpio_in = 0;
       
          wait (GPIO_INT[2]==1);
         
          apb_write(32'h10, 32'hFFFFFFFB);
        
        // High level on bit 1
        apb_write(32'h14, 32'hFFFFFFFF); // Change to level-sensitive
        
      gpio_in = 32'h00000002;
         
         wait (GPIO_INT[1]==1);
          @(posedge PCLK);
           @(posedge PCLK);
            @(posedge PCLK);
              gpio_in = 32'h00000000;
              @(posedge PCLK);
            @(posedge PCLK);
         
       
          apb_write(32'h10, 32'hFFFFFFFD);
                                

       gpio_in = 32'h00000004;
            @(posedge PCLK);
            @(posedge PCLK);
          
          
          
        
         
          apb_write(32'h10, 32'hFFFFFFFB);
          // two interupts 
          
          
          
               apb_write(32'h14, 32'h00000000); // Set bits 1 and 2 as edge-sensitive
        apb_write(32'h18, 32'h00000004); // Set bit 1 as positive edge, bit 2 as negative edge
        
        // Test each interrupt case for bits 1 and 2
        
        
       
           @(posedge PCLK);
            gpio_in = 32'h00000006;
               @(posedge PCLK);
                @(posedge PCLK);
        gpio_in = 32'h00000004;
        
@(posedge PCLK);
        gpio_in = 0;
        @(posedge PCLK);
           @(posedge PCLK);
            @(posedge PCLK);
     
         apb_write(32'h10, 32'hFFFFFFFD);
         @(posedge PCLK);
          @(posedge PCLK);
           @(posedge PCLK);
            
      
          apb_write(32'h10, 32'hFFFFFFFB);
          
          
          
        
        // Change GPIO direction to output
        apb_write(32'h04, 32'hFFFFFFFF); // Set all GPIOs to output
        
        // Write data to GPIO
        apb_write(32'h00, 32'hA5AFFFA5);
        apb_write(32'h00, 32'hADD5ACA5);
        apb_write(32'h00, 32'hA5A5A5B5);
        
      
        
        // Finish simulation
        #50 $finish;
    end
endmodule