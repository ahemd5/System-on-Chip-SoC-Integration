
package slave_apb_monitor_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import slave_apb_seq_item_pkg::*;

class slave_apb_monitor extends uvm_monitor;
   `uvm_component_utils(slave_apb_monitor)
     virtual slave_arb_if slv_apb_vif;
   slave_apb_seq_item rsp_seq_item;
   uvm_analysis_port #(slave_apb_seq_item) mon_ap;
   
   function new(string name = "slave_apb_monitor", uvm_component parent = null);
      super.new(name, parent);
   endfunction
   
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon_ap = new("mon_ap", this);
   endfunction: build_phase
   
		 
		 
   task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
         rsp_seq_item = slave_apb_seq_item::type_id::create("rsp_seq_item");
         @(negedge slv_apb_vif.i_clk_apb);
         rsp_seq_item.i_rstn_apb = slv_apb_vif.i_rstn_apb;
		 rsp_seq_item.o_valid = slv_apb_vif.o_valid;
		 rsp_seq_item.o_rd0_wr1 = slv_apb_vif.o_rd0_wr1;
         rsp_seq_item.o_wr_data = slv_apb_vif.o_wr_data;
         rsp_seq_item.o_addr = slv_apb_vif.o_addr;
         rsp_seq_item.i_rd_data = slv_apb_vif.i_rd_data;
         rsp_seq_item.i_ready = slv_apb_vif.i_ready;
		 rsp_seq_item.i_rd_valid = slv_apb_vif.i_rd_valid;
		 rsp_seq_item.i_pwdata = slv_apb_vif.i_pwdata;
		 rsp_seq_item.i_paddr = slv_apb_vif.i_paddr;
	     rsp_seq_item.i_psel = slv_apb_vif.i_psel;
	     rsp_seq_item.i_penable = slv_apb_vif.i_penable;
		 rsp_seq_item.i_pwrite = slv_apb_vif.i_pwrite;
		 rsp_seq_item.o_pslverr = slv_apb_vif.o_pslverr;
	     rsp_seq_item.o_pready = slv_apb_vif.o_pready;
		 rsp_seq_item.o_prdata = slv_apb_vif.o_prdata;
		 
         mon_ap.write(rsp_seq_item);
         `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_HIGH)
      end
   endtask
endclass
endpackage


