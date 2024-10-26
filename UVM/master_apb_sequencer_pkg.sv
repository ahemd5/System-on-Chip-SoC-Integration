
package master_apb_sequencer_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_apb_seq_item_pkg::*;

class master_apb_sequencer extends uvm_sequencer #(master_apb_seq_item);
`uvm_component_utils(master_apb_sequencer);

function new(string name = "master_apb_sequencer" , uvm_component parent = null);
super.new(name,parent);
endfunction

endclass
endpackage
