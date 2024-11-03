
package master_apb_driver_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_apb_seq_item_pkg::*;
import apb_config_pkg::*;

class master_apb_driver extends uvm_driver #(master_apb_seq_item);
   `uvm_component_utils(master_apb_driver)

   virtual master_arb_if mast_apb_vif;
   master_apb_seq_item mast_stim_seq_item;

   function new(string name = "master_apb_driver", uvm_component parent = null);
      super.new(name, parent);
   endfunction


   task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
         mast_stim_seq_item = master_apb_seq_item::type_id::create("mast_stim_seq_item");
         seq_item_port.get_next_item(mast_stim_seq_item);
         mast_apb_vif.i_rstn_apb = mast_stim_seq_item.i_rstn_apb;
         mast_apb_vif.i_valid = mast_stim_seq_item.i_valid;
         mast_apb_vif.i_rd0_wr1 = mast_stim_seq_item.i_rd0_wr1;
         mast_apb_vif.i_wr_data = mast_stim_seq_item.i_wr_data;
         mast_apb_vif.i_addr = mast_stim_seq_item.i_addr;
         mast_apb_vif.o_rd_data = mast_stim_seq_item.o_rd_data;
         mast_apb_vif.o_ready = mast_stim_seq_item.o_ready;
         mast_apb_vif.o_rd_valid = mast_stim_seq_item.o_rd_valid;
         mast_apb_vif.o_pwdata = mast_stim_seq_item.o_pwdata;
         mast_apb_vif.o_paddr = mast_stim_seq_item.o_paddr;
         mast_apb_vif.o_psel = mast_stim_seq_item.o_psel;
		 mast_apb_vif.o_penable = mast_stim_seq_item.o_penable;
		 mast_apb_vif.o_pwrite = mast_stim_seq_item.o_pwrite;
		 mast_apb_vif.i_pslverr = mast_stim_seq_item.i_pslverr;
		 mast_apb_vif.i_pready = mast_stim_seq_item.i_pready;
		 mast_apb_vif.i_prdata = mast_stim_seq_item.i_prdata;

         @(posedge mast_apb_vif.i_clk_apb);
         seq_item_port.item_done();
         `uvm_info("Driver", mast_stim_seq_item.convert2string_stimulus(), UVM_HIGH);
      end
   endtask
endclass
endpackage
