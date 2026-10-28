`timescale 1ns / 1ps

module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import uart_pkg::*;

    bit clk;
    always #5 clk = ~clk; // 100 MHz

    uart_bus_if vif(clk);

    // DUT instantiation with loopback: TXD -> RxD
    uart_top #(
        .clk_freq(100_000_000),
        .baud_rate(9600),
        .oversample(16),
        .FIFO_DEPTH(16)
    ) dut (
        .clk(clk),
        .reset(vif.reset),
        .RxD(vif.TXD),      // LOOPBACK: TX output feeds RX input
        .TXD(vif.TXD),
        .addr(vif.addr),
        .wdata(vif.wdata),
        .write_en(vif.write_en),
        .read_en(vif.read_en),
        .rdata(vif.rdata),
        .irq(vif.irq),
        .led_debug(vif.led_debug)
    );

    initial begin
        uvm_config_db#(virtual uart_bus_if)::set(null, "*", "vif", vif);
        run_test("uart_base_test");
    end

    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, tb_top);
    end

    bind uart_top uart_assertions #(.oversample(16)) u_assertions (
        .clk(clk), .reset(reset), .TXD(TXD)
    );

endmodule
