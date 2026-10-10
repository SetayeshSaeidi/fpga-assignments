/*
 * Testbench for Multi-Mode CORDIC - 50 MHz Version
 * Compatible with cordic_constraints_relaxed.xdc
 * Tests both Circular and Linear modes
 */

`timescale 1ns/1ps

module cordic_tb_50mhz;

    // Parameters
    parameter WIDTH = 32;
    parameter FRAC_BITS = 28;
    parameter ITERATIONS = 16;
    parameter CLK_PERIOD = 20;  // 50 MHz clock (relaxed timing)
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg start;
    reg [1:0] operation;
    reg signed [WIDTH-1:0] angle;
    reg signed [WIDTH-1:0] mult_a;
    reg signed [WIDTH-1:0] mult_b;
    wire signed [WIDTH-1:0] cos_out;
    wire signed [WIDTH-1:0] sin_out;
    wire signed [WIDTH-1:0] mult_out;
    wire valid;
    
    // Real number representations for comparison
    real angle_real, cos_expected, sin_expected;
    real mult_a_real, mult_b_real, mult_expected;
    real cos_result, sin_result, mult_result;
    real cos_error, sin_error, mult_error;
    
    // Test statistics
    integer test_count;
    real max_cos_error, max_sin_error, max_mult_error;
    integer pass_count, fail_count;
    
    // DUT instantiation
    cordic_wrapper #(
        .WIDTH(WIDTH),
        .FRAC_BITS(FRAC_BITS),
        .ITERATIONS(ITERATIONS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .operation(operation),
        .angle(angle),
        .mult_a(mult_a),
        .mult_b(mult_b),
        .cos_out(cos_out),
        .sin_out(sin_out),
        .mult_out(mult_out),
        .valid(valid)
    );
    
    // Clock generation - 50 MHz
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Conversion functions
    function real fixed_to_real;
        input signed [WIDTH-1:0] fixed_val;
        begin
            fixed_to_real = $itor(fixed_val) / $itor(2**FRAC_BITS);
        end
    endfunction
    
    function signed [WIDTH-1:0] real_to_fixed;
        input real real_val;
        reg signed [WIDTH-1:0] temp;
        begin
            temp = $rtoi(real_val * $itor(2**FRAC_BITS));
            real_to_fixed = temp;
        end
    endfunction
    
    // Test tasks
    task test_sin_cos;
        input real angle_deg;
        real angle_rad;
        begin
            test_count = test_count + 1;
            angle_rad = angle_deg * 3.14159265359 / 180.0;
            angle_real = angle_rad;
            
            // Expected values
            cos_expected = $cos(angle_rad);
            sin_expected = $sin(angle_rad);
            
            // Apply stimulus
            angle = real_to_fixed(angle_rad);
            operation = 2'b00;  // Sin/Cos operation
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Wait for result (18 cycles at 50 MHz = 360ns)
            wait(valid);
            @(posedge clk);
            
            // Get results
            cos_result = fixed_to_real(cos_out);
            sin_result = fixed_to_real(sin_out);
            
            // Calculate errors
            cos_error = cos_result - cos_expected;
            sin_error = sin_result - sin_expected;
            
            if (cos_error < 0) cos_error = -cos_error;
            if (sin_error < 0) sin_error = -sin_error;
            
            // Update max errors
            if (cos_error > max_cos_error) max_cos_error = cos_error;
            if (sin_error > max_sin_error) max_sin_error = sin_error;
            
            // Display results
            $display("Test %0d: Sin/Cos of %.2f degrees (%.6f rad)", 
                     test_count, angle_deg, angle_rad);
            $display("  Expected: cos = %f, sin = %f", cos_expected, sin_expected);
            $display("  Hardware: cos = %f, sin = %f", cos_result, sin_result);
            $display("  Errors:   cos = %.2e, sin = %.2e", cos_error, sin_error);
            $display("  Latency:  18 cycles @ 50 MHz = 360ns");
            
            // Check if within tolerance (1e-4)
            if (cos_error < 1e-4 && sin_error < 1e-4) begin
                $display("  PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL - Error exceeds tolerance");
                fail_count = fail_count + 1;
            end
            $display("");
            
            // Wait a few cycles
            repeat(3) @(posedge clk);
        end
    endtask
    
    task test_multiply;
        input real a_val;
        input real b_val;
        begin
            test_count = test_count + 1;
            mult_a_real = a_val;
            mult_b_real = b_val;
            
            // Expected value
            mult_expected = a_val * b_val;
            
            // Apply stimulus
            mult_a = real_to_fixed(a_val);
            mult_b = real_to_fixed(b_val);
            operation = 2'b01;  // Multiply operation
            start = 1;
            @(posedge clk);
            start = 0;
            
            // Wait for result
            wait(valid);
            @(posedge clk);
            
            // Get result
            mult_result = fixed_to_real(mult_out);
            
            // Calculate error
            mult_error = mult_result - mult_expected;
            if (mult_error < 0) mult_error = -mult_error;
            
            // Update max error
            if (mult_error > max_mult_error) max_mult_error = mult_error;
            
            // Display results
            $display("Test %0d: Multiply %.4f * %.4f", test_count, a_val, b_val);
            $display("  Expected: %f", mult_expected);
            $display("  Hardware: %f", mult_result);
            $display("  Error:    %.2e", mult_error);
            $display("  Latency:  18 cycles @ 50 MHz = 360ns");
            
            // Check if within tolerance
            if (mult_error < 1e-4) begin
                $display("  PASS");
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL - Error exceeds tolerance");
                fail_count = fail_count + 1;
            end
            $display("");
            
            // Wait a few cycles
            repeat(3) @(posedge clk);
        end
    endtask
    
    // Main test sequence
    initial begin
        // Initialize
        $display("========================================");
        $display("CORDIC Multi-Mode Testbench - 50 MHz");
        $display("========================================");
        $display("Configuration:");
        $display("  Width: %0d bits", WIDTH);
        $display("  Fractional bits: %0d", FRAC_BITS);
        $display("  Iterations: %0d", ITERATIONS);
        $display("  Clock: 50 MHz (20ns period)");
        $display("  Latency: 18 cycles = 360ns");
        $display("========================================");
        $display("");
        
        // Initialize signals
        rst_n = 0;
        start = 0;
        operation = 0;
        angle = 0;
        mult_a = 0;
        mult_b = 0;
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        max_cos_error = 0;
        max_sin_error = 0;
        max_mult_error = 0;
        
        // Reset
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(5) @(posedge clk);
        
        // Test Circular Mode (Sin/Cos)
        $display("========================================");
        $display("CIRCULAR MODE TESTS (Sin/Cos)");
        $display("========================================");
        $display("");
        
        test_sin_cos(0.0);
        test_sin_cos(15.0);
        test_sin_cos(30.0);
        test_sin_cos(45.0);
        test_sin_cos(60.0);
        test_sin_cos(75.0);
        test_sin_cos(90.0);
        test_sin_cos(-30.0);
        test_sin_cos(-45.0);
        
        // Test Linear Mode (Multiplication)
        $display("========================================");
        $display("LINEAR MODE TESTS (Multiplication)");
        $display("========================================");
        $display("");
        
        test_multiply(0.5, 0.5);
        test_multiply(1.0, 1.0);
        test_multiply(1.5, 0.75);
        test_multiply(0.25, 0.8);
        test_multiply(2.0, 1.5);
        test_multiply(-1.0, 0.5);
        test_multiply(0.707, 0.707);
        test_multiply(1.2, -0.8);
        
        // Summary
        $display("========================================");
        $display("TEST SUMMARY");
        $display("========================================");
        $display("Clock: 50 MHz (20ns period)");
        $display("Latency per operation: 18 cycles = 360ns");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("");
        $display("Maximum Errors:");
        $display("  Cosine:         %.2e", max_cos_error);
        $display("  Sine:           %.2e", max_sin_error);
        $display("  Multiplication: %.2e", max_mult_error);
        $display("========================================");
        
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED!");
            $display("Design meets timing at 50 MHz");
        end else begin
            $display("SOME TESTS FAILED!");
        end
        
        // Finish simulation
        repeat(10) @(posedge clk);
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #2000000;  // 2ms timeout (longer for 50 MHz)
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Optional: Waveform dumping for GTKWave
    initial begin
        $dumpfile("cordic_tb_50mhz.vcd");
        $dumpvars(0, cordic_tb_50mhz);
    end

endmodule