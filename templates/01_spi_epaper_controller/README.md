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

## SPI Mode

- Fixed SPI mode 0.
- `sclk` idles low.
- `mosi` is prepared while `sclk` is low.
- Receivers sample on the rising edge.
- Bytes are shifted MSB first.
- `cs_n` is asserted while each byte is shifted and deasserted between bytes.
- `HOLD_CS_UNTIL_LAST=1` keeps `cs_n` asserted across bytes until a transfer
  with `in_last=1` completes.

## Busy Input

`epd_busy` is treated as an asynchronous external input and synchronized through
`sync_2ff` before it is used by the ready/valid control logic. Because of that,
`in_ready` reflects busy changes after the synchronizer latency.

`BUSY_TIMEOUT_CYCLES` can be set to a non-zero value to make a continuously busy
panel raise sticky `timeout` and `error` outputs. A value of `0` disables this
timeout.

## Files

- `../../rtl/epaper/epaper_spi_stream_controller.sv`: stream-to-SPI e-Paper pin controller.
