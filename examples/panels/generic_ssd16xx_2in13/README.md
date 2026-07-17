# Generic SSD16xx-like 2.13 Inch Profile

This is a practical starting point for small SPI e-Paper modules that resemble
SSD16xx/UC81xx public examples.

It is not complete product support. Check every value against the target panel.

## Assumed Geometry

- Width: 122 pixels.
- Height: 250 pixels.
- Line bytes: 16.

`122 / 8` rounds up to 16 bytes per line because the display RAM is byte
addressed.

## Typical Bring-up Path

1. Reset the panel.
2. Send a small init sequence.
3. Set the RAM window and cursor.
4. Write frame data with command `0x24`.
5. Trigger display update with `0x22`, data, `0x20`.
6. Wait until busy is idle.

The exact init and refresh values vary across panels.
