// ---------------------------------------------------------------------
// Module: address_decoder
// Description:
//   This module decodes a 32-bit word-aligned AHB slave address and maps
//   it to either the Register File or the Command Buffer based on the
//   address range. The module outputs:
//     - `reg_en` to select the Register File when the address falls within 
//       the Register File's range.
//     - `cmd_en` to select the Command Buffer when the address falls within 
//       the Command Buffer's range.
//   It also generates a `trans_addr` which is the translated address, 
//   representing the offset within the selected region (Register File or 
//   Command Buffer).
//
//   The address ranges are defined as follows:
//     1. Register File: Address range from 0x00 to 0x03 (4 words).
//     2. Command Buffer: Address range from 0x04 to 0x103 (256 words).
//
//   This module is responsible for routing the AHB address to the correct
//   block (Register File or Command Buffer) and calculating the appropriate
//   offset within the selected block.
// ---------------------------------------------------------------------
module address_decoder #(parameter ADDR_WIDTH = 32 , TRANS_ADDR_WIDTH = 8)(
    input  logic [ADDR_WIDTH-1:0]    slv_o_addr,   // 32-bit AHB SLAVE Address  
    output reg [TRANS_ADDR_WIDTH-1:0] trans_addr,   // Translated address (offset)
    output reg reg_en,   // Enable signal for Register File
    output reg cmd_en    // Enable signal for Command Buffer
);

// -----------------------------------------------------------------
//   Address Range Definitions (32-bit word-aligned, first two LSBs are always 0)
//   - Register File: Address range from 0x00 to 0x03 (4 words).
//   - Command Buffer: Address range from 0x04 to 0x103 (256 words).
// -----------------------------------------------------------------

always @(*) begin
    // Default outputs to ensure proper initial state
    reg_en = 1'b0;   // Deassert register file enable by default
    cmd_en = 1'b0;   // Deassert command buffer enable by default
    trans_addr = 8'd0; // Default translated address to zero

    // -----------------------------------------------------------------
    // Decode Logic:
    //   - reg_en: Asserted when slv_o_addr falls within Register File range.
    //   - cmd_en: Asserted when slv_o_addr falls within Command Buffer range.
    //   The translated address (trans_addr) is calculated as the offset
    //   within the selected region (Register File or Command Buffer).
    // -----------------------------------------------------------------
	
    // Check if the address falls within the Register File address range
    if (slv_o_addr[31:2] < 10'h04) begin
        // Register File range: slv_o_addr[31:2] = 0x00 to 0x03 (4 words)
        reg_en = 1'b1;  // Enable Register File block
        trans_addr = slv_o_addr[3:2]; // Translate to offset within Register File (2-bit offset)
    end 
    // Check if the address falls within the Command Buffer address range
    else if (slv_o_addr[31:2] >= 10'h04 && slv_o_addr[31:2] <= 10'h103) begin
        // Command Buffer range: slv_o_addr[31:2] = 0x04 to 0x103 (256 words)
        cmd_en = 1'b1;  // Enable Command Buffer block
        trans_addr = slv_o_addr[31:2] - 10'h04; // Translate to offset within Command Buffer (8-bit offset)
    end
end
	
endmodule
