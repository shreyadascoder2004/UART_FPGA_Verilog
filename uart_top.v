`timescale 1ns / 1ps

module uart_top #(
    parameter clk_freq   = 100_000_000,
    parameter baud_rate  = 9600,
    parameter oversample = 16,
    parameter FIFO_DEPTH = 16
)(
    input  wire        clk,
    input  wire        reset,

    // Serial pins
    input  wire        RxD,
    output wire         TXD,

    // Bus interface (drive this from CPU or testbench)
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    input  wire        write_en,
    input  wire        read_en,
    output wire [31:0] rdata,

    output wire        irq,

    // Debug / board LEDs
    output wire [7:0]  led_debug
);

    // ---------------------------------------------------------
    // Baud tick generator
    // ---------------------------------------------------------
    wire baud_tick;
    wire [15:0] baud_div;

    baud_gen #(
        .clk_freq(clk_freq),
        .baud_rate(baud_rate),
        .oversample(oversample)
    ) u_baud_gen (
        .clk(clk),
        .reset(reset),
        .div_override(baud_div),
        .tick(baud_tick)
    );

    // ---------------------------------------------------------
    // Register file <-> control wires
    // ---------------------------------------------------------
    wire parity_en, parity_odd, rx_ie, tx_ie;

    wire [7:0] tx_fifo_wdata;
    wire       tx_fifo_wr, tx_fifo_full, tx_fifo_empty;

    wire [7:0] rx_fifo_rdata;
    wire       rx_fifo_rd, rx_fifo_full, rx_fifo_empty;

    wire       frame_error, parity_error;

    uart_regs u_regs (
        .clk(clk), .reset(reset),
        .addr(addr), .wdata(wdata), .write_en(write_en),
        .read_en(read_en), .rdata(rdata),
        .tx_fifo_wdata(tx_fifo_wdata), .tx_fifo_wr(tx_fifo_wr), .tx_fifo_full(tx_fifo_full), .tx_fifo_empty(tx_fifo_empty),
        .rx_fifo_rdata(rx_fifo_rdata), .rx_fifo_rd(rx_fifo_rd), .rx_fifo_full(rx_fifo_full), .rx_fifo_empty(rx_fifo_empty),
        .frame_error_in(frame_error), .parity_error_in(parity_error),
        .parity_en(parity_en), .parity_odd(parity_odd),
        .rx_ie(rx_ie), .tx_ie(tx_ie),
        .baud_div(baud_div),
        .irq(irq)
    );

    // ---------------------------------------------------------
    // TX path: TX FIFO -> uart_tx
    // ---------------------------------------------------------
    wire [7:0] tx_data_out;
    wire       tx_fifo_rd_internal, tx_valid, tx_ready;

    sync_fifo #(.DATA_WIDTH(8), .DEPTH(FIFO_DEPTH)) u_tx_fifo (
        .clk(clk), .reset(reset),
        .wr_en(tx_fifo_wr), .wr_data(tx_fifo_wdata), .full(tx_fifo_full),
        .rd_en(tx_fifo_rd_internal), .rd_data(tx_data_out), .empty(tx_fifo_empty)
    );

    // Pull from TX FIFO whenever uart_tx is ready and FIFO has data
    assign tx_fifo_rd_internal = tx_ready && !tx_fifo_empty;
    assign tx_valid            = !tx_fifo_empty;

    uart_tx #(.oversample(oversample)) u_tx (
        .clk(clk), .reset(reset), .baud_tick(baud_tick),
        .tx_data(tx_data_out), .tx_valid(tx_valid), .tx_ready(tx_ready),
        .parity_en(parity_en), .parity_odd(parity_odd),
        .TXD(TXD)
    );

    // ---------------------------------------------------------
    // RX path: uart_rx -> RX FIFO
    // ---------------------------------------------------------
    wire [7:0] rx_data_in;
    wire       rx_valid;

    uart_rx #(.oversample(oversample)) u_rx (
        .clk(clk), .reset(reset), .baud_tick(baud_tick),
        .RxD(RxD),
        .parity_en(parity_en), .parity_odd(parity_odd),
        .rx_data(rx_data_in), .rx_valid(rx_valid), .rx_ready(!rx_fifo_full),
        .frame_error(frame_error), .parity_error(parity_error)
    );

    sync_fifo #(.DATA_WIDTH(8), .DEPTH(FIFO_DEPTH)) u_rx_fifo (
        .clk(clk), .reset(reset),
        .wr_en(rx_valid && !rx_fifo_full), .wr_data(rx_data_in), .full(rx_fifo_full),
        .rd_en(rx_fifo_rd), .rd_data(rx_fifo_rdata), .empty(rx_fifo_empty)
    );

    // ---------------------------------------------------------
    // Debug LEDs: show last received byte on board LEDs
    // ---------------------------------------------------------
    reg [7:0] led_reg;
    always @(posedge clk) begin
        if (reset) led_reg <= 8'h00;
        else if (rx_valid) led_reg <= rx_data_in;
    end
    assign led_debug = led_reg;

endmodule
