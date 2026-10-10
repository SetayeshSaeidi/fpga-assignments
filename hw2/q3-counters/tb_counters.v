`timescale 1ns / 1ps
`include "counter_structural.v"
`include "counter_behavioral.v"
`include "jk_ff.v"

module tb_counters;

    // ==========================================
    // 1. Signal Declarations
    // ==========================================
    reg clk;
    reg rst_n;

    // Outputs from the Structural Counter (Ripple)
    wire [3:0] q_structural;

    // Outputs from the Behavioral Counter (Synchronous)
    wire [3:0] q_behavioral;

    // ==========================================
    // 2. Instantiate Designs (DUTs)
    // ==========================================

    // DUT 1: The Structural JK Ripple Counter
    counter_structural dut_struct (
        .clk(clk), 
        .rst_n(rst_n), 
        .q_out(q_structural)
    );

    // DUT 2: The Behavioral "Always Block" Counter
    counter_behavioral dut_behav (
        .clk(clk), 
        .rst_n(rst_n), 
        .q_out(q_behavioral)
    );

    // ==========================================
    // 3. Clock Generation
    // ==========================================
    // Generate a clock with 10ns period (100MHz)
    always #5 clk = ~clk;

    // ==========================================
    // 4. Test Stimulus
    // ==========================================
    initial begin
        // Setup Waveform Dump for viewers like GTKWave or Vivado
        $dumpfile("counter_waves.vcd");
        $dumpvars(0, tb_counters);

        // Initialize Inputs
        clk = 0;
        rst_n = 0; // Assert Reset (Active Low)

        $display("---------------------------------------------------------");
        $display("Time | Reset | Struct (Ripple) | Behav (Sync) | Note");
        $display("---------------------------------------------------------");
        
        // Wait for a few cycles in Reset
        #20;
        
        // Release Reset
        rst_n = 1;
        $display("%4t |   %b   |      %d        |      %d       | Reset Released", $time, rst_n, q_structural, q_behavioral);

        // Run for 20 clock cycles to watch them count from 0 to 15 (and overflow)
        repeat (20) begin
            @(negedge clk); // Checking at negedge because our counters are negedge triggered
            #1; // Small delay to allow outputs to settle for printing
            $display("%4t |   %b   |      %d        |      %d       | Count", $time, rst_n, q_structural, q_behavioral);
        end

        // Apply Reset again to verify reset functionality
        rst_n = 0;
        #10;
        $display("%4t |   %b   |      %d        |      %d       | Reset Applied", $time, rst_n, q_structural, q_behavioral);
        
        // End Simulation
        #20;
        $finish;
    end

endmodule
