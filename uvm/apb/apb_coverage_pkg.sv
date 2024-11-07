package apb_coverage_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_config_pkg::*;
import master_apb_seq_item_pkg::*;
import slave_apb_seq_item_pkg::*;

class apb_coverage extends uvm_component;
  `uvm_component_utils(apb_coverage)
  uvm_analysis_export #(master_apb_seq_item) mast_cov_export;
  uvm_tlm_analysis_fifo #(master_apb_seq_item) mast_cov_fifo;
  master_apb_seq_item mast_seq_item_cov;
  
  uvm_analysis_export #(slave_apb_seq_item) slv_cov_export;
  uvm_tlm_analysis_fifo #(slave_apb_seq_item) slv_cov_fifo;
  slave_apb_seq_item slv_seq_item_cov;


    covergroup cov ;
        mast_in_valid: coverpoint mast_seq_item_cov.i_valid {
			bins mast_in_valid_1 = {1};
        }
        mast_in_rd0_wr1: coverpoint mast_seq_item_cov.i_rd0_wr1 {
                        bins mast_in_rd0_wr1_1 = {0};
						bins mast_in_rd0_wr1_2 = {1};
        }
		mast_out_rd_valid: coverpoint mast_seq_item_cov.o_rd_valid {
                        bins mast_out_rd_valid_1 = {1};
        }
		mast_out_ready: coverpoint mast_seq_item_cov.o_ready {
                        bins mast_out_ready_1 = {1};
        }
		/////////////////////////////////////////////////////////////////////////
		mast_out_psel: coverpoint mast_seq_item_cov.o_psel {
                        bins mast_out_psel_1 = {1};
        }
		mast_out_penable: coverpoint mast_seq_item_cov.o_penable {
                        bins mast_out_penable_1 = {1};
        }
		mast_out_pwrite: coverpoint mast_seq_item_cov.o_pwrite {
			bins mast_out_pwrite_1 = {0};
			bins mast_out_pwrite_2 = {1};
        }
		
		mast_in_pready: coverpoint mast_seq_item_cov.i_pready {
			bins mast_in_pready_1 = {1};
        }
		mast_in_pslverr: coverpoint mast_seq_item_cov.i_pslverr {
                        bins mast_in_pslverr_1 = {0};
        }
	//////////////////////////////////////////////////////////////////////////////////////////////	
    mast_l_0: cross mast_in_rd0_wr1, mast_in_valid;
    mast_l_1: cross mast_out_ready, mast_out_rd_valid ;
	
	mast_r_0: cross mast_out_psel, mast_out_penable;
	mast_r_1: cross mast_out_psel, mast_out_pwrite ;
	mast_r_2: cross mast_out_penable, mast_out_pwrite ;
	mast_r_3: cross mast_out_pwrite, mast_in_pready ;
	mast_r_4: cross mast_in_pready, mast_in_pslverr ;
    /////////////////////////////////////////////////////////////////////////////////////////////
        slv_out_valid: coverpoint slv_seq_item_cov.o_valid {
			bins mast_out_valid_1 = {1};
        }
        slv_out_rd0_wr1: coverpoint slv_seq_item_cov.o_rd0_wr1 {
                        bins slv_out_rd0_wr1_1 = {0};
						bins slv_out_rd0_wr1_2 = {1};
        }
		slv_in_rd_valid: coverpoint slv_seq_item_cov.i_rd_valid {
                        bins slv_in_rd_valid_1 = {1};
        }
		slv_in_ready: coverpoint slv_seq_item_cov.i_ready {
                        bins slv_in_ready_1 = {1};
        }
		/////////////////////////////////////////////////////////////////////////
		slv_in_psel: coverpoint slv_seq_item_cov.i_psel {
                        bins slv_in_psel_1 = {1};
        }
		slv_in_penable: coverpoint slv_seq_item_cov.i_penable {
                        bins slv_in_penable_1 = {1};
        }
		slv_in_pwrite: coverpoint slv_seq_item_cov.i_pwrite {
			bins slv_in_pwrite_1 = {0};
			bins slv_in_pwrite_2 = {1};
        }
		
		slv_out_pready: coverpoint slv_seq_item_cov.o_pready {
			bins slv_out_pready_1 = {1};
        }
		slv_out_pslverr: coverpoint slv_seq_item_cov.o_pslverr {
                        bins slv_out_pslverr_1 = {0};
        }
		//////////////////////////////////////////////////////////////////////////////////////////////	
        slv_l_0: cross slv_out_rd0_wr1,slv_out_valid;
        slv_l_1: cross slv_in_ready, slv_in_rd_valid ;
		
		slv_r_0: cross slv_in_psel, slv_in_penable;
     	slv_r_1: cross slv_in_psel, slv_in_pwrite ;
	    slv_r_2: cross slv_in_penable, slv_in_pwrite ;
	    slv_r_3: cross slv_in_pwrite, slv_out_pready ;
     	slv_r_4: cross slv_out_pready, slv_out_pslverr ;
    endgroup

  function new(string name = "apb_coverage", uvm_component parent = null);
    super.new(name, parent);
    cov = new(); // Ensure cov is instantiated here
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mast_cov_export = new("mast_cov_export", this);
    mast_cov_fifo   = new("mast_cov_fifo", this);
    slv_cov_export = new("slv_cov_export", this);
    slv_cov_fifo   = new("slv_cov_fifo", this);
  endfunction
	
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mast_cov_export.connect(mast_cov_fifo.analysis_export);
    slv_cov_export.connect(slv_cov_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      mast_cov_fifo.get(mast_seq_item_cov);
      slv_cov_fifo.get(slv_seq_item_cov);
      cov.sample();
    end
  endtask

endclass
endpackage

