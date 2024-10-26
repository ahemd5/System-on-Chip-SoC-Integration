
package apb_test_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import apb_env_pkg::*;  
  import apb_config_pkg::*; 
  ///////////////////////////////////////////////////////////////////////
  import master_apb_main_sequence_pkg::*; 
  import slave_apb_main_sequence_pkg::*; 
  //////////////////////////////////////////////////////////////////
  class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)

    apb_env env;
    apb_config apb_cfg;
	virtual master_arb_if mast_apb_vif;
	virtual slave_arb_if slv_apb_vif;
	/////////////////////////////////////////////////
	master_apb_main_sequence mast_main_seq;
    slave_apb_main_sequence slv_main_seq;
    /////////////////////////////////////////////////
    function new(string name = "apb_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = apb_env::type_id::create("env", this);
      apb_cfg = apb_config::type_id::create("apb_cfg", this);
	  /////////////////////////////////////////////////////////////////////////
       mast_main_seq = master_apb_main_sequence::type_id::create("mast_main_seq", this);
	   slv_main_seq = slave_apb_main_sequence::type_id::create("slv_main_seq", this);
	   ////////////////////////////////////////////////////////////////////////
      if (!uvm_config_db#(virtual master_arb_if)::get(this, "", "apb_IF", apb_cfg.mast_apb_vif))
        `uvm_fatal("build_phase", "Unable to get the virtual master interface from uvm_config_db");
		
	  if (!uvm_config_db#(virtual slave_arb_if)::get(this, "", "apb_IF", apb_cfg.slv_apb_vif))
        `uvm_fatal("build_phase", "Unable to get the virtual slave interface from uvm_config_db");
		
      uvm_config_db#(apb_config)::set(this, "*", "CFG", apb_cfg);
    endfunction

    task run_phase(uvm_phase phase);
      super.run_phase(phase);
      phase.raise_objection(this);
	  ////////////////////////////////////////////////////////////////////////
	  `uvm_info("run_phase"," BEGIN MASTER AGENT.",UVM_LOW)
       mast_main_seq.start(env.mast_agt.mast_sqr);
	  `uvm_info("run_phase"," END MASTER AGENT.",UVM_LOW)
	  
	  `uvm_info("run_phase"," BEGIN SLAVE AGENT.",UVM_LOW)
       slv_main_seq.start(env.slv_agt.slv_sqr);
	  `uvm_info("run_phase"," END SLAVE AGENT.",UVM_LOW)
	  
      ////////////////////////////////////////////////////////////////////////
      phase.drop_objection(this);
    endtask

  endclass
endpackage



