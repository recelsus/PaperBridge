# PaperBridge

PaperBridge is a SystemVerilog RTL collection and template set for hardware-side
processing in e-Ink/e-Paper device adapters.

It is intended to replace vendor-app- or manufacturer-specific assumptions with
reusable building blocks for SPI panel control, signal observation, framebuffer
conversion, and related hardware-facing work.

## Policy

Software and RTL responsibilities are separated.

- Software side: image loading, rendering, resizing, rotation, dithering, device
  profiles, and USB/BLE/network communication
- SystemVerilog side: SPI pin control, ready/valid streams, signal capture,
  trigger detection, packing, and simple command sequence generation

- `rtl/`: reusable RTL modules
- `templates/`: learning, bring-up, and experiment templates
- `sim/`: simple Icarus Verilog testbenches
- `paperbridge.f`: RTL file list for external tools and projects

## Templates

### 01: SPI e-Paper Controller

Path: `templates/01_spi_epaper_controller`

Template for SPI-connected e-Paper panels and Waveshare-like modules.
Reusable RTL: `rtl/epaper/epaper_spi_stream_controller.sv`

Details:

- Converts `{dc, byte}` streams into SPI signals
- Handles `CS`, `SCLK`, `MOSI`, `DC`, `RST`, and `BUSY`
- Fixed SPI mode 0
- MSB first
- Parameterized reset low/high timing

### 02: Protocol Capture Trigger

Path: `templates/02_protocol_capture_trigger`

Template for observing low-speed signals on existing devices or adapter boards.
Reusable RTL: `rtl/capture/serial_pin_capture.sv`

Targets:

- SPI
- UART
- GPIO
- Control lines such as reset, busy, and data-command

Details:

- Converts pin changes into edge events
- Supports separate rising-edge and falling-edge enables
- Supports `arm_i` capture enable
- Detects false-to-true level condition transitions
- Emits timestamped events
- Holds multiple pending events in a small FIFO
- Sets sticky `overflow` when an additional event occurs while another event is
  received while the FIFO is full

This is not intended for directly observing high-speed differential links such
as PCIe, USB high-speed, or MIPI DSI.

### 03: Framebuffer Packer

Path: `templates/03_framebuffer_packer`

Template for converting a 1bpp pixel stream into a packed-byte format commonly
used by e-Paper panels.
Reusable RTL: `rtl/framebuffer/fb_1bpp_packer.sv`

Details:

- Packs 8 pixels into 1 byte
- Places the first pixel at bit 7
- MSB first
- Pads unused lower bits with 0 when `pixel_last` arrives before 8 pixels
- Supports ready/valid backpressure

### 04: Panel Command Builder

Path: `templates/04_panel_command_builder`

Template for generating window/cursor setup command streams commonly seen on
controller-style e-Paper panels.
Reusable RTL: `rtl/epaper/epaper_window_sequence.sv`

Details:

- `0x44`: RAM X address start/end
- `0x45`: RAM Y address start/end
- `0x4E`: RAM X address counter
- `0x4F`: RAM Y address counter

These commands are based on Waveshare public samples. They are not a universal
specification for every e-Paper controller.

### 05: Frame Fill Generator

Path: `templates/05_frame_fill_generator`

Template for filling frame RAM with a constant byte during bring-up and wiring
checks.
Reusable RTL: `rtl/epaper/epaper_frame_fill.sv`

Details:

- Command `0x24`
- Repeated transmission of a selected byte
- Deterministic traffic for white clear, black clear, and SPI waveform checks

Verify whether `0x24` is the image RAM write command and what byte polarity
means on the target panel.

## Common RTL

### ready/valid stream

Most templates use ready/valid handshaking.

```text
valid: producer has data
ready: consumer can accept data
data : payload
last : frame / command / packet end
```

Transfer occurs on cycles where `valid && ready`.

### rv_skid_buffer

Path: `rtl/common/rv_skid_buffer.sv`

One-word buffer for ready/valid streams.

Use cases:

- Absorbing backpressure
- Separating ready paths
- Small timing improvements

### sync_2ff

Path: `rtl/common/sync_2ff.sv`

Two-flop synchronizer for single-bit asynchronous inputs.

Use cases:

- e-Paper `BUSY`
- External trigger pins
- Slow status inputs crossing into the local clock domain

### spi_tx

Path: `rtl/spi/spi_tx.sv`

8-bit MSB-first SPI transmitter used by the e-Paper stream controller.

Current scope:

- Fixed SPI mode 0
- One byte per transfer
- Ready/valid input
- Byte-scoped chip select by default
- Optional chip-select hold until `in_last`
- Registered `transfer_done`

### epaper_reset_controller

Path: `rtl/epaper/epaper_reset_controller.sv`

Reset sequencer for e-Paper panels.

Current scope:

- Parameterized reset-low duration
- Parameterized reset-high wait duration
- `ready` output after the reset sequence completes

## Test

Icarus Verilog is used for the current tests.

```sh
sudo apt install iverilog
sudo pacman -S iverilog
```

Run all tests:

```sh
make test
```

Individual tests:

```sh
make test-packer
make test-capture
make test-epaper
make test-epaper-reset
make test-window
make test-fill
make test-skid
make test-sync
make test-bad-params
```

Test coverage:

- `fb_1bpp_packer`: byte packing for 1bpp pixels
- `serial_pin_capture`: edge events, level events, FIFO holding, and overflow
- `epaper_spi_stream_controller`: SPI output, reset timing, busy handling,
  command/data switching, SPI clock period, optional CS hold, and busy timeout
  for `{dc, byte}` streams
- `epaper_reset_controller`: reset-low, reset-high wait, and ready behavior
- `epaper_window_sequence`: window/cursor command streams
- `epaper_frame_fill`: `0x24` and fill data generation
- `rv_skid_buffer`: one-word holding under backpressure
- `sync_2ff`: two-stage synchronization behavior
- `spi_tx`: covered through `epaper_spi_stream_controller`
- bad-parameter tests: expected `$fatal` behavior for invalid module parameters

## Caution

Some templates are based on Waveshare public manuals and sample code.

- e-Paper controller commands are not a complete common standard.
- `0x24`, `0x44`, `0x45`, `0x4E`, and `0x4F` are practical starting points, but
  must be checked against each target panel.
- No-brand devices and finished consumer devices may use different internal
  controllers or command sequences.

- Complete initialization sequences for specific products are not included.
- Board-specific FPGA constraint files are not included.
- USB/BLE/network protocol analysis is outside the RTL scope.
- Direct observation of high-speed differential signals is outside the scope.
- External SDRAM framebuffers are not supported yet.
- AXI4 / Wishbone / Avalon wrappers are not supported yet.
- Automated hardware tests are only partially supported.

## License

MIT License. See [LICENSE](LICENSE).
