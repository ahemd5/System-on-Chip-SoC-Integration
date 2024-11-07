module tb_Sync_FIFO;

    // Parameters
    localparam DATA_WIDTH = 32;   // Width of data in the FIFO
    localparam MEM_DEPTH = 16;    // Depth of the FIFO (number of entries)
    localparam PTR_WIDTH = $clog2(MEM_DEPTH);  // Pointer width, calculated from depth

    // Inputs
    reg                  i_clk;         // Clock input for the FIFO
    reg                  i_rstn;        // Active-low reset
    reg [DATA_WIDTH-1:0] i_wr_data;     // Data input for write operations
    reg                  i_wr_en;       // Write enable signal
    reg                  i_rd_en;       // Read enable signal

    // Outputs
    logic [DATA_WIDTH-1:0] o_rd_data;   // Data output for read operations
    logic                  o_full;      // FIFO full indicator
    logic                  o_empty;     // FIFO empty indicator

    // Instantiate the FIFO under test (UUT)
    Sync_FIFO #(
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(MEM_DEPTH),
        .PTR_WIDTH(PTR_WIDTH)
    ) U0_Sync_FIFO (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_wr_data(i_wr_data),
        .i_wr_en(i_wr_en),
        .i_rd_en(i_rd_en),
        .o_rd_data(o_rd_data),
        .o_full(o_full),
        .o_empty(o_empty)
    );

    // Clock generation: toggles every 5 time units
    initial begin
        i_clk = 1;
        forever #5 i_clk = ~i_clk;
    end

    // Reset task: asserts reset for a duration and then deasserts it
    task reset();
        begin
            i_rstn = 0;
            #17.5 i_rstn = 1;
        end
    endtask

    // Task to write data to the FIFO
    task write(input [DATA_WIDTH-1:0] data);
        begin
            @(negedge i_clk);
            #2.5
			i_wr_data = data;
            i_wr_en = 1;
            @(posedge i_clk);
            #2.5
            i_wr_en = 0;
        end
    endtask

    // Task to read data from the FIFO
    task read();
        begin
            @(negedge i_clk);
            #2.5
            i_rd_en = 1;
            @(posedge i_clk);
            #2.5
            i_rd_en = 0;
        end
    endtask

    // Task to fill the FIFO to capacity
    task fill_fifo();
        integer i;
        begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                write(i);
            end
        end
    endtask

    // Task to empty the FIFO completely
    task empty_fifo();
        integer i;
        begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                read();
            end
        end
    endtask

    // Test sequence
    initial begin
        // Perform reset
        reset();
		
        /*****************************************************************************/
        /***************** Test 1: Write and read a single data item******************/
		/*****************************************************************************/
		
        $display("Test 1: Normal Write/Read");
        write(32'hABA51536);
        read();
        if (o_rd_data == 32'hABA51536)
            $display("PASS: Data Read = %h", o_rd_data);
        else
            $display("FAIL: Data Read = %h", o_rd_data);
         
		$display("");
		
		/*****************************************************************************/
        /***************** Test 2: Fill FIFO and check full condition*****************/
		/*****************************************************************************/
		
        $display("Test 2: Fill FIFO to Full");
        fill_fifo();
        if (o_full)
            $display("PASS: FIFO is Full");
        else
            $display("FAIL: FIFO is not Full");
			
		$display("");	
		
        /*****************************************************************************/
        /************** Test 3: Empty FIFO and check empty condition******************/
		/*****************************************************************************/
		
        $display("Test 3: Empty FIFO to Empty");
        empty_fifo();
        if (o_empty)
            $display("PASS: FIFO is Empty");
        else
            $display("FAIL: FIFO is not Empty");
			
		$display("");	

		/*****************************************************************************/
        /************** Test 4: Perform random read/write operations******************/
		/*****************************************************************************/
		
        $display("Test 4: Random Read/Write");
        write(32'h3CFA7891);
        write(32'h4DEC9511);
        read();
        if (o_rd_data == 32'h3CFA7891)
            $display("PASS: Data Read = %h", o_rd_data);
        else
            $display("FAIL: Data Read = %h", o_rd_data);

        read();
        if (o_rd_data == 32'h4DEC9511)
            $display("PASS: Data Read = %h", o_rd_data);
        else
            $display("FAIL: Data Read = %h", o_rd_data);
			
        $display("");
		
		/*****************************************************************************/
        /*** Test 5: Attempt to write when FIFO is full and read when FIFO is empty***/
		/*****************************************************************************/
		
        $display("Test 5: Boundary Condition - Write Full / Read Empty");

        // Fill FIFO again
        fill_fifo();

        // Try writing one more item
        write(32'hFFFFFFFF);  // Should not write, as FIFO is full

        if (o_full)
            $display("PASS: FIFO remains Full after attempting overfill");
        else
            $display("FAIL: FIFO is not Full after attempting overfill");

        // Empty FIFO again
        empty_fifo();

        // Try reading one more item
        read();  // Should not read, as FIFO is empty

        if (o_empty)
            $display("PASS: FIFO remains Empty after attempting to over-read");
        else
            $display("FAIL: FIFO is not Empty after attempting to over-read");
        
		$display("");
		
		/*****************************************************************************/
		/*** Test 6: write pointer has wrapped around and caught up to read pointer***/
		/*****************************************************************************/
		
        $display("Test 6: Full Condition - Write wrapped around and caught up to read");

        // Fill FIFO 
        fill_fifo();
        
		// 19 write operatiob (2'b10011) & 3 read operation (2'b00011) 
        read(); read(); read();
		write(32'hFFFFFFFF); write(32'hFFFFFFFF); write(32'hFFFFFFFF);

        if (o_full) begin 
            $display("PASS: Design solution worked Using an Extra Bit in Each Pointer");
			$display("----reliable full and empty fifo condition----");
        end else
            $display("FAIL: Design solution not worked Using an Extra Bit in Each Pointer");
        
		$display("");
		
        // End of test sequence
        $display("Test complete");
		$display("");
        $finish;
    end

endmodule