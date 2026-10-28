`timescale 1ns / 1ps
`include "uart_defines.vh"

class uart_driver extends uvm_driver #(uart_transaction);

    `uvm_component_utils(uart_driver)

    virtual uart_bus_if vif;
    uart_scoreboard sb;  // set by environment in connect_phase

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_bus_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Virtual interface not found in config_db")
    endfunction

    task reset_phase(uvm_phase phase);
        phase.raise_objection(this);

        vif.reset    <= 1'b1;
        vif.write_en <= 1'b0;
        vif.read_en  <= 1'b0;
        vif.addr     <= 4'b0;
        vif.wdata    <= 32'b0;

        repeat (5) @(posedge vif.clk);
        vif.reset <= 1'b0;
        repeat (5) @(posedge vif.clk);

        `uvm_info("DRV", "RESET DONE", UVM_LOW)

        phase.drop_objection(this);
    endtask

    task write_reg(bit [3:0] a, bit [31:0] d);
        @(posedge vif.clk);
        vif.addr     <= a;
        vif.wdata    <= d;
        vif.write_en <= 1'b1;
        @(posedge vif.clk);
        vif.write_en <= 1'b0;
    endtask

    task run_phase(uvm_phase phase);
        forever begin
            uart_transaction tr;

            seq_item_port.get_next_item(tr);

            write_reg(`REG_TXDATA, {24'b0, tr.data});
            `uvm_info("DRV", $sformatf("WROTE DATA = 0x%02h to TXDATA", tr.data), UVM_MEDIUM)

            if (sb != null) sb.write_expected(tr);

            // wait for full frame time (10 bits * 16x oversample, generous margin)
            repeat (20000) @(posedge vif.clk);

            seq_item_port.item_done();
        end
    endtask

endclass
