# GX4000 FPGA Real-Cartridge Clone

This project is my attempt to recreate the Amstrad GX4000 around a Tang Nano 20K FPGA while still using real CPC Plus / GX4000 cartridges.

The idea is not to treat a cartridge as a ROM file loaded into the FPGA. The design talks to the physical cartridge through a level-shifted adapter, then recreates the rest of the console in logic: the Z80-compatible CPU, RAM, CRTC, Gate Array, Plus ASIC features, sound hardware, controllers and HDMI output.

I have been building it in stages rather than trying to make the whole machine work at once. Each phase adds another part of the GX4000, and the older projects are deliberately kept in the repository because they are useful when something needs to be tested in isolation.

## Current build

The current integrated build is:

`GX4000_Phase4_HDMI.gprj`

with top module:

`gx4000_phase4_hdmi_top`

The current signal path is:

`real GX4000 cartridge -> cartridge mapper -> 4 MHz Z80 -> 64 KiB RAM -> CRTC / Gate Array -> Plus ASIC -> AY / PPI / controller logic -> HDMI video + stereo audio`

Video is sent as 720×576p50 HDMI/TMDS and audio is carried as 48 kHz stereo LPCM.

---

# Project phases

## Phase 1 — real cartridge and HDMI bring-up

**Status: complete as a bring-up stage**

The first phase was about proving that the Tang Nano 20K could safely talk to real GX4000 cartridges and drive the onboard HDMI connector.

The cartridge bus is 5 V, so it cannot be connected directly to the FPGA. A level-shifted cartridge adapter was designed around that limitation, with a separate translator enable so the FPGA can keep the bus isolated while it is configuring and coming out of reset.

This phase also established the basic cartridge address, data and control wiring, along with a standalone HDMI/TMDS test build.

Useful projects from this stage:

- `GX4000_RealCart_RevA.gprj` — cartridge-interface bring-up
- `GX4000_HDMI_Bringup.gprj` — standalone HDMI/video/audio testing

These are still worth keeping because they let the cartridge bus and HDMI output be tested without involving the rest of the console core.

## Phase 2 — base CPC-compatible machine

**Status: implemented**

Phase 2 turned the project from a cartridge interface into an actual computer core.

This stage added the TV80 Z80-compatible CPU, 64 KiB of system RAM, the CPC-style CRTC, Gate Array behaviour, ROM selection and the basic CPC video path. The cartridge mapper was connected into the Z80 memory system so the CPU could read from a real cartridge while still using the underlying RAM in the same way the original machine does.

The video path was then connected to HDMI through a small scan converter rather than a full framebuffer. The CPC side runs at a 15.625 kHz line rate and the 576p HDMI side runs at 31.25 kHz, which gives an exact 2:1 relationship and lets each source line be shown twice.

Useful Phase 2 projects:

- `GX4000_Phase2_BaseCPC.gprj` — base CPC-style core with native video
- `GX4000_Phase2_HDMI.gprj` — Phase 2 core connected to HDMI/TMDS

At this point the machine had the basic CPC hardware needed to execute code and produce a display, but it was still missing the extra hardware that makes a CPC Plus / GX4000 different from a normal CPC.

## Phase 3 — GX4000 / CPC Plus ASIC

**Status: implemented**

Phase 3 added the Plus-specific hardware.

The ASIC unlock sequence and register page were added first, followed by the 12-bit palette that gives the Plus machines their 4096-colour range.

The video side then gained the 16 hardware sprites, sprite priority and independent X/Y magnification. Raster interrupts, split-screen control and soft scrolling were also added so software can change the display during a frame in the same style as the real Plus hardware.

The other major part of Phase 3 is the three-channel ASIC DMA engine. It can fetch DMA instructions from RAM and handle the main LOAD, PAUSE, REPEAT, LOOP, INT and STOP operations. At this stage the DMA engine could generate PSG register writes, but there was not yet a sound chip connected to receive them.

The main project for this stage is:

- `GX4000_Phase3_HDMI.gprj`

## Phase 4 — sound and controllers

**Status: implemented and current main build**

Phase 4 fills in the sound and input side of the machine.

The project now has an AY-3-8912-compatible PSG with three tone channels, noise, mixer, volume and envelope support using the CPC/GX4000 1 MHz PSG timing.

An 8255-compatible PPI provides the CPU-facing control path and drives the AY through the normal BDIR/BC1 signals. The Phase 3 sound-DMA engine is connected to the same PSG registers, so DMA sound commands and ordinary CPU/PPI sound writes now control the same sound core.

The stereo mix follows the original Amstrad-style layout:

- Channel A goes to the left
- Channel B goes to both left and right
- Channel C goes to the right

Those 16-bit stereo samples are passed into the existing HDMI audio transmitter as 48 kHz LPCM.

Phase 4 also adds the CPC-style joystick matrix and Plus analogue input registers at `6808h-680Fh`.

The current project is:

- `GX4000_Phase4_HDMI.gprj`

More detail is in `docs/PHASE4_AUDIO_CONTROLLERS.md`.

## Phase 5 — integration and compatibility refinement

**Status: planned / next major stage**

Phase 5 is about taking the parts that now exist and making the whole machine more tolerant of real software and real hardware behaviour.

The main areas I want to improve here are unusual CRTC timings, edge cases in the HDMI scan conversion, reset and cartridge timing, Plus raster effects that do not fit the standard display assumptions, and general debugging visibility inside the core.

This is also the point where it makes sense to add better traces and diagnostics so problems can be narrowed down without guessing whether the fault is in the CPU, cartridge bus, ASIC, video path or DMA system.

## Phase 6 — hardware validation

**Status: planned**

The final phase is proper testing on the real Tang Nano 20K and cartridge adapter rather than relying only on structural and reference checks.

That means testing with real GX4000 cartridges, checking the cartridge bus with a logic analyser where needed, confirming HDMI behaviour on real monitors and televisions, checking sound output, controller response and reset behaviour, and then fixing any timing differences that only show up on physical hardware.

The goal of Phase 6 is to turn the project from an FPGA implementation that is logically complete into one that is actually proven against real cartridges and real peripherals.

---

# Controllers

There are not enough unused Tang Nano 20K GPIOs left to connect every controller button directly to the FPGA. The cartridge interface and onboard HDMI already use most of the available pins, so the two controller ports use a small I2C-style input expander instead.

The two FPGA pins used for the controller bus are:

| Signal | FPGA pin |
| --- | ---: |
| `ctrl_sda` | **76** |
| `ctrl_scl` | **86** |

Both signals are **3.3 V only**. The controller board should have **4.7 kΩ pull-ups to 3.3 V** on SDA and SCL.

## MCP23017 controller board

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

# FPGA pin usage

For reference, these are the pins currently reserved by the Phase 4 build.

## Cartridge interface

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

## Controller bus

| Function | FPGA pin |
| --- | ---: |
| SDA | 76 |
| SCL | 86 |

## Onboard HDMI

| Function | FPGA pins |
| --- | --- |
| TMDS clock | 33 / 34 |
| TMDS data 0 | 35 / 36 |
| TMDS data 1 | 37 / 38 |
| TMDS data 2 | 39 / 40 |

# TV80 dependency

The Z80-compatible CPU comes from the `third_party/Z80-FPGA` git submodule.

For a fresh clone, use:

```bash
git clone --recurse-submodules https://github.com/Matrixite/GX4000-clone.git
```

If the repository has already been cloned, run:

```bash
git submodule update --init --recursive
```

# Hardware safety

The real GX4000 cartridge bus uses **5 V signals**. Do not connect it directly to the Tang Nano 20K FPGA pins. Use the level-shifted cartridge adapter and keep the translator outputs disabled until the FPGA clocks and reset are stable.

The controller expansion bus is different: SDA and SCL are **3.3 V only**. Use 3.3 V pull-ups and never feed 5 V into FPGA pins 76 or 86.

# Testing status

The repository contains focused reference checks for the CPC timing and video work from Phase 2, the Plus ASIC features from Phase 3, the PPI/AY/controller/ADC work from Phase 4, and the HDMI/TMDS/audio timing.

These tests are useful for catching logic and integration mistakes, but they are not a replacement for testing on the real Tang Nano 20K, real cartridge hardware and a monitor. That is the job of the later hardware-validation phase.
