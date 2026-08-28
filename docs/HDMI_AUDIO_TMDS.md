# HDMI audio + TMDS implementation

This project now contains a true HDMI 1.4-style data-island path rather than DVI-only video.

## Output mode

- CEA VIC 17: 720x576 progressive, 50 Hz
- Pixel clock: 27 MHz
- TMDS serializer clock: 135 MHz
- Audio: 2-channel LPCM, 16-bit, 48 kHz
- Product type InfoFrame: Game
- Tang Nano 20K onboard HDMI connector

576p50 was deliberately selected because its 27 MHz pixel clock exactly matches the Tang Nano 20K oscillator. A 135 MHz rPLL output is divided by 5 for the pixel clock, keeping OSER10 PCLK/FCLK phase-related. The bring-up top holds the HDMI pipeline in reset for 256 input-clock cycles after PLL lock while the divided pixel clock is already running.

## HDMI packet support

The transmitter includes:

- normal TMDS video/control encoding
- TERC4 data-island encoding
- video and data-island guard bands/preambles
- BCH/ECC packet assembly
- Audio Clock Regeneration (N/CTS)
- stereo LPCM Audio Sample Packets
- Audio InfoFrame
- AVI InfoFrame
- Source Product Description InfoFrame

The HDMI packet/encoding modules are vendored from `hdl-util/hdmi`, MIT licensed, pinned to commit `83b1c9543a91b776671a44e68e130f81cae437b7`. The Gowin serializer is project-local and uses four `OSER10` blocks: three TMDS data lanes plus a serialized TMDS clock character for phase-aligned clock/data output.

## Bring-up build

Open `GX4000_HDMI_Bringup.gprj` in GOWIN EDA and set `gx4000_hdmi_bringup_top` as the top module.

The bring-up design displays colour bars and sends a 1 kHz stereo test tone. This proves the PHY, TMDS encoder, data-island packet path, and PCM audio transport independently of the unfinished GX4000 machine core.

## Core integration

`gx4000_hdmi_tx.sv` is reusable. It accepts:

- 4-bit R/G/B
- signed 16-bit left/right PCM
- 27 MHz pixel clock
- 135 MHz serializer clock
- ~48 kHz audio sample clock

It returns `pixel_x`/`pixel_y`, allowing the future GX4000 renderer/scaler to generate the pixel requested by the HDMI timing generator.

The original GX4000 analogue-rate video still needs a line doubler/scaler/framebuffer before it can become 576p50. That is separate from TMDS/audio packet encoding.

## Hardware testing status

The code is structurally prepared for GOWIN EDA but has not been synthesised or tested on a physical Tang Nano 20K in this environment.

## Cartridge adapter pin compatibility

The HDMI bring-up design deliberately does not use the Tang Nano user LEDs. The real-cartridge adapter reserves FPGA pin 20 for `XLAT_OE_N` and uses several other LED-bank pins for cartridge signals. HDMI itself is confined to the onboard differential pairs on FPGA pins 33 through 40, so there is no cartridge GPIO conflict.
