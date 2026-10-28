`timescale 1ns / 1ps

class uart_env extends uvm_env;

    `uvm_component_utils(uart_env)

    uart_sequencer           sequencer;
    uart_driver               driver;
    uart_monitor              monitor;
    uart_scoreboard           scoreboard;
    uart_coverage_collector   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        sequencer  = uart_sequencer::type_id::create("sequencer", this);
        driver     = uart_driver::type_id::create("driver", this);
        monitor    = uart_monitor::type_id::create("monitor", this);
        scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
        cov        = uart_coverage_collector::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        driver.seq_item_port.connect(sequencer.seq_item_export);

        monitor.ap.connect(scoreboard.mon_export);
        monitor.ap.connect(cov.analysis_export);

        driver.sb = scoreboard;  // direct handle for write_expected()
    endfunction

endclass
