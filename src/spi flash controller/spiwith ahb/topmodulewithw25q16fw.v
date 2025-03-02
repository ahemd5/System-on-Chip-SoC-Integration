module Top_Module (
    input wire i_clk_spi_flash,       // SPI clock
    input wire i_rstn_spi_flash,      // SPI reset (active low)
    input wire ahbclk,                // AHB clock
    input wire ahbrst,                // AHB reset
 
   
    output wire o_spi_flash_irq,      // IRQ output
    
    
    input  wire i_hreadyy,
input wire                                               i_hmastlock,                // Master lock signal for exclusive transactions
input wire                                                i_htrans,                        // AHB transaction type
input wire       [3:0]                                i_hprot,                        // AHB protection control
input wire [2:0]                                i_hburst,                        // AHB burst type
input wire        [2:0]                                i_hsize,                        // AHB transfer size
input wire                                        i_hwrite,                        // AHB write control, 1 for write, 0 for read
input wire [31:0]                        i_haddr,                        // AHB address for the transaction
input wire        [31:0]        i_hwdata,                        // AHB write data from master
input wire                                       i_hselx,                        // AHB slave select, indicates if the slave is selected
output wire                                      o_hreadyout,                // Slave ready output signal
output wire                                        o_hresp,                        // Slave response signal, always OKAY in this module
output wire [31:0]        o_hrdata,                         // Read data output to AHB bus





input  wire i_hready,       // Slave ready signal, indicates the bus is ready for transfer
    input  wire i_hresp,        // Slave response signal (assumed always OKAY in this design)
    output wire   o_hwrite,       // Write control signal (1 for write, 0 for read)
    output wire   o_htrans,       // Transfer type (e.g., IDLE, NONSEQ)
   
    input  wire [31:0] i_hrdata, // Data received during a read operation
    output wire [31:0] o_haddr,  // Address for the current transfer
    output wire  [31:0] o_hwdata // Data sent during a write operation
  
  
  
   

    
); 
// ahb master signals
     wire i_ready;              
     wire [31:0] o_addr;
    wire [31:0] o_wr_data;
    wire  o_rd0_wr1;
    wire o_valid;
    // ahb slave signals
      wire  [31:0] i_address;
     wire i_rd0_wr1;
       wire  [31:0] i_wr_data;
       wire I_valid;
        wire  [31:0] o_rd_data;
           wire o_rd_valid;
         wire  o_ready;
        
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
ahb_slave #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) u_ahb_slave (
        .i_clk_ahb(ahbclk),
        .i_rstn_ahb(ahbrst),
        .i_hready(i_hreadyy),
        .i_hmastlock(i_hmastlock),
        .i_htrans(i_htrans),
        .i_hprot(i_hprot),
        .i_hburst(i_hburst),
        .i_hsize(i_hsize),
        .i_hwrite(i_hwrite),
        .i_haddr(i_haddr),
        .i_hwdata(i_hwdata),
        .i_hselx(i_hselx),
        
        .o_hreadyout(o_hreadyout),
        .o_hresp(o_hresp),
        .o_hrdata(o_hrdata),
        .i_ready( o_ready),
        .i_rd_valid(o_rd_valid),
        .i_rd_data(o_rd_data),
        .o_valid(I_valid),
        .o_rd0_wr1(i_rd0_wr1),
        .o_wr_data(i_wr_data),
        .o_addr(i_address)
    );
    
 
 
 
 AHB_master #(.DATA_WIDTH(32), .ADDR_WIDTH(32)) u_ahb_master (
    .i_wr_data(o_wr_data),
    .i_addr(o_addr),
    .i_rstn_ahb(ahbrst),
    .i_clk_ahb(ahbclk),
    .i_valid(o_valid),
    .i_rd0_wr1(o_rd0_wr1),
   
    .o_ready(i_ready),

    // Right side AHB interface
    .o_hwdata(o_hwdata),
    .o_haddr(o_haddr),
    .o_hwrite(o_hwrite),
    .o_htrans(o_htrans),
    .i_hrdata(i_hrdata),
    .i_hresp(i_hresp),
    .i_hready(i_hready)
);


  
  
    
   
            
    

    
    
endmodule

