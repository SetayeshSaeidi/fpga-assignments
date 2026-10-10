`timescale 1ns / 1ps

module Stack #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter PTR_WIDTH = 4 // Log2(DEPTH)
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  push,
    input  wire                  pop,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    output wire                  full,
    output wire                  empty
);

    // Memory storage
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH:0]    ptr; // Extra bit for full/empty distinction if needed, 
                              // though here ptr=0 is empty, ptr=DEPTH is full.

    // Status Flags
    assign empty = (ptr == 0);
    assign full  = (ptr == DEPTH);
    
    // Read logic (asynchronous read for 0-latency access, synchronous write)
    // Note: We check ptr > 0 to avoid reading out of bounds underflow, 
    // though the FSM prevents this.
    assign dout = (ptr > 0) ? mem[ptr - 1] : {DATA_WIDTH{1'b0}};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ptr <= 0;
        end else begin
            if (push && !full) begin
                mem[ptr] <= din;
                ptr <= ptr + 1;
            end else if (pop && !empty) begin
                ptr <= ptr - 1;
            end
        end
    end

endmodule

module TwoStackFIFO #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  wr_en,
    input  wire                  rd_en,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    output wire                  full,
    output wire                  empty,
    output reg                   busy // Indicates internal transfer operation
);

    // Parameters for Stack Pointer
    localparam PTR_WIDTH = $clog2(DEPTH);

    // Internal Signals
    wire a_full, a_empty, b_full, b_empty;
    wire [DATA_WIDTH-1:0] a_dout;
    
    reg a_push, a_pop;
    reg b_push, b_pop;
    reg [DATA_WIDTH-1:0] b_din;

    // State Machine Definition
    localparam STATE_IDLE      = 2'b00;
    localparam STATE_MOVE_POP  = 2'b01;
    localparam STATE_MOVE_PUSH = 2'b10;

    reg [1:0] state, next_state;

    // -------------------------------------------------------------------------
    // Instantiate Stack A (Input Stack)
    // -------------------------------------------------------------------------
    Stack #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .PTR_WIDTH(PTR_WIDTH)
    ) stack_A (
        .clk(clk), .rst(rst),
        .push(a_push), .pop(a_pop),
        .din(din),     .dout(a_dout),
        .full(a_full), .empty(a_empty)
    );

    // -------------------------------------------------------------------------
    // Instantiate Stack B (Output Stack)
    // -------------------------------------------------------------------------
    Stack #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .PTR_WIDTH(PTR_WIDTH)
    ) stack_B (
        .clk(clk), .rst(rst),
        .push(b_push), .pop(b_pop),
        .din(b_din),   .dout(dout), // FIFO Output comes directly from Stack B
        .full(b_full), .empty(b_empty)
    );

    // -------------------------------------------------------------------------
    // Global Status Signals
    // -------------------------------------------------------------------------
    // The FIFO is "empty" to the user only if both stacks are empty.
    assign empty = a_empty && b_empty;
    
    // The FIFO is "full" if Stack A is full.
    // (Technically we could accept writes if A is empty and B is full, 
    // but standard FIFO logic usually applies backpressure at the input point).
    assign full  = a_full; // Can't write if Input Stack is full.

    // -------------------------------------------------------------------------
    // Control Logic (FSM)
    // -------------------------------------------------------------------------
    
    // Sequential State Logic
    always @(posedge clk or posedge rst) begin
        if (rst) state <= STATE_IDLE;
        else     state <= next_state;
    end

    // Combinational Next State & Control Signal Logic
    always @(*) begin
        // Default Assignments
        next_state = state;
        a_push = 0; a_pop = 0;
        b_push = 0; b_pop = 0;
        b_din  = 0;
        busy   = 0;

        case (state)
            STATE_IDLE: begin
                // --- WRITE OPERATION ---
                // Always allow writing to Stack A if enabled and not full
                if (wr_en && !a_full) begin
                    a_push = 1;
                end

                // --- READ OPERATION ---
                if (rd_en) begin
                    if (!b_empty) begin
                        // Case 1: Stack B has data. Pop directly.
                        b_pop = 1;
                    end else if (!a_empty) begin
                        // Case 2: Stack B is empty, but A has data. 
                        // Trigger Transfer. Do not pop B yet.
                        // We must move A -> B first.
                        busy = 1; // Signal that FIFO is busy reorganizing
                        next_state = STATE_MOVE_POP;
                    end
                end
            end

            STATE_MOVE_POP: begin
                busy = 1;
                // Step 1: Pop data from A
                if (!a_empty) begin
                    a_pop = 1;
                    next_state = STATE_MOVE_PUSH;
                end else begin
                    // Should not happen if logic is correct, but safe return
                    next_state = STATE_IDLE;
                end
            end

            STATE_MOVE_PUSH: begin
                busy = 1;
                // Step 2: Push that data to B
                b_din  = a_dout; // Data from Stack A output
                b_push = 1;

                // Decision: Continue moving or finish?
                if (a_empty) begin
                    // If A is now empty, we are done moving.
                    // Return to IDLE so the user can perform the Read.
                    next_state = STATE_IDLE;
                end else begin
                    // If A still has data, go back and pop the next item.
                    next_state = STATE_MOVE_POP;
                end
            end
            
            default: next_state = STATE_IDLE;
        endcase
    end

endmodule
