module aon_regfile#(parameter DATA_WIDTH = 32, N=2,M=3) (
    input  logic i_aon_clk,                        // Always-on running clock
    input  logic i_soc_pwr_on_rst,                 // Active-high main reset signal for the SoC

    // Interface with APB slave  
    input logic                   slv_o_valid,     // Slave output valid signal
    input logic [DATA_WIDTH-1:0]  slv_o_wr_data,   // written data into the register file
    input logic [DATA_WIDTH-1:0]  slv_o_addr,      //address of data
    input logic                   slv_o_rd0_wr1,   // read (0) / write (1)
    output logic                  slv_i_ready,     // register is ready for new transaction
    output logic [DATA_WIDTH-1:0] slv_i_rd_data,   // Data read from the register file 
    output logic                  slv_i_rd_valid,  // read data is valid to slave
    //Interface with FSM to read wakeup and sleep requests
    //Control Registers: 
    output logic [N-1:0]   rf_o_sleep_req,           //sleep request
    output logic [M*N-1:0] rf_o_wakeup_enable,       // wakeup src enable  
    output logic           rf_o_pwrgate_enable,      //power gating enable 
    //Read_Only logicisters:
    input  logic[N-1:0]    fsm_o_d_status,           //domain power status 
    //Power Sequencing Timers
    output logic [3:0]  rf_o_pwr_on_seq_delay,         //Delay between control events during the power-on sequence
    output logic [3:0]  rf_o_pwr_off_seq_delay,        //Delay between control events during the power-off sequence
    output logic [7:0]  rf_o_pwr_on_delay,             //Delay before asserting o_dcdc_enable during power-on.
    output logic [7:0]  rf_o_pwr_off_delay,            //Delay before deasserting o_dcdc_enable during power-off.
	input  logic    o_clk_en,              // Active-high signals enabling clocks for all modules within a PD
    input  logic    o_iso,                 // Active-high isolation enable for all domain outputs
    input  logic    o_ret,                 // Active-high retention enable for flip-flops or memory within the PD
                                            // Rising edge: Trigger for save operation, Falling edge: Trigger for restore operation
    input  logic    o_rstn                 // Active-low global reset for each PD

);

     // Register Address Map: 
    localparam SLEEP_REQ_ADDR         = 32'h00,    // Sleep request register address
               WAKEUP_SRC_EN_ADDR     = 32'h04,    // Wakeup source enable register address
               PWR_GATING_EN_ADDR     = 32'h08,    // Power gating enable register address
               PWR_STATUS_ADDR        = 32'h0C,    // Power status register address
               PWR_ON_SEQ_ADDR        = 32'h10,    // Power on sequence delay register address
               PWR_OFF_SEQ_ADDR       = 32'h14,    // Power off sequence delay register address
               PWR_ON_DCDC_ADDR       = 32'h18,    //pwr_on_delay  register address
               PWR_OFF_DCDC_ADDR      = 32'h1C;    //pwr_off_delay  register address
              

   wire vld_addr;
   assign vld_addr = ((slv_o_addr >= 32'h00) && (slv_o_addr <= 32'h1C))  ? 1'b1 : 1'b0;

   logic [N-1:0] sleep_req,power_gating,status;
   logic [M*N-1:0] wakeup_enable;
   logic [3:0] on_seq_delay,off_seq_delay;
   logic [7:0] on_delay,off_delay;

   assign rf_o_sleep_req=sleep_req;
   assign rf_o_wakeup_enable=wakeup_enable;
   assign rf_o_pwrgate_enable=power_gating;
   assign rf_o_pwr_on_seq_delay=on_seq_delay;
   assign rf_o_pwr_off_seq_delay=off_seq_delay;
   assign rf_o_pwr_on_delay =on_delay;
   assign rf_o_pwr_off_delay =off_delay; 
   assign slv_i_ready =1'b1;
    

always_ff @( posedge i_aon_clk or posedge i_soc_pwr_on_rst ) begin
    if(i_soc_pwr_on_rst) begin
        sleep_req     <= 'b0; 
        wakeup_enable <= 'b0;
        power_gating  <= 'b0;
        status        <= 'b0;
        on_seq_delay  <= 'b0;
        off_seq_delay <= 'b0;
        on_delay      <= 'b0;
        off_delay     <= 'b0;    
    end else if (vld_addr && slv_o_valid && slv_o_rd0_wr1) begin
        case (slv_o_addr)
        32'h00: sleep_req     <= slv_o_wr_data;   //Writing to Sleep request Register
        32'h04: wakeup_enable <= slv_o_wr_data;   // Writing to Wakeup Source Enable Register
        32'h08: power_gating  <= slv_o_wr_data;   // Writing to Power Gating Enable Register
        32'h0C: status        <= fsm_o_d_status;  //Writing to Power status Register
        32'h10: on_seq_delay  <= slv_o_wr_data;// Writing to Power on seq delay Register
        32'h14: off_seq_delay <= slv_o_wr_data;// Writing to Power off seq delay Register
        32'h18: on_delay      <= slv_o_wr_data;    // Writing to Power on delay Register
        32'h1C: off_delay     <= slv_o_wr_data;   // Writing to Power off delay Register
        default: ;  // NTH
        endcase
    end
	else if (~fsm_o_d_status[0] || (~power_gating && ~o_clk_en && ~o_iso && ~o_ret && ~o_rstn))
	   sleep_req[0] <= 0;
	else if (~fsm_o_d_status[1])
       sleep_req[1] <= 0;   
end


always @(*)  begin
    if (vld_addr && slv_o_valid && !slv_o_rd0_wr1) begin 
        // Reading (only for verf purpose)
        case (slv_o_addr)
        32'h00: begin
            slv_i_rd_data = sleep_req;
            slv_i_rd_valid=1'b1;
        end
        32'h04: begin
            slv_i_rd_data = wakeup_enable;
            slv_i_rd_valid=1'b1;
        end
        32'h08: begin
            slv_i_rd_data = power_gating;
            slv_i_rd_valid=1'b1;
        end
        32'h0C: begin
            slv_i_rd_data = status;
            slv_i_rd_valid=1'b1;
        end
        32'h10: begin
            slv_i_rd_data = on_seq_delay;
            slv_i_rd_valid=1'b1;
        end
        32'h14: begin
            slv_i_rd_data = off_seq_delay;
            slv_i_rd_valid=1'b1;
        end
        32'h18: begin
            slv_i_rd_data = on_delay;
            slv_i_rd_valid=1'b1;
        end
        32'h1C: begin
            slv_i_rd_data = off_delay;
            slv_i_rd_valid=1'b1;
        end
        default: begin
            slv_i_rd_data  = 'b0;
            slv_i_rd_valid =1'b0;
        end
    endcase
    end
        else begin
            slv_i_rd_data  ='b0;
            slv_i_rd_valid =1'b0;
        end
end
endmodule
