`timescale 1ns / 1ps

module tb_fir_folded;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg signed [7:0] x_in;
    reg signed [7:0] a, b, c;

    // Outputs
    wire signed [15:0] y;
    wire valid_out;

    // Instantiate the Folded Design
    fir_folded_area_optimized uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start), 
        .x_in(x_in), 
        .a(a), .b(b), .c(c), 
        .y(y), 
        .valid_out(valid_out)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave_folded.vcd");
        $dumpvars(0, tb_fir_folded);

        clk = 0; rst_n = 0; start = 0; x_in = 0;
        a = 2; b = 3; c = 4;

        #20 rst_n = 1;
        $display("--- Folded Form Test (Wait for Valid Signal) ---");

        // --- INPUT 1: 10 ---
        @(posedge clk);
        x_in = 10; start = 1; // Load 10
        @(posedge clk); start = 0; // Clear start
        
        // Wait for valid output
        wait(valid_out == 1); 
        #1 $display("Time: %0t | Input: 10 | Output: %d (Expect 20)", $time, y);
        @(posedge clk); // Sync

        // --- INPUT 2: 0 ---
        @(posedge clk);
        x_in = 0; start = 1; // Load 0
        @(posedge clk); start = 0;

        wait(valid_out == 1);
        #1 $display("Time: %0t | Input: 0  | Output: %d (Expect 30)", $time, y);
        @(posedge clk);

        // --- INPUT 3: 0 ---
        @(posedge clk);
        x_in = 0; start = 1; // Load 0
        @(posedge clk); start = 0;

        wait(valid_out == 1);
        #1 $display("Time: %0t | Input: 0  | Output: %d (Expect 40)", $time, y);

        #50 $finish;
    end
endmodule
