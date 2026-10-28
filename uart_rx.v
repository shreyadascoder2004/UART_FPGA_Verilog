`timescale 1ns / 1ps

module uart_rx #(
    parameter oversample = 16
)(
    input  wire       clk,
    input  wire       reset,
    input  wire       baud_tick,

    input  wire       RxD,

    input  wire       parity_en,
    input  wire       parity_odd,

    output reg  [7:0] rx_data,
    output reg        rx_valid,        // 1-cycle pulse: new byte ready
    input  wire       rx_ready,        // consumer (FIFO) ready to accept

    output reg        frame_error,
    output reg        parity_error
);

    localparam IDLE = 0, START = 1, DATA = 2, PARITY = 3, STOP = 4;
    localparam MID   = oversample/2;

    reg [2:0] state;
    reg [4:0] tick_count;
    reg [2:0] bit_index;
    reg [7:0] shift_reg;
    reg       parity_calc;

    // 2-flop synchronizer for RxD (metastability protection)
    reg RxD_sync0, RxD_sync1;
    always @(posedge clk) begin
        RxD_sync0 <= RxD;
        RxD_sync1 <= RxD_sync0;
    end

    always @(posedge clk) begin
        if (reset) begin
            state        <= IDLE;
            rx_valid     <= 1'b0;
            frame_error  <= 1'b0;
            parity_error <= 1'b0;
        end else begin

            rx_valid <= 1'b0; // default, pulse only on completion

            case (state)

                IDLE: begin
                    if (RxD_sync1 == 1'b0) begin   // start bit edge
                        state      <= START;
                        tick_count <= 0;
                    end
                end

                START: if (baud_tick) begin
                    if (tick_count == MID) begin
                        // confirm still low at mid-point (reject glitch)
                        if (RxD_sync1 == 1'b0) begin
                            tick_count  <= 0;
                            bit_index   <= 0;
                            parity_calc <= 0;
                            state       <= DATA;
                        end else
                            state <= IDLE; // false start
                    end else
                        tick_count <= tick_count + 1;
                end

                DATA: if (baud_tick) begin
                    if (tick_count == MID) begin
                        shift_reg   <= {RxD_sync1, shift_reg[7:1]};
                        parity_calc <= parity_calc ^ RxD_sync1;
                    end
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
                    if (tick_count == MID) begin
                        parity_error <= (parity_odd ? ~parity_calc : parity_calc) != RxD_sync1;
                    end
                    if (tick_count == oversample-1) begin
                        tick_count <= 0;
                        state <= STOP;
                    end else
                        tick_count <= tick_count + 1;
                end

                STOP: if (baud_tick) begin
                    if (tick_count == MID) begin
                        frame_error <= (RxD_sync1 != 1'b1);  // stop bit should be high
                        rx_data     <= shift_reg;
                        rx_valid    <= 1'b1;
                    end
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
