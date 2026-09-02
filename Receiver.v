`timescale 1ns / 1ps

module UART_Receiver #(
    parameter clk_freq  = 100_000_000,
    parameter baud_rate = 9600
)(
    input        clk_fpga,
    input        reset_button,

    input        RxD,

    output reg [7:0] RxData,
    output reg [7:0] LED,

    output reg       done
);

    // =========================================================
    // UART parameters
    // =========================================================

    parameter integer div_sample = 4;

    // 100 MHz / (9600 × 4)
    //
    // ≈ 2604 clocks per sample
    //
    localparam integer DIV_COUNTER =
                clk_freq / (baud_rate * div_sample);

    // Middle of 4 samples
    //
    // 0,1,2,3
    //     ^
    // sample 2 = middle
    //
    localparam integer MID_SAMPLE = div_sample / 2;


    // =========================================================
    // Counters
    // =========================================================

    reg [13:0] baudrate_counter;

    reg [2:0] sample_counter;

    reg [3:0] bit_counter;


    // =========================================================
    // Receive shift register
    //
    // [9]   = Stop bit
    // [8:1] = Data bits
    // [0]   = Start bit
    // =========================================================

    reg [9:0] shift_register;


    // =========================================================
    // FSM
    // =========================================================

    localparam IDLE    = 1'b0;
    localparam RECEIVE = 1'b1;

    reg state;
    reg next_state;


    // =========================================================
    // Control signals
    // =========================================================

    reg clear_samplecounter;
    reg inc_samplecounter;

    reg clear_bitcounter;
    reg inc_bitcounter;

    reg shift;


    // =========================================================
    // Sequential logic
    // =========================================================

    always @(posedge clk_fpga) begin

        if (reset_button) begin

            state <= IDLE;

            baudrate_counter <= 0;
            sample_counter   <= 0;
            bit_counter      <= 0;

            shift_register <= 0;

            RxData <= 0;
            LED    <= 0;

            done <= 0;

        end

        else begin

            state <= next_state;

            // -------------------------------------------------
            // Generate 4x baud-rate sampling tick
            // -------------------------------------------------

            if (baudrate_counter == DIV_COUNTER-1) begin

                baudrate_counter <= 0;


                // Sample counter

                if (inc_samplecounter)
                    sample_counter <= sample_counter + 1;

                if (clear_samplecounter)
                    sample_counter <= 0;


                // Bit counter

                if (inc_bitcounter)
                    bit_counter <= bit_counter + 1;

                if (clear_bitcounter)
                    bit_counter <= 0;


                // Shift received bit

                if (shift) begin

                    shift_register <=
                        {RxD, shift_register[9:1]};

                end

            end

            else begin

                baudrate_counter <= baudrate_counter + 1;

            end


            // done is normally low
            done <= 1'b0;

        end

    end


    // =========================================================
    // Receiver FSM
    // =========================================================

    always @(*) begin

        // -----------------------------------------------------
        // Default values
        // -----------------------------------------------------

        next_state = state;

        inc_samplecounter   = 1'b0;
        clear_samplecounter = 1'b0;

        inc_bitcounter      = 1'b0;
        clear_bitcounter    = 1'b0;

        shift = 1'b0;


        case (state)


            // =================================================
            // IDLE
            // =================================================

            IDLE: begin

                // UART idle line = 1
                //
                // Start bit = 0

                if (RxD == 1'b0) begin

                    next_state = RECEIVE;

                    clear_samplecounter = 1'b1;
                    clear_bitcounter    = 1'b1;

                end

            end


            // =================================================
            // RECEIVE
            // =================================================

            RECEIVE: begin

                // Count samples inside current UART bit

                inc_samplecounter = 1'b1;


                // -------------------------------------------------
                // Sample at middle of bit
                // -------------------------------------------------

                if (sample_counter == MID_SAMPLE) begin

                    shift = 1'b1;

                end


                // -------------------------------------------------
                // Four samples completed
                // Move to next bit
                // -------------------------------------------------

                if (sample_counter == div_sample-1) begin

                    clear_samplecounter = 1'b1;

                    inc_bitcounter = 1'b1;

                end


                // -------------------------------------------------
                // 10 UART bits received
                // -------------------------------------------------

                if (bit_counter == 9) begin

                    next_state = IDLE;

                end

            end


            default: begin

                next_state = IDLE;

            end

        endcase

    end


    // =========================================================
    // Output received byte
    // =========================================================

    always @(posedge clk_fpga) begin

        if (reset_button) begin

            RxData <= 8'h00;
            LED    <= 8'h00;

            done <= 1'b0;

        end

        else begin

            // Last UART bit completed

            if ((state == RECEIVE) &&
                (bit_counter == 9) &&
                (sample_counter == div_sample-1)) begin

                // Extract 8 data bits
                //
                // shift_register:
                //
                // [9]   stop
                // [8:1] data
                // [0]   start

                RxData <= shift_register[8:1];

                LED <= shift_register[8:1];

                done <= 1'b1;

            end

        end

    end

endmodule
