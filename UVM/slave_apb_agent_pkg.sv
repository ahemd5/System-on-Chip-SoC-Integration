
package slave_apb_agent_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import slave_apb_driver_pkg::*;
import slave_apb_monitor_pkg::*;
import slave_apb_main_sequence_pkg::*;
import slave_apb_seq_item_pkg::*;
import apb_config_pkg::*;
import slave_apb_sequencer_pkg::*;

class slave_apb_agent extends uvm_agent;
  `uvm_component_utils(slave_apb_agent);
  slave_apb_sequencer slv_sqr;  
  slave_apb_driver slv_drv;
  slave_apb_monitor slv_mon;
  apb_config slv_apb_cfg;
  uvm_analysis_port #(slave_apb_seq_item) agt_ap;

  function new(string name = "slave_apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(apb_config)::get(this, "", "CFG", slv_apb_cfg)) begin
      `uvm_fatal("build_phase", "Unable to get configuration object");
    end else begin
      `uvm_info("slave Agent", "Configuration object retrieved successfully", UVM_MEDIUM);
    end
    slv_sqr = slave_apb_sequencer::type_id::create("slv_sqr", this);
    slv_drv = slave_apb_driver::type_id::create("slv_drv", this);
    slv_mon = slave_apb_monitor::type_id::create("slv_mon", this);
    agt_ap = new("agt_ap", this);
    `uvm_info("slave Agent", "Driver, Monitor, and Sequence created", UVM_MEDIUM);
  endfunction

  function void connect_phase(uvm_phase phase);
      slv_drv.slv_apb_vif = slv_apb_cfg.slv_apb_vif; 
      slv_mon.slv_apb_vif = slv_apb_cfg.slv_apb_vif;
	  slv_drv.seq_item_port.connect(slv_sqr.seq_item_export); 
	  slv_mon.mon_ap.connect(agt_ap); 
      `uvm_info("slave Agent", "Connections to slave interface established", UVM_MEDIUM);
  endfunction
endclass
endpackage
