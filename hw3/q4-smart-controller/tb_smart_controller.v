`timescale 1ns / 1ps

module tb_smart_controller;

    // Inputs
    reg clk;
    reg rst;
    reg btn_async;

    // Outputs
    wire appliance_on;
    wire fault_status;

    // Instantiate the Unit Under Test (UUT)
    smart_controller uut (
        .clk(clk), 
        .rst(rst), 
        .btn_async(btn_async), 
        .appliance_on(appliance_on), 
        .fault_status(fault_status)
    );
    
    // Override the Debounce parameter to make simulation faster
    // (Default was large, we set it to 4 for testing bounce filtering)
    defparam uut.DEBOUNCE_LIMIT = 4;

    // Clock Generation (10ns period -> 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Task to simulate a Bouncy Button Press ---
    // This simulates the messy signal of a physical switch
    task press_button_noisy;
        begin
            $display("[Time %0t] Button Pressed (Noisy)", $time);
            // Bounce low-high-low rapidly
            btn_async = 1; #12; 
            btn_async = 0; #8;
            btn_async = 1; #5;
            btn_async = 0; #5;
            
            // Finally settle at High (Stable press)
            btn_async = 1; 
            #100; // Hold for a while (longer than debounce limit)
            
            // Release with bounce
            $display("[Time %0t] Button Released (Noisy)", $time);
            btn_async = 0; #7;
            btn_async = 1; #6;
            btn_async = 0; 
            #50;
        end
    endtask

    // Main Test Stimulus
    initial begin
        // Initialize
        rst = 1;
        btn_async = 0;
        
        // 1. Reset Sequence
        $display("--- Test Case 1: Power On Reset ---");
        #20;
        rst = 0;
        #10; // Wait for state transition Reset -> Idle
        if (uut.current_state == 2'b01) // S_IDLE
            $display("State Check: System correctly entered IDLE.");
        else
            $display("State Check: FAILED to enter IDLE.");

        // 2. Normal Operation
        $display("\n--- Test Case 2: Valid Activation (Noisy Press) ---");
        press_button_noisy();
        
        // Check if Appliance turned ON
        if (appliance_on) 
            $display("Output Check: Appliance ON (Correct)");
        
        // Wait for the 10-cycle timer to finish
        wait(appliance_on == 0); 
        $display("[Time %0t] Appliance Auto-OFF (Timer Complete)", $time);
        
        #50; // Wait in Idle

        // 3. Error Trigger Test
        $display("\n--- Test Case 3: Error Trigger (Double Press) ---");
        
        // First Press: Activate System
        btn_async = 1; #60; btn_async = 0; // Clean press for simplicity here
        #20; // Wait a few cycles (System is now in ACTIVE state)
        
        if (uut.current_state == 2'b10) $display("State: ACTIVE");

        // Second Press: While Active
        $display("[Time %0t] Interrupting with Second Button Press!", $time);
        btn_async = 1; #60; btn_async = 0;

        #20;
        if (fault_status == 1 && uut.current_state == 2'b11) 
            $display("State Check: System entered ERROR state correctly.");
        else 
            $display("State Check: FAILED (Did not enter Error).");

        // 4. Reset from Error
        $display("\n--- Test Case 4: Recover from Error ---");
        rst = 1; 
        #20; 
        rst = 0;
        #10;
        if (fault_status == 0 && uut.current_state == 2'b01)
            $display("Recovery Check: System Reset to IDLE.");

        $display("\nTest Completed.");
        $finish;
    end
      
endmodule
