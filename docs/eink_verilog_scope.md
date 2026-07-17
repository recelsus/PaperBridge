# e-Ink Projects: What Belongs in SystemVerilog

## Put in Software First

- Device discovery.
- Image decoding.
- Text layout.
- Scaling, cropping, and rotation.
- Dithering.
- Device profile management.
- USB, BLE, HTTP, MQTT, ADB, and file-transfer adapters.
- Long panel command tables while still experimenting.

These parts change frequently and are easier to inspect, log, and repair in
software.

## Good SystemVerilog Boundaries

### Pin-Level Panel Driver

Use RTL when a panel expects deterministic pin timing:

- SPI byte shifting.
- Data/command pin control.
- Reset pulse generation.
- Busy pin wait states.
- Chip-select framing.

Template: `templates/01_spi_epaper_controller`

### Capture and Trigger

Use RTL when you need stable sampling or event timing:

- Observe SPI/UART/GPIO pins.
- Detect command boundaries.
- Timestamp edges.
- Trigger when a known sequence appears.

Template: `templates/02_protocol_capture_trigger`

### Framebuffer Packing

Use RTL when the panel consumes a byte layout that is simple but high volume:

- 1-bit pixels to packed bytes.
- Fixed byte order conversion.
- Optional line buffering.

Template: `templates/03_framebuffer_packer`

## Avoid Putting These in RTL Initially

- Full image rendering.
- Complex decompression.
- Device-specific policy that changes during reverse engineering.
- Encrypted or authenticated application protocols.
- High-speed links beyond the chosen FPGA board's physical capability.

## Practical Architecture

```text
host app
  |
image pipeline
  |
device-independent framebuffer
  |
transport bridge
  |
SystemVerilog block
  |
panel pins / capture pins
```

Keep the hardware block narrow. If the same RTL can be reused with a different
device profile by changing only the host-side command stream, the boundary is
probably healthy.
