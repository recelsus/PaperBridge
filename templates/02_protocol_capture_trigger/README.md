# Template 02: Protocol Capture Trigger

This template is for learning and for practical reverse-engineering support on
low-speed e-Ink related signals.

Good candidates:

- SPI between MCU and e-Paper panel.
- UART debug or command pins.
- Reset, data/command, chip-select, and busy pins.
- I2C-like low-speed management links.

Poor candidates:

- USB high-speed/superspeed.
- PCIe.
- MIPI DSI.
- Any link that exceeds the FPGA board, probes, or routing budget.

## Boundary

Host software should handle:

- Storing logs.
- Protocol decoding beyond simple markers.
- Comparing known-good update traces.
- Building replay scripts.

SystemVerilog should handle:

- Precise pin sampling.
- Edge detection.
- Per-pin rising/falling edge selection.
- Arm/disarm control.
- Timestamping.
- Trigger filtering.
- Compact event output.

## Event Format

The sample module outputs event words whose timestamp field follows
`TIMESTAMP_WIDTH`:

```text
bits[TIMESTAMP_WIDTH+15:TIMESTAMP_WIDTH+8] event kind
bits[TIMESTAMP_WIDTH+7 :TIMESTAMP_WIDTH]   sampled pin value
bits[TIMESTAMP_WIDTH-1 :0]                 timestamp
```

Transfer uses ready/valid.

`PIN_COUNT` is limited to 1 through 8 because the event format reserves an
8-bit sampled-pin field.

## Trigger and Loss Behavior

- `edge_enable_i` is the compatibility input for both-edge detection.
- `rising_enable_i` enables rising-edge detection per pin.
- `falling_enable_i` enables falling-edge detection per pin.
- Edge events are generated when any enabled edge condition matches.
- `arm_i=0` suppresses new events while timestamping and input synchronization
  continue.
- Level events are generated only when the level condition changes from false
  to true.
- A level condition that remains true does not repeatedly emit events.
- If a new event occurs while an older event is pending, the older event is
  preserved in FIFO order while space remains.
- If a new event occurs while the FIFO is full, the new event is dropped and
  `overflow` is set.
- `overflow` is sticky until reset.

## Parameters

- `PIN_COUNT`: number of sampled pins, from 1 to 8.
- `TIMESTAMP_WIDTH`: timestamp width stored in each event.
- `FIFO_DEPTH`: number of event records held before overflow.

## Files

- `../../rtl/capture/serial_pin_capture.sv`: reusable capture RTL.
