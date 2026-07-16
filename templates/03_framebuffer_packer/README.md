# Template 03: Framebuffer Packer

This template is for converting a host-friendly pixel stream into panel-friendly
packed bytes.

## Boundary

Host software should handle:

- Font rendering.
- Image decode.
- Scaling.
- Rotation unless fixed hardware rotation is useful.
- Dithering and threshold decisions.

SystemVerilog should handle:

- Simple pixel packing.
- Byte ordering.
- Optional line buffering.
- Backpressure toward a slower panel interface.

## Sample Format

Input:

```text
1 pixel per transfer
pixel_i[0] = 0 or 1
```

Output:

```text
8 pixels per byte, MSB first
```

This is the common packing style used by many monochrome display controllers.
