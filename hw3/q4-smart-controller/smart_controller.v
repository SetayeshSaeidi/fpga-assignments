`timescale 1ns / 1ps

module smart_controller(
    input wire clk,             // System Clock
    input wire rst,             // System Reset (Active High)
    input wire btn_async,       // Raw asynchronous button input
    output reg appliance_on,    // Output to Appliance
    output reg fault_status     // Error indicator
    );

    // =========================================================================
    // PART 1: Input Conditioning Logic
    // Addresses: (a) Asynchronous input, (b) Switch bouncing, (c) Clean events
    // =========================================================================

    // 1. Synchronization Chain
    // Prevents metastability by passing the async signal through 2 Flip-Flops.
    reg btn_meta, btn_sync;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_meta <= 0;
            btn_sync <= 0;
        end else begin
            btn_meta <= btn_async;
            btn_sync <= btn_meta;
        end
    end

    // 2. Debouncing Logic
    // Filters out mechanical bouncing. The signal must be stable for DEBOUNCE_LIMIT
    // clock cycles before it is accepted as a valid change.
    // For a 50MHz clock, 10ms ~ 500,000 cycles.
    // For simulation/testing, we use a smaller value (e.g., 20).
    parameter DEBOUNCE_LIMIT = 20; 
    reg [19:0] debounce_cnt;
    reg btn_debounced;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            debounce_cnt <= 0;
            btn_debounced <= 0;
        end else begin
            if (btn_sync != btn_debounced) begin
                // Input different from current state? Increment counter.
                debounce_cnt <= debounce_cnt + 1;
                if (debounce_cnt >= DEBOUNCE_LIMIT) begin
                    btn_debounced <= btn_sync; // Acceptance
                    debounce_cnt <= 0;
                end
            end else begin
                // Input matches state? Reset counter (noise glitch).
                debounce_cnt <= 0;
            end
        end
    end

    // 3. Edge Detection
    // Converts the long "High" duration of a press into a single-cycle pulse.
    // This ensures "Multiple state transitions" don't happen for one press.
    reg btn_prev;
    wire btn_event;

    always @(posedge clk or posedge rst) begin
        if (rst) btn_prev <= 0;
        else     btn_prev <= btn_debounced;
    end

    // Pulse is High ONLY on the rising edge (0 -> 1)
    assign btn_event = btn_debounced & ~btn_prev;


    // =========================================================================
    // PART 2: Main Controller FSM
    // Implements the 4-state system behavior
    // =========================================================================

    // State Encoding
    localparam [1:0]
        S_RESET  = 2'b00,
        S_IDLE   = 2'b01,
        S_ACTIVE = 2'b10,
        S_ERROR  = 2'b11;

    reg [1:0] current_state, next_state;
    reg [3:0] timer_cnt; // 4-bit counter to count up to 10
    
    // Timer Logic
    // We need a counter that only runs in the ACTIVE state.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            timer_cnt <= 0;
        end else begin
            if (current_state == S_ACTIVE) 
                timer_cnt <= timer_cnt + 1;
            else 
                timer_cnt <= 0;
        end
    end

    // Sequential State Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= S_RESET;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational Next State Logic
    always @(*) begin
        // Defaults
        next_state = current_state;
        
        case (current_state)
            // (a) Reset: Auto-transition to Idle
            S_RESET: begin
                next_state = S_IDLE;
            end

            // (b) Idle: Wait for valid button event
            S_IDLE: begin
                if (btn_event) begin
                    next_state = S_ACTIVE;
                end
            end

            // (c) Active: Appliance ON for 10 cycles
            S_ACTIVE: begin
                // Priority: "If user generates another button event... immediate Error"
                if (btn_event) begin
                    next_state = S_ERROR;
                end
                // Requirement: "Remains active for exactly 10 clock cycles"
                // Note: timer_cnt starts at 0 upon entry.
                // When count reaches 9 (0 to 9 is 10 cycles), we leave.
                else if (timer_cnt == 9) begin 
                    next_state = S_IDLE;
                end
            end

            // (d) Error: Lock until reset
            S_ERROR: begin
                // Remains in this state until reset (handled by synchronous reset block)
                next_state = S_ERROR; 
            end
            
            default: next_state = S_RESET;
        endcase
    end

    // Output Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            appliance_on <= 0;
            fault_status <= 0;
        end else begin
            // Outputs based on state
            case (next_state) // Using next_state for Mealy-like fast response or current_state for Moore
                S_ACTIVE: appliance_on <= 1;
                S_ERROR:  fault_status <= 1; // Latch fault
                default:  appliance_on <= 0;
            endcase
            
            // Explicitly clear fault only on Reset (handled above), 
            // but ensure appliance is off in non-Active states.
            if (next_state != S_ACTIVE) appliance_on <= 0;
        end
    end

endmodule
