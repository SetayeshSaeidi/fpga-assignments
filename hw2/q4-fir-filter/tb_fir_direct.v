`timescale 1ns / 1ps

module tb_fir_direct;

    // Inputs
    reg clk;
    reg rst_n;
    reg signed [7:0] x;
    reg signed [7:0] a, b, c;

    // Outputs
    wire signed [15:0] y;

    // Instantiate the Direct Form Design
    fir_direct_form uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .x(x), 
        .a(a), .b(b), .c(c), 
        .y(y)
    );

    // Clock Generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Setup Waveform
        $dumpfile("wave_direct.vcd");
        $dumpvars(0, tb_fir_direct);

        // Initialize
        clk = 0; rst_n = 0; x = 0;
        a = 2; b = 3; c = 4; // Equation: 2*x[n] + 3*x[n-1] + 4*x[n-2]

        // Reset
        #20 rst_n = 1;

        // --- IMPULSE TEST (10, 0, 0...) ---
        $display("--- Direct Form Test ---");
        
        @(posedge clk); x = 10; // Input = 10
        @(posedge clk); x = 0;  // Input = 0 (Expect y = 10*2 = 20)
        #1 $display("Time: %0t | Input: 10 | Output: %d (Expect 20)", $time, y);

        @(posedge clk);         // Input = 0 (Expect y = 10*3 = 30)
        #1 $display("Time: %0t | Input: 0  | Output: %d (Expect 30)", $time, y);

        @(posedge clk);         // Input = 0 (Expect y = 10*4 = 40)
        #1 $display("Time: %0t | Input: 0  | Output: %d (Expect 40)", $time, y);

        @(posedge clk);
        #1 $display("Time: %0t | Input: 0  | Output: %d (Expect 0)", $time, y);

        #20 $finish;
    end
endmodule
