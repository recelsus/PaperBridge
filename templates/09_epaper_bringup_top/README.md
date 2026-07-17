# Template 09: e-Paper Bring-up Top

This template is a small integration example that wires the existing reset,
frame fill, and SPI stream modules together.

It is intentionally narrow: after reset timing completes, `start` emits one
`0x24` frame fill transaction to the panel pins.

## Included Path

- Reset pulse and reset-high wait.
- Frame fill stream generation.
- SPI mode 0 output.
- Busy-gated SPI controller behavior.
- `done` pulse after the last SPI byte completes.

## Not Included

- Full panel initialization.
- LUT upload.
- Display refresh command tail.
- Product-specific voltage or waveform settings.

## Files

- `../../rtl/epaper/epaper_bringup_fill_top.sv`: reset + fill + SPI integration example.
