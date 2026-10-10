`timescale 1ns / 1ps

module tb_TwoStackFIFO;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter DEPTH = 4; // Small depth to easily test "Full" condition

    // Inputs
    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] din;

    // Outputs
    wire [DATA_WIDTH-1:0] dout;
    wire full;
    wire empty;
    wire busy;

    // Instantiate the Unit Under Test (UUT)
    TwoStackFIFO #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .clk(clk), 
        .rst(rst), 
        .wr_en(wr_en), 
        .rd_en(rd_en), 
        .din(din), 
        .dout(dout), 
        .full(full), 
        .empty(empty), 
        .busy(busy)
    );

    // Clock Generation (10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Helper Task: Write to FIFO ---
    task write_fifo(input [DATA_WIDTH-1:0] val);
        begin
            if (full) begin
                $display("Warning: FIFO Full, cannot write %d", val);
            end else begin
                @(posedge clk);
                wr_en = 1;
                din = val;
                @(posedge clk); // Hold for 1 cycle
                wr_en = 0;
                $display("[Time %0t] Wrote %d to FIFO", $time, val);
            end
        end
    endtask

    // --- Helper Task: Read from FIFO ---
    // This task handles the complexity of the 2-stack transfer delay
    task read_fifo;
        begin
            // 1. Request Read
            @(posedge clk);
            rd_en = 1;
            
            // 2. Allow logic to react (check if it goes Busy)
            @(posedge clk); 
            rd_en = 0; // De-assert after 1 cycle pulse

            // 3. Check if the FIFO entered "Busy" mode (Transferring A->B)
            if (busy) begin
                $display("[Time %0t] FIFO is BUSY (Transferring Stack A -> B)... Waiting.", $time);
                wait(busy == 0); // Wait until transfer finishes
                @(posedge clk);  // Sync to clock
                $display("[Time %0t] Transfer Complete.", $time);
                
                // 4. Now that transfer is done, the data is in Stack B.
                // We need to issue the read command again to actually pop the data.
                rd_en = 1;
                @(posedge clk);
                rd_en = 0;
            end

            // 5. Sample the Output
            // Note: In this architecture, dout shows valid data before pop if Stack B has data.
            // The pop happens on the clock edge. We sample the data that *was* there.
            $display("[Time %0t] Read Value: %d", $time, dout);
        end
    endtask

    // --- Main Test Stimulus ---
    initial begin
        // Initialize
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        din = 0;

        // Reset Pulse
        #20;
        rst = 0;
        $display("=== Simulation Start ===");
        #10;

        // ------------------------------------------------------------
        // Scenario 1: Fill Stack A (Write 10, 20, 30)
        // ------------------------------------------------------------
        $display("\n--- Step 1: Writing 10, 20, 30 ---");
        write_fifo(8'd10);
        write_fifo(8'd20);
        write_fifo(8'd30);
        
        // Check internals (optional, specific to verification)
        if (uut.a_empty == 0 && uut.b_empty == 1) 
            $display("Check: Stack A has data, Stack B is empty. (Correct)");

        // ------------------------------------------------------------
        // Scenario 2: Read (Triggers Transfer A -> B)
        // ------------------------------------------------------------
        $display("\n--- Step 2: Requesting Read (Should trigger transfer) ---");
        // This first read will detect B is empty, trigger the Move FSM, wait, 
        // then pop the first value (10).
        read_fifo(); 

        // ------------------------------------------------------------
        // Scenario 3: Continue Reading (No transfer needed)
        // ------------------------------------------------------------
        $display("\n--- Step 3: Reading remaining items (Should be immediate) ---");
        // Stack B now holds [30, 20] (Top is 20).
        // 10 was already popped in the previous task.
        read_fifo(); // Should get 20
        read_fifo(); // Should get 30

        if (empty) $display("Check: FIFO is empty. (Correct)");

        // ------------------------------------------------------------
        // Scenario 4: Interleaved Write/Read
        // ------------------------------------------------------------
        $display("\n--- Step 4: Interleaved Operations ---");
        write_fifo(8'd44);
        write_fifo(8'd55);
        
        // Read 44 (Will trigger transfer of 44, 55 to B)
        read_fifo(); // Expect 44
        
        write_fifo(8'd66); // Write 66 into A (B still has 55)
        
        read_fifo(); // Should read 55 (From B) - No transfer needed
        read_fifo(); // Should read 66 (B empty, triggers transfer of A->B)

        $display("\n=== Test Completed ===");
        $finish;
    end

endmodule
