# GX4000 HDMI audio + TMDS bring-up

The standalone HDMI project remains available as `GX4000_HDMI_Bringup.gprj`, with top module `gx4000_hdmi_bringup_top`.

It provides 720x576p50 colour bars, true HDMI data islands, 48 kHz 16-bit stereo LPCM, and a 1 kHz stereo test tone. Transport blocks include 27 MHz pixel / 135 MHz OSER10 clocking, TMDS video/control encoding, TERC4 data islands, BCH/ECC, N=6144 / CTS=27000 audio clock regeneration, Audio/AVI/SPD InfoFrames, OSER10 serializers and TLVDS outputs.

The HDMI transport accepts 4-bit RGB and signed 16-bit stereo PCM. The Phase 4 build now feeds the integrated GX4000 video and AY stereo audio paths into this transmitter.

See `docs/HDMI_AUDIO_TMDS.md` for transport details.
