   module interface_with_flash (
   
    input logic        o_spi_flash_so0,    // Output line 0
     input logic        o_spi_flash_so1,    // Output line 1
     input logic       o_spi_flash_so2,    // Output line 2   
    input logic        o_spi_flash_so3,    // Output line 3
	input logic o_spi_flash_clk_en,
	input logic i_clk_spi_flash,
	output reg spiclock,
	input logic o_spi_flash_csn,
	


   input logic  o_spi_flash_si_io0_oen,o_spi_flash_si_io1_oen,o_spi_flash_si_io2_oen,o_spi_flash_si_io3_oen, //output enable 
      output logic   i_spi_flash_si0, i_spi_flash_si1, i_spi_flash_si2 ,  i_spi_flash_si3,     
    
     inout wire DIO,
     inout wire DO,
      inout wire WPn,
       inout wire  HOLDn);
       reg enable ;
      
 always @ (negedge i_clk_spi_flash )   
 begin 
   enable =o_spi_flash_clk_en;
 end
     
     
     assign DIO = (!o_spi_flash_si_io0_oen)?  o_spi_flash_so0: 1'bz;
    assign DO = (!o_spi_flash_si_io1_oen)?  o_spi_flash_so1: 1'bz;
    assign WPn = (!o_spi_flash_si_io2_oen)?  o_spi_flash_so2: 1'bz;
    assign HOLDn = (!o_spi_flash_si_io3_oen)?  o_spi_flash_so3: 1'bz;
    assign  i_spi_flash_si0 =(o_spi_flash_si_io0_oen)? DIO: 1'bz;
   assign  i_spi_flash_si1=(o_spi_flash_si_io0_oen)? DO: 1'bz;
    assign  i_spi_flash_si2 =(o_spi_flash_si_io0_oen)?  WPn: 1'bz;
     assign  i_spi_flash_si3 = (o_spi_flash_si_io0_oen)? HOLDn : 1'bz;
	 assign spiclock=(enable )?    i_clk_spi_flash  :0;
	 
	 
     
	 
     
   endmodule
    
    
   
  
