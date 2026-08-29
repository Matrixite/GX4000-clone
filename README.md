# GX4000 FPGA Real-Cartridge Clone — Phase 4

This project builds an Amstrad GX4000-compatible FPGA console around a Tang Nano 20K and real CPC Plus / GX4000 cartridges.

## Main project

Open `GX4000_Phase4_HDMI.gprj` and use top module `gx4000_phase4_hdmi_top`.

Current integrated path:

`real GX4000 cartridge -> mapper -> 4 MHz Z80 -> 64 KiB RAM -> CRTC/Gate Array -> Plus ASIC -> AY/PPI/controller logic -> 720x576p50 HDMI/TMDS + 48 kHz stereo LPCM`

## Phase 4 additions

- AY-3-8912-compatible PSG register interface
- CPC 1 MHz PSG timing
- three tone channels, noise, mixer and envelope
- 8255-compatible PPI mode-0 access path
- PPI-to-AY BDIR/BC1 control
- Phase-3 ASIC sound-DMA writes connected to the PSG
- CPC digital joystick matrix compatibility
- four 6-bit Plus analogue controller/paddle inputs
- ADC0-ADC7 reads at 6808h-680Fh
- A/B/C stereo routing matching the Amstrad output mix
- real 16-bit stereo samples connected to the existing HDMI audio packet path

See `docs/PHASE4_AUDIO_CONTROLLERS.md`.

## Controller hardware note

The Phase-4 core exposes real logical digital and analogue controller inputs. The standard Tang Nano HDMI top currently ties them inactive because the cartridge-adapter pinout already consumes many GPIOs and a controller-harness pin assignment has not been specified. This avoids inventing pins that may conflict with existing hardware.

## Earlier bring-up projects

The repository retains `GX4000_RealCart_RevA.gprj`, `GX4000_HDMI_Bringup.gprj`, `GX4000_Phase2_BaseCPC.gprj`, and `GX4000_Phase3_HDMI.gprj` for isolated debugging.

## CPU dependency

TV80 is pinned as the `third_party/Z80-FPGA` git submodule. Clone with `--recurse-submodules` or run `git submodule update --init --recursive` in an existing clone.

## Hardware safety

The real cartridge interface is 5 V. Use the level-shifted cartridge adapter and keep translator outputs disabled until FPGA configuration, clocks and reset are stable. Never connect the cartridge bus directly to Tang Nano 20K FPGA I/O.

## Reference validation

The source tree includes focused checks for Phase-2 CPC timing, Phase-3 Plus ASIC constants, Phase-4 PPI/AY/controller/ADC/stereo relationships, and HDMI 576p50/TMDS/audio-clock constants. Physical hardware compatibility work remains Phase 6.
