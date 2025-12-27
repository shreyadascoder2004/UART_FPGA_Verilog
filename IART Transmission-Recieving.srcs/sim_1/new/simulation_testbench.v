`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.12.2025 19:09:08
// Design Name: 
// Module Name: simulation_testbench
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


`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Advanced Full-Loopback Testbench for Top_UART_Module and UART_Receiver
//////////////////////////////////////////////////////////////////////////////////

module tb_UART_FullLoop;

    // Inputs for Top_UART_Module
    reg clk;
    reg btn_transmit;
    reg btn_reset;
    reg [7:0] data;

    // Outputs from Top_UART_Module
    wire TXD;
    wire TXD_debug;
    wire Transmit_debug;
    wire Btn_debug;
    wire Reset_debug;

    // Outputs from UART_Receiver
    wire [7:0] RxData;
    wire [7:0] LED;

    // Instantiate Top_UART_Module
    Top_UART_Module uut_tx (
        .clk(clk),
        .btn_transmit(btn_transmit),
        .btn_reset(btn_reset),
        .data(data),
        .TXD(TXD),
        .TXD_debug(TXD_debug),
        .Transmit_debug(Transmit_debug),
        .Btn_debug(Btn_debug),
        .Reset_debug(Reset_debug)
    );

    // Instantiate UART_Receiver
    UART_Receiver uut_rx (
        .clk_fpga(clk),
        .reset_button(btn_reset),
        .RxD(TXD),       // Connect TXD from transmitter to receiver
        .RxData(RxData),
        .LED(LED)
    );

    // Clock generation: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns period

    // Task to transmit a byte using Top_UART_Module
    task transmit_byte(input [7:0] byte);
        begin
            data = byte;
            btn_transmit = 1;   // press transmit
            #20;                // short pulse
            btn_transmit = 0;

            // Wait enough time for UART to finish sending 10 bits (start+data+stop)
            #(10416*10*10);     // 10 bits * 9600 baud timing * safety factor
        end
    endtask

    // Main simulation
    initial begin
        // Initialize signals
        clk = 0;
        btn_transmit = 0;
        btn_reset = 1; // reset active
        data = 8'h00;

        #50;
        btn_reset = 0; // release reset

        $display("=== UART Full Loopback Simulation Started ===");

        // Transmit bytes and observe receiver
        transmit_byte(8'hA5);
        $display("Transmitted: 0xA5, Receiver RxData = 0x%0h", RxData);

        transmit_byte(8'h3C);
        $display("Transmitted: 0x3C, Receiver RxData = 0x%0h", RxData);

        transmit_byte(8'hFF);
        $display("Transmitted: 0xFF, Receiver RxData = 0x%0h", RxData);

        transmit_byte(8'h00);
        $display("Transmitted: 0x00, Receiver RxData = 0x%0h", RxData);

        $display("=== UART Full Loopback Simulation Finished ===");
        #500000;
        $finish;
    end

    // Optional: monitor key signals in console
    initial begin
        $monitor("Time=%0t | TXD=%b | RxData=%h | LED=%h | Transmit=%b",
                 $time, TXD_debug, RxData, LED, Transmit_debug);
    end

endmodule

