# GX4000 FPGA Real-Cartridge Clone — Rev A

This project builds an Amstrad GX4000-compatible FPGA console around a Tang Nano 20K and real CPC Plus / GX4000 cartridges.

## Projects

- `GX4000_RealCart_RevA.gprj` — real-cartridge diagnostic bring-up
- `GX4000_HDMI_Bringup.gprj` — 720x576p50 HDMI + 48 kHz stereo LPCM bring-up
- `GX4000_Phase2_BaseCPC.gprj` — Phase 2 executable CPC base core

## Phase 2 — executable CPC base core

Phase 2 adds a 4 MHz TV80 Z80, 64 KiB RAM, deterministic CPU/video timing, CPC Gate Array palette/mode/interrupt logic, a programmable 6845-style CRTC, CPC Modes 0/1/2 video decoding, and real-cartridge ROM execution with Z80 WAIT states.

The CPU is pinned as the `third_party/Z80-FPGA` git submodule. Clone with `--recurse-submodules`, or run `git submodule update --init --recursive` in an existing clone. TV80 carries a permissive MIT-style source license.

See `docs/PHASE2_BASE_CPC.md` and `docs/FULL_CORE_ROADMAP.md`.

## HDMI audio + TMDS

The standalone HDMI build implements CEA VIC 17 (720x576p50), 27 MHz pixel timing, 135 MHz OSER10 serialization, TMDS/TERC4, BCH/ECC, AVI/SPD/Audio InfoFrames and 48 kHz 16-bit stereo LPCM. See `docs/HDMI_AUDIO_TMDS.md`.

## Hardware safety

The cartridge bus is 5 V and must use the level-shifted adapter. Never connect the real cartridge bus directly to Tang Nano FPGA I/O. Keep translator outputs disabled until FPGA clocks and reset are stable.

## Validation status

Phase 2 RTL has passed structural/reference checks for CPC pixel packing, screen addressing and clock/timing constants. GOWIN EDA is not installed in the current execution environment, so synthesis/place-and-route and physical cartridge/logic-analyser validation are still required. Phase 3 (the GX4000 ASIC enhancements) remains next.
