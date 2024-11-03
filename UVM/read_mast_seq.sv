package master_apb_read_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_apb_seq_item_pkg::*;

class master_apb_read extends uvm_sequence #(master_apb_seq_item);
 `uvm_object_utils(master_apb_read)

master_apb_seq_item mast_seq_item;

function new(string name = "master_apb_read" );
super.new(name);
endfunction

task body();
repeat(100)begin
mast_seq_item = master_apb_seq_item::type_id::create("mast_seq_item");
mast_seq_item.write_c.constraint_mode(0);
start_item(mast_seq_item);
assert(mast_seq_item.randomize());
finish_item(mast_seq_item);
end
endtask



endclass
endpackage