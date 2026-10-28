`timescale 1ns / 1ps
`include "uart_defines.vh"

class uart_monitor extends uvm_monitor;

    `uvm_component_utils(uart_monitor)

    virtual uart_bus_if vif;

    uvm_analysis_port #(uart_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_bus_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Virtual interface not found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            uart_transaction tr;

            // Poll STATUS until RX FIFO not empty
            do begin
                @(posedge vif.clk);
                vif.read_en <= 1'b1;
                vif.addr    <= `REG_STATUS;
                @(posedge vif.clk);
                vif.read_en <= 1'b0;
            end while (vif.rdata[`STAT_RX_EMPTY]);

            // Read RXDATA
            @(posedge vif.clk);
            vif.read_en <= 1'b1;
            vif.addr    <= `REG_RXDATA;
            @(posedge vif.clk);
            vif.read_en <= 1'b0;

            tr = uart_transaction::type_id::create("tr");
            tr.rx_data = vif.rdata[7:0];

            `uvm_info("MON", $sformatf("RX DATA = 0x%02h", tr.rx_data), UVM_MEDIUM)

            ap.write(tr);  // broadcast to anyone subscribed (scoreboard, coverage)
        end
    endtask

endclass
