# Phase 4 — AY audio, PPI and controllers

Phase 4 connects the CPC/GX4000 sound and controller path to the Phase-3 machine and the existing HDMI audio transport.

## Implemented

- AY-3-8912-compatible 16-register PSG interface
- 1 MHz CPC PSG timing derived from the 16 MHz machine master
- three tone generators, shared noise generator, mixer and envelope path
- 8255-compatible mode-0 PPI path
- PPI Port A data bus to AY
- PPI Port C bits 7/6 as AY BDIR/BC1
- PPI Port C bits 3-0 as keyboard/joystick row select
- CPU AY access through the normal CPC PPI sequence
- Phase-3 ASIC DMA PSG writes connected to the same PSG register file
- digital joystick 0 at matrix row 9 and joystick 1 at row 6
- active-low up/down/left/right/fire1/fire2/optional fire3 mapping
- ASIC ADC0-ADC7 reads at 6808h-680Fh
- four external 6-bit analogue-axis inputs at ADC0-ADC3
- ADC4..ADC7 fixed to 3F,00,3F,00
- stereo mix: AY A -> left, B -> both, C -> right
- signed 16-bit stereo audio fed into the existing 48 kHz HDMI LPCM transport

## PPI / AY access

The PPI uses CPC partial address decoding: A11 low selects the PPI and A9:A8 choose Port A, B, C or control. Conventional addresses are F4xx, F5xx, F6xx and F7xx.

AY BDIR/BC1 are driven by PPI Port C bits 7/6: 00 inactive, 01 read, 10 write, 11 select register.

## Digital joystick matrix

Logical joystick vectors use active-low bits: bit0 up, bit1 down, bit2 left, bit3 right, bit4 fire2, bit5 fire1, bit6 optional fire3. Joystick 0 appears on matrix row 9 and joystick 1 on row 6.

## Analogue controls

The core exposes four 6-bit values for ADC0-ADC3, corresponding to two X/Y analogue sticks or four paddles. Software reads them through the paged Plus ASIC registers at 6808h-680Bh.

## Physical controller harness

`gx4000_phase4_top` exposes logical digital and analogue controller inputs. The standard Tang Nano HDMI wrapper intentionally ties them inactive because the existing cartridge adapter already reserves many FPGA pins and no physical controller-harness pin assignment has been specified. Add a reviewed harness CST when the connector/header wiring is known.

## Main build

Open `GX4000_Phase4_HDMI.gprj` and use top module `gx4000_phase4_hdmi_top`.

The integrated path is:

`real cartridge -> Z80/RAM -> CRTC/Gate Array -> Plus ASIC -> AY/PPI/controllers -> video scan converter + stereo HDMI/TMDS`

## Validation

`sim/phase4_audio_io_reference_test.py` covers PPI decode, AY control modes, joystick matrix bits, ADC addresses, PSG timing relationships and stereo routing. Existing Phase 2, Phase 3 and HDMI reference tests remain as regressions.
