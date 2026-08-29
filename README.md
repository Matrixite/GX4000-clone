# GX4000 FPGA Real-Cartridge Clone — Phase 4

This project is an attempt to recreate the Amstrad GX4000 around a Tang Nano 20K FPGA while still using real CPC Plus / GX4000 cartridges.

Rather than treating the cartridge as a ROM image loaded into the FPGA, the design talks to the physical cartridge through a level-shifted adapter. From there the FPGA recreates the main parts of the machine: the Z80-compatible CPU, RAM, CRTC, Gate Array, Plus ASIC features, sound hardware, controller interface and HDMI output.

The project is still being developed and tested in stages, so the older bring-up projects are kept in the repository as useful debugging tools.

## Main build

The current build is:

`GX4000_Phase4_HDMI.gprj`

with the top module:

`gx4000_phase4_hdmi_top`

The overall path is now:

`real GX4000 cartridge -> cartridge mapper -> 4 MHz Z80 -> 64 KiB RAM -> CRTC / Gate Array -> Plus ASIC -> AY / PPI / controller logic -> HDMI video + stereo audio`

Video is sent as 720×576p50 HDMI/TMDS and audio is carried as 48 kHz stereo LPCM.

## What Phase 4 adds

Phase 4 brings the sound and controller side of the machine into the main build.

The AY-3-8912-compatible PSG now has the normal three tone channels, noise generator, mixer, volume control and envelope support, running from the CPC/GX4000 1 MHz PSG timing. The 8255-compatible PPI provides the CPU-facing control path and drives the AY through the usual BDIR/BC1 signals.

The sound-DMA work from Phase 3 is connected to the same PSG registers, so DMA sound commands and normal CPU/PPI sound writes end up controlling the same sound chip model.

Stereo output follows the original Amstrad-style mix:

- Channel A goes to the left
- Channel B goes to both left and right
- Channel C goes to the right

The resulting 16-bit stereo samples are sent into the existing HDMI audio path.

Phase 4 also includes the CPC-style digital joystick matrix and the Plus analogue input registers at `6808h-680Fh`.

More detail is in `docs/PHASE4_AUDIO_CONTROLLERS.md`.

## Controllers

There are not enough unused Tang Nano 20K GPIOs left to connect every controller button directly to the FPGA. The cartridge interface and onboard HDMI already use most of the available pins, so the two controller ports use a small I2C-style input expander instead.

The two FPGA pins used for the controller bus are:

| Signal | FPGA pin |
| --- | ---: |
| `ctrl_sda` | **76** |
| `ctrl_scl` | **86** |

Both signals are **3.3 V only**. The controller board should have **4.7 kΩ pull-ups to 3.3 V** on SDA and SCL.

### MCP23017 controller board

The controller adapter uses an MCP23017-compatible 16-bit I/O expander at I2C address `0x20`.

Wire it as follows:

| MCP23017 pin | Connection |
| --- | --- |
| A0 | GND |
| A1 | GND |
| A2 | GND |
| VDD | 3.3 V |
| VSS | GND |
| SDA | `ctrl_sda` / FPGA pin 76 |
| SCL | `ctrl_scl` / FPGA pin 86 |
| RESET | 3.3 V |

The FPGA module `rtl/phase4/mcp23017_controller_reader.sv` polls GPIOA and GPIOB and passes the button states into the Phase 4 joystick matrix.

All controller buttons are active low, so pressing a button connects the corresponding MCP23017 input to ground.

### Player 1

Player 1 uses GPIOA:

| GPIO | Function |
| --- | --- |
| GPA0 | Up |
| GPA1 | Down |
| GPA2 | Left |
| GPA3 | Right |
| GPA4 | Fire 1 |
| GPA5 | Fire 2 |
| GPA6 | Fire 3 |
| GPA7 | Spare |

### Player 2

Player 2 uses GPIOB:

| GPIO | Function |
| --- | --- |
| GPB0 | Up |
| GPB1 | Down |
| GPB2 | Left |
| GPB3 | Right |
| GPB4 | Fire 1 |
| GPB5 | Fire 2 |
| GPB6 | Fire 3 |
| GPB7 | Spare |

The Plus analogue ADC logic is already present in the core, but the standard board wrapper currently returns full-scale values for ADC0-ADC3. If analogue paddles are added later, an external ADC can share the same two-wire controller bus.

See `docs/PHASE4_CONTROLLER_GPIO.md` for the controller adapter details.

## FPGA pin usage

For reference, these are the pins currently reserved by the Phase 4 build.

### Cartridge interface

| Function | FPGA pin(s) |
| --- | --- |
| 27 MHz clock | 4 |
| A0-A13 | 73, 74, 75, 85, 77, 15, 16, 27, 28, 25, 26, 29, 30, 31 |
| CA14-CA18 | 17, 18, 19, 80, 42 |
| `/CE` | 41 |
| `CLK4` | 56 |
| `CCLR` | 54 |
| `XLAT_OE_N` | 20 |
| D0-D7 | 51, 48, 55, 49, 79, 72, 71, 53 |
| `SIN` | 52 |

### Controller bus

| Function | FPGA pin |
| --- | ---: |
| SDA | 76 |
| SCL | 86 |

### Onboard HDMI

| Function | FPGA pins |
| --- | --- |
| TMDS clock | 33 / 34 |
| TMDS data 0 | 35 / 36 |
| TMDS data 1 | 37 / 38 |
| TMDS data 2 | 39 / 40 |

## Older bring-up projects

The earlier projects are deliberately still included because they make it much easier to isolate problems while testing the hardware:

- `GX4000_RealCart_RevA.gprj` — real-cartridge interface bring-up
- `GX4000_HDMI_Bringup.gprj` — standalone HDMI/video/audio testing
- `GX4000_Phase2_BaseCPC.gprj` — base CPC-compatible core
- `GX4000_Phase3_HDMI.gprj` — Plus ASIC features before the Phase 4 sound/controller work

## TV80 dependency

The Z80-compatible CPU comes from the `third_party/Z80-FPGA` git submodule.

For a fresh clone, use:

```bash
git clone --recurse-submodules https://github.com/Matrixite/GX4000-clone.git
```

If the repository has already been cloned, run:

```bash
git submodule update --init --recursive
```

## Hardware safety

The real GX4000 cartridge bus uses **5 V signals**. Do not connect it directly to the Tang Nano 20K FPGA pins. Use the level-shifted cartridge adapter and keep the translator outputs disabled until the FPGA clocks and reset are stable.

The controller expansion bus is different: SDA and SCL are **3.3 V only**. Use 3.3 V pull-ups and never feed 5 V into FPGA pins 76 or 86.

## Testing status

The repository contains focused reference checks for the CPC timing and video work from Phase 2, the Plus ASIC features from Phase 3, the PPI/AY/controller/ADC work from Phase 4, and the HDMI/TMDS/audio timing.

These tests are useful for catching logic and integration mistakes, but they are not a replacement for testing on the real Tang Nano 20K, real cartridge hardware and a monitor. Physical hardware compatibility work is still part of the later validation phase.
