# Notes

## Source

- General SSD16xx/UC81xx-style public examples.
- Existing PaperBridge window sequence and frame fill templates.

## Verification

- Hardware tested: no
- Reset timing checked: no
- Busy polarity checked: no
- RAM write command checked: no
- White/black polarity checked: no
- Full refresh checked: no
- Partial refresh checked: no

## Assumptions

- SPI mode: mode 0.
- BUSY polarity: active high.
- Pixel order: MSB first.
- RAM write command: `0x24`.
- X address range is byte based.
- Y address range is little endian.

## Known Gaps

- Full initialization is not included.
- LUT upload is not included.
- Display update control value is not fixed here.
- Deep sleep and wake-up behavior are not included.
