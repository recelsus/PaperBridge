# Template 04: Panel Command Builder

This template emits common e-Paper controller command streams from structured
inputs.

It is useful when the host knows the target rectangle but you want hardware to
produce the repetitive command/data byte sequence for a controller-style panel.

## Public Basis

Waveshare's 2.13inch e-Paper HAT manual documents SPI mode 0, command/data pin
usage, and MSB-first 1bpp display data. Their public `EPD_2in13_V4` sample code
uses these command groups for window and cursor setup:

- `0x44`: RAM X address start/end.
- `0x45`: RAM Y address start/end.
- `0x4E`: RAM X address counter.
- `0x4F`: RAM Y address counter.

This module does not claim those commands are universal. Treat it as a common
SSD16xx/UC81xx-style starting point and verify against the target panel.

## Stream Format

Output is the same 9-bit `{dc, byte}` format used by
`epaper_spi_stream_controller`.
