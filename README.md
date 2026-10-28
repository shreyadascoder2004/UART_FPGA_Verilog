# UART Peripheral with Register Interface + UVM Verification Environment

A from-scratch 8N1 UART IP core, upgraded from a simple button-triggered
transmitter/receiver into a memory-mapped peripheral with FIFOs, parity,
error detection, and a full UVM-based verification environment — built and
simulated in Xilinx Vivado.

## Why this project

Most student UART projects stop at "TX sends a byte, RX receives it,
demo on an LED." This one goes further in both directions:

- **Design side:** the core is wrapped as an actual bus-facing peripheral
  (address/data/write-enable/read-enable register interface), the kind of
  interface a CPU would use to talk to it — not just a button and an LED.
- **Verification side:** instead of a handful of `$display` checks, it has
  a constrained-random UVM testbench with a scoreboard, functional coverage,
  and protocol-level SystemVerilog assertions running independently of the
  data-matching checks.

## Features

**RTL**
- 8N1 UART transmitter and receiver (parameterized baud rate, default 9600 @ 100 MHz)
- 16x oversampling with mid-bit sampling (upgraded from naive 1x/4x sampling)
  for better clock-drift tolerance and noise rejection
- 2-flop synchronizer on the asynchronous `RxD` input (metastability protection)
- Start-bit glitch rejection (re-checked at the oversample midpoint, not just
  the edge)
- Optional parity (even/odd, enabled via control register)
- Framing-error and overrun-error detection
- TX and RX FIFOs (depth configurable, default 16 bytes)
- Memory-mapped register file: `TXDATA`, `RXDATA`, `STATUS`, `CTRL`, `BAUDDIV`
- Interrupt output (`irq`), gated by RX-data-available / TX-empty enables

**Verification**
- Full UVM testbench: sequence → sequencer → driver → monitor → scoreboard
- Constrained-random stimulus biased toward edge cases (`0x00`, `0xFF`)
  via a `dist` constraint
- Self-checking scoreboard (driver reports "sent" data directly to the
  scoreboard; monitor reports "received" data; mismatches are flagged
  automatically, no manual waveform inspection needed)
- Functional coverage (data-value bins, frame/parity error bins, cross
  coverage) via a `uvm_subscriber`
- SystemVerilog Assertions bound onto the DUT (`bind`) checking protocol
  properties — e.g. TXD can't stay stuck low — independently of the
  scoreboard
- `report_phase` auto-generates a final pass/fail/error-count summary

## Repository structure

```
rtl/                     Design sources (Verilog)
├── uart_defines.vh      Register map / bit-field constants
├── baud_gen.v           Baud/oversample tick generator
├── uart_tx.v            Transmitter FSM
├── uart_rx.v            Receiver FSM (synchronizer, 16x oversample, parity)
├── sync_fifo.v          Generic synchronous FIFO (used for TX and RX)
├── uart_regs.v          Memory-mapped register file / bus interface
└── uart_top.v           Top-level peripheral integration

constraints/
└── uart_top.xdc         Board pin constraints (edit LOCs for your board)

sim/                     UVM verification environment (SystemVerilog)
├── uart_bus_if.sv       DUT-facing interface
├── uart_transaction.sv  uvm_sequence_item
├── uart_sequence.sv     Constrained-random stimulus
├── uart_sequencer.sv
├── uart_driver.sv       Drives register writes, reports expected data
├── uart_monitor.sv      Polls status, reads back received data
├── uart_scoreboard.sv   Self-checking comparator
├── uart_coverage_collector.sv
├── uart_env.sv          TLM wiring (connect_phase)
├── uart_test.sv         Top-level uvm_test
├── uart_assertions.sv   SVA protocol checks
├── uart_pkg.sv          Package bundling the above
└── tb_top.sv            Simulation top, DUT instantiation, loopback
```



