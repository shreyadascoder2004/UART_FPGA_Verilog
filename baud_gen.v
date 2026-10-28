`timescale 1ns / 1ps

module baud_gen #(
    parameter clk_freq   = 100_000_000,
    parameter baud_rate  = 9600,
    parameter oversample = 16          // 16x oversampling (industry standard)
)(
    input  wire        clk,
    input  wire        reset,
    input  wire [15:0] div_override,   // 0 = use default, else use this
    output reg          tick            // 1-cycle pulse at oversample rate
);

    localparam integer DEFAULT_DIV = clk_freq / (baud_rate * oversample);

    reg [15:0] div_count;
    wire [15:0] active_div = (div_override != 0) ? div_override : DEFAULT_DIV[15:0];

    always @(posedge clk) begin
        if (reset) begin
            div_count <= 0;
            tick      <= 1'b0;
        end else if (div_count == active_div - 1) begin
            div_count <= 0;
            tick      <= 1'b1;
        end else begin
            div_count <= div_count + 1;
            tick      <= 1'b0;
        end
    end

endmodule
