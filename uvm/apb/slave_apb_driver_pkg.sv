package slave_apb_driver_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import slave_apb_seq_item_pkg::*;
import apb_config_pkg::*;

class slave_apb_driver extends uvm_driver #(slave_apb_seq_item);
   `uvm_component_utils(slave_apb_driver)

   virtual slave_arb_if slv_apb_vif;
   slave_apb_seq_item slv_stim_seq_item;

   function new(string name = "slave_apb_driver", uvm_component parent = null);
      super.new(name, parent);
   endfunction


   task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
         slv_stim_seq_item = slave_apb_seq_item::type_id::create("slv_stim_seq_item");
         seq_item_port.get_next_item(slv_stim_seq_item);
         slv_apb_vif.i_rstn_apb = slv_stim_seq_item.i_rstn_apb;
         slv_apb_vif.o_valid = slv_stim_seq_item.o_valid;
         slv_apb_vif.o_rd0_wr1 = slv_stim_seq_item.o_rd0_wr1;
         slv_apb_vif.o_wr_data = slv_stim_seq_item.o_wr_data;
         slv_apb_vif.o_addr = slv_stim_seq_item.o_addr;
         slv_apb_vif.i_rd_data = slv_stim_seq_item.i_rd_data;
         slv_apb_vif.i_ready = slv_stim_seq_item.i_ready;
         slv_apb_vif.i_rd_valid = slv_stim_seq_item.i_rd_valid;
         slv_apb_vif.i_pwdata = slv_stim_seq_item.i_pwdata;
         slv_apb_vif.i_paddr = slv_stim_seq_item.i_paddr;
         slv_apb_vif.i_psel = slv_stim_seq_item.i_psel;
		 slv_apb_vif.i_penable = slv_stim_seq_item.i_penable;
		 slv_apb_vif.i_pwrite = slv_stim_seq_item.i_pwrite;
		 slv_apb_vif.o_pslverr = slv_stim_seq_item.o_pslverr;
		 slv_apb_vif.o_pready = slv_stim_seq_item.o_pready;
		 slv_apb_vif.o_prdata = slv_stim_seq_item.o_prdata;

         @(posedge slv_apb_vif.i_clk_apb);
         seq_item_port.item_done();
         `uvm_info("Driver", slv_stim_seq_item.convert2string_stimulus(), UVM_HIGH);
      end
   endtask
endclass
endpackage

