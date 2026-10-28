`timescale 1ns / 1ps

class uart_sequence extends uvm_sequence #(uart_transaction);

    `uvm_object_utils(uart_sequence)

    int count = 20;

    function new(string name = "uart_sequence");
        super.new(name);
    endfunction

    task body();
        uart_transaction tr;

        repeat (count) begin
            tr = uart_transaction::type_id::create("tr");

            start_item(tr);
            assert (tr.randomize())
                else `uvm_error("SEQ", "Randomization failed")
            `uvm_info("SEQ", $sformatf("Generated DATA = 0x%02h", tr.data), UVM_MEDIUM)
            finish_item(tr);
        end
    endtask

endclass
