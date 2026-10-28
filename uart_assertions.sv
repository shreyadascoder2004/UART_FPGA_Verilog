`timescale 1ns / 1ps

module uart_assertions #(
    parameter oversample = 16
)(
    input logic clk,
    input logic reset,
    input logic TXD
);

    // Property: TXD must return to idle (1) within a bounded time after
    // going low (i.e., no stuck-low line / hung transmitter)
    property p_txd_recovers;
        @(posedge clk) disable iff (reset)
        $fell(TXD) |-> ##[1:20000] TXD;
    endproperty
    a_txd_recovers: assert property (p_txd_recovers)
        else $error("[SVA] TXD stuck low - transmitter hung");

    // Property: line must be idle-high shortly after reset deasserts
    property p_idle_after_reset;
        @(posedge clk)
        $fell(reset) |-> ##[0:5] TXD;
    endproperty
    a_idle_after_reset: assert property (p_idle_after_reset)
        else $error("[SVA] TXD not idle-high shortly after reset");

endmodule
