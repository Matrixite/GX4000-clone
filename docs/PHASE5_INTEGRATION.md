# Phase 5 - integration and compatibility refinement

Phase 5 keeps the Phase 4 machine core and concentrates on the parts around it that are most likely to expose timing problems on real hardware.

## Adaptive HDMI scan conversion

The earlier scan converter assumed a 312-line CPC frame and looked for source line 267 at the beginning of every 576p HDMI frame. That is correct for the normal timing, but it is fragile when software changes CRTC vertical total or vertical-total-adjust values.

`cpc_hdmi_adaptive_scanconverter.sv` now measures the number of source lines between visible-frame starts. The normal 312-line frame still selects line 267, but a 320-line frame automatically selects line 275, and so on. The measured frame length is range-checked before it is accepted.

The horizontal source counter is also widened to 11 bits. This means stretched CRTC lines no longer wrap at 1024 16 MHz clocks before HSYNC arrives. The last measured line period is exposed to the debug monitor.

The FIFO reader validates line number and frame epoch before advancing. A temporary miss repeats the previous line; four consecutive misses drop lock and force clean reacquisition rather than displaying memory that has already been overwritten by the source side.

## Cartridge startup guard

The Phase 5 board wrapper no longer exposes the Phase 4 core outputs directly during power-up.

For the first 64 cycles of the 27 MHz board clock, the cartridge translator stays disabled and the external cartridge lines are held in safe states. The translator is then enabled while the externally visible address/control lines remain safe. When the Phase 4 core finishes its own PLL/reset sequence, the wrapper waits until the generated 4 MHz cartridge clock is low and then switches the external bus over to the live core.

This gives the level shifters and cartridge interface time to settle before the first real bus transaction reaches the cartridge.

## Timing/debug overlay

Player 1 Fire 2 + Fire 3 toggles a small binary timing overlay in the top-left of the HDMI picture.

Rows show:

1. status flags (scan lock, controller state, bus/startup state, HDMI PLL, audio activity)
2. current measured source frame lines
3. minimum measured frame lines since reset
4. maximum measured frame lines since reset
5. current measured 16 MHz clocks per source line
6. minimum measured line clocks
7. maximum measured line clocks
8. scan-converter lock error count

The overlay deliberately uses binary cells rather than a font ROM, keeping the debug logic small and avoiding another block-memory allocation.

## What this does not claim

Phase 5 is still not a hardware-validation result. GOWIN synthesis/place-and-route and real-cartridge testing are Phase 6 work. In particular, unusual CRTC programs can still expose edge cases in the simplified CRTC/ASIC implementation itself; this phase makes the HDMI side more tolerant and makes those problems easier to observe.
