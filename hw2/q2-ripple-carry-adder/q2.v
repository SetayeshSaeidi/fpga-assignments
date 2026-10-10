// ---------------------------------------------------------
// Module 1: Full Adder
// Implements Eq: {co, s} = a + b + ci
// ---------------------------------------------------------
module full_adder (
    input wire a,
    input wire b,
    input wire ci,
    output wire s,
    output wire co
);
    // You can implement this structurally (gates) or behaviorally.
    // Since the text gives the math expression, this is cleanest:
    assign {co, s} = a + b + ci;

endmodule

// ---------------------------------------------------------
// Module 2: 4-bit Ripple Carry Adder
// Instantiates 4 Full Adders to add two 4-bit numbers
// ---------------------------------------------------------
module ripple_carry_4bit (
    input wire [3:0] A,
    input wire [3:0] B,
    input wire Cin,      // Carry In (usually 0 for simple addition)
    output wire [3:0] S, // Sum Output
    output wire Cout     // Final Carry Out
);

    // Internal wires to carry the ripple signals between stages
    wire c1, c2, c3;

    // Instance 0 (LSB)
    full_adder FA0 (
        .a(A[0]), .b(B[0]), .ci(Cin), 
        .s(S[0]), .co(c1)
    );

    // Instance 1
    full_adder FA1 (
        .a(A[1]), .b(B[1]), .ci(c1), 
        .s(S[1]), .co(c2)
    );

    // Instance 2
    full_adder FA2 (
        .a(A[2]), .b(B[2]), .ci(c2), 
        .s(S[2]), .co(c3)
    );

    // Instance 3 (MSB)
    full_adder FA3 (
        .a(A[3]), .b(B[3]), .ci(c3), 
        .s(S[3]), .co(Cout)
    );

endmodule
