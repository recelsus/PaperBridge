# Template 01: SPI e-Paper Controller

This template is for raw e-Paper panels and Waveshare-like modules where the
hardware interface is SPI plus control pins.

## Boundary

Host software should usually handle:

- Image rendering.
- Resize/crop/rotate.
- Dithering.
- Device profile selection.
- Panel command sequence selection.

SystemVerilog should handle:

- SPI byte shifting.
- `dc`, `cs_n`, `rst_n`, and `busy` pin timing.
- Ready/valid backpressure.
- Optional reset pulse generation.

## Stream Format

The sample controller accepts 9-bit stream words:

```text
bit[8]   dc: 0 = command, 1 = data
bit[7:0] byte
```

The host sends the complete panel initialization and frame update sequence as a
stream of these words. This keeps panel-specific policy out of the RTL while the
RTL still owns pin-level timing.

## Files

- `epaper_spi_stream_controller.sv`: stream-to-SPI e-Paper pin controller.
