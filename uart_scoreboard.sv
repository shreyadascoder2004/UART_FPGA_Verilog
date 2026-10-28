`timescale 1ns / 1ps

class uart_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(uart_scoreboard)

    uvm_analysis_imp #(uart_transaction, uart_scoreboard) mon_export;

    uart_transaction expected_q[$];  // queue of expected bytes, FIFO order

    int pass_count = 0;
    int err_count  = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_export = new("mon_export", this);
    endfunction

    // Called by the driver right after it writes a byte to TXDATA —
    // the driver is the single source of truth for "what did we send"
    function void write_expected(uart_transaction tr);
        expected_q.push_back(tr);
    endfunction

    // Called automatically when uart_monitor's ap.write(tr) fires
    function void write(uart_transaction actual);
        uart_transaction expected;

        if (expected_q.size() == 0) begin
            `uvm_error("SCO", "Received data but no expected transaction queued")
            return;
        end

        expected = expected_q.pop_front();

        `uvm_info("SCO", $sformatf("EXPECTED = 0x%02h | ACTUAL = 0x%02h",
                   expected.data, actual.rx_data), UVM_MEDIUM)

        if (expected.data == actual.rx_data) begin
            `uvm_info("SCO", "DATA MATCH", UVM_LOW)
            pass_count++;
        end else begin
            `uvm_error("SCO", $sformatf("DATA MISMATCH: expected 0x%02h, got 0x%02h",
                        expected.data, actual.rx_data))
            err_count++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCO", $sformatf("TOTAL PASS=%0d  TOTAL ERRORS=%0d", pass_count, err_count), UVM_NONE)
    endfunction

endclass
