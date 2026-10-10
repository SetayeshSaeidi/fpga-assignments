// ---------------------------------------------------------
// Module: 4-bit Behavioral Counter (Synchronous)
// ---------------------------------------------------------
module counter_behavioral (
    input wire clk,
    input wire rst_n,
    output reg [3:0] q_out
);

    // Synchronous Up Counter
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) 
            q_out <= 4'b0000;
        else 
            q_out <= q_out + 1;
    end

endmodule
