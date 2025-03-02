module soc_top (
	
	);
	 
    // AON Subsystem
    aon_subsystem u_aon_subsystem (
    
    );
    
    // TxRx Subsystem
    txrx_subsystem u_txrx_subsystem (

    );
    
    // MCU Subsystem
    mcu_subsystem u_mcu_subsystem (
	
    );
	
	// AHB2AHB bridge 
	AHB_AHB_bridge #(.DATA_WIDTH(),.ADDR_WIDTH(),.P_SIZE(),.F_DEPTH()
	) u_ahb_bridge (
    .i_clk_src(),
    .i_rstn_src(),
    .i_src_sleep_req(),
    .o_src_sleep_ack(),
    .i_clk_sink(),
    .i_rstn_sink(),
    .i_sink_sleep_req(),
    .o_sink_sleep_ack(),
    .i_hready_src(),
    .i_htrans(),
    .i_hsize(),
    .i_hwrite(),
    .i_haddr(),
    .i_hwdata(),
    .i_hselx(),
    .o_hreadyout(),
    .o_hresp(),
    .o_hrdata(),
    .i_hready_sink(),
    .i_hresp(),
    .i_hrdata(),
    .o_hwrite(),
    .o_htrans(),
    .o_hsize(),
    .o_haddr(),
    .o_hwdata()
	);
	
	// AHB2APB bridge 
	AHB_AHB_bridge #(.DATA_WIDTH(),.ADDR_WIDTH(),.P_SIZE(),.F_DEPTH()
	) u_apb_bridge (
    .i_clk_src(),
    .i_rstn_src(),
    .i_src_sleep_req(),
    .o_src_sleep_ack(),
    .i_clk_sink(),
    .i_rstn_sink(),
    .i_sink_sleep_req(),
    .o_sink_sleep_ack(),
    .i_hready(),
    .i_htrans(),
    .i_hsize(),
    .i_hwrite(),
    .i_haddr(),
    .i_hwdata(),
    .i_hselx(),
    .o_hreadyout(),
    .o_hresp(),
    .o_hrdata(),
    .i_prdata(),
    .i_pready(),
    .i_pslverr(),
    .o_psel(),
    .o_penable(),
    .o_pwrite(),
    .o_paddr(),
    .o_pwdata()
	);

endmodule