`timescale 1ns / 1ps

class uart_transaction extends uvm_sequence_item;

    rand bit [7:0] data;

    bit [7:0] rx_data;
    bit       frame_error;
    bit       parity_error;

    constraint data_dist {
        data dist { 8'h00 := 1, 8'hFF := 1, [8'h01:8'hFE] :/ 8 };
    }

    `uvm_object_utils_begin(uart_transaction)
        `uvm_field_int(data,         UVM_ALL_ON)
        `uvm_field_int(rx_data,      UVM_ALL_ON)
        `uvm_field_int(frame_error,  UVM_ALL_ON)
        `uvm_field_int(parity_error, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_transaction");
        super.new(name);
    endfunction

endclass
