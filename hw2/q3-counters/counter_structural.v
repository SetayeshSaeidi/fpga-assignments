// ---------------------------------------------------------
// Module: JK Flip-Flop
// Trigger: Negative Edge (Standard for Ripple Counters)
// ---------------------------------------------------------
module jk_ff (
    input wire clk,
    input wire rst_n, // Active low reset
    input wire j,
    input wire k,
    output reg q
);

    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
        end else begin
            case ({j, k})
                2'b00: q <= q;      // Hold
                2'b01: q <= 1'b0;   // Reset
                2'b10: q <= 1'b1;   // Set
                2'b11: q <= ~q;     // Toggle
            endcase
        end
    end

endmodule

// ---------------------------------------------------------
// Module: 4-bit Structural Counter (Ripple Architecture)
// ---------------------------------------------------------
module counter_structural (
    input wire clk,
    input wire rst_n,
    output wire [3:0] q_out
);

    // Logic High for J and K inputs
    wire high;
    assign high = 1'b1;

    // Instantiate 4 JK Flip-Flops
    // Note: The Output q of bit 0 becomes the Clock of bit 1
    
    // Bit 0 (LSB) - Clocked by system clock
    jk_ff ff0 (
        .clk(clk), .rst_n(rst_n), .j(high), .k(high), 
        .q(q_out[0])
    );

    // Bit 1 - Clocked by q[0]
    jk_ff ff1 (
        .clk(q_out[0]), .rst_n(rst_n), .j(high), .k(high), 
        .q(q_out[1])
    );

    // Bit 2 - Clocked by q[1]
    jk_ff ff2 (
        .clk(q_out[1]), .rst_n(rst_n), .j(high), .k(high), 
        .q(q_out[2])
    );

    // Bit 3 (MSB) - Clocked by q[2]
    jk_ff ff3 (
        .clk(q_out[2]), .rst_n(rst_n), .j(high), .k(high), 
        .q(q_out[3])
    );

endmodule
