# Template 05: Frame Fill Generator

This template emits a simple full-frame write stream:

```text
command 0x24
data byte repeated N times
```

Many monochrome SPI e-Paper controller examples write image data to command
`0x24`. Waveshare's public 2.13inch V4 sample uses this command for clear,
black clear, normal display, fast display, base display, and partial display
paths.

Use this module for:

- Initial bring-up without a host framebuffer.
- Clear-to-white / clear-to-black testing.
- Producing deterministic traffic for SPI capture templates.

Verify the RAM write command and byte polarity against the target panel.

## Files

- `../../rtl/epaper/epaper_frame_fill.sv`: reusable frame fill RTL.
