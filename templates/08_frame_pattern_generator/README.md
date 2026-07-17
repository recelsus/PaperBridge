# Template 08: Frame Pattern Generator

This template emits deterministic frame RAM write traffic for bring-up and
signal checks.

It starts with command `0x24`, then emits generated data bytes.

## Patterns

`pattern_mode` values:

- `0`: fill with `fill_byte`.
- `1`: checker-style alternating `0xaa` / `0x55`.
- `2`: vertical stripe byte `0xf0`.
- `3`: horizontal stripes based on `LINE_BYTES`.
- `4`: walking one bit.

## Use Cases

- Confirming SPI byte order.
- Confirming display RAM polarity.
- Checking line width assumptions.
- Producing recognizable traffic before a full framebuffer path exists.

## Files

- `../../rtl/epaper/epaper_pattern_generator.sv`: generated pattern stream RTL.
