`timescale 1ns / 1ps

package uart_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "uart_defines.vh"
    `include "uart_transaction.sv"
    `include "uart_sequence.sv"
    `include "uart_sequencer.sv"
    `include "uart_scoreboard.sv"
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_coverage_collector.sv"
    `include "uart_env.sv"
    `include "uart_test.sv"

endpackage
