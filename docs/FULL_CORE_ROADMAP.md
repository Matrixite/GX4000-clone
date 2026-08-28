# Full playable GX4000 roadmap

## Phase 1 — real cartridge electrical bring-up
Included in Rev A.

- 5 V-safe cartridge adapter
- address/page drive
- ROM read
- ACID link observation
- UART cartridge dump

## Phase 2 — CPU + base CPC timing
- Z80-compatible CPU at 4 MHz
- 64 KiB RAM
- memory arbitration
- I/O decode
- Gate Array compatible mode/palette registers
- CRTC timing
- CPC modes 0/1/2

## Phase 3 — GX4000 ASIC
- ASIC unlock state machine
- ASIC register page at 0x4000-0x7FFF
- 12-bit palette
- 16 x 16 hardware sprites, 16 sprites
- sprite zoom
- programmable raster interrupt
- soft scroll
- split screen
- DMA channels and interrupts
- DMA sound

## Phase 4 — audio and controllers
- AY-3-8912 compatible PSG
- PPI behaviour needed by GX4000 software
- digital joystick ports
- optional analogue paddle support

## Phase 5 — Tang Nano 20K presentation layer
- exact 16 MHz system timing domain
- HDMI video scaler/output
- HDMI or I2S audio
- reset and cartridge-presence handling
- optional UART debugger

## Phase 6 — compatibility validation
Test real cartridges with logic-analyser captures.

Priority examples:
- Burnin' Rubber
- Batman the Movie
- Pang
- Switchblade
- Navy Seals
- Robocop 2
