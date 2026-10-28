## Clock (100 MHz onboard oscillator — adjust LOC/PACKAGE_PIN to your board)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk [get_ports clk]

## Reset button
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## UART RxD / TXD — if using onboard USB-UART bridge, use those pins;
## otherwise route to a Pmod header for external loopback/scope probing
set_property PACKAGE_PIN B18 [get_ports RxD]
set_property IOSTANDARD LVCMOS33 [get_ports RxD]

set_property PACKAGE_PIN A18 [get_ports TXD]
set_property IOSTANDARD LVCMOS33 [get_ports TXD]

## LEDs (8 onboard LEDs for debug display)
set_property PACKAGE_PIN U16 [get_ports {led_debug[0]}]
set_property PACKAGE_PIN E19 [get_ports {led_debug[1]}]
set_property PACKAGE_PIN U19 [get_ports {led_debug[2]}]
set_property PACKAGE_PIN V19 [get_ports {led_debug[3]}]
set_property PACKAGE_PIN W18 [get_ports {led_debug[4]}]
set_property PACKAGE_PIN U15 [get_ports {led_debug[5]}]
set_property PACKAGE_PIN U14 [get_ports {led_debug[6]}]
set_property PACKAGE_PIN V14 [get_ports {led_debug[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_debug[*]}]

## NOTE: addr/wdata/write_en/read_en/rdata/irq are left unconstrained here
## because in this phase they're driven by your testbench, not board I/O.
## Once you add a real CPU/bus master on the FPGA, you'll constrain those too.
## IMPORTANT: Pin LOC values above are placeholders from a common Basys3
## layout — verify against YOUR board's official master XDC before use.
