## ================================
## CLOCK (100 MHz Basys3 Clock)
## ================================
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## ================================
## BUTTONS
## ================================

## Transmit Button (BTN0)
set_property PACKAGE_PIN U18 [get_ports btn_transmit]
set_property IOSTANDARD LVCMOS33 [get_ports btn_transmit]

## Reset Button (BTN1)
set_property PACKAGE_PIN T18 [get_ports btn_reset]
set_property IOSTANDARD LVCMOS33 [get_ports btn_reset]

## ================================
## DATA INPUT SWITCHES (8-bit)
## ================================
set_property PACKAGE_PIN V17 [get_ports {data[0]}]
set_property PACKAGE_PIN V16 [get_ports {data[1]}]
set_property PACKAGE_PIN W16 [get_ports {data[2]}]
set_property PACKAGE_PIN W17 [get_ports {data[3]}]
set_property PACKAGE_PIN W15 [get_ports {data[4]}]
set_property PACKAGE_PIN V15 [get_ports {data[5]}]
set_property PACKAGE_PIN W14 [get_ports {data[6]}]
set_property PACKAGE_PIN W13 [get_ports {data[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {data[*]}]

## ================================
## UART TX OUTPUT
## ================================
## JA PMOD PIN 1 (Example UART TX)
set_property PACKAGE_PIN J1 [get_ports TXD]
set_property IOSTANDARD LVCMOS33 [get_ports TXD]

## ================================
## DEBUG OUTPUTS → LEDs
## ================================
set_property PACKAGE_PIN U16 [get_ports TXD_debug]
set_property PACKAGE_PIN E19 [get_ports Transmit_debug]
set_property PACKAGE_PIN U19 [get_ports Btn_debug]
set_property PACKAGE_PIN V19 [get_ports Reset_debug]

set_property IOSTANDARD LVCMOS33 [get_ports {TXD_debug Transmit_debug Btn_debug Reset_debug}]