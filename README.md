# GX4000 FPGA Real-Cartridge Clone — Phase 4

This project builds an Amstrad GX4000-compatible FPGA console around a Tang Nano 20K and real CPC Plus / GX4000 cartridges.

## Main project

Open `GX4000_Phase4_HDMI.gprj` and use top module `gx4000_phase4_hdmi_top`.

Current integrated path:

`real GX4000 cartridge -> mapper -> 4 MHz Z80 -> 64 KiB RAM -> CRTC/Gate Array -> Plus ASIC -> AY/PPI/controller logic -> 720x576p50 HDMI/TMDS + 48 kHz stereo LPCM`

## Phase 4 additions

- AY-3-8912-compatible PSG register interface
- CPC 1 MHz PSG timing
- three tone channels, noise, mixer and envelope
- 8255-compatible PPI mode-0 access path
- PPI-to-AY BDIR/BC1 control
- Phase-3 ASIC sound-DMA writes connected to the PSG
- CPC digital joystick matrix compatibility
- four 6-bit Plus analogue controller/paddle inputs
- ADC0-ADC7 reads at 6808h-680Fh
- A/B/C stereo routing matching the Amstrad output mix
- real 16-bit stereo samples connected to the existing HDMI audio packet path

See `docs/PHASE4_AUDIO_CONTROLLERS.md`.

## Controller GPIO wiring

The cartridge and onboard HDMI interfaces already consume most of the Tang Nano 20K GPIOs, so the two digital controller ports are carried over a two-wire I2C-style expansion bus instead of using one FPGA pin per button.

### Tang Nano 20K pins

- `ctrl_sda` = FPGA pin **76**
- `ctrl_scl` = FPGA pin **86**

Both lines are 3.3 V signals. Fit external **4.7 kOhm pull-ups to 3.3 V** on the controller adapter. Do not connect 5 V directly to either FPGA pin.

### Controller I/O expander

Use an MCP23017-compatible 16-bit I/O expander at I2C address `0x20`:

- A0 = GND
- A1 = GND
- A2 = GND
- VDD = 3.3 V
- VSS = GND
- SDA = `ctrl_sda` / FPGA pin 76
- SCL = `ctrl_scl` / FPGA pin 86
- RESET = 3.3 V

The FPGA module `rtl/phase4/mcp23017_controller_reader.sv` polls GPIOA and GPIOB and feeds the existing Phase-4 joystick matrix.

All controller inputs are active low. Each switch connects its MCP23017 GPIO input to ground when pressed.

### Player 1 — GPIOA

| MCP23017 pin | Function |
| --- | --- |
| GPA0 | Up |
| GPA1 | Down |
| GPA2 | Left |
| GPA3 | Right |
| GPA4 | Fire 1 |
| GPA5 | Fire 2 |
| GPA6 | Fire 3 |
| GPA7 | Spare |

### Player 2 — GPIOB

| MCP23017 pin | Function |
| --- | --- |
| GPB0 | Up |
| GPB1 | Down |
| GPB2 | Left |
| GPB3 | Right |
| GPB4 | Fire 1 |
| GPB5 | Fire 2 |
| GPB6 | Fire 3 |
| GPB7 | Spare |

The Phase-4 ASIC ADC register logic remains implemented. The current standard wrapper still returns full-scale values for ADC0-ADC3; a separate external ADC can later share the same two-wire bus if analogue paddles are required.

See `docs/PHASE4_CONTROLLER_GPIO.md` for the controller adapter details.

## FPGA pins currently used

The main Phase-4 build currently reserves:

- clock: pin 4
- cartridge A0-A13: pins 73, 74, 75, 85, 77, 15, 16, 27, 28, 25, 26, 29, 30, 31
- cartridge CA14-CA18: pins 17, 18, 19, 80, 42
- cartridge `/CE`: pin 41
- cartridge `CLK4`: pin 56
- cartridge `CCLR`: pin 54
- cartridge level-shifter `XLAT_OE_N`: pin 20
- cartridge D0-D7: pins 51, 48, 55, 49, 79, 72, 71, 53
- cartridge `SIN`: pin 52
- controller `SDA`: pin 76
- controller `SCL`: pin 86
- onboard HDMI TMDS clock: pins 33/34
- onboard HDMI TMDS D0: pins 35/36
- onboard HDMI TMDS D1: pins 37/38
- onboard HDMI TMDS D2: pins 39/40

## Earlier bring-up projects

The repository retains `GX4000_RealCart_RevA.gprj`, `GX4000_HDMI_Bringup.gprj`, `GX4000_Phase2_BaseCPC.gprj`, and `GX4000_Phase3_HDMI.gprj` for isolated debugging.

## CPU dependency

TV80 is pinned as the `third_party/Z80-FPGA` git submodule. Clone with `--recurse-submodules` or run `git submodule update --init --recursive` in an existing clone.

## Hardware safety

The real cartridge interface is 5 V. Use the level-shifted cartridge adapter and keep translator outputs disabled until FPGA configuration, clocks and reset are stable. Never connect the cartridge bus directly to Tang Nano 20K FPGA I/O.

The controller expansion bus is **3.3 V only**. Use 3.3 V pull-ups on SDA/SCL and do not expose pins 76 or 86 to 5 V.

## Reference validation

The source tree includes focused checks for Phase-2 CPC timing, Phase-3 Plus ASIC constants, Phase-4 PPI/AY/controller/ADC/stereo relationships, and HDMI 576p50/TMDS/audio-clock constants. Physical hardware compatibility work remains Phase 6.
