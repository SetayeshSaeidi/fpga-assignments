`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Module: q2_5_adder_abs
// Description: Adds two Q2.5 numbers and calculates the Absolute Value of the sum.
// Inputs: 8-bit Signed Q2.5 (1 Sign, 2 Integer, 5 Fraction)
// Output: 8-bit Unsigned (Magnitude in Q2.5 scale)
//////////////////////////////////////////////////////////////////////////////////

module q2_5_adder_abs (
    input wire signed [7:0] a_in,      // Operand A (e.g., 1.25 -> 0x28)
    input wire signed [7:0] b_in,      // Operand B (e.g., -0.625 -> 0xEC)
    output reg [7:0] abs_sum_out,      // Result |A+B| (e.g., 0.625 -> 0x14)
    output reg overflow                // Overflow flag
);

    reg signed [8:0] temp_sum;         // 9-bit register for carry/overflow handling

    always @(*) begin
        // 1. Sign-extend and Add
        // We use 9 bits to catch sums that exceed the 8-bit range [-4, 3.96]
        temp_sum = {a_in[7], a_in} + {b_in[7], b_in};

        // 2. Overflow Check
        // Q2.5 limits: Max +127 (approx 3.96), Min -128 (-4.00) in raw units
        if (temp_sum > 127 || temp_sum < -128) begin
            overflow = 1;
            abs_sum_out = 8'h7F;       // Saturate to max positive value
        end else begin
            overflow = 0;
            
            // 3. Absolute Value Calculation
            // If the sum is negative, perform Two's Complement Negation
            if (temp_sum < 0)
                abs_sum_out = -temp_sum[7:0];
            else
                abs_sum_out = temp_sum[7:0];
        end
    end

endmodule
