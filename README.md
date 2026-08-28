# GX4000 FPGA Real-Cartridge Clone

Tang Nano 20K FPGA recreation of the Amstrad GX4000 using real CPC Plus / GX4000 cartridges and onboard HDMI.

## Main build

`GX4000_Phase3_HDMI.gprj`

Current path: `real cartridge -> GX4000 mapper -> 4 MHz TV80 Z80 -> 64 KiB RAM -> CRTC/Gate Array -> Plus ASIC -> scan converter -> HDMI/TMDS`.

## Phase 3

The integrated core now includes ASIC unlock/RMR2 mapping, a 32-entry 12-bit palette, 16 hardware sprites with transparency/priority/x1-x4 zoom, programmable raster interrupts, split-screen and soft-scroll registers, Plus interrupt vectors, and the three-channel DMA list engine with LOAD/PAUSE/REPEAT/LOOP/INT/STOP commands.

See `docs/PHASE3_PLUS_ASIC.md`.

The DMA engine exports PSG register writes, but the AY/PPI sound generator is Phase 4, so HDMI audio remains silent for now. The existing HDMI transport is still true 720x576p50 HDMI with 48 kHz 16-bit stereo LPCM packet support.

TV80 remains a git submodule under `third_party/Z80-FPGA`; initialize it with `git submodule update --init --recursive`.

The cartridge bus is 5 V and must use the level-shifted adapter. `XLAT_OE_N` remains disabled until clock/reset startup completes.

Phase 4 is AY-3-8912/PPI/controllers and connection of CPU/DMA PSG writes to audible HDMI audio.
