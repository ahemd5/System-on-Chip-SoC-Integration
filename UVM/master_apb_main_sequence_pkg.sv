
package master_apb_main_sequence_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_apb_seq_item_pkg::*;

class master_apb_main_sequence extends uvm_sequence #(master_apb_seq_item);
 `uvm_object_utils(master_apb_main_sequence)

master_apb_seq_item mast_seq_item;

function new(string name = "master_apb_main_sequence" );
super.new(name);
endfunction

task body();
repeat(10000)begin
mast_seq_item = master_apb_seq_item::type_id::create("mast_seq_item");
start_item(mast_seq_item);
assert(mast_seq_item.randomize());
finish_item(mast_seq_item);
end
endtask



endclass
endpackage


 
