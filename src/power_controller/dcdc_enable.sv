module dcdc_enable(
    input  logic        i_aon_clk,      
    input  logic        i_soc_pwr_on_rst,  
    input  logic [7:0]  pwr_on_delay,    //Delay before asserting o_dcdc_enable during power-on.
    input  logic [7:0]  pwr_off_delay,  //Delay before deasserting o_dcdc_enable during power-off.
    //input  logic        i_pwr_on_ack,
    input  logic        i_hw_sleep_ack, //sleep ack fron PD1
    input  logic        i_dcdc_enable,
    output logic         o_dcdc_enable
);

logic delayed_dcdc_enable;
logic [7:0] delay_counter;
assign o_dcdc_enable = delayed_dcdc_enable;

    always_ff @(posedge i_aon_clk or posedge i_soc_pwr_on_rst) begin
        if (i_soc_pwr_on_rst) begin
            delayed_dcdc_enable<='b0;
            delay_counter <='b0;
        end
        else if(i_hw_sleep_ack) begin //Deep sleep
            if(delay_counter < pwr_off_delay -1) begin
                delay_counter <= delay_counter + 1;
            end
            else
                delayed_dcdc_enable <= i_dcdc_enable;
        end
        else begin //ON
            if(delay_counter < pwr_on_delay -1) 
                delay_counter <= delay_counter +1;
            else
                delayed_dcdc_enable <= i_dcdc_enable;
        end
    end
 
    endmodule







