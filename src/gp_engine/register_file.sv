// ---------------------------------------------------------------------------------------------------
// Module: register_file
//
// Key Features:
//   1. This register file module stores configurations for 4 trigger sources.
//   2. Supports both write and read operations via an external slave interface (AHB Slave).
//   3. Provides handshaking signals to ensure correct data transfer with the slave interface.
//   4. Supports FSM access to read configurations from the register file.
// -----------------------------------------------------------------------------------------------------

module register_file #(
    parameter DATA_WIDTH = 32,                                 
			  TRANS_ADDR_WIDTH = 8 
)(
    input logic i_clk,      // Clock signal for the register file
    input logic i_rstn,     // Active-low reset signal for the register file
    
    // Interface with AHB slave (write and read operations)
    input logic slv_o_valid,                       // Slave output valid signal (indicates the validity of the slave's request)
    input logic [DATA_WIDTH-1:0] slv_o_wr_data,    // Data to write into the register file
    input logic slv_o_rd0_wr1,                     // Signal to distinguish between read (0) and write (1) operations
    output reg  slv_i_ready,                       // Slave interface ready signal (indicates that register file is ready for new transaction)
    output reg  [DATA_WIDTH-1:0] slv_i_rd_data,    // Data read from the register file (on read operation)
    output reg  slv_i_rd_valid,                    // Read valid signal (indicates that read data is valid)
    
    // Interface with FSM (to read configurations of trigger sources)
    input logic reg_rd_en,                          // Register read enable signal (from FSM)
    output reg [DATA_WIDTH-1:0] rd_trig_s1_config,  // Configuration for trigger source 1
    output reg [DATA_WIDTH-1:0] rd_trig_s2_config,  // Configuration for trigger source 2
    output reg [DATA_WIDTH-1:0] rd_trig_s3_config,  // Configuration for trigger source 3
    output reg [DATA_WIDTH-1:0] rd_trig_s4_config,  // Configuration for trigger source 4
    output reg reg_rd_valid,                        // Register read valid signal (indicates the validity of the read data to FSM)

    // Register enable signal from address decoder
    input logic reg_en,                             // Register file enable signal (from address decoder)
	input logic [TRANS_ADDR_WIDTH-1:0] trans_addr   // Translated address 
);

    // Registers to store trigger configurations for 4 trigger sources
    reg [DATA_WIDTH-1:0] trigger_config[0:3];  // Array to store the 32-bit configurations for each trigger source

    // Write and read operations for the register file
    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            // Reset all trigger configurations to zero on reset
            trigger_config[0] <= {DATA_WIDTH{1'b0}};
            trigger_config[1] <= {DATA_WIDTH{1'b0}};
            trigger_config[2] <= {DATA_WIDTH{1'b0}};
            trigger_config[3] <= {DATA_WIDTH{1'b0}};
            
            // Reset other signals
            slv_i_ready <= 1'b1;
			slv_i_rd_valid <= 1'b0;
            slv_i_rd_data <= {DATA_WIDTH{1'b0}};      	
        end else if (reg_en && slv_o_valid && slv_o_rd0_wr1) begin
            // Check if the register file is enabled by address decoder
            // If slave output is valid, check for write (1) or read (0) operation
            // Write operation
                case (trans_addr)
                    // Writing to the trigger source 1 configuration
                    8'b0000_0000: trigger_config[0] <= slv_o_wr_data;
                    // Writing to the trigger source 2 configuration
                    8'b0000_0001: trigger_config[1] <= slv_o_wr_data;
                    // Writing to the trigger source 3 configuration
                    8'b0000_0010: trigger_config[2] <= slv_o_wr_data;
                    // Writing to the trigger source 4 configuration
                    8'b0000_0011: trigger_config[3] <= slv_o_wr_data;
                    default: ;  // Do nothing for invalid addresses
                endcase
                slv_i_ready <= 1'b1;  // Indicate that the register file is ready for the next write operation
        end else if (~reg_en || ~slv_o_valid && slv_o_rd0_wr1) begin
		    slv_i_ready <= 1'b1;
		end 
    end
	
	always @(*) begin
		if (reg_en && slv_o_valid && !slv_o_rd0_wr1) begin
			// Read operation (debugging mode)
			slv_i_ready = 1'b1;
			slv_i_rd_valid = 1'b0;
			case (trans_addr)
				// Reading trigger source 1 configuration
				8'b0000_0000: begin 
					slv_i_rd_data = trigger_config[0];
					slv_i_rd_valid = 1'b1;  // Indicate valid read data
				end 				
				// Reading trigger source 2 configuration
				8'b0000_0001: begin 
					slv_i_rd_data = trigger_config[1];
					slv_i_rd_valid = 1'b1;  // Indicate valid read data
				end 			
				// Reading trigger source 3 configuration
				8'b0000_0010: begin 
					slv_i_rd_data = trigger_config[2];
					slv_i_rd_valid = 1'b1;  // Indicate valid read data
				end 			
				// Reading trigger source 4 configuration
				8'b0000_0011: begin 
					slv_i_rd_data = trigger_config[3];
					slv_i_rd_valid = 1'b1;  // Indicate valid read data
				end 			
				default: begin 
					// if address not valid
					slv_i_rd_data = {DATA_WIDTH{1'b0}};
					slv_i_rd_valid = 1'b0;  // Indicate invalid read data
				end 			
			endcase
        end else begin
            // Reset the ready and read valid signals if slave output is not valid and reg file not enabled 
			slv_i_rd_data = {DATA_WIDTH{1'b0}};
            slv_i_ready = 1'b1;
            slv_i_rd_valid = 1'b0;
        end
	end 
	

    // Read configurations for FSM 
    always @(*) begin
        if (reg_rd_en && (!reg_en || (reg_en && !slv_o_rd0_wr1))) begin
            if (trigger_config[0] == 32'b0 && trigger_config[1] == 32'b0 && trigger_config[2] == 32'b0 && trigger_config[3] == 32'b0) begin
			    reg_rd_valid = 1'b0;  
				rd_trig_s1_config = {DATA_WIDTH{1'b0}};
                rd_trig_s2_config = {DATA_WIDTH{1'b0}};
                rd_trig_s3_config = {DATA_WIDTH{1'b0}};
                rd_trig_s4_config = {DATA_WIDTH{1'b0}};
				slv_i_ready = 1'b1;
			end else begin
                // If FSM has enabled register read
                rd_trig_s1_config = trigger_config[0];
                rd_trig_s2_config = trigger_config[1];
                rd_trig_s3_config = trigger_config[2];
                rd_trig_s4_config = trigger_config[3];
                reg_rd_valid = 1'b1;  // Indicate valid configuration data to FSM
				slv_i_ready = 1'b1;
			end 
        end else begin
            // Reset register read valid signal if FSM has not enabled read
            reg_rd_valid = 1'b0;
			rd_trig_s1_config = {DATA_WIDTH{1'b0}};
            rd_trig_s2_config = {DATA_WIDTH{1'b0}};
            rd_trig_s3_config = {DATA_WIDTH{1'b0}};
            rd_trig_s4_config = {DATA_WIDTH{1'b0}};
			slv_i_ready = 1'b1;
        end
    end

endmodule