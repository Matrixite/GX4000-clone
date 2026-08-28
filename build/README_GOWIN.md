# Gowin build notes

Top module for the first hardware test:

`gx4000_realcart_diag_top`

Add these source files:

- rtl/top/gx4000_realcart_diag_top.sv
- rtl/cart/cart_read_cycle.sv
- rtl/cart/acid_link_monitor.sv
- rtl/diag/cart_diag_engine.sv
- rtl/common/uart_tx.sv

Target the exact FPGA fitted to your Tang Nano 20K board.

Before synthesis:

1. Copy `constraints/tangnano20k.cst.template`.
2. Fill in only verified Tang Nano 20K pins.
3. Keep all FPGA banks at the voltage required by the board.
4. Never configure any bank for 5 V.
5. Build and check that there are no unconstrained cartridge I/O pins.

The diagnostic top assumes the supplied `clk` frequency is 27 MHz by default.
If your chosen clock differs, change `CLOCK_HZ`.
