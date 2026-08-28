# GX4000 FPGA Real-Cartridge Clone — Rev A

This is a **hardware bring-up revision** for building an Amstrad GX4000-compatible FPGA console around a Tang Nano 20K while using **real CPC Plus / GX4000 cartridges**.

Rev A deliberately starts with the cartridge interface because the physical cartridge bus is 5 V and must be proved safe before a full GX4000 core is connected to it.

## What this revision does

- Defines the real 36-contact (2x18) GX4000/CPC Plus cartridge bus.
- Drives A0-A13 and CA14-CA18.
- Drives cartridge `/CE`.
- Provides `CLK4` and `CCLR` outputs and samples `SIN` for ACID diagnostics.
- Reads the cartridge D0-D7 bus.
- Includes a synthesizable real-cartridge diagnostic reader.
- Dumps cartridge bytes over UART at 115200 baud.
- Includes the GX4000 cartridge page-translation logic described by the Arnold V specification.
- Includes an ASIC/core integration shell for the later playable core.
- Includes a testbench for cartridge bank translation.

## Software needed to program the FPGA

For the **Tang Nano 20K** build, use **GOWIN EDA**.

GOWIN EDA is used to compile the HDL, synthesize the FPGA design, perform place-and-route, generate the bitstream, and program the Tang Nano 20K.

The main real-cartridge diagnostic project is:

`GX4000_RealCart_RevA.gprj`

The HDMI audio/TMDS bring-up project is:

`GX4000_HDMI_Bringup.gprj`

## Important: do NOT wire a cartridge directly to the Tang Nano 20K

The original cartridge bus is a **5 V interface**. The FPGA side is 3.3 V. Use proper level translation for address/control, D0-D7 and `SIN`, and keep translator enables disabled until configuration is complete.

## Cartridge connector

The original system uses a female 2x18 cartridge-edge connector. See `docs/CARTRIDGE_BUS.md`.

## HDMI audio + TMDS bring-up

The standalone HDMI build targets the Tang Nano 20K onboard HDMI connector and implements:

- CEA VIC 17 / 720x576p50
- 27 MHz pixel clock
- 135 MHz OSER10 serializer clock
- 270 Mbit/s per TMDS lane
- full TMDS video/control encoding
- TERC4 HDMI data islands
- BCH/ECC packet assembly
- 48 kHz, 16-bit stereo LPCM
- Audio Sample Packets
- Audio Clock Regeneration using N=6144 and CTS=27000
- Audio, AVI and SPD InfoFrames
- TLVDS differential outputs on the onboard HDMI pairs
- colour-bar test image and 1 kHz stereo test tone

Open `GX4000_HDMI_Bringup.gprj` and use `gx4000_hdmi_bringup_top` as the top module.

The HDMI packet/TMDS code is self-contained under `third_party/hdl-util-hdmi/hdmi_bundle.sv`, derived from the MIT-licensed `hdl-util/hdmi` project and documented in `third_party/hdl-util-hdmi/LICENSE-MIT`.

See `README_HDMI_AUDIO.md` and `docs/HDMI_AUDIO_TMDS.md`.

## Status

The cartridge diagnostic path and HDMI bring-up path are separate builds. The HDMI source has been statically checked, but **GOWIN synthesis/place-and-route and physical Tang Nano 20K testing have not yet been run in this environment**.

The full playable GX4000 CPU/ASIC/video/audio core remains unfinished; the reusable HDMI transport is ready to accept future GX4000 RGB and stereo PCM sources.
