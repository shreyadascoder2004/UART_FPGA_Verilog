`timescale 1ns / 1ps

module uart_tx #(
    parameter oversample = 16
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       baud_tick,       // from baud_gen

    input  wire [7:0] tx_data,
    input  wire       tx_valid,        // asserted when data is available
    output reg        tx_ready,        // asserted when TX can accept new byte

    input  wire       parity_en,
    input  wire       parity_odd,

    output reg        TXD
);

    localparam IDLE = 0, START = 1, DATA = 2, PARITY = 3, STOP = 4;

    reg [2:0]  state;
    reg [3:0]  tick_count;
    reg [2:0]  bit_index;
    reg [7:0]  data_reg;
    reg        parity_bit;

    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            TXD        <= 1'b1;
            tx_ready   <= 1'b1;
            tick_count <= 0;
            bit_index  <= 0;
        end else begin
            case (state)

                IDLE: begin
                    TXD      <= 1'b1;
                    tx_ready <= 1'b1;
                    if (tx_valid) begin
                        data_reg   <= tx_data;
                        parity_bit <= parity_odd ? ~(^tx_data) : (^tx_data);
                        tx_ready   <= 1'b0;
                        state      <= START;
                        tick_count <= 0;
                    end
                end

                START: if (baud_tick) begin
                    TXD <= 1'b0;
                    if (tick_count == oversample-1) begin
                        tick_count <= 0;
                        bit_index  <= 0;
                        state      <= DATA;
                    end else
                        tick_count <= tick_count + 1;
                end

                DATA: if (baud_tick) begin
                    TXD <= data_reg[bit_index];
                    if (tick_count == oversample-1) begin
                        tick_count <= 0;
                        if (bit_index == 7)
                            state <= parity_en ? PARITY : STOP;
                        else
                            bit_index <= bit_index + 1;
                    end else
                        tick_count <= tick_count + 1;
                end

                PARITY: if (baud_tick) begin
                    TXD <= parity_bit;
                    if (tick_count == oversample-1) begin
                        tick_count <= 0;
                        state <= STOP;
                    end else
                        tick_count <= tick_count + 1;
                end

                STOP: if (baud_tick) begin
                    TXD <= 1'b1;
                    if (tick_count == oversample-1) begin
                        tick_count <= 0;
                        state <= IDLE;
                    end else
                        tick_count <= tick_count + 1;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
