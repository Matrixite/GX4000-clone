# Phase 2 + HDMI/TMDS integration

`GX4000_Phase2_HDMI.gprj` is the first single build that joins the previously separate real-cartridge, Phase-2 CPC core and HDMI/TMDS work.

## Data path

```text
real GX4000 cartridge
        |
        v
5 V-safe adapter / XLAT_OE_N
        |
        v
GX4000 cartridge mapper + WAIT bridge
        |
        v
TV80 Z80 + 64 KiB RAM + CRTC + Gate Array
        |
        v
native 16 MHz CPC RGB / HSYNC / VSYNC / DE
        |
        v
32-line elastic scan converter
        |
        v
720x576p50 HDMI packet/TMDS encoder
        |
        v
OSER10 + TLVDS -> Tang Nano 20K onboard HDMI
```

## Scan conversion

The CPC source line rate is exactly 15.625 kHz with the Phase-2 16 MHz / 1024-pixel default raster. VIC 17 HDMI is 31.25 kHz (`27 MHz / 864`), exactly twice that line rate.

The integration therefore uses a line-based converter rather than a large full-frame buffer:

- 32 stored lines
- 720 RGB444 pixels per stored line
- about 276 kbit of line storage
- each CPC source line is emitted twice
- source pixels 248..967 relative to HSYNC form the 720-pixel HDMI crop
- source line 267 is used as the start of the 288-source-line HDMI window
- the window includes the real CPC border and the 200 active display lines
- HDMI vertical blanking is used as the elastic period before relocking the next frame

This keeps the existing 64 KiB Phase-2 RAM in FPGA block RAM and avoids adding a second full video frame buffer.

## HDMI audio

The HDMI packet layer remains fully enabled at 48 kHz, 16-bit stereo LPCM. Phase 2 has no AY/ASIC audio generator yet, so this integrated build currently supplies digital silence. Phase 4 can connect the AY + DMA mixer directly to the existing `gx4000_hdmi_tx` audio inputs.

## Projects retained for debugging

The earlier standalone projects are intentionally kept:

- `GX4000_RealCart_RevA.gprj` — cartridge/UART bring-up
- `GX4000_HDMI_Bringup.gprj` — HDMI colour bars + 1 kHz tone
- `GX4000_Phase2_BaseCPC.gprj` — raw Phase-2 CPC core
- `GX4000_Phase2_HDMI.gprj` — integrated cartridge + Phase 2 + HDMI build

## Current scope

The scan converter is tuned to the standard Phase-2 CRTC raster. Exotic CRTC totals, Plus soft-scroll and raster effects will need to be folded into the Phase-3/compatibility work rather than treated as already complete here.
