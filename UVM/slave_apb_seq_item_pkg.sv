package slave_apb_seq_item_pkg;

import uvm_pkg::*;
`include "uvm_macros.svh"

class slave_apb_seq_item extends uvm_sequence_item;
`uvm_object_utils(slave_apb_seq_item)

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 32;
///////////// right side ///////////////////////
bit [DATA_WIDTH-1:0] o_wr_data;
bit [ADDR_WIDTH-1:0] o_addr;
bit  o_valid, o_rd0_wr1;
rand bit [DATA_WIDTH-1:0] i_rd_data;
rand bit i_rstn_apb,i_rd_valid, i_ready;

////////// left side /////////////
rand bit [DATA_WIDTH-1:0] i_pwdata;
rand bit [ADDR_WIDTH-1:0] i_paddr;
rand bit i_psel, i_penable, i_pwrite;
bit [DATA_WIDTH-1:0] o_prdata;
bit o_pslverr, o_pready;


function new(string name ="slave_apb_seq_item");
super.new(name);
endfunction


function string convert2string(); 
return $sformatf("%s i_rstn_apb = 0b%0b,o_wr_data = 0b%0b, o_addr = 0b%0b, o_valid = 0b%0b, o_rd0_wr1 = 0b%0b, i_rd_data = 0b%0b , i_rd_valid = 0b%0b, i_ready = 0b%0b, i_pwdata = 0b%0b, i_paddr = 0b%0b, i_psel = 0b%0b, i_penable = 0b%0b, i_pwrite = 0b%0b, o_prdata = 0b%0b, o_pslverr = 0b%0b, o_pready = 0b%0b",super.convert2string, i_rstn_apb,o_wr_data, o_addr, o_valid, o_rd0_wr1,i_rd_data,i_rd_valid,i_ready,i_pwdata,i_paddr,i_psel,i_penable,i_pwrite,o_prdata,o_pslverr,o_pready);
endfunction


function string convert2string_stimulus(); 
return $sformatf("i_rstn_apb = 0b%0b,o_wr_data = 0b%0b, o_addr = 0b%0b, o_valid = 0b%0b, o_rd0_wr1 = 0b%0b, o_rd_data = 0b%0b , o_rd_valid = 0b%0b, o_ready = 0b%0b, o_pwdata = 0b%0b, o_paddr = 0b%0b, o_psel = 0b%0b, i_penable = 0b%0b, i_pwrite = 0b%0b, o_prdata = 0b%0b, o_pslverr = 0b%0b, o_pready = 0b%0b", i_rstn_apb,o_wr_data, o_addr, o_valid, o_rd0_wr1, i_rd_data,i_rd_valid,i_ready,i_pwdata,i_paddr,i_psel,i_penable,i_pwrite,o_prdata,o_pslverr,o_pready);
endfunction

////////////////////////////////

constraint trans {
i_rstn_apb dist {0:=5 , 1:=95};
i_rd_valid dist {0:=10, 1:=90};
i_psel dist {0:=10 , 1:=90};
i_penable dist {0:=10 , 1:=90};
i_pwrite dist {0:=30 , 1:=70};
i_ready dist {0:=30 , 1:=70};
}
endclass

endpackage
