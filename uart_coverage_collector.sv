`timescale 1ns / 1ps

class uart_coverage_collector extends uvm_subscriber #(uart_transaction);

    `uvm_component_utils(uart_coverage_collector)

    uart_transaction tr;

    covergroup cg;
        option.per_instance = 1;
        cp_data: coverpoint tr.data {
            bins zero       = {8'h00};
            bins all_ones   = {8'hFF};
            bins low_range  = {[8'h01:8'h7F]};
            bins high_range = {[8'h80:8'hFE]};
        }
        cp_frame_err:  coverpoint tr.frame_error;
        cp_parity_err: coverpoint tr.parity_error;
        cross cp_data, cp_frame_err;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();
    endfunction

    function void write(uart_transaction t);
        tr = t;
        cg.sample();
    endfunction

endclass
