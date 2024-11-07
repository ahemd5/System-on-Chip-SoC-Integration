
package apb_config_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class apb_config extends uvm_object;
    `uvm_object_utils(apb_config)

    virtual master_arb_if mast_apb_vif;
	virtual slave_arb_if slv_apb_vif;

    function new(string name = "apb_config");
      super.new(name);
    endfunction

  endclass
endpackage



