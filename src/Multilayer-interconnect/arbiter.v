module arbiter #(
    parameter NUM_MASTERS = 2
) (
    input  wire 	          		htrans     [NUM_MASTERS-1:0], // Transaction type from each master
    input  wire                	 	hready,                      // Ready signal from slave
    output reg  [NUM_MASTERS-1:0] 	bus_grant                  // One-hot grant signal (select for slave mux)
);

    integer i;

    always @(*) begin
        bus_grant = 0;
        if (hready) begin
            for (i = 0; i < NUM_MASTERS; i = i + 1) begin
                if (!htrans[i]) begin // Check if master i is initiating a valid transaction
                    bus_grant[i] = 1;         // Grant bus to master i
                    break;                    // Fixed priority: grant to first valid master
                end
            end
        end
    end
endmodule
