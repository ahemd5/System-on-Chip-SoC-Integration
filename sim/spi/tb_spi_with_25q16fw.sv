`timescale 1ns/1ps
 module tb_spi;
parameter MEM_DEPTH = 131072; // Number of lines (16M-bit = 2M bytes, 16 bytes per line)
    parameter LINE_WIDTH = 32;   // Line width in bits (16 bytes = 128 bits)

   
    reg [LINE_WIDTH-1:0] memory [0:MEM_DEPTH-1];
reg [7:0] cmd_check_memory[0:11];
parameter spiperiod= 20;
parameter ahbperiod=10;
// Declare testbench signals
reg i_clk_spi_flash;
reg i_rstn_spi_flash;
reg ahbclk;
reg ahbrst;
reg i_ready;
reg chek;

reg [31:0] i_address;
reg i_rd0_wr1;
reg [31:0] i_wr_data;
reg I_valid;



wire o_spi_flash_irq;


wire [31:0] o_addr;
wire [31:0] o_wr_data;
wire o_rd0_wr1;
wire o_valid;
wire  [31:0] o_rd_data;
wire o_rd_valid;
wire o_ready;

///
reg [3:0] cmd_number;
reg [23:0] write_data_number ;
reg [23:0] read_data_number;
reg [31:0] start_address_of_dma ;
reg [31:0]  cmd1_data;
reg [31:0]  cmd2_data;
reg [31:0]  cmd3_data;
reg [25:0] mode_of_muxing;
reg [23:0] start_address_of_flash;



    
    
    
     

// Instantiate the Top_Module
Top_Module uut (
    .i_clk_spi_flash(i_clk_spi_flash),
    .i_rstn_spi_flash(i_rstn_spi_flash),
    .ahbclk(ahbclk),
    .ahbrst(ahbrst),
    
 
    .o_spi_flash_irq(o_spi_flash_irq),
   
   
    //master
    .i_ready(i_ready),
    .o_addr(o_addr),
    .o_wr_data(o_wr_data),
    .o_rd0_wr1(o_rd0_wr1),
    .o_valid(o_valid),
    // slave
    .i_address(i_address),
    .i_rd0_wr1(i_rd0_wr1),
    .i_wr_data(i_wr_data),
    .I_valid(I_valid),
    .o_rd_data(o_rd_data),
    .o_rd_valid(o_rd_valid),
    .o_ready(o_ready)
);

// Clock generation

initial 
begin
forever  #(spiperiod/2)  i_clk_spi_flash = ~i_clk_spi_flash;
end
 initial 
begin
forever     #(ahbperiod/2)  ahbclk = ~ahbclk;  
end 
  

// Initial block to drive signals and simulate a test
initial begin
  integer p;
  chek=1;
$readmemh("MEMnospaces.txt", memory);


 
        

  // defult values and reseting 
        i_clk_spi_flash = 0;
        
        ahbclk = 0;
        i_rstn_spi_flash = 0;
        ahbrst = 0;
        i_ready = 0;
    
        i_address = 32'b0;
        i_rd0_wr1 = 0;
        i_wr_data = 32'b0;
        I_valid = 0;
        #20 i_rstn_spi_flash = 1; 
        ahbrst = 1;
        i_ready = 1;
        
 // enable reset 

cmd_number = 1;
write_data_number = 0;
read_data_number = 0;
start_address_of_dma = 'h40;
cmd1_data = 'h66;
cmd2_data = 0;
cmd3_data = 0;
mode_of_muxing = {2'b00, 24'b010100};
start_address_of_flash = 'h8;

start_transaction(cmd_number, write_data_number, read_data_number, start_address_of_dma, cmd1_data, cmd2_data, cmd3_data, mode_of_muxing);
wait_interrupt;
#40
//reset 
cmd_number = 1; 
write_data_number = 0;
read_data_number = 0;
start_address_of_dma = 'h4040;
cmd1_data = 'h99;
cmd2_data = 0;
cmd3_data = 0;
mode_of_muxing = {2'b00, 24'b010100};
start_address_of_flash = 'h8;

start_transaction(cmd_number, write_data_number, read_data_number, start_address_of_dma, cmd1_data, cmd2_data, cmd3_data, mode_of_muxing);
wait_interrupt;

$display("reset is succeeded ");
#30000 // time we dont have to make any transactions after reset in side that time  30us to reset 
// TEST CASE 1 
cmd_number = 4;
write_data_number = 0;
read_data_number = 4;
start_address_of_dma = 'h40;
cmd1_data = 'h08000003;
cmd2_data = 0;
cmd3_data = 0;
mode_of_muxing = {2'b00 , 24'b000000};
start_address_of_flash = 'h08;

$display(" test case 1  READ DATA INSTRUCTION 03h (reading 4 bytes ) in standard mode ");



start_transaction(cmd_number, write_data_number, read_data_number, start_address_of_dma, cmd1_data, cmd2_data, cmd3_data, mode_of_muxing);

fork
    
    check(start_address_of_flash, read_data_number, start_address_of_dma);
    wait_interrupt;
join
 
#40
// TEST CASE 2 
cmd_number = 5;
write_data_number = 0;
read_data_number = 32;
start_address_of_dma = 'h60;
cmd1_data = 'hE803000B;
cmd2_data = 0;
cmd3_data = 0;
mode_of_muxing = {2'b00 , 24'b000000};
start_address_of_flash = 'h0003E8;

$display(" test case 2  standard FAST READ  INSTRUCTION 0Bh (reading 32 bytes )     ");



start_transaction(cmd_number, write_data_number, read_data_number, start_address_of_dma, cmd1_data, cmd2_data, cmd3_data, mode_of_muxing);

fork
    
    check(start_address_of_flash, read_data_number, start_address_of_dma);
    wait_interrupt;
join
#40
// TEST CASE 3 
cmd_number = 5;
write_data_number = 0;
read_data_number = 64;
start_address_of_dma = 'h60;
cmd1_data = 'h3C00003B;
cmd2_data = 0;
cmd3_data = 0;
mode_of_muxing = {2'b01 , 24'b000000};
start_address_of_flash = 'h000003C;

$display(" test case 3 FAST READ  dualoutput INSTRUCTION 3Bh (reading 64 bytes )     ");



start_transaction(cmd_number, write_data_number, read_data_number, start_address_of_dma, cmd1_data, cmd2_data, cmd3_data, mode_of_muxing);

fork
    
    check(start_address_of_flash, read_data_number, start_address_of_dma);
    wait_interrupt;
join

 



#40
// TEST CASE 4 
cmd_number = 5;
write_data_number = 0;
read_data_number = 128;
start_address_of_dma = 'h60;
cmd1_data = 'h240000BB;
cmd2_data = 0;
cmd3_data = 0;
mode_of_muxing = {2'b01 , 24'b0101010100};
start_address_of_flash = 'h0000024;

$display(" test case 4 FAST READ  dual I/O INSTRUCTION BBh (reading 128 bytes )     ");



start_transaction(cmd_number, write_data_number, read_data_number, start_address_of_dma, cmd1_data, cmd2_data, cmd3_data, mode_of_muxing);

fork
    
    check(start_address_of_flash, read_data_number, start_address_of_dma);
    wait_interrupt;
join

#40






 if (chek)

   

$display(" all tests succeeded     ");

   

else 

   

   

$display(" not all tests succeeded     ");

   

  

 


    $stop;
end
//
  
    //
    
   
//

task check (input [31:0] flash_start_address, input [23:0] num_bytes, input [31:0] dma_start_address );

 reg    [31:0]   expected_out_data; 
 
 reg  [31:0] addressflash;
 reg [31:0] addressdma;
 
 integer   k ;
 

 begin
   addressdma=dma_start_address ;
  addressflash= flash_start_address;

	for(k=0; k<(num_bytes/4); k=k+1)
	begin
	  
	     
            expected_out_data = memory[addressflash[23:2]];  
   
       
	  // this for generating i ready to be equal zero for number of cycles then asserted too one 
	i_ready =0;
	@(posedge o_valid)
	repeat ($urandom_range(1,10)) begin @(negedge ahbclk); end 
		i_ready =1;
	
		
	//

    
if(o_wr_data == expected_out_data) 
		begin
			$display("data transfer word %d is succeeded because expected word is  %h  output wrdata is %h ",k,expected_out_data,o_wr_data);
		end
	else
		begin
			$display("data transfer word %d is failed because expected word is  %h     output wrdata is %h ",k,expected_out_data,o_wr_data);
			chek=0;
		end 
		  
		  if(o_addr==  addressdma) 
		begin
			$display("address transfer word %d is succeeded because expected dma address  is %h  outputaddress is %h ",k ,addressdma,o_addr);
		end
	else
		begin
			$display("address transfer word %d is failed because expected dma address  is %h  outputaddress is %h ",k ,addressdma,o_addr);
			chek=0;
			
		end 
		  @(negedge ahbclk);

	addressflash=addressflash +4;
	addressdma=addressdma+4;

 end //for loop
 end
endtask


//  



task wait_interrupt ;
  begin 
    wait (o_spi_flash_irq==1);
   @(negedge ahbclk);
    i_address= 'h24;  
    i_rd0_wr1='b1;
    i_wr_data=32'b0;
    I_valid='b1; // oready from memory is always one so no constraint or wait for it ; 
     @(negedge ahbclk);
      I_valid='b0;
     
  end 
endtask 
task start_transaction (input [3:0] command_count , input [23:0] write_data_count, input [23:0] read_data_count,input [31:0] dma_start_address,
input [31:0]  cmd_buffer1 , input [31:0]  cmd_buffer2 ,input [31:0] cmd_buffer3 , input [25:0] mux_mode);
integer s;
integer i;

 integer n;

reg [31:0] address;
   begin
     //	$display("transaction of reading %d bytes from flash  \n using address_and_command_instruction  %h%h%h \n as command number is %d \n muxmode is %b  \n dma start address is %h",read_data_count,cmd_buffer3,cmd_buffer2,cmd_buffer1,command_count,mux_mode,dma_start_address);
     address=0;
   @(negedge ahbclk); 
     i_address= 'h0;
     i_rd0_wr1='b1;
     I_valid='b1;
     i_wr_data=command_count;
      @(negedge ahbclk); 
     i_address= i_address+ 4;
     i_wr_data=write_data_count;
      @(negedge ahbclk); 
     i_address= i_address+ 4;
     i_wr_data=read_data_count;
       @(negedge ahbclk); 
     i_address= i_address+ 4;
     i_wr_data=dma_start_address;
        @(negedge ahbclk); 
     i_address= i_address+ 4;
     i_wr_data=cmd_buffer1;
        @(negedge ahbclk); 
     i_address= i_address+ 4;
     i_wr_data=cmd_buffer2;
          @(negedge ahbclk); 
     i_address= i_address+ 4;
     i_wr_data=cmd_buffer3;
          @(negedge ahbclk); 
     i_address= i_address+ 4;
     i_wr_data=mux_mode;
          @(negedge ahbclk); 
     i_address= i_address+ 4;
     i_wr_data=0;
          @(negedge ahbclk);
          @(negedge ahbclk); 
          @(negedge ahbclk); 
          @(negedge ahbclk);  
     i_wr_data=1 ; // i make start transaction equal zero then rise again to one to make spi controller detect that posedge 
     @(negedge ahbclk); 
      I_valid='b0;
     
  ///////
  
@(negedge uut.o_spi_flash_csn);
 @(negedge i_clk_spi_flash);

  for (n = 0; n < 4096; n = n + 1) begin
   cmd_check_memory[n] =0;  
end

             for (s = 0; s < command_count; s = s + 1) begin
               case (mux_mode[1:0])
                 2'b00: begin
                      for (i = 7; i >= 0; i = i - 1) begin 
                          @(negedge  i_clk_spi_flash );
                        
                       cmd_check_memory[address][i]=uut.o_spi_flash_so0;
 
                     end 
                   
                 
                 end 
                  2'b01: begin 
                     for (i = 7; i >= 0; i = i - 2) begin
                    @(negedge  i_clk_spi_flash );
                    cmd_check_memory [address][i]=uut.o_spi_flash_so1;
                    cmd_check_memory [address][i-1]=uut.o_spi_flash_so0;
        
                     end 
                    
                 end 
                  2'b10: begin
                          for (i = 7; i >= 0; i = i - 4) begin
              @(negedge  i_clk_spi_flash );
               cmd_check_memory [address][i]=uut.o_spi_flash_so3;
               cmd_check_memory[address][i-1]=uut.o_spi_flash_so2;
              cmd_check_memory[address][i-2]=uut.o_spi_flash_so1;
               cmd_check_memory [address][i-3]=uut.o_spi_flash_so0;
        
                  end
                
                 end 
                 
               endcase //endcase one byte
            mux_mode = mux_mode >> 2; 
               address=address+ 32'b1; 
            
        end //end for loop
                 if({cmd_buffer3,cmd_buffer2,cmd_buffer1}=={  cmd_check_memory[11] , cmd_check_memory [10] ,  cmd_check_memory [9] ,  cmd_check_memory [8],cmd_check_memory[7] , cmd_check_memory [6] ,  cmd_check_memory [5] ,  cmd_check_memory [4],cmd_check_memory[3] , cmd_check_memory [2] ,  cmd_check_memory [1] ,  cmd_check_memory [0]}
  )  
		begin
			$display("cmd transfer %h%h%h is succeeded",cmd_buffer3,cmd_buffer2,cmd_buffer1);
		end
	else
		begin
			$display("cmd transfer %h%h%h  is failed",cmd_buffer3,cmd_buffer2,cmd_buffer1);
			chek=0;
		end 
     ///
 end
 endtask

 


endmodule
