# GX4000 FPGA Real-Cartridge Clone — Rev A

This is a **hardware bring-up revision** for building an Amstrad GX4000-compatible FPGA console around a Tang Nano 20K while using **real CPC Plus / GX4000 cartridges**.

Rev A deliberately starts with the cartridge interface because the physical cartridge bus is 5 V and must be proved safe before a full GX4000 core is connected to it.

## What this revision does

- Defines the real 36-contact (2x18) GX4000/CPC Plus cartridge bus.
- Drives A0-A13 and CA14-CA18.
- Drives cartridge `/CE`.
- Provides `CLK4` and `CCLR` outputs and samples `SIN` for ACID diagnostics.
- Reads the cartridge D0-D7 bus.
- Includes a synthesizable real-cartridge diagnostic reader.
- Dumps cartridge bytes over UART at 115200 baud.
- Includes the GX4000 cartridge page-translation logic described by the Arnold V specification.
- Includes an ASIC/core integration shell for the later playable core.
- Includes a testbench for cartridge bank translation.

## Important: do NOT wire a cartridge directly to the Tang Nano 20K

The original cartridge bus is a **5 V interface**. The FPGA side is 3.3 V.

Use level translation:

- FPGA -> cartridge address/control: 3.3 V to 5 V translation.
- Cartridge D0-D7 -> FPGA: 5 V to 3.3 V translation.
- Cartridge `SIN` -> FPGA: 5 V to 3.3 V translation.

A practical adapter can use:

- 3x SN74LVC8T245 for A0-A13, CA14-CA18, `/CE`, `CLK4`, `CCLR`.
- 1x SN74LVC8T245 for D0-D7 in the cartridge-to-FPGA direction.
- 1x single-bit dual-supply translator for `SIN` (or one spare channel on another suitable translator).

The translator enables should default to the **safe / disabled** state until FPGA configuration is complete.

## Cartridge connector

The original system uses a female 2x18 cartridge-edge connector.

Logical signals used by this project:

- A0-A13
- CA14-CA18
- D0-D7
- /CE
- CLK4
- CCLR
- SIN
- +5V
- GND

See `docs/CARTRIDGE_BUS.md`.

## ACID behaviour

A genuine cartridge contains the ACID identification chip. On original hardware the ASIC checks the cartridge's serial `SIN` stream and intentionally disrupts RAM accesses when authentication fails.

This clone does **not need to reproduce that anti-copy penalty to read a genuine cartridge**. Rev A still clocks and resets the cartridge ACID and samples `SIN` so the link can be examined and a cycle-accurate ASIC-side checker can be added later.

## Cartridge banking

The cartridge can contain up to 32 x 16 KiB pages (512 KiB).

The mapper module implements:

- low cartridge page: RMR2 bits 2:0 -> physical pages 0..7
- high cartridge page:
  - logical ROM 0 or 7 -> physical page 3
  - logical ROM 1..127 -> physical page 1
  - logical ROM 128..255 -> physical pages 0..31 using bits 4:0

See `rtl/cart/gx4000_cart_mapper.sv`.

## First hardware test

1. Build the level-shifted cartridge adapter.
2. Leave the cartridge disconnected and verify:
   - no FPGA pin is exposed to 5 V,
   - `/CE` is high while FPGA is unconfigured,
   - output translators are disabled while FPGA is unconfigured.
3. Fit the Tang Nano 20K and program the diagnostic core.
4. Verify address/control voltages before inserting a cartridge.
5. Power down.
6. Insert a cartridge.
7. Power up.
8. Capture the UART output at 115200 8N1.
9. The diagnostic core reads the first 256 bytes of cartridge page 0 and prints them as hexadecimal.

## Full GX4000 core architecture

The playable core will connect these blocks:

- Z80-compatible CPU, 4 MHz
- 64 KiB RAM
- CPC Gate Array-compatible video/memory timing
- integrated 6845-style CRTC behaviour
- CPC Plus/GX4000 ASIC register page
- 12-bit (4096-colour) palette
- 16 hardware sprites
- raster interrupts
- split-screen / soft scrolling
- ASIC DMA audio
- AY-3-8912-compatible PSG
- PPI / joystick interface
- cartridge mapper from this Rev A project
- HDMI video/audio wrapper for Tang Nano 20K

`rtl/top/gx4000_core_shell.sv` defines the integration boundary but intentionally does not pretend the CPU/ASIC implementation is finished.

## Status

**Rev A is a real-cartridge electrical/logic bring-up project, not yet a complete playable GX4000 core.**

That distinction is intentional: a wrong 5 V cartridge interface can damage the FPGA, so the physical bus is separated and testable before the complete console logic is added.
