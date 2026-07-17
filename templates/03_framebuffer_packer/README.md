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
8 pixels per byte, MSB first by default
```

This is the common packing style used by many monochrome display controllers.

## Files

- `../../rtl/framebuffer/fb_1bpp_packer.sv`: reusable framebuffer packing RTL.

## Timing and Partial Byte Rules

- With `MSB_FIRST=1`, the first pixel in a byte is placed at bit 7.
- With `MSB_FIRST=0`, the first pixel in a byte is placed at bit 0.
- With `INVERT=1`, each input pixel is inverted before packing.
- If `pixel_last` arrives before eight pixels have been collected, unused lower
  or upper bits are filled with zero according to the selected bit order.
- When `byte_valid=1` and `byte_ready=0`, `byte_o` and `byte_last` remain stable.
- If the current output byte is accepted in a cycle, the next pixel may also be
  accepted in that same cycle.
- If the current output byte is not accepted, `pixel_ready=0` prevents new input.
