`timescale 1ns / 1ps

module tb_fir_transposed;

    // Inputs
    reg clk;
    reg rst_n;
    reg signed [7:0] x;
    reg signed [7:0] a, b, c;

    // Outputs
    wire signed [15:0] y;

    // Instantiate the Transposed Design
    fir_transposed uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .x(x), 
        .a(a), .b(b), .c(c), 
        .y(y)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave_transposed.vcd");
        $dumpvars(0, tb_fir_transposed);

        clk = 0; rst_n = 0; x = 0;
        a = 2; b = 3; c = 4;

        #20 rst_n = 1;

        // --- IMPULSE TEST (10, 0, 0...) ---
        $display("--- Transposed Form Test ---");

        @(posedge clk); x = 10; // Input 10
        @(posedge clk); x = 0;  // Input 0
        #1 $display("Time: %0t | Output: %d (Expect 20)", $time, y);

        @(posedge clk); 
        #1 $display("Time: %0t | Output: %d (Expect 30)", $time, y);

        @(posedge clk); 
        #1 $display("Time: %0t | Output: %d (Expect 40)", $time, y);

        #20 $finish;
    end
endmodule
