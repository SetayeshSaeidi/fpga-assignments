module logic_with_dff (
    input  wire a,
    input  wire b,
    input  wire c,
    input  wire clk,
    output reg  Q1,
    output reg  Q2
);

    wire and_out;
    wire or_out;

    // Combinational logic
    assign and_out = a & b;
    assign or_out  = b | c;

    // D Flip-Flops (positive edge triggered)
    always @(posedge clk) begin
        Q1 <= and_out;
        Q2 <= or_out;
    end

endmodule
