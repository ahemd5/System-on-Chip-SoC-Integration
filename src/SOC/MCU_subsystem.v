module mcu_subsystem (
	// AHB-APB bridge interface (slave)
	input                   i_hready_pd0,         
    input                   i_htrans_pd0,   
    input  [2:0]            i_hsize_pd0,
    input                   i_hwrite_pd0,
    input  [ADDR_WIDTH-1:0] i_haddr_pd0,
    input  [DATA_WIDTH-1:0] i_hwdata_pd0,
    input                   i_hselx_pd0,
	output                  o_hreadyout_pd0,
    output                  o_hresp_pd0,
    output [DATA_WIDTH-1:0] o_hrdata_pd0,
	// AHB-AHB bridge interface (slave)
	input                   i_hready_src_pd2,         
    input                   i_htrans_pd2,   
    input  [2:0]            i_hsize_pd2,
    input                   i_hwrite_pd2,
    input  [ADDR_WIDTH-1:0] i_haddr_pd2,
    input  [DATA_WIDTH-1:0] i_hwdata_pd2,
    input                   i_hselx_pd2,
	output                  o_hreadyout_pd2,
    output                  o_hresp_pd2,
    output [DATA_WIDTH-1:0] o_hrdata_pd2,
	);
	
	////////////////////////////////////////////////////////////
	//////////////////////// RISC-V Core ///////////////////////
	////////////////////////////////////////////////////////////
    riscv u_riscv (
    
    );
    
	////////////////////////////////////////////////////////////
	//////////////////////// DMA engine ////////////////////////
	////////////////////////////////////////////////////////////
	top_module #(.DATA_WIDTH( ), .BUFFER_DEPTH( ),.ADDR_WIDTH( )
	) u_dma_engine (
	.clk_top(),
	.rst_top(),
	.i_pwdata_top(),
	.i_paddr_top(),
	.i_psel_top(), 
	.i_penable_top(), 
	.i_pwrite_top(),
	.o_prdata_top(),
	.o_pslverr_top(),  
	.o_pready_top(),
	.o_hwdata_top(),
	.o_haddr_top(),
	.o_hwrite_top(),  
	.o_htrans_top(),
	.i_hrdata_top(),
	.i_hresp_top(), 
	.i_hready_top(),
	.o_trig_end_top(),
	.i_dma_start_trig_top()
	);
	

	////////////////////////////////////////////////////////////
	//////////////////////// SPI Flash /////////////////////////
	////////////////////////////////////////////////////////////
    Top_Module your_instance_name (
    .i_clk_spi_flash(),
    .i_rstn_spi_flash(),
    .ahbclk(),
    .ahbrst(),
    .o_spi_flash_irq(),
    .i_hreadyy(),
    .i_hmastlock(),
    .i_htrans(),
    .i_hprot(),
    .i_hburst(),
    .i_hsize(),
    .i_hwrite(),
    .i_haddr(),
    .i_hwdata(),
    .i_hselx(),
    .o_hreadyout(),
    .o_hresp(),
    .o_hrdata(),
    .i_hready(),
    .i_hresp(),
    .o_hwrite(),
    .o_htrans(),
    .i_hrdata(),
    .o_haddr(),
    .o_hwdata()
	);
	
	////////////////////////////////////////////////////////////
	/////////////////////////// SRAM ///////////////////////////
	////////////////////////////////////////////////////////////
    system_memory u_system_memory (
    
    );
    
	////////////////////////////////////////////////////////////
	///////////////////////// BOOT ROM /////////////////////////
	////////////////////////////////////////////////////////////
    boot_rom u_boot_rom (
    
    );
    
	////////////////////////////////////////////////////////////
	////////////////////// Register file ///////////////////////
	////////////////////////////////////////////////////////////
    apb_register_file #(.ADDR_WIDTH(), .DATA_WIDTH(), .NUM_REGS(8)
	) u_reg_file (
    .i_pclk(),
    .i_presetn(),
    .i_psel(),
    .i_penable(),
    .i_pwrite(),
    .i_paddr(),
    .i_pwdata(),
    .o_prdata(),
    .o_pready(),
    .o_pslverr(),
    .i_status_hw_en(),
    .i_status_hw(),
    .i_toggle_event()
	);
    
	////////////////////////////////////////////////////////////
	//////////////////////////// GPIO //////////////////////////
	////////////////////////////////////////////////////////////
    gpio_controller_apb u_GPIO (
    .PCLK(),
    .PRESETn(),
    .PSEL(),
    .PENABLE(),
    .PWRITE(),
    .PADDR(),
    .PWDATA(),
    .PRDATA(),
    .PREADY(),
    .PSLVERR(),
    .gpio_in(),
    .gpio_out(),
    .gpio_oe(),
    .GPIO_INT()
	);
    
	////////////////////////////////////////////////////////////
	/////////////////////////// I2C ////////////////////////////
	////////////////////////////////////////////////////////////
    i2c u_i2c (
    
    );
    
	////////////////////////////////////////////////////////////
	/////////////////////////// UART ///////////////////////////
	////////////////////////////////////////////////////////////
	UART_apb_top #(.DATA_WIDTH(8),.ADDR_WIDTH(),.apb_dataW(),
	.F_DEPTH(8), .ratio_wd(8), .prescale(32)
	) u_uart (
    .PRSTn(),
    .PCLK(),
    .PSEL(),
    .PENABLE(),
    .PWRITE(),
    .PADDR(),
    .PWDATA(),
    .PRDATA(),
    .PREADY(),
    .PSLVERR(),
    .Rx_s(),
    .Tx_s(),
    .TX_FIFO_Empty(),
    .RX_FIFO_Full(),
    .Parity_Error(),
    .Frame_Error(),
    .overrun_error()
	);
    
	////////////////////////////////////////////////////////////
	////////////////////////// Timers //////////////////////////
	////////////////////////////////////////////////////////////
    Top_timers #(.DATA_WIDTH(), .ADDR_WIDTH(),.NUM_TIMERS(4)
	) your_instance_name (
    .clk(),
    .rst(),
    .clk_gate_en(),
    .i_pwdata(),
    .i_paddr(),
    .i_psel(),
    .i_penable(),
    .i_pwrite(),
    .o_prdata(),
    .o_pslverr(),
    .o_pready(),
    .gen_clk(),
    .o_trig_end()
	);
    
	////////////////////////////////////////////////////////////
	////////////////////// Watchdog Timer //////////////////////
	////////////////////////////////////////////////////////////
    wdt_top #(.ADDR_WIDTH(32), .DATA_WIDTH(32)
	) u_watchdog_timer (
    .i_clk_wdt(),
    .i_rstn_wdt(),
    .i_pwrite_wdt(),
    .i_pwdata_wdt(),
    .i_paddr_wdt(),
    .i_psel_wdt(),
    .i_penable_wdt(),
    .o_prdata_wdt(),
    .o_pslverr_wdt(),
    .o_pready_wdt()
	);
    
	////////////////////////////////////////////////////////////
	////////////////// Interrupt Controller ////////////////////
	////////////////////////////////////////////////////////////
    interrupt_controller u_interrupt_controller (
    
    );
    
	////////////////////////////////////////////////////////////
	/////////////////////// interconnect ///////////////////////
	////////////////////////////////////////////////////////////
    interconnect_top_module #(.NUM_MASTERS(4),.NUM_SLAVES(6),.ADDR_WIDTH(),.DATA_WIDTH(),
    .START_ADDR(),.END_ADDR()
	) u_ahb_interconnect (
    // System signals
    .i_clk(),
    .i_reset_n(),
    // Inputs from slaves
    .i_hreadyout(),
    .i_hrdata(),
    .i_hresp(), 
    // Inputs from masters
    .i_hready(),
    .i_htrans(), 
    .i_hwrite(), 
    .i_haddr()
    .i_hwdata(), 
    // Outputs to slaves
    .o_hready(),
    .o_htrans(),
    .o_hwrite(),
    .o_haddr(),
    .o_hwdata(),
    .o_hselx(),
    // Outputs to masters
    .o_hrdata(),
    .o_hresp(), 
    .o_mhready()
	);
    
	////////////////////////////////////////////////////////////
	///////////////////////// APB Bus //////////////////////////
	////////////////////////////////////////////////////////////
    apb_bus u_apb_bus (
    
    );

endmodule