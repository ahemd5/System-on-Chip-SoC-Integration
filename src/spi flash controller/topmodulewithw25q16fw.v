module Top_Module (
    input wire i_clk_spi_flash,       // SPI clock
    input wire i_rstn_spi_flash,      // SPI reset (active low)
    input wire ahbclk,                // AHB clock
    input wire ahbrst,                // AHB reset
 
   
    output wire o_spi_flash_irq,      // IRQ output
   
// ahb master signals
    input wire i_ready,               
    output wire [31:0] o_addr,
    output wire [31:0] o_wr_data,
    output wire  o_rd0_wr1,
    output wire o_valid,
    // ahb slave signals
     input wire  [31:0] i_address,
       input wire i_rd0_wr1,
       input wire  [31:0] i_wr_data,
       input wire I_valid,
       output wire  [31:0] o_rd_data,
          output wire o_rd_valid,
        output wire  o_ready
    
); 
wire DIO;
wire DO;
wire WPn;
wire HOLDn;
wire o_spi_flash_csn; 
	
	
	 wire spiclock;
wire  o_spi_flash_clk_en; 
wire o_spi_flash_so0;   
  wire o_spi_flash_so1;     
  wire o_spi_flash_so2;     
  wire o_spi_flash_so3;     
  wire o_spi_flash_si_io0_oen;
  wire  o_spi_flash_si_io1_oen;
   wire o_spi_flash_si_io2_oen;
  wire  o_spi_flash_si_io3_oen;
  wire i_spi_flash_si0;
   wire i_spi_flash_si1;
   wire  i_spi_flash_si2 ; 
   wire   i_spi_flash_si3;

// internal registers 
    wire [31:0] reg_0C ;      // DMA address
    wire [3:0] reg_00;          // Command count
    wire [23:0] reg_04;         // Data count to be read 
    wire [23:0] reg_08;         // Data count to be read 
    wire [25:0] reg_1C;         // Mux mode
     wire [31:0] reg_10;         // Command buffer 1
     wire [31:0] reg_14;         // Command buffer 2
     wire [31:0] reg_18;         // Command buffer 3
     wire reg_20;                // Transaction start bit
   wire reg_24;
  



  

    // Internal FIFO signals
    wire fifo_full, fifo_empty;
    wire [31:0] fifo_rdata, fifo_wdata;
    wire fifo_read_enable, fifo_write_enable;

    // Instantiate Async FIFO
    Async_fifo #(
        .D_SIZE(32),
        .F_DEPTH(64),
        .P_SIZE(7)
    ) u_async_fifo (
        .i_w_clk(i_clk_spi_flash),
        .i_w_rstn(i_rstn_spi_flash),
        .i_w_inc(fifo_write_enable),
        .i_r_clk(ahbclk),
        .i_r_rstn(ahbrst),
        .i_r_inc(fifo_read_enable),
        .i_w_data(fifo_wdata),
        .o_r_data(fifo_rdata),
        .o_full(fifo_full),
        .o_empty(fifo_empty)
    );

    // Instantiate SPI FSM
    SPI_FSM u_spi_fsm (
        .i_clk_spi_flash(i_clk_spi_flash),
        .i_rstn_spi_flash(i_rstn_spi_flash),
        //
 
        
        .reg_0C(reg_0C),
        .reg_04(reg_04),
        .reg_00(reg_00),
        .reg_08(reg_08),
        .reg_1C(reg_1C),
        .reg_10(reg_10),
        .reg_14(reg_14),
        .reg_18(reg_18),
        .reg_20(reg_20),
        .reg_24(reg_24),
        .o_spi_flash_irq(o_spi_flash_irq),
        .o_spi_flash_csn(o_spi_flash_csn),
        .o_spi_flash_so0(o_spi_flash_so0),
        .o_spi_flash_so1(o_spi_flash_so1),
        .o_spi_flash_so2(o_spi_flash_so2),
        .o_spi_flash_so3(o_spi_flash_so3),
        .o_spi_flash_si_io0_oen(o_spi_flash_si_io0_oen),
        .o_spi_flash_si_io1_oen(o_spi_flash_si_io1_oen),
        .o_spi_flash_si_io2_oen(o_spi_flash_si_io2_oen),
        .o_spi_flash_si_io3_oen(o_spi_flash_si_io3_oen),
        .empty(fifo_empty),
        .rdata(fifo_rdata),
        .renable(fifo_read_enable),
        .fifo_write_enable(fifo_write_enable),
        .fifo_full(fifo_full),
        .wdata(fifo_wdata),
         .o_addr(o_addr),
        .o_wr_data( o_wr_data),
        .o_rd0_wr1(o_rd0_wr1),
        .o_valid(o_valid),
        
        .i_spi_flash_si0(i_spi_flash_si0),   
        .i_spi_flash_si1(i_spi_flash_si1),    
        .i_spi_flash_si2(i_spi_flash_si2),
        .i_spi_flash_si3(i_spi_flash_si3),
        .o_spi_flash_clk_en(o_spi_flash_clk_en),
        .ahbclk(ahbclk),
        .ahbrst(ahbrst),
        .i_ready(i_ready)
       
       
        
    );
        reg_file u_reg_file (
        .i_clk_ahb(ahbclk),
        .i_address(i_address),
        .i_rd0_wr1(i_rd0_wr1),
        .i_wr_data(i_wr_data),
        .I_valid(I_valid),
        .o_rd_data(o_rd_data),
        .o_rd_valid(o_rd_valid),
        .o_ready(o_ready),
        .reg_24(reg_24),
        .reg_00(reg_00),
        .reg_04(reg_04),
        .reg_08(reg_08),
        .reg_0C(reg_0C),
        .reg_1C(reg_1C),
        .reg_10(reg_10),
        .reg_14(reg_14),
        .reg_18(reg_18),
        .reg_20(reg_20)
    );
 
 W25Q16FW u_w25q16fw (
    .CSn(o_spi_flash_csn),         // Chip Select (active low)
    .CLK(spiclock),         // SPI Clock
    .DIO(DIO),        
    .DO(DO),           
    .WPn(WPn),         // Write Protect (active low)
    .HOLDn(HOLDn)      // Hold (active low)
);

interface_with_flash u_interface_with_flash (
    .o_spi_flash_so0(o_spi_flash_so0),       // Output line 0
    .o_spi_flash_so1(o_spi_flash_so1),       // Output line 1
    .o_spi_flash_so2(o_spi_flash_so2),       // Output line 2
    .o_spi_flash_so3(o_spi_flash_so3),       // Output line 3

    .o_spi_flash_si_io0_oen(o_spi_flash_si_io0_oen), // Output enable for SPI IO0
    .o_spi_flash_si_io1_oen(o_spi_flash_si_io1_oen), // Output enable for SPI IO1
    .o_spi_flash_si_io2_oen(o_spi_flash_si_io2_oen), // Output enable for SPI IO2
    .o_spi_flash_si_io3_oen(o_spi_flash_si_io3_oen), // Output enable for SPI IO3

    .i_spi_flash_si0(i_spi_flash_si0),       // SPI input line 0
    .i_spi_flash_si1(i_spi_flash_si1),       // SPI input line 1
    .i_spi_flash_si2(i_spi_flash_si2),       // SPI input line 2
    .i_spi_flash_si3(i_spi_flash_si3),       // SPI input line 3

    .DIO(DIO),                             
    .DO(DO),                          
    .WPn(WPn),                               
    .HOLDn(HOLDn),
.i_clk_spi_flash(i_clk_spi_flash),
	 .spiclock(spiclock),
 .o_spi_flash_clk_en(o_spi_flash_clk_en), 
 .o_spi_flash_csn(o_spi_flash_csn)
 	
);


  
  
    
   
            
    

    
    
endmodule

