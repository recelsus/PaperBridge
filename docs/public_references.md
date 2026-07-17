# Public References Used for Templates

## Waveshare 2.13inch e-Paper HAT Manual

Reference: https://www.waveshare.com/wiki/2.13inch_e-Paper_HAT_Manual

Used for:

- SPI interface shape: `CS`, `SCLK`, `DC`, `DIN`, `RST`, `BUSY`.
- SPI mode 0 expectation.
- 1-bit pixel packing model where one byte represents eight pixels.
- Operational cautions around partial refresh and sleep/power handling.

Template impact:

- `templates/01_spi_epaper_controller`
- `templates/03_framebuffer_packer`

## Waveshare e-Paper Public Sample Code

Reference: https://github.com/waveshareteam/e-Paper

Specific public sample inspected:

- `RaspberryPi_JetsonNano/c/lib/e-Paper/EPD_2in13_V4.c`
- `RaspberryPi_JetsonNano/c/lib/e-Paper/EPD_2in13_V4.h`

Used for:

- 2.13inch V4 profile dimensions: 122 x 250.
- Window/cursor command pattern: `0x44`, `0x45`, `0x4E`, `0x4F`.
- Frame RAM write command pattern: `0x24`.
- Display update commands such as `0x22` and `0x20` as future sequencer
  candidates.

Template impact:

- `templates/04_panel_command_builder`
- `templates/05_frame_fill_generator`

## Scope Note

The command values above are a practical starting profile, not a universal
e-Paper standard. Keep host-side device profiles explicit and validate each
unknown panel or no-brand device against its observed traffic or controller
datasheet.
