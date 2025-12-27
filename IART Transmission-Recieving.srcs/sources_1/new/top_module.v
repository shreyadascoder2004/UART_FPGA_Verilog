`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.11.2025 19:50:48
// Design Name: 
// Module Name: top_module
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


module Top_UART_Module(
    input clk,             // 100 MHz clock from Basys3
    input btn_transmit,    // Transmit button
    input btn_reset,       // Reset button
    input [7:0] data,      // Data to transmit
    output TXD,            // UART TX line
    output TXD_debug,      // Debug: TXD
    output Transmit_debug, // Debug: debounced transmit
    output Btn_debug,      // Debug: raw transmit button
    output Reset_debug     // Debug: raw reset button
);

    // Internal wires
    wire transmit_clean;
    wire reset_clean;

    // Debounce transmit button (positional)
    Debounce_Signals debounce_transmit (
        clk,
        btn_transmit,
        transmit_clean
    );

    // Debounce reset button (positional)
    Debounce_Signals debounce_reset (
        clk,
        btn_reset,
        reset_clean
    );

    // UART Transmitter (positional)
    Transmitter uart_tx (
        data,
        clk,
        reset_clean,
        transmit_clean,
        TXD
    );

    // Debug assignments
    assign TXD_debug       = TXD;
    assign Transmit_debug  = transmit_clean;
    assign Btn_debug       = btn_transmit;
    assign Reset_debug     = btn_reset;

endmodule
