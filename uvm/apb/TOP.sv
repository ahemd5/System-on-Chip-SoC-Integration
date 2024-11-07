import uvm_pkg::*; 
`include "uvm_macros.svh"
import apb_test_pkg::*; 

module apb_top ();

bit i_clk_apb ;
initial begin
       i_clk_apb = 0;
        forever begin 
            #5 i_clk_apb = ~i_clk_apb;
        end
    end

    master_arb_if mast_inter(i_clk_apb);
	slave_arb_if slv_inter(i_clk_apb);
    
    apb_master dut1(mast_inter);   
    apb_slave dut2(slv_inter); 
// bind apb master SVA
  //bind apb_master assertions_master assertions_inst(mast_inter);

initial begin 
uvm_config_db#(virtual master_arb_if)::set(null,"uvm_test_top","apb_IF",mast_inter);
uvm_config_db#(virtual slave_arb_if)::set(null,"uvm_test_top","apb_IF",slv_inter);
run_test("apb_test");
end
	
endmodule



  