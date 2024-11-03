
package apb_env_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"

import master_apb_agent_pkg::*;
import slave_apb_agent_pkg::*;
import apb_scoreboard_pkg::*;
import apb_coverage_pkg::*;
import master_apb_sequencer_pkg::*; 
import slave_apb_sequencer_pkg::*; 
import apb_config_pkg::*;
class apb_env extends uvm_env;
   `uvm_component_utils(apb_env)
   
   master_apb_agent mast_agt;
   slave_apb_agent slv_agt;
   apb_scoreboard sb;
   apb_coverage cov;
   master_apb_sequencer mast_seqr;
   slave_apb_sequencer slv_seqr;
   

   function new(string name = "apb_env", uvm_component parent = null);
      super.new(name, parent);
   endfunction
   
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mast_agt = master_apb_agent::type_id::create("mast_agt", this);
	  slv_agt = slave_apb_agent::type_id::create("slv_agt", this);
      sb = apb_scoreboard::type_id::create("sb", this);
      cov = apb_coverage::type_id::create("cov", this);
	  mast_seqr = master_apb_sequencer::type_id::create("mast_seqr", this);
	  slv_seqr =  slave_apb_sequencer::type_id::create("slv_seqr", this);
     
   endfunction // build_phase
   
   function void connect_phase(uvm_phase phase);
      mast_agt.agt_ap.connect(sb.mast_sb_export);
      mast_agt.agt_ap.connect(cov.mast_cov_export);
      slv_agt.agt_ap.connect(sb.slv_sb_export);
      slv_agt.agt_ap.connect(cov.slv_cov_export);
   endfunction
endclass
endpackage
