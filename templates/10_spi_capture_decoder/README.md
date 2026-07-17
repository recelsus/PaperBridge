# Template 10: SPI Capture Decoder

This template decodes low-speed SPI-like edge events captured by
`serial_pin_capture`.

It is meant for observing known-good public modules or simple adapter boards
where the SPI clock is slow enough for the capture clock domain.

## Assumptions

- Input events are `serial_pin_capture` edge events.
- Captured pins fit in the 8-bit pin field.
- `CPHA=0`.
- Bytes are sampled MSB first.
- Chip select is active low.

## Outputs

- `byte_valid`, `byte_ready`, and `byte_o` for decoded bytes.
- `dc_o` sampled with the completed byte.
- `frame_done` when chip select deasserts.

## Files

- `../../rtl/capture/spi_edge_decoder.sv`: event-to-SPI-byte decoder.
