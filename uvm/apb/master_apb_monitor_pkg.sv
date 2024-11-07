

package master_apb_monitor_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_apb_seq_item_pkg::*;

class master_apb_monitor extends uvm_monitor;
   `uvm_component_utils(master_apb_monitor)
     virtual master_arb_if mast_apb_vif;
   master_apb_seq_item rsp_seq_item;
   uvm_analysis_port #(master_apb_seq_item) mon_ap;
   
   function new(string name = "master_apb_monitor", uvm_component parent = null);
      super.new(name, parent);
   endfunction
   
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon_ap = new("mon_ap", this);
   endfunction: build_phase
   
		 
		 
   task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
         rsp_seq_item = master_apb_seq_item::type_id::create("rsp_seq_item");
         @(posedge mast_apb_vif.i_clk_apb);
         rsp_seq_item.i_rstn_apb = mast_apb_vif.i_rstn_apb;
		 rsp_seq_item.i_valid = mast_apb_vif.i_valid;
		 rsp_seq_item.i_rd0_wr1 = mast_apb_vif.i_rd0_wr1;
         rsp_seq_item.i_wr_data = mast_apb_vif.i_wr_data;
         rsp_seq_item.i_addr = mast_apb_vif.i_addr;
         rsp_seq_item.o_rd_data = mast_apb_vif.o_rd_data;
         rsp_seq_item.o_ready = mast_apb_vif.o_ready;
		 rsp_seq_item.o_rd_valid = mast_apb_vif.o_rd_valid;
		 rsp_seq_item.o_pwdata = mast_apb_vif.o_pwdata;
		 rsp_seq_item.o_paddr = mast_apb_vif.o_paddr;
	     rsp_seq_item.o_psel = mast_apb_vif.o_psel;
	     rsp_seq_item.o_penable = mast_apb_vif.o_penable;
		 rsp_seq_item.o_pwrite = mast_apb_vif.o_pwrite;
		 rsp_seq_item.i_pslverr = mast_apb_vif.i_pslverr;
	     rsp_seq_item.i_pready = mast_apb_vif.i_pready;
		 rsp_seq_item.i_prdata = mast_apb_vif.i_prdata;
		 
         mon_ap.write(rsp_seq_item);
         `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_HIGH)
      end
   endtask
endclass
endpackage


