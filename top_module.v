`timescale 1ns / 1ps

module Top_UART_Module #(
    parameter debounce_threshold = 1000000
)(
    input clk,
    input btn_transmit,
    input btn_reset,
    input [7:0] data,

    output TXD,
    output TXD_debug,
    output Transmit_debug,
    output Btn_debug,
    output Reset_debug
);

    wire transmit_clean;
    wire reset_clean;

    // Transmit button debounce
    Debounce_Signals #(
        .treshold(debounce_threshold)
    ) debounce_transmit (
        .clk(clk),
        .btn(btn_transmit),
        .transmit(transmit_clean)
    );

    // Reset button debounce
    Debounce_Signals #(
        .treshold(debounce_threshold)
    ) debounce_reset (
        .clk(clk),
        .btn(btn_reset),
        .transmit(reset_clean)
    );

    // UART transmitter
    Transmitter uart_tx (
        .data(data),
        .clk(clk),
        .reset(reset_clean),
        .transmit(transmit_clean),
        .TXD(TXD)
    );

    // Debug
    assign TXD_debug      = TXD;
    assign Transmit_debug = transmit_clean;
    assign Btn_debug      = btn_transmit;
    assign Reset_debug    = btn_reset;

endmodule
