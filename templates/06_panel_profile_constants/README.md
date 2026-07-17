# Template 06: Panel Profile Constants

This template collects practical e-Paper command values and small panel geometry
profiles in one place.

It is not a device database. Treat these constants as common SSD16xx/UC81xx-style
starting points and verify them against the target panel or public sample code.

## Typical Commands

- `0x12`: software reset.
- `0x20`: master activate.
- `0x22`: display update control.
- `0x24`: black/white RAM write.
- `0x26`: red RAM write on many tri-color panels.
- `0x44`: RAM X address range.
- `0x45`: RAM Y address range.
- `0x4E`: RAM X address counter.
- `0x4F`: RAM Y address counter.

## Typical Geometry

The package includes a few common dimensions used by small SPI e-Paper modules:

- 2.13 inch class: 122 x 250, 16 bytes per line.
- 2.9 inch class: 128 x 296, 16 bytes per line.
- 4.2 inch class: 400 x 300, 50 bytes per line.

## Files

- `../../rtl/epaper/epaper_panel_profile_pkg.sv`: shared command and geometry constants.
