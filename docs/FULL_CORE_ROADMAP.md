# Full playable GX4000 roadmap

## Phase 1 — real cartridge electrical bring-up — implemented
- 5 V-safe cartridge adapter design
- address/page drive
- ROM read path
- ACID link observation path
- UART cartridge dump

## Phase 2 — CPU + base CPC timing — implemented
- TV80 Z80-compatible CPU at 4 MHz
- 64 KiB RAM
- CPU/video access timing
- I/O decode
- Gate Array compatible mode/palette registers
- programmable CRTC timing
- CPC modes 0/1/2
- real-cartridge execution path
- integrated 720x576p50 HDMI/TMDS output

## Phase 3 — GX4000 / CPC Plus ASIC — implemented in RTL
- ASIC unlock/relock state machine
- RMR2 and memory-mapped register page at 4000-7FFF
- 32-entry 12-bit RGB palette
- 16 x 16 hardware sprites, 16 sprites
- independent x1/x2/x4 sprite zoom
- programmable raster interrupt
- screen split / secondary start address
- horizontal and vertical soft scroll
- interrupt vector/source handling
- three-channel sound-DMA list engine
- DMA PAUSE/REPEAT/LOOP/INT/STOP and PSG LOAD commands
- DMA status/interrupts

## Phase 4 — audio and controllers — implemented in RTL
- AY-3-8912-compatible PSG
- CPC/GX4000 mode-0 PPI path
- CPU PSG access through PPI Port A / Port C BDIR+BC1
- Phase-3 DMA PSG writes connected to the same PSG registers
- AY tone, noise, mixer, amplitude and envelope path
- CPC+/GX4000 stereo mix: A left, B both, C right
- stereo 16-bit audio into existing 48 kHz HDMI LPCM transport
- digital joystick matrix rows 9 and 6
- optional third-fire matrix bits
- Plus ADC0-ADC7 register reads at 6808-680F
- four 6-bit external analogue channels for two sticks / four paddles
- two-wire MCP23017 controller adapter on FPGA pins 76/86

## Phase 5 — presentation / system integration — implemented in RTL
- adaptive HDMI scan conversion measures source frame length instead of assuming 312 lines
- widened source-line timing counter for stretched CRTC line periods
- FIFO line/epoch validation and clean lock reacquisition after repeated misses
- guarded cartridge startup with translator precharge and safe bus handover
- timing trace with min/max frame and line measurements
- on-screen binary debug overlay toggled by Player 1 Fire 2 + Fire 3
- controller-harness pin constraints integrated into the main build
- main project: `GX4000_Phase5_HDMI.gprj`

## Phase 6 — compatibility validation
Test real cartridges with logic-analyser captures and tune edge cases.

Priority examples:
- Burnin' Rubber
- Batman the Movie
- Pang
- Switchblade
- Navy Seals
- Robocop 2
