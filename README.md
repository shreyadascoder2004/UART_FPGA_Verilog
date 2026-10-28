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

## Getting started (Vivado)

1. Create a new RTL project targeting your FPGA board.
2. Add everything in `rtl/` as **design sources**; set `uart_top.v` as top.
3. Add `constraints/uart_top.xdc` — **edit the pin `LOC` values** to match
   your actual board before running implementation.
4. Add everything in `sim/` as **simulation sources**; set `tb_top` as the
   simulation top.
5. Project Settings → Simulation → set UVM version to 1.2.
6. Run Behavioral Simulation. Watch for the `[SCO] DATA MATCH` /
   `TOTAL PASS=.. TOTAL ERRORS=..` lines in the Tcl console.

Full step-by-step instructions, including the exact compile-order gotcha
(`uart_scoreboard.sv` must compile before `uart_driver.sv`), are in
[`README.md`](./README.md).

## Register map

| Offset | Name     | Access | Description                          |
|--------|----------|--------|---------------------------------------|
| 0x0    | TXDATA   | W      | Write byte, pushes into TX FIFO       |
| 0x4    | RXDATA   | R      | Read byte, pops from RX FIFO          |
| 0x8    | STATUS   | R      | TX full/empty, RX full/empty, errors  |
| 0xC    | CTRL     | RW     | IRQ enables, parity enable/polarity   |
| 0x10   | BAUDDIV  | RW     | Runtime baud divisor override         |

## What's simulated vs. what's verified on hardware

The current testbench uses an internal `TXD → RxD` **loopback** in
simulation — this verifies the TX and RX datapaths and the UVM environment
end-to-end, but has not yet been run against a real external device (a
second board, a UART-to-USB bridge, a logic analyzer capture). That's the
next step for anyone picking this up — see Roadmap below.

## Roadmap / known limitations

- [ ] Hardware bring-up: physical loopback or PC-terminal test over a
      UART-to-USB bridge, with timing closure report
- [ ] AXI-Lite or APB wrapper around `uart_regs.v` for real SoC integration
- [ ] Overrun-error logic is currently simplistic (flags on any FIFO-full
      write-attempt cycle, not a precise "lost byte" count)
- [ ] No configurable data-bit count (fixed at 8) or stop-bit count (fixed at 1)
- [ ] Formal verification of selected properties (e.g. with SymbiYosys) not
      yet attempted

## License

MIT (or your choice — add a LICENSE file)
