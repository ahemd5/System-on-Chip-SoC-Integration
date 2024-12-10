module tb_gp_engine;

    // Local parameters for the design
    localparam DATA_WIDTH = 32;           // Width of data being transferred (default: 32-bit)
    localparam ADDR_WIDTH = 32;           // Address width (default: 32-bit)
    localparam TRANS_ADDR_WIDTH = 8;     // Width for address translation (default: 8-bit)
    localparam CMD_WIDTH  = 64;          // Command width (default: 64-bit)
    localparam NO_TRIG_SR = 4;           // Number of trigger sources (default: 4)
    localparam BUFFER_WIDTH = 32;        // Width of command buffer
    localparam BUFFER_DEPTH = 256;      // command buffer depth

    // Testbench signals
    logic i_clk;
    logic i_rstn;
    
    // AHB-Lite Slave Interface (Incoming)
    logic i_hready_slave;
    logic i_htrans_slave;
    logic [2:0] i_hsize_slave;
    logic i_hwrite_slave;
    logic [ADDR_WIDTH-1:0] i_haddr_slave;
    logic [DATA_WIDTH-1:0] i_hwdata_slave;
    logic i_hselx_slave;
    logic o_hreadyout_slave;
    logic o_hresp_slave;
    logic [DATA_WIDTH-1:0] o_hrdata_slave;
    
    // Trigger Inputs (4 triggers)
    logic [NO_TRIG_SR-1:0] i_start_trig;
    
    // AHB-Lite Master Interface (Outgoing)
    logic i_hready_master;
    logic i_hresp_master;
    logic o_hwrite_master;
    logic o_htrans_master;
    logic [2:0] o_hsize_master;
    logic [DATA_WIDTH-1:0] i_hrdata_master;
    logic [ADDR_WIDTH-1:0] o_haddr_master;
    logic [DATA_WIDTH-1:0] o_hwdata_master;

    // Clock generation 
    always begin
        #5 i_clk = ~i_clk; 
    end

    // Reset generation (assert for 100 time units)
    initial begin
	    i_clk = 0;
        i_rstn = 0;
        #10 i_rstn = 1;
    end

    // Task to initialize all signals
    task init_signals;
    begin
        i_hready_slave = 1;
        i_htrans_slave = 0;
        i_hsize_slave = 3'b010; // 32-bit transfer size
        i_hwrite_slave = 0;
        i_haddr_slave = 32'h0000_0000;
        i_hwdata_slave = 32'h0000_0000;
        i_hselx_slave = 0;
        i_start_trig = 4'b0000;
        i_hready_master = 1;
        i_hresp_master = 0;
        i_hrdata_master = 32'h0000_0000;
    end
    endtask

    // Task for AHB slave write transaction
    task slave_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
    begin
        i_htrans_slave = 1'b1;  // NONSEQ (start of transfer)
        i_hwrite_slave = 1;      // Write operation
        i_haddr_slave = addr;
		i_hselx_slave = 1;       // Slave selected
		#10;
        i_hwdata_slave = data;
		#10; 
		i_hwrite_slave = 0;      // Write operation
    end
    endtask

    // Task for AHB slave read transaction
    task slave_read(input [ADDR_WIDTH-1:0] addr);
    begin
        i_htrans_slave = 1'b1;  // NONSEQ (start of transfer)
        i_hwrite_slave = 0;      // Read operation
        i_haddr_slave = addr;
        i_hwdata_slave = 32'h0000_0000; // Not used for read
        i_hselx_slave = 1;       // Slave selected
        #10;
    end
    endtask

    // Task to assert trigger signal "rising edge"
    task assert_trigger_rising (input [NO_TRIG_SR-1:0] trigger_mask);
    begin
	    @(negedge i_clk)
        i_start_trig = 4'b0000; // Reset trigger
        @(negedge i_clk)
        i_start_trig = trigger_mask;  
    end
    endtask
	
    // Task to assert trigger signal "failing edge"
	task assert_trigger_failing (input [NO_TRIG_SR-1:0] trigger_mask);
    begin
	    @(negedge i_clk)
        i_start_trig = trigger_mask; // Reset trigger
        @(negedge i_clk)
        i_start_trig = 4'b0000;  
    end
    endtask
	
	// task to check RMW conditions
	task RMW_check ;
    begin
		@(u_gp_engine.fsm_inst.fsm_o_addr == 32'h00e70f54);
		
		#10;
		i_hrdata_master = 32'hFAFF_1245;
			
		@(u_gp_engine.fsm_inst.modified_value == 32'h50550044);	
		@(u_gp_engine.fsm_inst.fsm_o_wr_data == 32'hD8DD99DD);
    end
    endtask
	
	// task to check poll 1 condition 
	task poll_1_check ;
    begin
		@(u_gp_engine.fsm_inst.fsm_o_addr == 32'h01ae3314);
		#10;    
			i_hrdata_master = 32'h0000_0000 ; 
		#10;
		    i_hrdata_master = 32'hFFFF_FFFF;
    end
    endtask
	
	// task to check poll 0 condition 
    task poll_0_check;
    begin
		@(u_gp_engine.fsm_inst.fsm_o_addr == 32'h01ae95e0);
		#10;    
			i_hrdata_master = 32'hFFFF_0000 ; 
		#10;
		    i_hrdata_master = 32'h0000_5555;
    end
    endtask
	
    // Stimulus generation for the test case
    initial begin
        // Initialize all signals
        init_signals;

        // Wait for reset to deassert
        wait(i_rstn == 1);

        // Test Case 1: AHB slave write transaction "cmd configuration"
		
		/*********************************************************************************/
		/************************* trigger 1 *********************************************/
        /*********************************************************************************/	
		
		// write command 
        slave_write(32'h1000_0010, 32'hDEAD_BEEF);
        slave_write(32'h1000_0014, 32'h0000_D798);
		
		// rmw command 
		slave_write(32'h1000_0018, 32'hAAAA_BBBB);
		slave_write(32'h1000_001C, 32'h00E7_0F55);
		
		// write command 
		slave_write(32'h1000_0020, 32'hCCCC_DDDD);
		slave_write(32'h1000_0024, 32'h01DF_555C);
		
		// poll0_command 
		slave_write(32'h1000_0028, 32'hFFFF_AAAA);
		slave_write(32'h1000_002C, 32'h01AE_95E3);
		
		// write command 
		slave_write(32'h1000_0038, 32'h1111_4444);
		slave_write(32'h1000_003C, 32'hABFA_CBD0);
		
		// poll_1 command 
		slave_write(32'h1000_0030, 32'hDDDD_CCCC);
		slave_write(32'h1000_0034, 32'h01AE_3316);
		
		// write command 
		slave_write(32'h1000_0040, 32'h0000_0000);
		slave_write(32'h1000_0044, 32'hAAAA_BBB0);
		
		/*********************************************************************************/
		/************************* trigger 2 *********************************************/
        /*********************************************************************************/		
		// write command 
        slave_write(32'h1000_0058, 32'hDEAD_BEEF);
        slave_write(32'h1000_005C, 32'h0000_D798);
		
		// rmw command 
		slave_write(32'h1000_0060, 32'hAAAA_BBBB);
		slave_write(32'h1000_0064, 32'h00E7_0F55);
		
		// write command 
		slave_write(32'h1000_0068, 32'hCCCC_DDDD);
		slave_write(32'h1000_006C, 32'h01DF_555C);
		
		// poll0_command 
		slave_write(32'h1000_0070, 32'hFFFF_AAAA);
		slave_write(32'h1000_0074, 32'h01AE_95E3);
		
		// write command 
		slave_write(32'h1010_0078, 32'h1111_4444);
		slave_write(32'h1000_007C, 32'hABFA_CBD0);
		
		// poll_1 command 
		slave_write(32'h1000_0080, 32'hDDDD_CCCC);
		slave_write(32'h1020_0084, 32'h01AE_3316);
		
		// write command 
		slave_write(32'h1000_0088, 32'h0000_0000);
		slave_write(32'h1000_008C, 32'hAAAA_BBB0);
		
		/*********************************************************************************/
		/************************* trigger 3 *********************************************/
        /*********************************************************************************/		
		// write command 
        slave_write(32'h1000_00A0, 32'hDEAD_BEEF);
        slave_write(32'h1000_00A4, 32'h0000_D798);
		
		// rmw command 
		slave_write(32'h1000_00A8, 32'hAAAA_BBBB);
		slave_write(32'h1000_00AC, 32'h00E7_0F55);
		
		// write command 
		slave_write(32'h1000_00B0, 32'hCCCC_DDDD);
		slave_write(32'h1000_00B4, 32'h01DF_555C);
		
		// poll0_command 
		slave_write(32'h1000_00B8, 32'hFFFF_AAAA);
		slave_write(32'h1000_00BC, 32'h01AE_95E3);
		
		// write command 
		slave_write(32'h1010_00C0, 32'h1111_4444);
		slave_write(32'h1000_00C4, 32'hABFA_CBD0);
		
		// poll_1 command 
		slave_write(32'h1000_00C8, 32'hDDDD_CCCC);
		slave_write(32'h1020_00CC, 32'h01AE_3316);
		
		// write command 
		slave_write(32'h1000_00D0, 32'h0000_0000);
		slave_write(32'h1000_00D4, 32'hAAAA_BBB0);
		
		
	    // Test Case 2: AHB slave write transaction "register configuration"
		// trigger 1 & trigger 3 active high ----- trigger 2 & 4 active low 
		slave_write(32'h0000_0000, 32'h0000_0003);
		slave_write(32'h0000_0004, 32'h0000_0049);
	    slave_write(32'h0000_0008, 32'h0000_0093);
		// made trigger source 4 take same start address of trigger 1 
		slave_write(32'h0000_000C, 32'h0000_0001);
		
		#10;
		i_htrans_slave = 1'b0;  // IDLE (end of transfer)
        i_hselx_slave = 0;       // Slave deselected
		
        // Test Case 3: AHB slave read transaction from both cmd and register 
        slave_read(32'h1000_0010);
        slave_read(32'h1000_0014);
		slave_read(32'h1000_0018);
		slave_read(32'h1000_001C);
		slave_read(32'h1000_0020);
		slave_read(32'h1000_0024);
		slave_read(32'h1000_0028);
		slave_read(32'h1000_002C);
		slave_read(32'h1000_0030);
		slave_read(32'h1000_0034);
		slave_read(32'h1000_0038);
		slave_read(32'h1000_003C);
		slave_read(32'h1000_0040);
		slave_read(32'h1000_0044);
		slave_read(32'h0000_0000);
		slave_read(32'h0000_0004);
		slave_read(32'h0000_0008);
		slave_read(32'h0000_000C);
		
		i_htrans_slave = 1'b0;  // IDLE (end of transfer)
        i_hselx_slave = 0;       // Slave deselected
		
        // Test Case 4: Trigger signal assertion 
		// Trigger signal assertion individually
        assert_trigger_rising(4'b0001);  // Trigger 1 activated
		
		RMW_check ;
		poll_0_check;
        poll_1_check ;
		
	    assert_trigger_failing(4'b0010);  // Trigger 2 activated
		
		RMW_check ;
		poll_0_check;
        poll_1_check ;
		
		// Trigger signal assertion serially 
		assert_trigger_rising(4'b0001);  // Trigger 1 activated
		assert_trigger_failing(4'b0010);  // Trigger 2 activated
		
		RMW_check ;
		poll_0_check;
        poll_1_check ;
		
		RMW_check ;
		poll_0_check;
        poll_1_check ;
		
		// Trigger signal assertion simultaneously & all activated
		assert_trigger_rising(4'b0101);  
		assert_trigger_failing(4'b1010);  

		RMW_check ;
	    poll_0_check;
        poll_1_check;
		
		RMW_check ;
		poll_0_check;
        poll_1_check;
		
		RMW_check ;
		poll_0_check;
        poll_1_check;
		
		RMW_check ;
		poll_0_check;
        poll_1_check;

		#10; i_hrdata_master = 32'h0000_0000 ; 
		
	    // Test Case 5: fsm read and slave read  
		assert_trigger_rising(4'b0100);  // Trigger 3 activated
		
	    slave_read(32'h1000_0058);
        slave_read(32'h1000_005C);
		slave_read(32'h1000_0060);
		slave_read(32'h1000_0064);
		slave_read(32'h1000_0068);
		slave_read(32'h1000_006C);
		slave_read(32'h1000_0070);
		slave_read(32'h1000_0074);
		slave_read(32'h1000_0078);
		slave_read(32'h1000_007C);
		slave_read(32'h1000_0080);
		slave_read(32'h1000_0084);
		slave_read(32'h1000_0088);
		slave_read(32'h1000_008C);
						
        #50 $finish;
    end

    // Instantiate the gp_engine module
    gp_engine #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TRANS_ADDR_WIDTH(TRANS_ADDR_WIDTH),
        .CMD_WIDTH(CMD_WIDTH),
        .NO_TRIG_SR(NO_TRIG_SR),
		.BUFFER_WIDTH(BUFFER_WIDTH),
		.BUFFER_DEPTH(BUFFER_DEPTH)
    ) u_gp_engine (
        // Clock and Reset
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        
        // AHB-Lite Slave Interface
        .i_hready_slave(i_hready_slave),
        .i_htrans_slave(i_htrans_slave),
        .i_hsize_slave(i_hsize_slave),
        .i_hwrite_slave(i_hwrite_slave),
        .i_haddr_slave(i_haddr_slave),
        .i_hwdata_slave(i_hwdata_slave),
        .i_hselx_slave(i_hselx_slave),
        .o_hreadyout_slave(o_hreadyout_slave),
        .o_hresp_slave(o_hresp_slave),
        .o_hrdata_slave(o_hrdata_slave),
        
        // Trigger Inputs
        .i_str_trig(i_start_trig),
        
        // AHB-Lite Master Interface
        .i_hready_master(i_hready_master),
        .i_hresp_master(i_hresp_master),
        .o_hwrite_master(o_hwrite_master),
        .o_htrans_master(o_htrans_master),
        .o_hsize_master(o_hsize_master),
        .i_hrdata_master(i_hrdata_master),
        .o_haddr_master(o_haddr_master),
        .o_hwdata_master(o_hwdata_master)
    );

endmodule
