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
- Timestamping.
- Trigger filtering.
- Compact event output.

## Event Format

The sample module outputs 32-bit event words:

```text
bits[31:24] event kind
bits[23:16] sampled pin value
bits[15:0]  timestamp low bits
```

Transfer uses ready/valid.
