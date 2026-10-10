module fir_folded_area_optimized (
    input wire clk,
    input wire rst_n,
    input wire start,                // Pulse to start calculation for current input
    input wire signed [7:0] x_in,    // Input x(n)
    input wire signed [7:0] a, b, c, // Coefficients
    output reg signed [15:0] y,      // Output Y(n)
    output reg valid_out             // High when Y is valid
);

    // Internal Storage for Inputs (x[n], x[n-1], x[n-2])
    reg signed [7:0] x_regs [0:2];
    
    // Accumulator
    reg signed [15:0] acc;

    // State Counter (0 to 2)
    reg [1:0] state;
    
    // Mux Outputs
    reg signed [7:0] mult_op_1; // Operand 1 (Data)
    reg signed [7:0] mult_op_2; // Operand 2 (Coeff)

    // 1. Data Shift Register Logic (Updates only when a new sample 'start' arrives)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_regs[0] <= 0; x_regs[1] <= 0; x_regs[2] <= 0;
            state <= 3; // Idle state
            y <= 0;
            valid_out <= 0;
            acc <= 0;
        end else begin
            if (start) begin
                // Shift in new data
                x_regs[2] <= x_regs[1];
                x_regs[1] <= x_regs[0];
                x_regs[0] <= x_in; 
                state <= 0; // Reset sequence counter
                acc <= 0;   // Reset accumulator
                valid_out <= 0;
            end else if (state < 3) begin
                // Accumulate results: Acc = Acc + (Data * Coeff)
                acc <= acc + (mult_op_1 * mult_op_2);
                
                if (state == 2) begin
                    y <= acc + (mult_op_1 * mult_op_2); // Final sum
                    valid_out <= 1;
                    state <= 3; // Go to idle
                end else begin
                    state <= state + 1;
                end
            end
        end
    end

    // 2. Multiplexer Logic (Resource Sharing)
    // Selects which data and which coeff to feed the SINGLE multiplier
    always @(*) begin
        case (state)
            2'd0: begin // Calculation for c * x[n-2]
                mult_op_1 = x_regs[2];
                mult_op_2 = c;
            end
            2'd1: begin // Calculation for b * x[n-1]
                mult_op_1 = x_regs[1];
                mult_op_2 = b;
            end
            2'd2: begin // Calculation for a * x[n]
                mult_op_1 = x_regs[0];
                mult_op_2 = a;
            end
            default: begin
                mult_op_1 = 0;
                mult_op_2 = 0;
            end
        endcase
    end

endmodule
