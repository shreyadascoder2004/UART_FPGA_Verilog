`timescale 1ns / 1ps
`include "uart_defines.vh"

module uart_regs (
    input  wire        clk,
    input  wire        reset,

    // Simple bus interface (APB-lite style)
    input  wire [3:0]  addr,
    input  wire [31:0] wdata,
    input  wire        write_en,
    input  wire        read_en,
    output reg  [31:0] rdata,

    // TX FIFO side
    output wire [7:0]  tx_fifo_wdata,
    output wire        tx_fifo_wr,
    input  wire        tx_fifo_full,
    input  wire        tx_fifo_empty,

    // RX FIFO side
    input  wire [7:0]  rx_fifo_rdata,
    output wire        rx_fifo_rd,
    input  wire        rx_fifo_full,
    input  wire        rx_fifo_empty,

    // Error flags (from uart_rx, latched here)
    input  wire        frame_error_in,
    input  wire        parity_error_in,

    // Control bits out to TX/RX logic
    output reg         parity_en,
    output reg         parity_odd,
    output reg         rx_ie,
    output reg         tx_ie,
    output reg  [15:0] baud_div,

    // Interrupt line
    output wire        irq
);

    reg frame_error_latched;
    reg overrun_latched;

    wire [31:0] status = {26'b0,
                           overrun_latched,
                           frame_error_in,
                           rx_fifo_full,
                           rx_fifo_empty,
                           tx_fifo_full,
                           !tx_fifo_full}; // bit0..5 per uart_defines

    assign tx_fifo_wdata = wdata[7:0];
    assign tx_fifo_wr    = write_en && (addr == `REG_TXDATA) && !tx_fifo_full;
    assign rx_fifo_rd    = read_en  && (addr == `REG_RXDATA) && !rx_fifo_empty;

    assign irq = (rx_ie && !rx_fifo_empty) || (tx_ie && tx_fifo_empty);

    // -----------------------------------------------------------
    // Write path
    // -----------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            parity_en  <= 1'b0;
            parity_odd <= 1'b0;
            rx_ie      <= 1'b0;
            tx_ie      <= 1'b0;
            baud_div   <= 16'd0;
        end else if (write_en) begin
            case (addr)
                `REG_CTRL: begin
                    rx_ie      <= wdata[`CTRL_RX_IE];
                    tx_ie      <= wdata[`CTRL_TX_IE];
                    parity_en  <= wdata[`CTRL_PARITY_EN];
                    parity_odd <= wdata[`CTRL_PARITY_ODD];
                end
                `REG_BAUDDIV: baud_div <= wdata[15:0];
                default: ;
            endcase
        end
    end

    // -----------------------------------------------------------
    // Overrun / frame-error latching (sticky until reset)
    // -----------------------------------------------------------
    always @(posedge clk) begin
        if (reset) begin
            frame_error_latched <= 1'b0;
            overrun_latched     <= 1'b0;
        end else begin
            if (frame_error_in)  frame_error_latched <= 1'b1;
            if (rx_fifo_full && !rx_fifo_rd) overrun_latched <= 1'b1; // simplistic overrun flag
        end
    end

    // -----------------------------------------------------------
    // Read path
    // -----------------------------------------------------------
    always @(posedge clk) begin
        if (reset)
            rdata <= 32'b0;
        else if (read_en) begin
            case (addr)
                `REG_RXDATA:  rdata <= {24'b0, rx_fifo_rdata};
                `REG_STATUS:  rdata <= status;
                `REG_CTRL:    rdata <= {28'b0, parity_odd, parity_en, tx_ie, rx_ie};
                `REG_BAUDDIV: rdata <= {16'b0, baud_div};
                default:      rdata <= 32'b0;
            endcase
        end
    end

endmodule
