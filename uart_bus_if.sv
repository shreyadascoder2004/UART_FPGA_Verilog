`timescale 1ns / 1ps

interface uart_bus_if (input bit clk);

    logic        reset;

    // Bus side (drives uart_top's register interface)
    logic [3:0]  addr;
    logic [31:0] wdata;
    logic        write_en;
    logic        read_en;
    logic [31:0] rdata;
    logic        irq;

    // Serial side (loopback)
    logic        TXD;
    logic        RxD;

    logic [7:0]  led_debug;

endinterface
