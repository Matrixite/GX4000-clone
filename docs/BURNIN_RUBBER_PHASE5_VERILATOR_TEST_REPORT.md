# Burnin' Rubber — Phase 5 Verilator core test

## Result

The cartridge now boots in the real Verilated GX4000 RTL model and produces both video and stereo AY audio.

The test uses the project's TV80 Z80 CPU, cartridge mapper/bridge, 64 KiB RAM, CRTC, Gate Array, Plus ASIC, DMA, PPI and AY implementation. No GX4000 software emulator was used for the capture.

## Bugs found during the test

1. Z80 I/O write cycles were being consumed more than once by 16 MHz peripheral logic. This prevented the Plus ASIC unlock sequence from completing reliably. A one-shot bus-write strobe in the simulation copy fixes this; the ASIC then unlocks and Burnin' Rubber programs its CRTC normally.
2. The synchronous video RAM fetch pipeline captured both display bytes one 16 MHz clock late. Moving the byte-0 capture from pixel phase 2 to 1 and the byte-pair latch from phase 3 to 2 fixes the repeated vertical-bar / corrupt-text output.
3. `within` in the video RTL is a SystemVerilog reserved keyword for Verilator. The simulation copy renames it to `within_slot`; this does not change the logic.

## Confirmed after the fixes

- CPR pages cb00-cb07 are read by the real cartridge-bus model.
- Boot switches to cartridge page 4 and jumps to C000 as expected.
- Plus ASIC unlock completes.
- Burnin' Rubber programs the CRTC.
- The title/setup text renders correctly from the core video path.
- Simulated Fire 1 input is detected and advances from the title to the controller/gears setup screen.
- AY stereo output becomes non-zero and is captured at 48 kHz.

## Capture

The supplied MP4 is made from the core's native RGB/HSYNC/VSYNC signals, scaled 2x vertically with nearest-neighbour scaling, with the core AY left/right samples encoded as stereo audio. It is not an emulator recording.

The capture reaches the first setup screen after pressing Fire 1. A longer simulation is still needed to show the qualifying race itself.
