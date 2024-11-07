package wait_seq;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_apb_seq_item_pkg::*;
import apb_config_pkg::*;
class master_apb_wait_state_sequence extends uvm_sequence #(master_apb_seq_item);
    `uvm_object_utils(master_apb_wait_state_sequence)


    function new(string name = "master_apb_wait_state_sequence");
        super.new(name);
    endfunction

     task body();
        master_apb_seq_item seq_item;
        
        // Generate a mix of read and write transactions
        for (int i = 0; i < 50; i++) begin
            seq_item = master_apb_seq_item::type_id::create("seq_item");

            seq_item.read_c.constraint_mode(0);
            
            // Start the sequence item
            start_item(seq_item);
            // Randomize the item
            if (!seq_item.randomize()) begin
                `uvm_error("SEQUENCE", "Randomization failed for seq_item.")
            end

            seq_item.i_pready=0;
            finish_item(seq_item);
        end
    endtask
endclass
endpackage : wait_seq