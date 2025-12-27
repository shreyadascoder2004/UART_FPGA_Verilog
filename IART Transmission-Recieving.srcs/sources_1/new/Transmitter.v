`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.11.2025 18:43:24
// Design Name: 
// Module Name: Transmitter
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


module Transmitter(
    input [7:0] data,
    input clk,
    input reset,
    input transmit,
    output reg TXD
);
    // Internal registers
    reg [3:0] bit_counter;
    reg [20:0] baudrate_counter;
    reg shift, load, clear;
    reg [9:0] shift_register;
    reg state, next_state;

    // Sequential logic: baudrate timing and state transitions
    always @(posedge clk) begin
        if (reset) begin
            bit_counter <= 0;
            baudrate_counter <= 0;
            state <= 0;
        end else begin
            baudrate_counter <= baudrate_counter + 1;
            if (baudrate_counter == 10416) begin // Assuming 9600 baud with 100MHz clock
                state <= next_state;
                baudrate_counter <= 0;

                if (load)
                    shift_register <= {1'b1, data[7:0], 1'b0}; // Stop bit, data, start bit

                if (clear)
                    bit_counter <= 0;

                if (shift)
                    shift_register <= shift_register >> 1;

                bit_counter <= bit_counter + 1;
            end
        end
    end

    // Mealy state machine for transmission control
    always @(posedge clk) begin
        // Default control signals
        load <= 0;
        shift <= 0;
        clear <= 0;
        TXD <= 1;

        case (state)
            0: begin // Idle state
                if (transmit) begin
                    next_state <= 1;
                    load <= 1;
                    shift <= 0;
                    clear <= 0;
                end else begin
                    next_state <= 0;
                    TXD <= 1;
                end
            end

            1: begin // Transmitting state
                if (bit_counter == 10) begin
                    next_state <= 0;
                    clear <= 1;
                end else begin
                    next_state <= 1;
                    TXD <= shift_register[0];
                    shift <= 1;
                end
            end

            default: next_state <= 0;
        endcase
    end
endmodule

            
     
   
    
    
  
