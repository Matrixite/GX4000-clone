# Full playable GX4000 roadmap

## Phase 1 — real cartridge electrical bring-up — implemented
- 5 V-safe adapter design
- address/page drive, ROM read, ACID observation, UART dump

## Phase 2 — CPU + base CPC timing — implemented
- 4 MHz TV80 Z80, 64 KiB RAM, CRTC/Gate Array, CPC modes 0/1/2
- real-cartridge execution and integrated 720x576p50 HDMI/TMDS

## Phase 3 — GX4000 / CPC Plus ASIC — implemented in RTL
- ASIC unlock/relock and RMR2 register page
- 32-entry 12-bit palette
- 16 hardware sprites with x1/x2/x4 zoom
- programmable raster interrupt
- screen split / secondary address
- horizontal and vertical soft scroll
- Plus interrupt vector/source handling
- three-channel sound-DMA engine, status and interrupts
- DMA PAUSE/REPEAT/LOOP/INT/STOP and PSG LOAD

## Phase 4 — audio and controllers — next
- AY-3-8912 compatible PSG
- Plus-compatible PPI behaviour
- CPU + Phase-3 DMA PSG writes
- stereo mixer to existing HDMI LPCM
- joystick ports and optional analogue paddles

## Phase 5 — presentation/system integration
- refine scaler for non-standard CRTC timings
- reset/cartridge-presence handling
- optional UART trace

## Phase 6 — compatibility validation
Real-cartridge and logic-analyser tuning. Priority examples: Burnin' Rubber, Batman the Movie, Pang, Switchblade, Navy Seals, Robocop 2.
