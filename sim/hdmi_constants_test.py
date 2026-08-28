#!/usr/bin/env python3
"""Static transport checks for the fixed GX4000 HDMI mode."""

PIXEL_CLOCK = 27_000_000
H_TOTAL = 864
V_TOTAL = 625
REFRESH = 50
AUDIO_RATE = 48_000
SERIAL_CLOCK = 135_000_000
N = 6144
CTS = 27000
NCO_INCREMENT = 7_635_497

assert H_TOTAL * V_TOTAL * REFRESH == PIXEL_CLOCK
assert SERIAL_CLOCK == PIXEL_CLOCK * 5
assert SERIAL_CLOCK * 2 == PIXEL_CLOCK * 10
assert PIXEL_CLOCK * N == 128 * AUDIO_RATE * CTS

nco_rate = NCO_INCREMENT * PIXEL_CLOCK / 2**32
ppm = (nco_rate / AUDIO_RATE - 1.0) * 1_000_000
assert abs(ppm) < 0.1

DATA_ISLAND_PIXELS = 830 - 734
assert DATA_ISLAND_PIXELS == 96
assert DATA_ISLAND_PIXELS // 32 == 3

audio_packets_per_second = AUDIO_RATE / 4
line_rate = PIXEL_CLOCK / H_TOTAL
packet_slots_per_second = line_rate * 3
assert packet_slots_per_second > audio_packets_per_second + 1000

print(f"576p50 clock check: {H_TOTAL}*{V_TOTAL}*{REFRESH} = {PIXEL_CLOCK} Hz")
print(f"TMDS bit rate: {SERIAL_CLOCK * 2 / 1e6:.1f} Mbit/s per lane")
print(f"ACR check: N={N}, CTS={CTS}, fs={AUDIO_RATE} Hz")
print(f"NCO average audio rate: {nco_rate:.9f} Hz ({ppm:+.6f} ppm)")
print(f"Data-island capacity: {packet_slots_per_second:.1f} packets/s")
print("HDMI transport constants: PASS")
