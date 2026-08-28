# Phase 3 — GX4000 / CPC Plus ASIC

Phase 3 connects the enhanced Amstrad Plus/GX4000 ASIC features to the Phase-2 Z80, RAM, cartridge and HDMI path.

## Main build

Open `GX4000_Phase3_HDMI.gprj`; top module: `gx4000_phase3_hdmi_top`.

Data path: `real cartridge -> mapper -> TV80 Z80 -> RAM/CRTC/Gate Array -> Plus ASIC -> CPC-to-HDMI scan converter -> HDMI/TMDS`.

## Implemented

- ASIC lock/unlock synchronization and sequence `FF 77 B3 51 A8 D4 62 39 9C 46 2B 15 8A CD EE`
- RMR2 register-page mapping over `4000-7FFF`
- 32 RGB444 palette entries at `6400-643F`
- 16 hardware sprites, 16x16x4-bit, transparent pixel 0, sprite priority, x1/x2/x4 zoom
- sprite RAM at `4000-4FFF` and attributes at `6000-607F`
- PRI, SPLT, SSA, SSCR and IVR registers at `6800-6805`
- programmable raster interrupt timing and Plus vector/source handling
- screen split, secondary start address, horizontal and vertical soft scroll
- three DMA channels with SAR/PPR/DCSR
- physical-RAM DMA list fetches independent of ROM mapping
- PSG LOAD, PAUSE, REPEAT, LOOP, INT and STOP commands
- DCSR enable/status/acknowledge handling and exported PSG register writes

The DMA engine now generates PSG register writes. Audible AY/PPI synthesis remains Phase 4, so HDMI audio stays silent in the Phase-3 build.

## Validation

Reference tests cover the unlock sequence, RMR2 page-in value, 12-bit palette byte ordering, CRTC compare-line formation, sprite layout/zoom, DMA opcode classes and the CPC/HDMI line-rate relationship. Static RTL delimiter/module and named-port checks also pass.

## Remaining compatibility tuning

Later real-hardware work can refine edge cases such as exact type-3 CRTC quirks, live sprite-RAM access side effects, split timing in unusual vertical-adjust cases, and exact CPU/PPI arbitration around DMA LOAD commands.

The register map and functional behaviour follow the Arnold V Issue 1.5 specification and Kevin Thacker's measured CPC Plus hardware notes.
