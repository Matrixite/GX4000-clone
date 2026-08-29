# Phase 4 controller GPIO assignment

The current cartridge + HDMI design leaves too few direct FPGA pins for two full 7-button controller ports, so Phase 4 uses a two-wire controller expansion bus.

## Tang Nano 20K FPGA pins

- `ctrl_sda` = FPGA pin 76
- `ctrl_scl` = FPGA pin 86

Both lines are 3.3 V LVCMOS open-drain style signals. Fit external 4.7 kOhm pull-ups to 3.3 V on the controller adapter.

## Controller adapter

Use an MCP23017-compatible 16-bit I/O expander at I2C address `0x20`:

- A0 = GND
- A1 = GND
- A2 = GND
- VDD = 3.3 V
- VSS = GND
- SDA = `ctrl_sda` / FPGA pin 76
- SCL = `ctrl_scl` / FPGA pin 86
- RESET = 3.3 V (normally high)

The MCP23017 power-on direction defaults are inputs, and the FPGA polls GPIOA/GPIOB directly.

## Digital controller mapping

All controller inputs are active low. Use pull-ups on the MCP23017 GPIO pins; each button/direction switch connects the corresponding GPIO to ground when pressed.

### Player 1 / GPIOA

- GPA0 = Up
- GPA1 = Down
- GPA2 = Left
- GPA3 = Right
- GPA4 = Fire 1
- GPA5 = Fire 2
- GPA6 = Fire 3
- GPA7 = spare

### Player 2 / GPIOB

- GPB0 = Up
- GPB1 = Down
- GPB2 = Left
- GPB3 = Right
- GPB4 = Fire 1
- GPB5 = Fire 2
- GPB6 = Fire 3
- GPB7 = spare

The FPGA module `rtl/phase4/mcp23017_controller_reader.sv` polls GPIOA then GPIOB at about 100 kHz I2C clock and feeds the existing Phase 4 joystick matrix.

## Analogue controls

The Phase 4 ASIC ADC register logic remains implemented, but the standard Tang Nano 20K wrapper currently returns full-scale values for ADC0-ADC3. A separate external ADC can be added later on the same two-wire bus if analogue paddles are required.

## Important hardware note

Pins 76 and 86 must only be connected to 3.3 V logic. Do not put GX4000/5 V signals directly on either FPGA pin.
