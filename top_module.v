interface uart_if;

    logic clk;

    // Inputs to transmitter top
    logic btn_transmit;
    logic btn_reset;
    logic [7:0] data;

    // Transmitter output
    logic TXD;

    // Receiver outputs
    logic [7:0] RxData;
    logic [7:0] LED;
    logic done;

    // Debug signals
    logic TXD_debug;
    logic Transmit_debug;
    logic Btn_debug;
    logic Reset_debug;

endinterface
`timescale 1ns / 1ps

module Top_UART_Module #(
    parameter debounce_threshold = 1_000_000
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

    // ---------------------------------------------------------
    // Transmit button debounce
    // ---------------------------------------------------------

    Debounce_Signals #(
        .treshold(debounce_threshold)
    ) debounce_transmit (
        .clk(clk),
        .btn(btn_transmit),
        .transmit(transmit_clean)
    );

    // ---------------------------------------------------------
    // Reset button debounce
    // ---------------------------------------------------------

    Debounce_Signals #(
        .treshold(debounce_threshold)
    ) debounce_reset (
        .clk(clk),
        .btn(btn_reset),
        .transmit(reset_clean)
    );

    // ---------------------------------------------------------
    // UART Transmitter
    // ---------------------------------------------------------

    Transmitter #(
        .clk_freq(100_000_000),
        .baud_rate(9600)
    ) uart_tx (
        .data(data),
        .clk(clk),
        .reset(reset_clean),
        .transmit(transmit_clean),
        .TXD(TXD)
    );

    // ---------------------------------------------------------
    // Debug outputs
    // ---------------------------------------------------------

    assign TXD_debug      = TXD;
    assign Transmit_debug = transmit_clean;
    assign Btn_debug      = btn_transmit;
    assign Reset_debug    = btn_reset;

endmodule
