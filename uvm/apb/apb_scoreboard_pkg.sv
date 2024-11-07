
package apb_scoreboard_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"
import master_apb_seq_item_pkg::*;
import slave_apb_seq_item_pkg::*;
import apb_config_pkg::*;

class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)
  
  uvm_analysis_export #(master_apb_seq_item) mast_sb_export;
  uvm_tlm_analysis_fifo #(master_apb_seq_item) mast_sb_fifo;
  master_apb_seq_item mast_seq_item_sb;
  
  uvm_analysis_export #(slave_apb_seq_item) slv_sb_export;
  uvm_tlm_analysis_fifo #(slave_apb_seq_item) slv_sb_fifo;
  slave_apb_seq_item slv_seq_item_sb;
/////////////////////////////////////////////////////////////////////////////////////////////////////////////  
//////////slave/////////////
bit [31:0] o_wr_data_ref;
bit [31:0] o_addr_ref;
bit o_valid_ref, o_rd0_wr1_ref;

////////// left side /////////////
bit [31:0] o_prdata_ref;
bit o_pslverr_ref, o_pready_ref;


////////// master /////////////
bit [31:0] o_rd_data_ref;
bit o_rd_valid_ref, o_ready_ref;

////////// right side /////////////
bit [31:0] o_pwdata_ref;
bit [31:0] o_paddr_ref;
bit o_psel_ref, o_penable_ref, o_pwrite_ref;
bit [31:0] save;
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////
  int master_error_count = 0;
  int master_correct_count = 0;
  int slave_error_count = 0;
  int slave_correct_count = 0;

  function new(string name = "apb_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mast_sb_export = new("mast_sb_export", this);
    mast_sb_fifo  = new("mast_sb_fifo", this);
    slv_sb_export = new("slv_sb_export", this);
    slv_sb_fifo  = new("slv_sb_fifo", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mast_sb_export.connect(mast_sb_fifo.analysis_export);
	slv_sb_export.connect(slv_sb_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      mast_sb_fifo.get(mast_seq_item_sb);
      slv_sb_fifo.get(slv_seq_item_sb);
      master_ref_model(mast_seq_item_sb);
      slave_ref_model(slv_seq_item_sb);

	  ///////////////////////////////////////////////////////////////////////////////////////////
      if (mast_seq_item_sb.o_rd_data != o_rd_data_ref &&
          mast_seq_item_sb.o_rd_valid != o_rd_valid_ref &&
          mast_seq_item_sb.o_ready != o_ready_ref &&
          mast_seq_item_sb.o_pwdata != o_pwdata_ref &&
          mast_seq_item_sb.o_paddr != o_paddr_ref &&
          mast_seq_item_sb.o_psel != o_psel_ref &&
          mast_seq_item_sb.o_pwrite != o_pwrite_ref &&
          mast_seq_item_sb.o_penable != o_penable_ref) begin
        `uvm_info("run_phase", $sformatf("Comparison failed : %s", mast_seq_item_sb.convert2string()), UVM_HIGH);
	//	`uvm_info("run_phase", $sformatf("Error: Mismatch REFF = ,o_rd_data_ref=%d,full=%d,empty=%d,overflow=%d,underflow=%d,almostfull=%d,almostempty=%d",data_out_ref,full_ref,empty_ref,overflow_ref,underflow_ref,almostfull_ref,almostempty_ref), UVM_HIGH);;
        master_error_count++;
      end else begin
        `uvm_info("run_phase", $sformatf("Correct out : %s", mast_seq_item_sb.convert2string()), UVM_HIGH);
        master_correct_count++;
      end
	   ///////////////////////////////////////////////////////////////////////////////////////////
      if (slv_seq_item_sb.o_wr_data != o_wr_data_ref &&
          slv_seq_item_sb.o_addr != o_addr_ref &&
          slv_seq_item_sb.o_rd0_wr1 != o_rd0_wr1_ref &&
          slv_seq_item_sb.o_valid != o_valid_ref &&
          slv_seq_item_sb.o_prdata != o_prdata_ref &&
          slv_seq_item_sb.o_pslverr != o_pslverr_ref &&
          slv_seq_item_sb.o_pready != o_pready_ref) begin
        `uvm_info("run_phase", $sformatf("Comparison failed : %s", slv_seq_item_sb.convert2string()), UVM_HIGH);
		//`uvm_info("run_phase", $sformatf("Error: Mismatch REFF = ,data_out=%d,full=%d,empty=%d,overflow=%d,underflow=%d,almostfull=%d,almostempty=%d",data_out_ref,full_ref,empty_ref,overflow_ref,underflow_ref,almostfull_ref,almostempty_ref), UVM_HIGH);;
        slave_error_count++;
      end else begin
        `uvm_info("run_phase", $sformatf("Correct out : %s", slv_seq_item_sb.convert2string()), UVM_HIGH);
        slave_correct_count++;
      end
    end
    
  endtask

  task master_ref_model(master_apb_seq_item mast_seq_item_chk);
  
    // Reset behavior for master
    if (!mast_seq_item_chk.i_rstn_apb) begin
        o_rd_data_ref = 0;
        o_rd_valid_ref = 0;
        o_ready_ref = 0;
        o_pwdata_ref = 0;
        o_paddr_ref = 0;
        o_psel_ref = 0;
        o_penable_ref = 0;
        o_pwrite_ref = 0;
    end else begin
        // Write transaction: i_rd0_wr1 = 1
        if (mast_seq_item_chk.i_valid && mast_seq_item_chk.i_rd0_wr1) begin
                      save=mast_seq_item_chk.i_wr_data;
            if (mast_seq_item_chk.o_ready) begin
                o_pwdata_ref = save;
                o_paddr_ref = mast_seq_item_chk.i_addr;
                o_pwrite_ref = mast_seq_item_chk.i_rd0_wr1;
                o_psel_ref = 1;
                o_penable_ref = 1;
            end else begin
                o_pwdata_ref = save;
            end
        end
        // Read transaction: i_rd0_wr1 = 0
        else if (mast_seq_item_chk.i_valid && !mast_seq_item_chk.i_rd0_wr1) begin
            if (mast_seq_item_chk.o_ready) begin
                o_paddr_ref = mast_seq_item_chk.i_addr;
                o_pwrite_ref = mast_seq_item_chk.i_rd0_wr1;
                o_psel_ref = 1;
                o_penable_ref = 1;
            end
        end
    end
endtask


  task slave_ref_model(slave_apb_seq_item slv_seq_item_chk);
    
    // Reset behavior for slave
    if (!slv_seq_item_chk.i_rstn_apb) begin
        o_wr_data_ref = 0;
        o_addr_ref = 0;
        o_valid_ref = 0;
        o_rd0_wr1_ref = 0;
        o_pslverr_ref = 0;
        o_prdata_ref = 0;
        o_pready_ref = 0;
    end else begin
        // Write transaction: o_rd0_wr1 = 1
        if (slv_seq_item_chk.o_rd0_wr1 && slv_seq_item_chk.o_valid && slv_seq_item_chk.i_ready) begin
            o_wr_data_ref = slv_seq_item_chk.o_wr_data;
            o_addr_ref = slv_seq_item_chk.o_addr;
            o_valid_ref = slv_seq_item_chk.o_valid;
            o_rd0_wr1_ref = slv_seq_item_chk.o_rd0_wr1;
            o_pready_ref = 1;
        end
        // Read transaction: o_rd0_wr1 = 0
        else if (!slv_seq_item_chk.o_rd0_wr1 && slv_seq_item_chk.o_valid && slv_seq_item_chk.i_ready) begin
            o_addr_ref = slv_seq_item_chk.o_addr;
            o_rd0_wr1_ref = slv_seq_item_chk.o_rd0_wr1;
            o_pready_ref = 1;
            o_prdata_ref = slv_seq_item_chk.i_rd_data;
        end
    end
endtask


  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("report_phase", $sformatf("Total successful master transactions: %0d, Total failed transactions: %0d", master_correct_count, master_error_count), UVM_MEDIUM);
	`uvm_info("report_phase", $sformatf("Total successful slave transactions: %0d, Total failed transactions: %0d", slave_correct_count, slave_error_count), UVM_MEDIUM);
  endfunction
endclass
endpackage
