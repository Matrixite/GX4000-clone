// 27 MHz board clock; generated clocks are recognized from rPLL/CLKDIV.
create_clock -name I_clk -period 37.037 -waveform {0 18.5185} [get_ports {I_clk}] -add
create_clock -name tmds_pixel_clk -period 37.037 -waveform {0 18.5185} [get_pins {u_clkdiv/CLKOUT}]
