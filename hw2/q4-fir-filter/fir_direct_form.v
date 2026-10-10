module fir_direct_form (
    input wire clk,
    input wire rst_n,
    input wire signed [7:0] x,       // Input x(n)
    input wire signed [7:0] a, b, c, // Coefficients
    output reg signed [15:0] y       // Output Y(n)
);

    // 1. Shift Register (Delay Line) for x(n-1) and x(n-2)
    reg signed [7:0] x_d1;
    reg signed [7:0] x_d2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_d1 <= 8'd0;
            x_d2 <= 8'd0;
            y    <= 16'd0;
        end else begin
            // Shift the data
            x_d2 <= x_d1;
            x_d1 <= x;

            // 2. Compute Output (Combinational Logic + Output Register)
            // Y(n) = a*x(n) + b*x(n-1) + c*x(n-2)
            y <= (a * x) + (b * x_d1) + (c * x_d2);
        end
    end

endmodule
