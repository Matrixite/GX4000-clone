# Full playable GX4000 roadmap

## Phase 1 — real cartridge electrical bring-up
Included in Rev A.

- 5 V-safe cartridge adapter
- address/page drive
- ROM read
- ACID link observation
- UART cartridge dump

## Phase 2 — CPU + base CPC timing — IMPLEMENTED IN RTL, HARDWARE VALIDATION PENDING
- [x] Z80-compatible CPU at 4 MHz (TV80 submodule)
- [x] 64 KiB RAM
- [x] deterministic CPU/video slot arbitration
- [x] I/O decode
- [x] Gate Array compatible mode/palette/interrupt registers
- [x] programmable 6845-style CRTC timing
- [x] CPC modes 0/1/2 pixel decoding
- [x] real-cartridge ROM execution path with WAIT states
- [ ] GOWIN synthesis/place-and-route validation
- [ ] physical logic-analyser validation and contention tuning

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
