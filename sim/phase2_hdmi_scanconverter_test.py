SRC_CLOCK = 16_000_000
SRC_TOTAL_X = 1024
HDMI_CLOCK = 27_000_000
HDMI_TOTAL_X = 864
FIFO_LINES = 32
LINE_PIXELS = 720
BITS_PER_PIXEL = 12
TARGET_FIRST_LINE = 267

src_line_rate = SRC_CLOCK / SRC_TOTAL_X
hdmi_line_rate = HDMI_CLOCK / HDMI_TOTAL_X
assert src_line_rate == 15_625
assert hdmi_line_rate == 31_250
assert hdmi_line_rate == 2 * src_line_rate

# 576 HDMI active lines = 288 doubled CPC lines.
sequence = [(TARGET_FIRST_LINE + n) % 312 for n in range(288)]
assert len(sequence) == 288
assert sum(1 for n in sequence if 0 <= n <= 199) == 200
assert sequence[0] == 267
assert sequence[-1] == 242

# Storage budget for the elastic line FIFO.
assert FIFO_LINES * LINE_PIXELS * BITS_PER_PIXEL == 276_480

# HDMI vertical blank is 49 output lines = 24.5 CPC line periods;
# a 32-line FIFO is enough to absorb it before frame relock.
assert 49 / 2 < FIFO_LINES

print("Phase2 HDMI scan-converter constants: PASS")
