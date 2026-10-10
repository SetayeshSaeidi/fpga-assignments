/*
 * Multi-Mode CORDIC Module (Rotation Mode)
 * Supports Circular (m=1) and Linear (m=0) modes
 * 
 * Fixed-point representation: 32-bit signed (Q4.28 format)
 * - 1 sign bit
 * - 3 integer bits
 * - 28 fractional bits
 * 
 * Modes:
 * - mode = 0: Linear mode (multiplication)
 * - mode = 1: Circular mode (sin/cos)
 */

module cordic_multimode #(
    parameter WIDTH = 32,        // Total bit width
    parameter FRAC_BITS = 28,    // Fractional bits
    parameter ITERATIONS = 16    // Number of CORDIC iterations
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire mode,              // 0: Linear, 1: Circular
    input wire signed [WIDTH-1:0] x_in,
    input wire signed [WIDTH-1:0] y_in,
    input wire signed [WIDTH-1:0] z_in,
    output reg signed [WIDTH-1:0] x_out,
    output reg signed [WIDTH-1:0] y_out,
    output reg signed [WIDTH-1:0] z_out,
    output reg valid
);

    // State machine
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state;
    reg [4:0] iteration;
    
    // CORDIC variables
    reg signed [WIDTH-1:0] x_reg, y_reg, z_reg;
    reg signed [WIDTH-1:0] x_next, y_next, z_next;
    reg mode_reg;
    
    // Direction signal
    wire d;
    assign d = z_reg[WIDTH-1]; // Sign bit (1 if negative)
    
    // Precomputed arctangent table for circular mode (in Q4.28 format)
    // atan(2^-i) values
    reg signed [WIDTH-1:0] atan_table [0:ITERATIONS-1];
    
    // Linear mode table (2^-i values in Q4.28 format)
    reg signed [WIDTH-1:0] linear_table [0:ITERATIONS-1];
    
    // Initialize lookup tables
    initial begin
        // Circular mode: atan(2^-i) in radians, scaled by 2^28
        atan_table[0]  = 32'h0C90FDA9;  // atan(2^0)  = 0.7853981634
        atan_table[1]  = 32'h076B19C1;  // atan(2^-1) = 0.4636476090
        atan_table[2]  = 32'h03EB6EBF;  // atan(2^-2) = 0.2449786631
        atan_table[3]  = 32'h01FD5BA9;  // atan(2^-3) = 0.1243549945
        atan_table[4]  = 32'h00FFAADE;  // atan(2^-4) = 0.0624188100
        atan_table[5]  = 32'h007FF556;  // atan(2^-5) = 0.0312398334
        atan_table[6]  = 32'h003FFEAA;  // atan(2^-6) = 0.0156237286
        atan_table[7]  = 32'h001FFFD5;  // atan(2^-7) = 0.0078123410
        atan_table[8]  = 32'h000FFFFA;  // atan(2^-8) = 0.0039062301
        atan_table[9]  = 32'h0007FFFF;  // atan(2^-9) = 0.0019531225
        atan_table[10] = 32'h00040000;  // atan(2^-10) = 0.0009765622
        atan_table[11] = 32'h00020000;  // atan(2^-11) = 0.0004882812
        atan_table[12] = 32'h00010000;  // atan(2^-12) = 0.0002441406
        atan_table[13] = 32'h00008000;  // atan(2^-13) = 0.0001220703
        atan_table[14] = 32'h00004000;  // atan(2^-14) = 0.0000610352
        atan_table[15] = 32'h00002000;  // atan(2^-15) = 0.0000305176
        
        // Linear mode: 2^-i values in Q4.28 format
        linear_table[0]  = 32'h10000000;  // 2^0  = 1.0
        linear_table[1]  = 32'h08000000;  // 2^-1 = 0.5
        linear_table[2]  = 32'h04000000;  // 2^-2 = 0.25
        linear_table[3]  = 32'h02000000;  // 2^-3 = 0.125
        linear_table[4]  = 32'h01000000;  // 2^-4
        linear_table[5]  = 32'h00800000;  // 2^-5
        linear_table[6]  = 32'h00400000;  // 2^-6
        linear_table[7]  = 32'h00200000;  // 2^-7
        linear_table[8]  = 32'h00100000;  // 2^-8
        linear_table[9]  = 32'h00080000;  // 2^-9
        linear_table[10] = 32'h00040000;  // 2^-10
        linear_table[11] = 32'h00020000;  // 2^-11
        linear_table[12] = 32'h00010000;  // 2^-12
        linear_table[13] = 32'h00008000;  // 2^-13
        linear_table[14] = 32'h00004000;  // 2^-14
        linear_table[15] = 32'h00002000;  // 2^-15
    end
    
    // Shifted values for current iteration
    wire signed [WIDTH-1:0] x_shifted, y_shifted;
    assign x_shifted = x_reg >>> iteration;  // Arithmetic right shift
    assign y_shifted = y_reg >>> iteration;
    
    // Select appropriate table value based on mode
    wire signed [WIDTH-1:0] z_adjustment;
    assign z_adjustment = mode_reg ? atan_table[iteration] : linear_table[iteration];
    
    // CORDIC iteration logic
    always @(*) begin
        if (mode_reg) begin
            // Circular mode (m=1)
            if (d) begin  // z is negative, rotate clockwise
                x_next = x_reg + y_shifted;
                y_next = y_reg - x_shifted;
                z_next = z_reg + z_adjustment;
            end else begin  // z is positive, rotate counter-clockwise
                x_next = x_reg - y_shifted;
                y_next = y_reg + x_shifted;
                z_next = z_reg - z_adjustment;
            end
        end else begin
            // Linear mode (m=0)
            if (d) begin  // z is negative
                x_next = x_reg;  // x remains constant
                y_next = y_reg - x_shifted;
                z_next = z_reg + z_adjustment;
            end else begin  // z is positive
                x_next = x_reg;  // x remains constant
                y_next = y_reg + x_shifted;
                z_next = z_reg - z_adjustment;
            end
        end
    end
    
    // State machine and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            iteration <= 0;
            x_reg <= 0;
            y_reg <= 0;
            z_reg <= 0;
            x_out <= 0;
            y_out <= 0;
            z_out <= 0;
            valid <= 0;
            mode_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 0;
                    if (start) begin
                        x_reg <= x_in;
                        y_reg <= y_in;
                        z_reg <= z_in;
                        mode_reg <= mode;
                        iteration <= 0;
                        state <= COMPUTE;
                    end
                end
                
                COMPUTE: begin
                    x_reg <= x_next;
                    y_reg <= y_next;
                    z_reg <= z_next;
                    
                    if (iteration == ITERATIONS - 1) begin
                        state <= DONE;
                    end else begin
                        iteration <= iteration + 1;
                    end
                end
                
                DONE: begin
                    x_out <= x_reg;
                    y_out <= y_reg;
                    z_out <= z_reg;
                    valid <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

/*
 * CORDIC Wrapper Module
 * Provides easy-to-use interfaces for common operations
 */

module cordic_wrapper #(
    parameter WIDTH = 32,
    parameter FRAC_BITS = 28,
    parameter ITERATIONS = 16
)(
    input wire clk,
    input wire rst_n,
    
    // Control signals
    input wire start,
    input wire [1:0] operation,  // 0: sin/cos, 1: multiply
    
    // Inputs
    input wire signed [WIDTH-1:0] angle,      // For sin/cos
    input wire signed [WIDTH-1:0] mult_a,     // For multiplication
    input wire signed [WIDTH-1:0] mult_b,     // For multiplication
    
    // Outputs
    output wire signed [WIDTH-1:0] cos_out,
    output wire signed [WIDTH-1:0] sin_out,
    output wire signed [WIDTH-1:0] mult_out,
    output wire valid
);

    // K_circular = 1.646760258 in Q4.28 format
    // 1/K_circular = 0.607252935 in Q4.28 format
    localparam signed [WIDTH-1:0] INV_K_CIRCULAR = 32'h09B74EDC;
    
    // CORDIC inputs
    reg signed [WIDTH-1:0] x_in, y_in, z_in;
    reg mode;
    reg cordic_start;
    
    // CORDIC outputs
    wire signed [WIDTH-1:0] x_out, y_out, z_out;
    wire cordic_valid;
    
    // Instantiate CORDIC core
    cordic_multimode #(
        .WIDTH(WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .ITERATIONS(ITERATIONS)
    ) cordic_core (
        .clk(clk),
        .rst_n(rst_n),
        .start(cordic_start),
        .mode(mode),
        .x_in(x_in),
        .y_in(y_in),
        .z_in(z_in),
        .x_out(x_out),
        .y_out(y_out),
        .z_out(z_out),
        .valid(cordic_valid)
    );
    
    // Operation handling
    always @(*) begin
        case (operation)
            2'b00: begin  // Sin/Cos calculation
                mode = 1'b1;  // Circular mode
                x_in = INV_K_CIRCULAR;
                y_in = 32'h00000000;
                z_in = angle;
                cordic_start = start;
            end
            
            2'b01: begin  // Multiplication
                mode = 1'b0;  // Linear mode
                x_in = mult_a;
                y_in = 32'h00000000;
                z_in = mult_b;
                cordic_start = start;
            end
            
            default: begin
                mode = 1'b0;
                x_in = 32'h00000000;
                y_in = 32'h00000000;
                z_in = 32'h00000000;
                cordic_start = 1'b0;
            end
        endcase
    end
    
    // Output assignments
    assign cos_out = x_out;
    assign sin_out = y_out;
    assign mult_out = y_out;
    assign valid = cordic_valid;

endmodule

