module interrupt_controller (
    input  logic         PCLK,      // APB Clock
    input  logic         rstn,   // APB Reset (active low)
    input  logic         PSEL,      // APB Select
    input  logic         PENABLE,   // APB Enable
    input  logic         PWRITE,    // APB Write Enable
    input  logic [4:0]   PADDR,     // APB Address Bus
    input  logic [31:0]  PWDATA,    // APB Write Data
    output logic [31:0]  PRDATA,    // APB Read Data
    output logic         PREADY,    // APB Ready
    output logic         PSLVERR,   // APB Slave Error

    input  logic [31:0]  IRQ,       // 32 Interrupt
    input  logic [4:0]   index,     // Index for interrupts
    output logic [3:0]   INT,       // 4 Interrupt Outputs
    output logic [4:0]   IRQ_VECTOR // Vector Address
);


logic [31:0] irq_enable;     
logic [31:0] irq_disable;        
logic [4:0] irq_priority [31:0]; 
logic [31:0] irq_status;     
logic [31:0] irq_type;       
logic [3:0]  irq_map [31:0]; 
logic [31:0] irq_ack;         
logic [4:0] irq_vector_table [31:0]; 


logic [31:0] pending_irq; 
logic [4:0] highest_irq;  
logic [3:0] assigned_int; 
logic [31:0]irq_f;      
always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn) 
        irq_f <= 32'b0;
    else
          irq_f <= IRQ;
end
always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn) 
        irq_status <= 32'b0;
     else begin
        irq_status <= irq_status | (irq_f & ~irq_disable &irq_enable ) ; 
        for (int i = 0; i < 32; i++)
            if (irq_type[i] == 1'b0 && irq_ack[i])
                irq_status[i] <= 1'b0;
        if (PSEL && PENABLE && PWRITE && (PADDR == 5'h00))
            irq_status <= irq_status | PWDATA; 

    end
end

always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn) begin
        for (int i = 0; i < 32; i++) begin
            irq_priority[i] <= 0;
        end
    end
    else if(PSEL && PENABLE && PWRITE && (PADDR == 5'h0C)) begin
            irq_priority[index] <= PWDATA[4:0];
    end
end
always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn) begin
        for (int i = 0; i < 32; i++) begin
            irq_map[i] <= 0;
        end
    end
    else if(PSEL && PENABLE && PWRITE && (PADDR == 5'h1C)) begin
            irq_map[index] <= PWDATA[3:0];
    end
end
always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn) begin
        for (int i = 0; i < 32; i++) begin
            irq_vector_table[i] <= 0;
        end
    end
    else if(PSEL && PENABLE && PWRITE && (PADDR == 5'h18)) begin
            irq_vector_table[index] <= PWDATA;
    end
end

always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn) begin
        irq_enable  <= 32'b0;
        irq_disable <= 32'b0;
        irq_ack     <= 32'b0;
        irq_type    <= 32'b0;
    end else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR)
                5'h04: irq_enable   <= irq_enable | PWDATA;   
                5'h08: irq_disable  <= irq_disable | PWDATA;  
                5'h10: irq_ack      <= irq_ack  | PWDATA;    
                5'h14: irq_type     <= PWDATA;              
            endcase
        end 
    end
always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn)
        PRDATA <= 32'b0;
        else if (PSEL && PENABLE && !PWRITE) begin
            case (PADDR)
                5'h00: PRDATA <= irq_status;
                5'h04: PRDATA <= irq_enable;
                5'h08: PRDATA <= irq_disable;
                5'h0C: PRDATA <= irq_priority[index];
                5'h10: PRDATA <= irq_ack;
                5'h14: PRDATA <= irq_type;
                5'h18: PRDATA <= irq_vector_table[index];
                5'h1C: PRDATA <= irq_map[index];
                default: PRDATA <= 'b0;
            endcase
        end
end
always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn) begin
        PREADY <= 1'b0;
         PSLVERR <= 1'b0;
    end
    else if (PSEL && PENABLE) begin
        PREADY <= 1'b1;
        PSLVERR <= 1'b0;
end
end
always_comb begin
    highest_irq = 5'b11111;
    assigned_int = 4'b0000;
    
    for (int i = 0; i < 32; i++) begin
        if (irq_status[i]) begin
            if (highest_irq == 5'b11111 || irq_priority[i] < irq_priority[highest_irq]) begin
                highest_irq = i;
                assigned_int = irq_map[i];
            end
        end
    end
end
always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn)
        INT <= 4'b0000;
    else begin
        INT[assigned_int] <= (highest_irq != 5'b11111);
    end
end
always_ff @(posedge PCLK or negedge rstn) begin
    if (!rstn)
        IRQ_VECTOR <= 5'b11111;
    else
        IRQ_VECTOR <= irq_vector_table[highest_irq];
end

endmodule

