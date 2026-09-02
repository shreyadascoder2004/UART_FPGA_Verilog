`timescale 1ns / 1ps

module Transmitter #(
    parameter clk_freq  = 100_000_000,
    parameter baud_rate = 9600
)(
    input  [7:0] data,
    input        clk,
    input        reset,
    input        transmit,
    output reg   TXD
);

    // =========================================================
    // Baud-rate calculation
    //
    // 100 MHz / 9600 ≈ 10416.67
    // =========================================================

    localparam integer BAUD_COUNT = clk_freq / baud_rate;


    // =========================================================
    // Internal registers
    // =========================================================

    reg [13:0] baudrate_counter;
    reg [3:0]  bit_counter;

    // 10-bit UART frame:
    //
    // [9]   = Stop bit
    // [8:1] = 8 data bits
    // [0]   = Start bit
    //
    reg [9:0] shift_register;

    reg busy;


    // =========================================================
    // Transmitter logic
    // =========================================================

    always @(posedge clk) begin

        if (reset) begin

            baudrate_counter <= 0;
            bit_counter      <= 0;
            shift_register   <= 10'b1111111111;

            TXD  <= 1'b1;   // UART idle state
            busy <= 1'b0;

        end

        else begin

            // =================================================
            // Start a new transmission
            // =================================================

            if (transmit && !busy) begin

                // UART frame:
                //
                // stop + data + start
                //
                // Example:
                // data = 8'b10101010
                //
                // shift_register =
                // 1_10101010_0

                shift_register <= {1'b1, data, 1'b0};

                baudrate_counter <= 0;
                bit_counter      <= 0;

                busy <= 1'b1;

                // Start bit
                TXD <= 1'b0;

            end


            // =================================================
            // Transmission in progress
            // =================================================

            else if (busy) begin

                if (baudrate_counter == BAUD_COUNT-1) begin

                    baudrate_counter <= 0;


                    if (bit_counter < 9) begin

                        bit_counter <= bit_counter + 1;

                        // Shift next bit toward TXD
                        shift_register <= shift_register >> 1;

                        TXD <= shift_register[1];

                    end

                    else begin

                        // =================================================
                        // Transmission complete
                        // =================================================

                        bit_counter <= 0;

                        busy <= 1'b0;

                        // UART returns to idle/high
                        TXD <= 1'b1;

                    end

                end

                else begin

                    baudrate_counter <= baudrate_counter + 1;

                end

            end

            else begin

                // Idle
                TXD <= 1'b1;

            end

        end

    end

endmodule  
