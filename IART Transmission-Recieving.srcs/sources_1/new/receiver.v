`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2025 18:52:53
// Design Name: 
// Module Name: receiver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module UART_Receiver(
    input clk_fpga,            // 100 MHz clock from Basys3
    input reset_button,        // Active-high reset
    input RxD,                 // UART receive line (from keyboard)
    output reg [7:0] RxData,   // Received byte
    output reg [7:0] LED       // LED output
);

    // Parameters
    parameter clk_freq = 100_000_000;
    parameter baud_rate = 9600;
    parameter div_sample = 4; // 4x oversampling
    parameter div_counter = clk_freq / (baud_rate * div_sample); // ~2604
    parameter mid_sample = div_sample / 2; // Sample at midpoint
    parameter total_bits = 10; // Start + 8 data + Stop

    // Internal registers
    reg [13:0] baudrate_counter = 0;
    reg [3:0] sample_counter = 0;
    reg [3:0] bit_counter = 0;
    reg [9:0] shift_register = 0;

    reg state = 0;
    reg next_state = 0;

    reg clear_bitcounter, inc_bitcounter;
    reg inc_samplecounter, clear_samplecounter;
    reg shift;

    // FSM States
    localparam IDLE = 1'b0;
    localparam RECEIVE = 1'b1;

    // Sequential logic
    always @(posedge clk_fpga) begin
        if (reset_button) begin
            state <= IDLE;
            baudrate_counter <= 0;
            sample_counter <= 0;
            bit_counter <= 0;
            RxData <= 0;
            LED <= 0;
        end else begin
            state <= next_state;

            // Baudrate timing
            baudrate_counter <= baudrate_counter + 1;
            if (baudrate_counter >= div_counter) begin
                baudrate_counter <= 0;

                // Sample control
                if (inc_samplecounter)
                    sample_counter <= sample_counter + 1;
                if (clear_samplecounter)
                    sample_counter <= 0;

                // Bit counter control
                if (inc_bitcounter)
                    bit_counter <= bit_counter + 1;
                if (clear_bitcounter)
                    bit_counter <= 0;

                // Shift register
                if (shift)
                    shift_register <= {RxD, shift_register[9:1]};
            end
        end
    end

    // FSM Logic
    always @(*) begin
        // Default values
        next_state = state;
        inc_samplecounter = 0;
        clear_samplecounter = 0;
        inc_bitcounter = 0;
        clear_bitcounter = 0;
        shift = 0;

        case (state)
            IDLE: begin
                if (RxD == 0) begin // Start bit detected
                    next_state = RECEIVE;
                    clear_samplecounter = 1;
                    clear_bitcounter = 1;
                end
            end

            RECEIVE: begin
                inc_samplecounter = 1;
                if (sample_counter == mid_sample) begin
                    shift = 1;
                end

                if (sample_counter == div_sample - 1) begin
                    inc_bitcounter = 1;
                    clear_samplecounter = 1;
                end

                if (bit_counter == total_bits) begin
                    next_state = IDLE;
                    RxData = shift_register[8:1]; // Extract data bits
                    LED = shift_register[8:1];    // Show on LEDs
                end
            end
        endcase
    end

endmodule
