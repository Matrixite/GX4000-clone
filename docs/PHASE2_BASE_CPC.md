# Phase 2 — CPU + base CPC timing

Phase 2 introduces the first executable machine core between the real cartridge interface and the later GX4000 ASIC work.

## Implemented in this milestone

- TV80 Z80-compatible CPU, enabled at 4 MHz from the 16 MHz CPC master domain
- 64 KiB base RAM with synchronous CPU and video ports
- deterministic CPU/video slot timing
- real-cartridge ROM reads through the existing GX4000 cartridge mapper
- Z80 WAIT-state bridge while the physical cartridge bus settles
- writes to RAM underneath enabled ROM windows
- Gate Array I/O decode at `7Fxx`
- classic pen select, ink programming, border ink and 27-colour palette
- screen mode / ROM configuration register
- mode changes latched on HSYNC
- classic CPC 52-HSYNC interrupt counter and interrupt acknowledge handling
- expansion/cartridge ROM select at `DFxx`
- 6845-style CRTC register select at `BCxx`, write at `BDxx`, readback at `BFxx`
- CRTC R0-R17 register file and standard non-interlaced timing
- CRTC start-address / MA / RA generation
- CPC display memory address formation from MA/RA/CCLK
- CPC Mode 0, Mode 1, Mode 2 and undocumented Mode 3 pixel unpacking
- 4-bit RGB output using CPC+ equivalents of the classic CPC hardware palette
- exact 16 MHz master generated as 27 MHz -> 32 MHz rPLL -> divide-by-two
- exact 4 MHz cartridge clock and safe translator enable

## CPU dependency

The project uses the Verilog TV80 Z80 core from `Obijuan/Z80-FPGA`, pinned as a git submodule at commit:

`d61a7907f3a9dc3598c6508360011c0f99edf8e1`

TV80's source files carry Guy Hutchison's permissive MIT-style license notice. Clone this repository recursively:

```bash
git clone --recurse-submodules https://github.com/Matrixite/GX4000-clone.git
```

If the repository was already cloned:

```bash
git submodule update --init --recursive
```

## GOWIN project

Open:

`GX4000_Phase2_BaseCPC.gprj`

Top module:

`gx4000_phase2_top`

The project targets `GW2AR-LV18QN88C8/I7`.

## What Phase 2 does not claim yet

This is a **base CPC/GX4000 execution core milestone**, not a finished GX4000.

Still outside Phase 2:

- CPC+/GX4000 ASIC unlock/register page
- 12-bit programmable Plus palette RAM
- hardware sprites, zoom, soft scroll and split screen
- PRI / ASIC interrupts
- DMA channels and DMA sound
- AY-3-8912 and PPI/controller path (Phase 4)
- HDMI scaling of the native CPC raster (Phase 5)
- CRTC type-specific undocumented quirks
- cycle-perfect original DRAM RAS/CAS/READY contention

The RAM architecture uses deterministic CPU and video slots with dual synchronous ports. This gives stable 4 MHz CPU timing and correct video addressing, but Phase 6 logic-analyser work is still required to tune contention and CRTC edge cases against real hardware.

## Validation status

The source tree has static structural checks and focused Python reference tests for:

- CPC Mode 0/1/2 pixel unpacking
- CPC screen-address mapping
- 27-colour hardware palette values
- standard CRTC timing constants
- 16/4/1 MHz clock relationships

GOWIN EDA is not installed in the current execution environment, so synthesis, place-and-route and physical real-cartridge testing are still required before this milestone can be called hardware-verified.
