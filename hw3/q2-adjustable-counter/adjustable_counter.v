`timescale 1ns / 1ps

module clk_enable_gen(
    input wire clk,
    input wire rst,
    input wire [7:0] speed_setting, // 0 = Full Speed, 255 = Slowest (1/256)
    output reg ce_out               // Clock Enable Pulse
    );

    reg [7:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            ce_out <= 0;
        end else begin
            // If counter reaches 0, it's time to generate a pulse
            if (counter == 0) begin
                ce_out <= 1'b1;           // Assert CE
                counter <= speed_setting; // Reload counter with the delay value
            end else begin
                ce_out <= 1'b0;           // Deassert CE
                counter <= counter - 1;   // Decrement
            end
        end
    end

endmodule

module adjustable_counter(
    input wire clk,
    input wire rst,
    input wire [7:0] speed_setting, // Control speed (0 to 255)
    output reg [7:0] count_val
    );

    // Internal wire to carry the enable pulse
    wire ce_wire;

    // (A) Instantiate the Clock Enable Generator
    clk_enable_gen ce_unit (
        .clk(clk),
        .rst(rst),
        .speed_setting(speed_setting),
        .ce_out(ce_wire)
    );

    // (B) The Counter Logic
    // Note: We use the main system 'clk', NOT 'ce_wire' as the clock.
    // 'ce_wire' is used as a synchronous enable condition.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_val <= 8'b0;
        end else if (ce_wire) begin
            // Only increment when the Enable signal is High
            count_val <= count_val + 1;
        end
        // If ce_wire is low, count_val retains its value (holds)
    end

endmodule
