module fir_transposed (
    input wire clk,
    input wire rst_n,
    input wire signed [7:0] x,       // Input x(n)
    input wire signed [7:0] a, b, c, // Coefficients
    output reg signed [15:0] y       // Output Y(n)
);

    // Internal Pipeline Registers
    reg signed [15:0] m2; // Stores partial sum between stages
    reg signed [15:0] m1; // Stores partial sum between stages

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m1 <= 16'd0;
            m2 <= 16'd0;
            y  <= 16'd0;
        end else begin
            // The Transposed Structure:
            // Input 'x' is broadcast to all multipliers at once.
            
            // Stage 1: (c * x) -> feeds into next stage
            m1 <= x * c;

            // Stage 2: (b * x) + previous_stage
            m2 <= (x * b) + m1;

            // Output Stage: (a * x) + previous_stage
            y  <= (x * a) + m2;
        end
    end

endmodule
