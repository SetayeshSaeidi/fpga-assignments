// ============================================================================
// 16-bit Galois Linear Feedback Shift Register (LFSR)
// ============================================================================
// Description:
//   This module implements a 16-bit Galois-style LFSR for pseudo-random
//   number generation. The Galois configuration places XOR gates between
//   register stages for improved timing performance.
//
// Tap Configuration: 
//   Taps at positions 16, 14, 13, and 11 (polynomial: x^16 + x^14 + x^13 + x^11 + 1)
//
// Features:
//   - Active-low asynchronous reset
//   - Clock enable signal
//   - Non-zero seed initialization
//   - Maximum-length sequence (2^16 - 1 = 65535 states)
// ============================================================================

module galois_lfsr_16bit (
    input  wire        clk,        // Clock input
    input  wire        rst_n,      // Active-low asynchronous reset
    input  wire        enable,     // Clock enable signal
    input  wire [15:0] seed,       // Initial seed value (loaded on reset)
    output reg  [15:0] lfsr_out,   // Current LFSR state
    output wire        random_bit  // LSB output (pseudo-random bit)
);

    // ========================================================================
    // Parameter Definition
    // ========================================================================
    // Default seed value (non-zero to avoid stuck state)
    parameter DEFAULT_SEED = 16'hACE1; // 0xACE1 = 1010_1100_1110_0001
    
    // ========================================================================
    // Internal Signals
    // ========================================================================
    wire feedback;           // Feedback bit from position 16 (LSB after shift)
    wire [15:0] next_state;  // Next state logic
    
    // ========================================================================
    // Galois LFSR Logic
    // ========================================================================
    // The feedback is taken from the LSB (bit 0) which will be shifted out
    assign feedback = lfsr_out[0];
    
    // Galois LFSR: XOR gates are inserted at tap positions
    // Taps at positions 16, 14, 13, 11
    // In Galois configuration:
    //   - Bit 15 gets the feedback
    //   - Bits at tap positions (excluding position 16) are XORed with feedback
    //   - Other bits just shift right
    
    assign next_state[15] = feedback;                              // Position 16 tap
    assign next_state[14] = lfsr_out[15];                          // No tap
    assign next_state[13] = lfsr_out[14] ^ feedback;               // Position 14 tap
    assign next_state[12] = lfsr_out[13] ^ feedback;               // Position 13 tap
    assign next_state[11] = lfsr_out[12];                          // No tap
    assign next_state[10] = lfsr_out[11] ^ feedback;               // Position 11 tap
    assign next_state[9]  = lfsr_out[10];
    assign next_state[8]  = lfsr_out[9];
    assign next_state[7]  = lfsr_out[8];
    assign next_state[6]  = lfsr_out[7];
    assign next_state[5]  = lfsr_out[6];
    assign next_state[4]  = lfsr_out[5];
    assign next_state[3]  = lfsr_out[4];
    assign next_state[2]  = lfsr_out[3];
    assign next_state[1]  = lfsr_out[2];
    assign next_state[0]  = lfsr_out[1];
    
    // ========================================================================
    // Sequential Logic - LFSR Register Update
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Active-low asynchronous reset
            // Load seed value, use default if seed is zero
            if (seed == 16'h0000)
                lfsr_out <= DEFAULT_SEED;
            else
                lfsr_out <= seed;
        end
        else if (enable) begin
            // Update LFSR state when enabled
            lfsr_out <= next_state;
        end
        // If enable is low, hold current state
    end
    
    // ========================================================================
    // Output Assignment
    // ========================================================================
    // Random bit output (LSB of current state)
    assign random_bit = lfsr_out[0];
    
endmodule

// ============================================================================
// Alternative Implementation with More Explicit Galois Structure
// ============================================================================
// This version makes the Galois structure more explicit and modular

module galois_lfsr_16bit_v2 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [15:0] seed,
    output reg  [15:0] lfsr_out,
    output wire        random_bit
);

    parameter DEFAULT_SEED = 16'hACE1;
    
    // Tap configuration for x^16 + x^14 + x^13 + x^11 + 1
    parameter [15:0] TAP_MASK = 16'b0010_1100_0000_0000; // Taps at 14, 13, 11
    
    wire feedback;
    wire [15:0] next_state;
    integer i;
    
    assign feedback = lfsr_out[0];
    
    // Generate next state using tap mask
    genvar bit_idx;
    generate
        for (bit_idx = 0; bit_idx < 15; bit_idx = bit_idx + 1) begin : shift_logic
            if (TAP_MASK[bit_idx+1]) begin
                // Position has a tap - XOR with feedback
                assign next_state[bit_idx] = lfsr_out[bit_idx+1] ^ feedback;
            end else begin
                // No tap - just shift
                assign next_state[bit_idx] = lfsr_out[bit_idx+1];
            end
        end
    endgenerate
    
    // MSB always gets feedback (position 16 tap)
    assign next_state[15] = feedback;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_out <= (seed == 16'h0000) ? DEFAULT_SEED : seed;
        end
        else if (enable) begin
            lfsr_out <= next_state;
        end
    end
    
    assign random_bit = lfsr_out[0];
    
endmodule