`timescale 1ns / 1ps

module tb_ripple_carry;

    // Inputs
    reg [3:0] A;
    reg [3:0] B;
    reg Cin;

    // Outputs
    wire [3:0] S;
    wire Cout;

    // Instantiate the Unit Under Test (UUT)
    ripple_carry_4bit uut (
        .A(A), 
        .B(B), 
        .Cin(Cin), 
        .S(S), 
        .Cout(Cout)
    );

    initial begin
        $dumpfile("rca_waves.vcd");
        $dumpvars(0, tb_ripple_carry);
        
        $display("Time |  A   +  B   + Cin | Sum (S) | Cout");
        $display("-------------------------------------------");

        // Test Case 1: 2 + 3 (Cin=0) -> Expect Sum=5, Cout=0
        A = 4'd2; B = 4'd3; Cin = 0;
        #10;
        $display("%4t | %d + %d +  %b  |   %d   |  %b", $time, A, B, Cin, S, Cout);

        // Test Case 2: 15 + 1 (Cin=0) -> Expect Sum=0, Cout=1 (Overflow)
        A = 4'd15; B = 4'd1; Cin = 0;
        #10;
        $display("%4t | %d + %d +  %b  |   %d   |  %b", $time, A, B, Cin, S, Cout);

        // Test Case 3: 5 + 5 (Cin=1) -> Expect Sum=11, Cout=0
        A = 4'd5; B = 4'd5; Cin = 1;
        #10;
        $display("%4t | %d + %d +  %b  |   %d   |  %b", $time, A, B, Cin, S, Cout);

        // Test Case 4: Max Value 15 + 15 (Cin=1) -> Expect Sum=15, Cout=1
        A = 4'd15; B = 4'd15; Cin = 1;
        #10;
        $display("%4t | %d + %d +  %b  |   %d   |  %b", $time, A, B, Cin, S, Cout);

        $finish;
    end

endmodule
