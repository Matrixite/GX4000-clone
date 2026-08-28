# GX4000 / CPC Plus cartridge bus

Physical connector: female 2x18 edge connector, 36 contacts.

| Cart contact | Signal | Direction at FPGA console | Purpose |
|---:|---|---|---|
| 1 | +5V | Power out | Cartridge supply |
| 2 | +5V | Power out | Cartridge supply |
| 3 | CLK4 | Out | 4 MHz ACID clock |
| 4 | CA18 | Out | Cartridge address bit 18 |
| 5 | CA16 | Out | Cartridge address bit 16 |
| 6 | CA17 | Out | Cartridge address bit 17 |
| 7 | CA15 | Out | Cartridge address bit 15 |
| 8 | CA14 | Out | Cartridge address bit 14 |
| 9 | A12 | Out | Cartridge address bit 12 |
| 10 | A13 | Out | Cartridge address bit 13 |
| 11 | A7 | Out | Cartridge address bit 7 |
| 12 | A8 | Out | Cartridge address bit 8 |
| 13 | A6 | Out | Cartridge address bit 6 |
| 14 | A9 | Out | Cartridge address bit 9 |
| 15 | A5 | Out | Cartridge address bit 5 |
| 16 | A11 | Out | Cartridge address bit 11 |
| 17 | A4 | Out | Cartridge address bit 4 |
| 18 | A3 | Out | Cartridge address bit 3 |
| 19 | A10 | Out | Cartridge address bit 10 |
| 20 | A2 | Out | Cartridge address bit 2 |
| 21 | /CE | Out | ROM chip enable / ACID input |
| 22 | A1 | Out | Cartridge address bit 1 |
| 23 | D7 | In | Cartridge ROM data bit 7 |
| 24 | A0 | Out | Cartridge address bit 0 |
| 25 | D6 | In | Cartridge ROM data bit 6 |
| 26 | D0 | In | Cartridge ROM data bit 0 |
| 27 | D5 | In | Cartridge ROM data bit 5 |
| 28 | D1 | In | Cartridge ROM data bit 1 |
| 29 | D4 | In | Cartridge ROM data bit 4 |
| 30 | D2 | In | Cartridge ROM data bit 2 |
| 31 | D3 | In | Cartridge ROM data bit 3 |
| 32 | SIN | In | ACID serial output |
| 33 | CCLR | Out | ACID clear/control |
| 34 | GND | Power | Ground |
| 35 | GND | Power | Ground |
| 36 | GND | Power | Ground |

## FPGA-side bus representation

The HDL uses:

```text
cart_a[13:0]   -> A13..A0
cart_ca[4:0]   -> CA18..CA14
cart_d[7:0]    <- D7..D0
cart_ce_n      -> /CE
cart_clk4      -> CLK4
cart_cclr      -> CCLR
cart_sin       <- SIN
```

## Level shifting

Never expose a Tang Nano 20K FPGA pin directly to cartridge 5 V.

For a dual-supply transceiver such as SN74LVC8T245:

- VCCA = 3.3 V FPGA side
- VCCB = 5 V cartridge side
- address/control direction = A -> B
- data direction = B -> A
- `/OE` pulled high so the translator is disabled during configuration

The cartridge data bus is read-only on the original connector; there is no cartridge write strobe.
