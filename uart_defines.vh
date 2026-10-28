`ifndef UART_DEFINES_VH
`define UART_DEFINES_VH

// =============================================================
// Register map (byte addresses, word-aligned)
// =============================================================
`define REG_TXDATA   4'h0   // W:  write byte to transmit
`define REG_RXDATA   4'h4   // R:  read received byte
`define REG_STATUS   4'h8   // R:  status flags
`define REG_CTRL     4'hC   // RW: control bits
`define REG_BAUDDIV  4'h10  // RW: baud divisor override

// Status bits
`define STAT_TX_FULL   0
`define STAT_TX_EMPTY  1
`define STAT_RX_EMPTY  2
`define STAT_RX_FULL   3
`define STAT_FRAME_ERR 4
`define STAT_OVERRUN   5

// Control bits
`define CTRL_RX_IE     0   // RX-data-available interrupt enable
`define CTRL_TX_IE     1   // TX-empty interrupt enable
`define CTRL_PARITY_EN 2
`define CTRL_PARITY_ODD 3  // 1 = odd parity, 0 = even

`endif
