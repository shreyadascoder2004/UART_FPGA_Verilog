module Transmitter #(
    parameter clk_freq = 100_000_000,
    parameter baud_rate = 9600
)(
    input [7:0] data,
    input clk,
    input reset,
    input transmit,
    output reg TXD
);

    localparam integer BAUD_COUNT = clk_freq / baud_rate;

    reg [13:0] baudrate_counter;
    reg [3:0] bit_counter;
    reg [9:0] shift_register;
    reg busy;

    always @(posedge clk) begin

        if (reset) begin
            baudrate_counter <= 0;
            bit_counter      <= 0;
            shift_register   <= 10'b1111111111;
            TXD              <= 1'b1;
            busy             <= 1'b0;
        end

        else begin

            // Start transmission
            if (transmit && !busy) begin

                // stop + data + start
                shift_register <= {1'b1, data, 1'b0};

                baudrate_counter <= 0;
                bit_counter <= 0;
                busy <= 1'b1;

                // Start bit
                TXD <= 1'b0;
            end

            else if (busy) begin

                if (baudrate_counter == BAUD_COUNT-1) begin

                    baudrate_counter <= 0;

                    if (bit_counter < 9) begin

                        bit_counter <= bit_counter + 1;

                        shift_register <= shift_register >> 1;

                        TXD <= shift_register[1];

                    end

                    else begin

                        bit_counter <= 0;
                        busy <= 1'b0;

                        // UART idle / stop
                        TXD <= 1'b1;

                    end
                end

                else begin
                    baudrate_counter <= baudrate_counter + 1;
                end
            end
        end
    end

endmodule
             
