`timescale 1ns / 1ps

module tb_adjustable_counter;

    // Inputs
    reg clk;
    reg rst;
    reg [7:0] speed_setting;

    // Outputs
    wire [7:0] count_val;

    // Instantiate the Unit Under Test (UUT)
    adjustable_counter uut (
        .clk(clk), 
        .rst(rst), 
        .speed_setting(speed_setting), 
        .count_val(count_val)
    );

    // Clock generation (10ns period / 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Stimulus
    initial begin
        // Monitor allows us to see the values whenever they change
        // uut.ce_wire lets us peek at the internal enable signal
        $monitor("Time=%0tns | Speed_Set=%0d | CE_Pulse=%b | Count=%0d", 
                 $time, speed_setting, uut.ce_wire, count_val);

        // -----------------------------------------------------------
        // Test Case 1: Full Speed (Setting = 0)
        // Expected: CE is HIGH continuously. Count increments every cycle.
        // -----------------------------------------------------------
        $display("\n--- Testing Full Speed (Setting 0) ---");
        rst = 1;
        speed_setting = 0;
        #20;       // Hold reset
        rst = 0;   // Release reset
        #60;       // Run for 60ns (6 clocks)

        // -----------------------------------------------------------
        // Test Case 2: Half Speed (Setting = 1)
        // Expected: CE is HIGH every 2nd cycle. Count increments every 20ns.
        // -----------------------------------------------------------
        $display("\n--- Testing Half Speed (Setting 1: Divide by 2) ---");
        rst = 1;   // Reset to clear count for clarity
        speed_setting = 1;
        #10;
        rst = 0;
        #100;      // Run for 100ns

        // -----------------------------------------------------------
        // Test Case 3: Quarter Speed (Setting = 3)
        // Expected: CE is HIGH every 4th cycle. Count increments every 40ns.
        // -----------------------------------------------------------
        $display("\n--- Testing Quarter Speed (Setting 3: Divide by 4) ---");
        rst = 1;
        speed_setting = 3;
        #10;
        rst = 0;
        #120;      // Run for 120ns

        $display("\nTest Completed.");
        $finish;
    end
      
endmodule
