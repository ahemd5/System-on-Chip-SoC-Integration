module buffer #(parameter DATA_WIDTH = 32, BUFFER_DEPTH = 16)(

input logic                    clk,rst,
input logic                    i_rd0_wr1,i_valid,
input logic  [DATA_WIDTH-1:0]  i_data,
output logic [DATA_WIDTH-1:0]  o_data,
output logic                   o_valid
);

logic  [DATA_WIDTH-1:0] memory [BUFFER_DEPTH-1:0] ;   
integer counter ;
integer counter_1;

always @ (posedge clk , negedge rst) begin
if (!rst)begin
o_data <= 'b0;
o_valid <= 0;
for(int i = 0; i<=BUFFER_DEPTH-1 ; i++)begin
    memory[i] <='b0;
	end
	
end else begin

if (i_valid && i_rd0_wr1) begin
    memory[counter][DATA_WIDTH-1:0] <= {0,i_data} ;
   
end else if (i_valid && !i_rd0_wr1) begin
    o_data <= memory[counter_1][DATA_WIDTH-1:0];
    o_valid <= 1;
	
end else begin
    o_data <= 'b0;
    o_valid <= 0;
end
end
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter <= 'b0;   // Reset write counter
        counter_1 <= 'b0; // Reset read counter
    end else begin
        // Handle write counter
        if (i_valid && i_rd0_wr1) begin
            if (counter < BUFFER_DEPTH - 1) begin
                counter <= counter + 1; // Increment on valid write
            end else begin
                counter <= 'b0; // Reset counter when max BUFFER_DEPTH is reached
            end
        end

        // Handle read counter
        if (i_valid && !i_rd0_wr1) begin
            if (counter_1 < BUFFER_DEPTH - 1) begin
                counter_1 <= counter_1 + 1; // Increment on valid read
            end else begin
                counter_1 <= 'b0; // Reset counter when max BUFFER_DEPTH is reached
            end
        end
    end
end

 
endmodule 
   
   