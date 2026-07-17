# Template 07: Command Sequence Player

This template converts a compact command script into the common 9-bit
`{dc, byte}` stream used by the SPI e-Paper controller.

The host or a small ROM can provide tokens. The RTL owns byte emission, simple
cycle delays, and busy-pin waits.

## Token Operations

`seq_op` values:

- `0`: emit command byte from `seq_data[7:0]`.
- `1`: emit data byte from `seq_data[7:0]`.
- `2`: delay for `seq_data` clock cycles.
- `3`: wait until `epd_busy` is low.
- `7`: end sequence and pulse `done`.

## Use Cases

- Small reset/init scripts.
- Display refresh command tails such as `0x22`, data, `0x20`, wait busy.
- Replaying a known-good public sample sequence without hard-coding it in a
  monolithic controller.

## Files

- `../../rtl/epaper/epaper_command_sequence_player.sv`: token-to-stream sequence player.
