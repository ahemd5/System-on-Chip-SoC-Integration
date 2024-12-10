module counter #(parameter N=2)(
    input  logic           i_aon_clk,      
    input  logic           i_soc_pwr_on_rst,  

    input  logic [3:0]     pwr_off_seq_delay, //Delay between control events during the power-of sequence       
    input  logic [3:0]     pwr_on_seq_delay, //Delay between control events during the power-on sequence
   
    input  logic   i_pwr_on_ack,
    input  logic   i_hw_sleep_ack,
    input  logic   i_iso,          // Input for isolation enable
    input  logic   i_ret,          // Input for retention enable
    input  logic   i_rstn,         // Input for reset
    input  logic   i_clk_en,       // Input for clock enable

    output logic    o_iso,          // Delayed isolation enable
    output logic    o_ret,          // Delayed retention enable
    output logic    o_rstn,          // Delayed reset 
    output logic    o_clk_en        // Delayed clock enable
);

    // Registers to store the delay counters for each output
    logic [3:0] delay_counter_iso;
    logic [3:0] delay_counter_ret;
    logic [3:0] delay_counter_rstn;
    logic [3:0] delay_counter_clk_en;


    logic  delayed_iso;
    logic  delayed_ret;
    logic  delayed_rstn;
    logic  delayed_clk_en;


    always_ff @(posedge i_aon_clk or posedge i_soc_pwr_on_rst) begin
        if (i_soc_pwr_on_rst) begin
            delay_counter_iso <= 4'b0;
            delay_counter_ret <= 4'b0;
            delay_counter_rstn <= 4'b0;
            delay_counter_clk_en <= 4'b0;
            delayed_iso <= 'b0;
            delayed_ret <= 'b0;
            delayed_rstn <= 'b0;
            delayed_clk_en <='b1;
     
        end 
        else begin
             if(i_hw_sleep_ack && ~i_clk_en  ) begin
            // Delay for o_iso
            if (delay_counter_iso < 2*pwr_off_seq_delay -1) begin
                delay_counter_iso <= delay_counter_iso + 1;
            end else begin
                delayed_iso <= i_iso;
            end

            // Delay for o_ret
            if (delay_counter_ret < 3*pwr_off_seq_delay -1 ) begin
                delay_counter_ret <= delay_counter_ret + 1;
            end else begin
                delayed_ret <= i_ret;
            end

            // Delay for o_rstn
            if (delay_counter_rstn < 4*pwr_off_seq_delay -1) begin
                delay_counter_rstn <= delay_counter_rstn + 1;
            end else begin
                delayed_rstn <= i_rstn;
            end

            // Delay for o_clk_en
            if (delay_counter_clk_en < pwr_off_seq_delay-1) begin
                delay_counter_clk_en <= delay_counter_clk_en + 1;
            end else begin
                delayed_clk_en <= i_clk_en;
            end
        end

         if (i_pwr_on_ack && i_clk_en) begin
            // Delay for o_iso
            if (delay_counter_iso < 3*pwr_on_seq_delay -1) begin
                delay_counter_iso <= delay_counter_iso + 1;
            end else begin
                delayed_iso <= i_iso;
            end

            // Delay for o_ret
            if (delay_counter_ret < 2*pwr_on_seq_delay -1) begin
                delay_counter_ret <= delay_counter_ret + 1;
            end else begin
                delayed_ret <= i_ret;
            end

            // Delay for o_rstn
            if (delay_counter_rstn < pwr_on_seq_delay -1) begin
                delay_counter_rstn <= delay_counter_rstn + 1;
            end else begin
                delayed_rstn <= i_rstn;
            end

            // Delay for o_clk_en
            if (delay_counter_clk_en < 4*pwr_on_seq_delay -1) begin
                delay_counter_clk_en <= delay_counter_clk_en + 1;
            end else begin
                delayed_clk_en <= i_clk_en;
            end
        end
    end
    end

    assign o_iso = delayed_iso;
    assign o_ret = delayed_ret;
    assign o_rstn = delayed_rstn;
    assign o_clk_en = delayed_clk_en;

endmodule
