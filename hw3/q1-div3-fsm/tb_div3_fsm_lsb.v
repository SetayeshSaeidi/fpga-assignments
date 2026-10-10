`timescale 1ns / 1ps

module tb_div3_fsm_lsb;

    // 1. Signal Declarations
    reg clk;
    reg rst;
    reg bit_in;
    wire rem;

    // 2. Instantiate the Device Under Test (DUT)
    div3_fsm_lsb dut (
        .clk(clk),
        .rst(rst),
        .bit_in(bit_in),
        .rem(rem)
    );

    // 3. Clock Generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Test Task
    task check_number;
        input [31:0] value;    // The integer to test
        input integer length;  // How many bits to shift in
        integer i;
        reg final_result;      // Store the result before clock edge
        begin
            
            // Reset FSM
            rst = 1;
            bit_in = 0;
            @(negedge clk);
            rst = 0;

            // Send bits sequentially
            for (i = 0; i < length; i = i + 1) begin
                bit_in = value[i]; // Drive LSB first
                
                // Wait small delay for Mealy output to settle
                #1; 
                
                // CRITICAL FIX: Sample the result BEFORE the clock edge
                // The Mealy output is valid while the current bit is applied to the current state.
                if (i == length - 1) begin
                    final_result = rem;
                end
                
                // Trigger state transition
                @(posedge clk);
            end
            
            // 5. Verify Result
            if (final_result == 0) begin
                if (value % 3 == 0)
                    $display("  -> Result: DIVISIBLE (rem=0) | Status: PASS");
                else
                    $display("  -> Result: DIVISIBLE (rem=0) | Status: FAIL (Expected Non-Divisible)");
            end else begin
                if (value % 3 != 0)
                    $display("  -> Result: Remainder (rem=1) | Status: PASS");
                else
                    $display("  -> Result: Remainder (rem=1) | Status: FAIL (Expected Divisible)");
            end
            
            $display("------------------------------------------------");
        end
    endtask

    // 6. Stimulus
    initial begin
        // Initialize inputs
        rst = 1;
        bit_in = 0;
        #100;
        
        $display("------------------------------------------------");
        $display("STARTING CORRECTED SIMULATION");
        $display("------------------------------------------------");

        // 3 (Binary 11) -> Divisible
        check_number(3, 2);

        // 6 (Binary 110) -> Divisible
        check_number(6, 3);

        // 5 (Binary 101) -> Not Divisible
        check_number(5, 3);

        // 9 (Binary 1001) -> Divisible
        check_number(9, 4);

        // 0 (Binary 0) -> Divisible
        check_number(0, 1);
        
        // 14 (Binary 1110) -> Not Divisible
        check_number(14, 4);
        
        // 43690 (Binary 1010101010101010) -> 43690 % 3 = 1 -> Not Divisible
        check_number(43690, 16);

        $display("SIMULATION COMPLETE");
        $stop;
    end

endmodule
