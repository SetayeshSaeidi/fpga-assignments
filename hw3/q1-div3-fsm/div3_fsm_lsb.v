`timescale 1ns / 1ps

module div3_fsm_lsb (
    input wire clk,
    input wire rst,      // Active high reset
    input wire bit_in,   // Serial bit input (LSB first)
    output reg rem       // 0 if divisible by 3, 1 otherwise
);

    // State Encoding
    // Format: S_Rem_Weight
    localparam S0_R0_W1 = 3'b000; // Remainder 0, Weight 1 (Initial State)
    localparam S1_R1_W1 = 3'b001; // Remainder 1, Weight 1
    localparam S2_R2_W1 = 3'b010; // Remainder 2, Weight 1
    localparam S3_R0_W2 = 3'b011; // Remainder 0, Weight 2
    localparam S4_R1_W2 = 3'b100; // Remainder 1, Weight 2
    localparam S5_R2_W2 = 3'b101; // Remainder 2, Weight 2

    reg [2:0] current_state, next_state;

    // Sequential Logic: State Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= S0_R0_W1;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational Logic: Next State and Output Logic (Mealy)
    always @(*) begin
        // Default assignment to prevent latches
        next_state = current_state;
        rem = 1'b1; // Default to Not Divisible

        case (current_state)
            // STATES WITH WEIGHT 1 (Next weight will be 2)
            S0_R0_W1: begin
                if (bit_in == 1'b0) begin
                    next_state = S3_R0_W2;
                    rem = 1'b0; // New Rem: (0 + 0*1)%3 = 0 -> Divisible
                end else begin
                    next_state = S4_R1_W2;
                    rem = 1'b1; // New Rem: (0 + 1*1)%3 = 1
                end
            end

            S1_R1_W1: begin
                if (bit_in == 1'b0) begin
                    next_state = S4_R1_W2;
                    rem = 1'b1; // New Rem: (1 + 0*1)%3 = 1
                end else begin
                    next_state = S5_R2_W2;
                    rem = 1'b1; // New Rem: (1 + 1*1)%3 = 2
                end
            end

            S2_R2_W1: begin
                if (bit_in == 1'b0) begin
                    next_state = S5_R2_W2;
                    rem = 1'b1; // New Rem: (2 + 0*1)%3 = 2
                end else begin
                    next_state = S3_R0_W2;
                    rem = 1'b0; // New Rem: (2 + 1*1)%3 = 0 -> Divisible
                end
            end

            // STATES WITH WEIGHT 2 (Next weight will be 1)
            S3_R0_W2: begin
                if (bit_in == 1'b0) begin
                    next_state = S0_R0_W1;
                    rem = 1'b0; // New Rem: (0 + 0*2)%3 = 0 -> Divisible
                end else begin
                    next_state = S2_R2_W1;
                    rem = 1'b1; // New Rem: (0 + 1*2)%3 = 2
                end
            end

            S4_R1_W2: begin
                if (bit_in == 1'b0) begin
                    next_state = S1_R1_W1;
                    rem = 1'b1; // New Rem: (1 + 0*2)%3 = 1
                end else begin
                    next_state = S0_R0_W1;
                    rem = 1'b0; // New Rem: (1 + 1*2)%3 = 0 -> Divisible
                end
            end

            S5_R2_W2: begin
                if (bit_in == 1'b0) begin
                    next_state = S2_R2_W1;
                    rem = 1'b1; // New Rem: (2 + 0*2)%3 = 2
                end else begin
                    next_state = S1_R1_W1;
                    rem = 1'b1; // New Rem: (2 + 1*2)%3 = 4%3 = 1
                end
            end

            default: begin
                next_state = S0_R0_W1;
                rem = 1'b1;
            end
        endcase
    end

endmodule
