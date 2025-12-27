`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.11.2025 19:44:14
// Design Name: 
// Module Name: debounce_signal
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Debounce_Signals #(parameter treshold = 1000000) (
    input clk,         // Input clock
    input btn,         // Raw button input
    output reg transmit // Debounced transmit signal
);

    // Synchronization flip-flops
    reg button_ff1 = 0;
    reg button_ff2 = 0;

    // Counter for debounce timing
    reg [30:0] count = 0;

    // Debounced button state
    reg debounced_btn = 0;

    // Synchronize button input to clock domain
    always @(posedge clk) begin
        button_ff1 <= btn;
        button_ff2 <= button_ff1;
    end

    // Debounce logic
    always @(posedge clk) begin
        if (button_ff2 != debounced_btn) begin
            count <= count + 1;
            if (count >= treshold) begin
                debounced_btn <= button_ff2;
                count <= 0;
            end
        end else begin
            count <= 0;
        end
    end

    // Generate transmit pulse on rising edge of debounced button
    reg debounced_btn_prev = 0;
    always @(posedge clk) begin
        debounced_btn_prev <= debounced_btn;
        transmit <= (debounced_btn && !debounced_btn_prev);
    end

endmodule
