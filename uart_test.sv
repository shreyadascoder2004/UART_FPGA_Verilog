`timescale 1ns / 1ps

class uart_base_test extends uvm_test;

    `uvm_component_utils(uart_base_test)

    uart_env env;

    function new(string name = "uart_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        uart_sequence seq;

        phase.raise_objection(this);

        seq = uart_sequence::type_id::create("seq");
        seq.count = 20;
        seq.start(env.sequencer);

        phase.drop_objection(this);
    endtask

endclass
