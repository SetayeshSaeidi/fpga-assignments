`timescale 1ns / 1ps
`include "q1.v"

module tb_logic_with_dff;

    // Testbench signals
    reg a;
    reg b;
    reg c;
    reg clk;

    wire q1;
    wire q2;

    // Instantiate the DUT (Device Under Test)
    logic_with_dff uut (
        .a(a),
        .b(b),
        .c(c),
        .clk(clk),
        .Q1(q1),
        .Q2(q2)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        a = 0;
        b = 0;
        c = 0;

        // Monitor values
        $monitor("Time=%0t | a=%b b=%b c=%b | Q1=%b Q2=%b",
                 $time, a, b, c, q1, q2);

        // Apply test vectors
        #10 a = 1; b = 0; c = 0;   // AND=0, OR=0
        #10 a = 1; b = 1; c = 0;   // AND=1, OR=1
        #10 a = 0; b = 1; c = 0;   // AND=0, OR=1
        #10 a = 0; b = 0; c = 1;   // AND=0, OR=1
        #10 a = 1; b = 1; c = 1;   // AND=1, OR=1
        #10 a = 0; b = 0; c = 0;   // AND=0, OR=0

        #20 $finish;
    end

endmodule
