`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module: tb_q2_5_adder_abs
// Description: Testbench for verifying Q2.5 Adder with Absolute Output.
//              Focuses on the specific case: 1.25 + (-0.625).
//////////////////////////////////////////////////////////////////////////////////

module tb_q2_5_adder_abs;

    // Inputs
    reg signed [7:0] a_in;
    reg signed [7:0] b_in;

    // Outputs
    wire [7:0] abs_sum_out;
    wire overflow;

    // Instantiate the Unit Under Test (UUT)
    q2_5_adder_abs uut (
        .a_in(a_in),
        .b_in(b_in),
        .abs_sum_out(abs_sum_out),
        .overflow(overflow)
    );

    // Helper function to display Q2.5 values as Real numbers
    function real q25_to_real;
        input [7:0] val;
        begin
            // Check sign bit (Bit 7) for correct display of signed inputs
            if (val[7] == 1) 
                q25_to_real = -((~val + 1) / 32.0); // 2's complement for negative
            else 
                q25_to_real = val / 32.0;
        end
    endfunction

    // Helper for Unsigned Output (Absolute Value)
    function real abs_to_real;
        input [7:0] val;
        begin
            abs_to_real = val / 32.0;
        end
    endfunction

    initial begin
        // Initialize Inputs
        a_in = 0;
        b_in = 0;

        $display("==================================================");
        $display("Starting Verification for Q2.5 Absolute Adder");
        $display("LSB Resolution: 0.03125");
        $display("==================================================");

        // ------------------------------------------------------------
        // Test Case 1: Specific Problem from Q3(c)
        // 1.25 + (-0.625)
        // ------------------------------------------------------------
        // Encoding 1.25:
        // 1.25 / 0.03125 = 40 = 0x28
        // Binary: 001 01000 (0 Sign, 01 Int, 01000 Frac)
        
        // Encoding -0.625:
        // 0.625 / 0.03125 = 20 = 0x14
        // -0.625 = Two's Comp of 0x14 = 0xEC
        
        a_in = 8'h28; // 1.25
        b_in = 8'hEC; // -0.625
        
        #10; // Wait for combinational logic to settle
        
        $display("\nTest Case 1: 1.25 + (-0.625)");
        $display("Input A: Hex=0x%h, Real=%0.5f", a_in, q25_to_real(a_in));
        $display("Input B: Hex=0x%h, Real=%0.5f", b_in, q25_to_real(b_in));
        $display("--------------------------------");
        $display("Output (Abs Sum): Hex=0x%h", abs_sum_out);
        $display("Output (Real):    %0.5f", abs_to_real(abs_sum_out));
        $display("Expected Result:  0.62500");
        
        if (abs_sum_out == 8'h14) // 0x14 is 0.625
            $display("STATUS: PASS");
        else
            $display("STATUS: FAIL");

        // ------------------------------------------------------------
        // Test Case 2: Negative Result Logic Check
        // -1.5 + 0.5 = -1.0 -> Abs Output should be 1.0
        // ------------------------------------------------------------
        // -1.5 = 0xD0 (Inv(0x30)+1)
        // 0.5  = 0x10
        #10;
        a_in = 8'hD0; // -1.5
        b_in = 8'h10; // 0.5
        
        #10;
        $display("\nTest Case 2: -1.5 + 0.5 = |-1.0|");
        $display("Output (Abs Sum): Hex=0x%h", abs_sum_out);
        $display("Output (Real):    %0.5f", abs_to_real(abs_sum_out));
        
        if (abs_sum_out == 8'h20) // 0x20 is 1.0
            $display("STATUS: PASS");
        else
            $display("STATUS: FAIL");

        // ------------------------------------------------------------
        // Test Case 3: Overflow Check
        // 2.5 + 2.0 = 4.5 (Exceeds max 3.96)
        // ------------------------------------------------------------
        // 2.5 = 0x50
        // 2.0 = 0x40
        #10;
        a_in = 8'h50; 
        b_in = 8'h40;
        
        #10;
        $display("\nTest Case 3: Overflow (2.5 + 2.0)");
        $display("Overflow Flag: %b", overflow);
        $display("Output (Saturated): 0x%h", abs_sum_out);

        if (overflow == 1 && abs_sum_out == 8'h7F)
            $display("STATUS: PASS");
        else
            $display("STATUS: FAIL");

        $display("\n==================================================");
        $finish;
    end

endmodule
