package slave_apb_main_sequence_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import slave_apb_seq_item_pkg::*;

class slave_apb_main_sequence extends uvm_sequence #(slave_apb_seq_item);
 `uvm_object_utils(slave_apb_main_sequence)

slave_apb_seq_item slv_seq_item;

function new(string name = "slave_apb_main_sequence" );
super.new(name);
endfunction

task body();
repeat(10000)begin
slv_seq_item = slave_apb_seq_item::type_id::create("slv_seq_item");
start_item(slv_seq_item);
assert(slv_seq_item.randomize());
finish_item(slv_seq_item);
end
endtask



endclass
endpackage


 
