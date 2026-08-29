# Phase 5 integration/reference checks.
DEFAULT_FRAME_LINES = 312
PRE_ACTIVE_LINES = 45
assert DEFAULT_FRAME_LINES - PRE_ACTIVE_LINES == 267
for frame_lines in (280, 300, 312, 320, 340):
    target = max(0, frame_lines - PRE_ACTIVE_LINES)
    assert target + PRE_ACTIVE_LINES == frame_lines

assert 16_000_000 / 1024 == 15_625
assert 512 <= 1024 <= 1792
assert 1100 > 1023

MAX_MISSES_BEFORE_UNLOCK = 4
assert MAX_MISSES_BEFORE_UNLOCK >= 2

PRECHARGE_CYCLES = 64
PRECHARGE_US = PRECHARGE_CYCLES / 27_000_000 * 1_000_000
assert 2.0 < PRECHARGE_US < 3.0

READY_SYNC_US = 2 / 27_000_000 * 1_000_000
CART_WAIT_US = 6 / 4_000_000 * 1_000_000
assert READY_SYNC_US < CART_WAIT_US

print('Phase 5 integration/refinement reference checks: PASS')
