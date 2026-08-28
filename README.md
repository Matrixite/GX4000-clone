# GX4000 FPGA Real-Cartridge Clone — Rev A

This project builds an Amstrad GX4000-compatible FPGA console around a Tang Nano 20K and real CPC Plus / GX4000 cartridges.

## Projects

- `GX4000_RealCart_RevA.gprj` — real-cartridge diagnostic bring-up
- `GX4000_HDMI_Bringup.gprj` — 720x576p50 HDMI + 48 kHz stereo LPCM bring-up
- `GX4000_Phase2_BaseCPC.gprj` — Phase 2 executable CPC base core
- `GX4000_Phase2_HDMI.gprj` — integrated real cartridge + Phase 2 + HDMI/TMDS build

## Phase 2 — executable CPC base core

Phase 2 adds a 4 MHz TV80 Z80, 64 KiB RAM, deterministic CPU/video timing, CPC Gate Array palette/mode/interrupt logic, a programmable 6845-style CRTC, CPC Modes 0/1/2 video decoding, and real-cartridge ROM execution with Z80 WAIT states.

The CPU is pinned as the `third_party/Z80-FPGA` git submodule. Clone with `--recurse-submodules`, or run `git submodule update --init --recursive` in an existing clone. TV80 carries a permissive MIT-style source license.

See `docs/PHASE2_BASE_CPC.md` and `docs/FULL_CORE_ROADMAP.md`.

## Integrated Phase 2 HDMI output

`GX4000_Phase2_HDMI.gprj` now connects the Phase-2 native CPC raster to the existing HDMI/TMDS transmitter. A 32-line elastic RGB buffer converts the 15.625 kHz CPC line stream into the 31.25 kHz 720x576p50 HDMI line stream while retaining the real CPC border around the active picture.

The integrated path is:

`real cartridge -> GX4000 mapper -> Z80/RAM/CRTC/Gate Array -> scan converter -> HDMI/TMDS -> onboard HDMI`

HDMI audio transport remains enabled but carries silence until the Phase-4 AY/DMA audio source is implemented. See `docs/PHASE2_HDMI_INTEGRATION.md`.

## HDMI audio + TMDS

The HDMI transmitter implements CEA VIC 17 (720x576p50), 27 MHz pixel timing, 135 MHz OSER10 serialization, TMDS/TERC4, BCH/ECC, AVI/SPD/Audio InfoFrames and 48 kHz 16-bit stereo LPCM. The standalone `GX4000_HDMI_Bringup.gprj` still provides colour bars and a 1 kHz tone for isolated HDMI testing. See `docs/HDMI_AUDIO_TMDS.md`.

## Hardware safety

The cartridge bus is 5 V and must use the level-shifted adapter. Never connect the real cartridge bus directly to Tang Nano FPGA I/O. Keep translator outputs disabled until FPGA clocks and reset are stable.

## Validation status

Phase 2 RTL has passed structural/reference checks for CPC pixel packing, screen addressing and clock/timing constants. The scan-converter constants also verify the exact 2:1 source/HDMI line-rate relationship and the 32-line blanking budget. Physical cartridge, monitor and logic-analyser validation remain part of the hardware bring-up and compatibility phases. Phase 3 (the GX4000 ASIC enhancements) remains next.
