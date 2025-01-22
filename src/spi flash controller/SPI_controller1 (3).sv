module SPI_FSM (
    input wire i_clk_spi_flash,       // SPI clock domain
    input logic  i_rstn_spi_flash,      // Reset (active low)
    // SPI Interface
    output reg         o_spi_flash_so0,    // Output line 0
    output reg         o_spi_flash_so1,    // Output line 1
    output reg        o_spi_flash_so2,    // Output line 2   
    output reg         o_spi_flash_so3,    // Output line 3
    input  logic         i_spi_flash_si0,    // Input line 0
    input  logic         i_spi_flash_si1,    // Input line 1
    input  logic         i_spi_flash_si2,    // Input line 2
    input  logic         i_spi_flash_si3,     // Input line 3

    output reg o_spi_flash_si_io0_oen,o_spi_flash_si_io1_oen,o_spi_flash_si_io2_oen,o_spi_flash_si_io3_oen, //output enable 
    output reg o_spi_flash_csn,       // Chip select
    output reg   o_spi_flash_clk_en,
  
    
   
              
    //AHB 
    input logic ahbclk,
    input logic ahbrst,
    input logic i_ready,
    input logic [31:0] reg_0C,// dma address
    output reg [31:0] o_addr,
    output reg [31:0] o_wr_data,
    output reg o_rd0_wr1,
    output reg o_valid, 
    // irdvalid and ird data will not beused 
    // Register File Interface (through memory model)
    output reg o_spi_flash_irq,
     output logic  reg_24,         // Flash transaction done IRQ (status register)
    input logic [3:0]  reg_00,          //command count
    input logic [23:0] reg_04,         // Data count register (number of bytes to written   )
    input logic [23:0] reg_08,         // Data count register (number of bytes to read)
    input logic [25:0] reg_1C,         // Mux mode register
    input logic[31:0] reg_10,         // Command buffer (first part)
    input logic [31:0] reg_14,         // Command buffer (second part)
    input logic [31:0] reg_18,        // Command buffer (third part)
    input logic  reg_20 ,              // transaction start bit 
    
    // fifo
   input  logic empty ,
   input  logic [31:0] rdata,
   output reg renable,
  output reg fifo_write_enable,    
    input logic fifo_full,     
   output reg [31:0] wdata

        
);

   
    


// Internal Signals and Counters
    reg [7:0] cmd_counter;           // Command buffer counter
    reg [23:0] read_count;
    reg [1:0] mux_mode;              // Muxing mode for current byte
    reg [7:0] current_byte;          // Current byte to send
    reg [31:0] rx_data_reg;
    reg [3:0] bit_counter,bit_counter2;;           // Bit counter for SPI transmission (to select each bit)  

// Address counter for ahb interfacing
    reg [31:0] address;
    reg [23:0] bytecounter ;
    wire fflag;

    // FSM State Encoding
    typedef enum logic [2:0] {
        IDLE,
        READ_CONFIG,
        SEND_CMD,
        RECEIVE_DATA,
        AHB_TRANSFER,
        COMPLETE
    } state_t;

    state_t current_state, next_state;
      // State Encoding
    typedef enum logic [1:0] {
        IDLE_AHB,
        READ_FIFO,
        checkempty,
        WAIT_FIFO
      
    } state_tt;
    
    state_tt ahb_state, ahb_nextstate;
    assign  o_spi_flash_irq= reg_24;
    assign o_spi_flash_clk_en= (current_state==SEND_CMD || current_state== RECEIVE_DATA)?  1 : 0;
    assign   fifo_write_enable =(!fifo_full && ( read_count % 4==0) && read_count != 0 &&(bit_counter2==0) )? 1:0;
    assign   wdata=(!fifo_full &&( read_count % 4==0) && read_count != 0 &&(bit_counter2==0) )? rx_data_reg: 32'bz;
    assign fflag = ( reg_08==4 )? ((ahb_state==checkempty ) ? 1 : 0):1;
    
    assign   reg_24 =(fflag  && empty && ((bytecounter+4)==reg_08)) ? 1:0;   
    
    
    module RisingEdgeDetector (
    input wire i_clk_spi_flash, // Clock signal
    input wire reg_20,          // Input signal to monitor
    output reg edge_detect      // Output: High for one clock cycle on rising edge
);

    // Internal register to hold the previous state of the signal
    reg previous_state;

    // Always block triggered on the clock's positive edge
    always @(posedge i_clk_spi_flash) begin
        // Detect rising edge
        if (previous_state == 0 && reg_20 == 1) begin
            edge_detect <= 1; // Rising edge detected
        end else begin
            edge_detect <= 0; // No rising edge
        end

        // Update the previous state
        previous_state <= reg_20;
    end
endmodule

 RisingEdgeDetector dut (
        .i_clk_spi_flash(i_clk_spi_flash),
        .reg_20(reg_20),
        .edge_detect(edge_detect)
    );
    

    // State Transition Logic
    always @(posedge i_clk_spi_flash or negedge i_rstn_spi_flash) begin
        if (!i_rstn_spi_flash)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // FSM Next State Logic
    always @(*) begin
        next_state = current_state;
       
        o_spi_flash_so3 = 1'bz;
        o_spi_flash_so2 = 1'bz;
        o_spi_flash_so1 = 1'bz;
        o_spi_flash_so0 = 1'bz;
        o_spi_flash_si_io0_oen = 1;
        o_spi_flash_si_io1_oen = 1; 
        o_spi_flash_si_io2_oen = 1; 
        o_spi_flash_si_io3_oen = 1; 
        o_spi_flash_csn= 1;
       current_byte='b0; 
       mux_mode = 2'b00;

        
     
       
    
         
        
        case (current_state)
            IDLE: begin
                  
               
                if ( edge_detect ) // Transaction start 
                  begin
                    next_state =  SEND_CMD;
                    o_spi_flash_csn=0;
              
                  end
            end
            
            SEND_CMD: begin
              o_spi_flash_csn=0;
           
                 case (cmd_counter)
            0: mux_mode = reg_1C[1:0];
            1: mux_mode = reg_1C[3:2];
            2: mux_mode = reg_1C[5:4];
            3: mux_mode = reg_1C[7:6];
            4: mux_mode = reg_1C[9:8];
            5: mux_mode = reg_1C[11:10];
            6: mux_mode = reg_1C[13:12];
            7: mux_mode = reg_1C[15:14];
            8: mux_mode = reg_1C[17:16];
            9: mux_mode = reg_1C[19:18];
            10: mux_mode = reg_1C[21:20];
            11: mux_mode = reg_1C[23:22];
            default: mux_mode = 2'b00; // Default or error state
        endcase   
              case (cmd_counter)
                        0: current_byte = reg_10[7:0];
                        1: current_byte = reg_10[15:8];
                        2: current_byte = reg_10[23:16];
                        3: current_byte = reg_10[31:24];
                        4: current_byte = reg_14[7:0];
                        5: current_byte = reg_14[15:8];
                        6: current_byte = reg_14[23:16];
                        7: current_byte = reg_14[31:24];
                        8: current_byte = reg_18[7:0];
                        9: current_byte = reg_18[15:8];
                        10: current_byte = reg_18[23:16];
                        11: current_byte = reg_18[31:24];
                        default: current_byte = 8'b0;
                    endcase
               case (mux_mode)
            2'b00: begin
            if (bit_counter >= 7 && cmd_counter == (reg_00[3:0]-1)) begin
                next_state = RECEIVE_DATA;
            end
            o_spi_flash_so0 = current_byte[7 - bit_counter]; // Send MSB

            // Set output enables (active low)
            o_spi_flash_si_io0_oen = 0; // Enable io0 as output
            o_spi_flash_si_io1_oen = 1; // Disable io1 as input
            o_spi_flash_si_io2_oen = 1; // Not used
            o_spi_flash_si_io3_oen = 1; // Not used
           end

            2'b01: begin
            if (bit_counter >= 6 && cmd_counter == (reg_00[3:0]-1)) begin
                next_state = RECEIVE_DATA;
            end
            o_spi_flash_so1 = current_byte[7 - bit_counter];
            o_spi_flash_so0 = current_byte[6 - bit_counter];
            

            // Set output enables (active low)
            o_spi_flash_si_io0_oen = 0; // Enable io0 as output
            o_spi_flash_si_io1_oen = 0; // Enable io1 as output
            o_spi_flash_si_io2_oen = 1; // Not used
            o_spi_flash_si_io3_oen = 1; // Not used
        end

        2'b10: begin
            if (bit_counter >= 4 && cmd_counter == (reg_00[3:0]-1)) begin
                next_state = RECEIVE_DATA;
            end
            o_spi_flash_so3 = current_byte[7 - bit_counter];
            o_spi_flash_so2 = current_byte[6 - bit_counter];
            o_spi_flash_so1 = current_byte[5 - bit_counter];
            o_spi_flash_so0 = current_byte[4 - bit_counter];
            

            // Set output enables (active low)
            o_spi_flash_si_io0_oen = 0; // Enable io0 as output
            o_spi_flash_si_io1_oen = 0; // Enable io1 as output
            o_spi_flash_si_io2_oen = 0; // Enable io2 as output
            o_spi_flash_si_io3_oen = 0; // Enable io3 as output
        end
    endcase
end

            RECEIVE_DATA: begin
              o_spi_flash_csn=0;
               mux_mode = reg_1C[25:24];
                     if ( (bit_counter2 ==0 && read_count== reg_08) ) begin
                    next_state =  IDLE;
                    o_spi_flash_csn=0;
                end
                
                    
              
             
              
    end
endcase
end

    // FSM Output Logic
    always @(posedge i_clk_spi_flash ) begin
     
            case (current_state)
                  IDLE: begin
                  
                  cmd_counter <= 0;
                  bit_counter <= 0;
                  bit_counter2 <= 0;
             rx_data_reg<='bz;
                  read_count<=0;
                end

        
                SEND_CMD: begin
                  
                     
                    
                    // Assign IOs based on Mux Mode and transmit bit-by-bit
                    case (mux_mode)
                        2'b00: begin // Standard SPI (1-bit per clock cycle)
                           
                             if (bit_counter >= 7) begin
                              bit_counter <= 0;
                               cmd_counter <= cmd_counter + 1;
                        end else begin 
                              bit_counter <= bit_counter + 1;
                            end
                          
                        end
                        2'b01: begin // Dual SPI (2-bits per clock cycle)
                           if (bit_counter >= 6) begin
                              bit_counter <= 0;
                               cmd_counter <= cmd_counter + 1;
                        end else begin
                              bit_counter <= bit_counter + 2;
                            end
                        end
                        2'b10: begin // Quad SPI (4-bits per clock cycle)
                                if (bit_counter >=4) begin
                              bit_counter <= 0;
                              cmd_counter <= cmd_counter + 1; 
                        end else begin
                              bit_counter <= bit_counter + 4;
                            end
                        end
                    endcase
                   
                end

                RECEIVE_DATA: begin
                  
                   case (mux_mode)
                  2'b00: begin    
                  if (next_state!= IDLE) rx_data_reg <= {rx_data_reg[30:0], i_spi_flash_si0};
                 if (bit_counter2 ==7 )  read_count = read_count + 1;
                  
            
                 if (bit_counter2 ==7 )
                  bit_counter2 <= 0;
                else 
                 bit_counter2 <= bit_counter2 + 1;  // Increment bit_counter2
              end
               2'b01: begin
                     if (next_state!= IDLE)  rx_data_reg = {rx_data_reg[29:0], i_spi_flash_si1, i_spi_flash_si0}; // Shift in data from SO0, SO1 
                 if (bit_counter2 ==6 )  read_count = read_count + 1;
                  
            
                 if (bit_counter2 ==6 )
                  bit_counter2 <= 0;
                else 
                 bit_counter2 <= bit_counter2 + 2;  // Increment bit_counter2
              
               end 
                 2'b10: begin    
                  if (next_state!= IDLE)  rx_data_reg = {rx_data_reg[27:0],i_spi_flash_si3, i_spi_flash_si2, i_spi_flash_si1, i_spi_flash_si0};
                 if (bit_counter2 ==4 )  read_count = read_count + 1;
                  
            
                 if (bit_counter2 ==4 )
                  bit_counter2 <= 0;
                else 
                 bit_counter2 <= bit_counter2 + 4;  // Increment bit_counter2
              end
               
          endcase 
        end
     
            
                  
           
                  

          
            endcase
        
    end
    
    
//AHB INTERFACING


  

    integer i;
    
    

   
    // State Transition Logic
    always @(posedge ahbclk or negedge ahbrst) begin
        if (!ahbrst)
            ahb_state <=IDLE_AHB;
        else
            ahb_state <= ahb_nextstate;
    end

    // State Machine
    always @(*) begin
        // Default values
        ahb_nextstate = ahb_state;
        renable =0;
        o_valid =  0;
        o_rd0_wr1 = 1;
        
        
        o_addr = address;
        o_wr_data = rdata;
     address=address;
        bytecounter=bytecounter;

        case (ahb_state)
            IDLE_AHB: begin
            
                 address = reg_0C;
                bytecounter = 0;
                if (!empty  )  begin 
                  
                ahb_nextstate = READ_FIFO;
              end 
            end

            READ_FIFO: begin
              
  
                   
                    o_valid = 1;
                    if (i_ready) begin
                     ahb_nextstate=WAIT_FIFO;
                     renable = 1;
                      end 
                   
            end
            WAIT_FIFO:
            begin 
              ahb_nextstate=checkempty;
            end 
            
           

           checkempty: begin
                   
                 if (!empty ) begin 
                  
                      ahb_nextstate = READ_FIFO;
                       address = address + 4; // Increment by 4 for each transaction
                      bytecounter = bytecounter+4; 
                    
                 end
                  if (empty && ((bytecounter+4)==reg_08) ) begin
                  ahb_nextstate = IDLE_AHB;
                end 
                 
            end
     
        endcase
    end

endmodule

