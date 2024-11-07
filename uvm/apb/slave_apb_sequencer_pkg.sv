package slave_apb_sequencer_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import slave_apb_seq_item_pkg::*;

class slave_apb_sequencer extends uvm_sequencer #(slave_apb_seq_item);
`uvm_component_utils(slave_apb_sequencer);

function new(string name = "slave_apb_sequencer" , uvm_component parent = null);
super.new(name,parent);
endfunction

endclass
endpackage