
package master_apb_agent_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_apb_driver_pkg::*;
import master_apb_monitor_pkg::*;
import master_apb_main_sequence_pkg::*;
import master_apb_seq_item_pkg::*;
import apb_config_pkg::*;
import master_apb_sequencer_pkg::*;

class master_apb_agent extends uvm_agent;
  `uvm_component_utils(master_apb_agent);
  master_apb_sequencer mast_sqr;  
  master_apb_driver mast_drv;
  master_apb_monitor mast_mon;
  apb_config mast_apb_cfg;
  uvm_analysis_port #(master_apb_seq_item) agt_ap;

  function new(string name = "master_apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(apb_config)::get(this, "", "CFG", mast_apb_cfg)) begin
      `uvm_fatal("build_phase", "Unable to get configuration object");
    end else begin
      `uvm_info("MASTER Agent", "Configuration object retrieved successfully", UVM_MEDIUM);
    end
    mast_sqr = master_apb_sequencer::type_id::create("mast_sqr", this);
    mast_drv = master_apb_driver::type_id::create("mast_drv", this);
    mast_mon = master_apb_monitor::type_id::create("mast_mon", this);
    agt_ap = new("agt_ap", this);
    `uvm_info("MASTER Agent", "Driver, Monitor, and Sequence created", UVM_MEDIUM);
  endfunction

  function void connect_phase(uvm_phase phase);
      mast_drv.mast_apb_vif = mast_apb_cfg.mast_apb_vif; 
      mast_mon.mast_apb_vif = mast_apb_cfg.mast_apb_vif;
	  mast_drv.seq_item_port.connect(mast_sqr.seq_item_export); 
	  mast_mon.mon_ap.connect(agt_ap); 
      `uvm_info("MASTER Agent", "Connections to MASTER interface established", UVM_MEDIUM);
  endfunction
endclass
endpackage
