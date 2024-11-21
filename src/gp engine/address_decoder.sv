// ---------------------------------------------------------------------
// Module: address_decoder
// Description:
//   This module decodes the 32-bit word-aligned AHB slave address to 
//   enable one of two blocks:
//     1. Register File (reg_en)
//     2. Command Buffer (cmd_en)
//   It ensures proper selection based on the address range.
//
// Parameters:
//   ADDR_WIDTH: Width of the address bus (default: 32 bits)
//
// Ports:
//   slv_o_addr [in]: 32-bit AHB slave address to decode.
//   reg_en     [out]: Select signal for Register File.
//   cmd_en     [out]: Select signal for Command Buffer.
// ---------------------------------------------------------------------
module address_decoder #(parameter ADDR_WIDTH = 32)(
    input  logic [ADDR_WIDTH-1:0] slv_o_addr,   // 32-bit AHB SLAVE Address        
    output logic                  reg_en,       // Select signal for Register File
    output logic                  cmd_en        // Select signal for Command Buffer
);

    // -----------------------------------------------------------------
    // Address Ranges (32-bit word-aligned, first two LSBs are always 0)
    //   REG_START_ADDR to REG_END_ADDR maps to the Register File
    //   CMD_START_ADDR to CMD_END_ADDR maps to the Command Buffer
    // -----------------------------------------------------------------
    localparam logic [31:0] REG_START_ADDR = 32'h0000_0000; // Start of Register File range (0)
    localparam logic [31:0] REG_END_ADDR   = 32'h0000_000C; // End of Register File range (12)
    localparam logic [31:0] CMD_START_ADDR = 32'h0000_0010; // Start of Command Buffer range (16)
    localparam logic [31:0] CMD_END_ADDR   = 32'hFFFF_FFFC; // End of Command Buffer range (4,294,967,300)

    // -----------------------------------------------------------------
    // Decode Logic:
    //   reg_en: Asserted when slv_o_addr falls within Register File range.
    //   cmd_en: Asserted when slv_o_addr falls within Command Buffer range.
    // -----------------------------------------------------------------
    assign reg_en = (slv_o_addr >= REG_START_ADDR) && (slv_o_addr <= REG_END_ADDR);
    assign cmd_en = (slv_o_addr >= CMD_START_ADDR) && (slv_o_addr <= CMD_END_ADDR);

endmodule