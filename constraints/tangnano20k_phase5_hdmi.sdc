create_clock -name clk27 -period 37.037 -waveform {0 18.5185} [get_ports {clk27}]
create_clock -name hdmi_pixel_clk -period 37.037 -waveform {0 18.5185} [get_pins {u_hdmi_clkdiv/CLKOUT}]
