# GX4000 HDMI audio + TMDS bring-up

This package adds a standalone Tang Nano 20K HDMI transmitter bring-up build for the GX4000 FPGA project.

## Open this GOWIN project

`GX4000_HDMI_Bringup.gprj`

Top module:

`gx4000_hdmi_bringup_top`

## Expected hardware result

After synthesis, place-and-route and programming, connect the Tang Nano 20K onboard HDMI socket to an HDMI display.

The test build is intended to output:

- 720x576p50 colour bars
- true HDMI data islands (not DVI-only)
- 48 kHz, 16-bit stereo LPCM
- a 1 kHz stereo test tone

## Implemented transport blocks

- 27 MHz pixel / 135 MHz OSER10 clock generation
- TMDS video/control encoding
- TERC4 data-island encoding
- HDMI guard bands and preambles
- BCH/ECC packet generation
- Audio Clock Regeneration, N=6144 / CTS=27000
- IEC-60958 stereo LPCM Audio Sample Packets
- Audio InfoFrame
- AVI InfoFrame (VIC 17)
- SPD InfoFrame (`MATRIX`, `GX4000 FPGA`, source type Game)
- four OSER10 serializers (three data + one clock)
- TLVDS differential output buffers

See `docs/HDMI_AUDIO_TMDS.md` for integration details.

## Status

Static source checks and transport-math checks pass in this environment. GOWIN EDA is not installed here, so this package has **not yet been synthesised, place-and-routed, or tested on physical Tang Nano 20K hardware**.

The HDMI transport accepts 4-bit RGB and signed 16-bit stereo PCM, but the full GX4000 CPU/ASIC/video/audio core is still a separate unfinished part of the project.
