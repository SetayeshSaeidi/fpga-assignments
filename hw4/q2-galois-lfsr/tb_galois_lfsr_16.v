// ============================================================================
// Testbench for 16-bit Galois LFSR
// ============================================================================
// Description:
//   Comprehensive testbench to verify the functionality of the Galois LFSR
//   - Tests reset functionality
//   - Verifies non-zero state maintenance
//   - Monitors sequence generation for 100+ cycles
//   - Checks for period and uniqueness
// ============================================================================

`timescale 1ns/1ps

module tb_galois_lfsr_16bit();

    // ========================================================================
    // Testbench Signals
    // ========================================================================
    reg         clk;
    reg         rst_n;
    reg         enable;
    reg  [15:0] seed;
    wire [15:0] lfsr_out;
    wire        random_bit;
    
    // Test control
    integer i;
    integer cycle_count;
    reg [15:0] previous_state;
    reg all_zero_detected;
    
    // For period detection
    reg [15:0] initial_state;
    reg period_found;
    integer period_length;
    
    // ========================================================================
    // Device Under Test (DUT) Instantiation
    // ========================================================================
    galois_lfsr_16bit dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .seed(seed),
        .lfsr_out(lfsr_out),
        .random_bit(random_bit)
    );
    
    // ========================================================================
    // Clock Generation
    // ========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock (10ns period)
    end
    
    // ========================================================================
    // Stimulus and Test Procedure
    // ========================================================================
    initial begin
        // Initialize waveform dump
        $dumpfile("galois_lfsr_16bit.vcd");
        $dumpvars(0, tb_galois_lfsr_16bit);
        
        // Initialize signals
        rst_n = 1;
        enable = 0;
        seed = 16'h0000;
        cycle_count = 0;
        all_zero_detected = 0;
        period_found = 0;
        period_length = 0;
        
        $display("========================================");
        $display("16-bit Galois LFSR Testbench");
        $display("========================================");
        $display("Taps: x^16 + x^14 + x^13 + x^11 + 1");
        $display("========================================\n");
        
        // ====================================================================
        // Test 1: Reset with Default Seed
        // ====================================================================
        $display("Test 1: Reset with Default Seed");
        $display("----------------------------------------");
        rst_n = 0;
        seed = 16'h0000; // Will use default seed
        #20;
        rst_n = 1;
        #10;
        $display("After reset with seed=0x0000:");
        $display("  LFSR State: 0x%04h (should be default 0xACE1)", lfsr_out);
        if (lfsr_out == 16'hACE1)
            $display("  ? PASSED: Default seed loaded correctly\n");
        else
            $display("  ? FAILED: Expected 0xACE1, got 0x%04h\n", lfsr_out);
        
        // ====================================================================
        // Test 2: Reset with Custom Seed
        // ====================================================================
        $display("Test 2: Reset with Custom Seed");
        $display("----------------------------------------");
        rst_n = 0;
        seed = 16'h1234;
        #20;
        rst_n = 1;
        #10;
        $display("After reset with seed=0x1234:");
        $display("  LFSR State: 0x%04h", lfsr_out);
        if (lfsr_out == 16'h1234)
            $display("  ? PASSED: Custom seed loaded correctly\n");
        else
            $display("  ? FAILED: Expected 0x1234, got 0x%04h\n", lfsr_out);
        
        // ====================================================================
        // Test 3: Enable/Disable Functionality
        // ====================================================================
        $display("Test 3: Enable/Disable Functionality");
        $display("----------------------------------------");
        enable = 0;
        previous_state = lfsr_out;
        #50; // Wait several clock cycles
        if (lfsr_out == previous_state)
            $display("  ? PASSED: State held when enable=0\n");
        else
            $display("  ? FAILED: State changed when disabled\n");
        
        // ====================================================================
        // Test 4: Sequence Generation (100 cycles)
        // ====================================================================
        $display("Test 4: Sequence Generation (100 cycles)");
        $display("----------------------------------------");
        
        // Reset with a known seed
        rst_n = 0;
        seed = 16'hACE1;
        enable = 0;
        #20;
        rst_n = 1;
        #10;
        
        initial_state = lfsr_out;
        $display("Initial State: 0x%04h\n", initial_state);
        
        enable = 1;
        
        $display("Cycle | LFSR State (Hex) | LFSR State (Binary)      | Random Bit");
        $display("------|------------------|--------------------------|------------");
        
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk);
            #1; // Small delay for signal propagation
            
            // Display every 10th cycle or first 10 cycles
            if (i < 10 || i % 10 == 0) begin
                $display("%5d | 0x%04h           | %016b | %b",
                         i, lfsr_out, lfsr_out, random_bit);
            end
            
            // Check for all-zero state (should never happen)
            if (lfsr_out == 16'h0000) begin
                all_zero_detected = 1;
                $display("\n? ERROR: All-zero state detected at cycle %0d!", i);
            end
            
            // Check if we've returned to initial state (period detection)
            if (i > 0 && lfsr_out == initial_state && !period_found) begin
                period_found = 1;
                period_length = i;
                $display("\n? Period detected: %0d cycles", period_length);
            end
            
            cycle_count = i + 1;
        end
        
        $display("\n");
        
        // ====================================================================
        // Test 5: All-Zero State Check
        // ====================================================================
        $display("Test 5: All-Zero State Check");
        $display("----------------------------------------");
        if (!all_zero_detected)
            $display("  ? PASSED: No all-zero state detected in %0d cycles\n", cycle_count);
        else
            $display("  ? FAILED: All-zero state was detected!\n");
        
        // ====================================================================
        // Test 6: Extended Period Detection
        // ====================================================================
        $display("Test 6: Extended Period Detection");
        $display("----------------------------------------");
        $display("Running extended test to find complete period...");
        $display("(This may take a while - testing up to 65535 cycles)\n");
        
        // Reset to known state
        rst_n = 0;
        seed = 16'hACE1;
        #20;
        rst_n = 1;
        enable = 1;
        #10;
        
        initial_state = lfsr_out;
        period_found = 0;
        
        // Test up to maximum period + some extra
        for (i = 0; i < 66000; i = i + 1) begin
            @(posedge clk);
            #1;
            
            if (i > 0 && lfsr_out == initial_state) begin
                period_found = 1;
                period_length = i;
                $display("? Complete period found: %0d cycles", period_length);
                $display("  Expected for maximum-length LFSR: 65535 (2^16 - 1)");
                
                if (period_length == 65535)
                    $display("  ? PASSED: This is a maximum-length LFSR!\n");
                else
                    $display("  ? WARNING: Not maximum-length (expected 65535)\n");
                
                i = 66000; // Exit loop
            end
            
            // Progress indicator every 10000 cycles
            if (i % 10000 == 0 && i > 0)
                $display("  ... tested %0d cycles", i);
        end
        
        if (!period_found)
            $display("  ? Period not found within 66000 cycles\n");

        // ====================================================================
        // Test Summary
        // ====================================================================
        $display("========================================");
        $display("Test Summary");
        $display("========================================");
        $display("All critical tests completed.");
        $display("Check results above for PASS/FAIL status.");
        $display("========================================\n");
        
        // End simulation
        #100;
        $display("Simulation completed at time %0t", $time);
        $finish;
    end
    
    // ========================================================================
    // Monitoring (Optional - displays all state changes)
    // ========================================================================
    // Uncomment to see all state transitions
    /*
    always @(posedge clk) begin
        if (enable && rst_n) begin
            $display("Time=%0t: LFSR=0x%04h, Bit=%b", $time, lfsr_out, random_bit);
        end
    end
    */
    
    // ========================================================================
    // Timeout Watchdog
    // ========================================================================
    initial begin
        #20000000; // 20ms timeout
        $display("\n? ERROR: Simulation timeout!");
        $finish;
    end

endmodule