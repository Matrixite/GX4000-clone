# Real-cartridge adapter hardware

## Recommended blocks

### Output translation: FPGA -> cartridge

22 output signals are required:

- A0-A13 = 14
- CA14-CA18 = 5
- /CE = 1
- CLK4 = 1
- CCLR = 1

Use three 8-bit dual-supply translators. Unused channels should be tied/left according to the translator datasheet.

### Input translation: cartridge -> FPGA

- D0-D7 = 8
- SIN = 1

Use one 8-bit translator for data and one 1-bit translator for SIN.

## Power

The cartridge expects +5 V. Do not source cartridge power from an FPGA I/O pin.

Suggested power path:

USB 5 V -> resettable fuse -> load switch -> cartridge +5 V

Add:

- 100 nF near each translator supply
- 10 uF bulk capacitor near cartridge connector
- optional ferrite bead on cartridge +5 V
- ESD protection if the cartridge connector is externally accessible

## Safe startup

Use pull-ups so that while FPGA configuration is in progress:

- `/CE` is HIGH at the cartridge
- translator output enables are disabled
- CCLR and CLK4 are not driven unpredictably

Only enable the FPGA->cartridge translators after reset logic is stable.

## Mechanical note

The electrical interface is known, but the exact cartridge socket mechanics must match the connector you obtain or salvage. Verify pitch, keying and insertion depth before making a PCB.
