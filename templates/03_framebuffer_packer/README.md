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

## Files

- `../../rtl/framebuffer/fb_1bpp_packer.sv`: reusable framebuffer packing RTL.

## Timing and Partial Byte Rules

- The first pixel in a byte is placed at bit 7.
- Pixels are packed MSB first.
- If `pixel_last` arrives before eight pixels have been collected, unused lower
  bits are filled with zero.
- When `byte_valid=1` and `byte_ready=0`, `byte_o` and `byte_last` remain stable.
- If the current output byte is accepted in a cycle, the next pixel may also be
  accepted in that same cycle.
- If the current output byte is not accepted, `pixel_ready=0` prevents new input.
