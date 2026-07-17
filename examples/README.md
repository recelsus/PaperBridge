# Examples

This directory contains example panel profiles and sequence files that can be
copied and adjusted for local experiments.

Examples are starting points, not complete product support declarations. Verify
command values, byte polarity, reset timing, busy behavior, and refresh
sequences against the target hardware.

## Layout

```text
examples/
  panels/
    _template/
      README.md
      panel_profile.svh
      init_sequence.mem
      notes.md

    generic_ssd16xx_2in13/
      README.md
      panel_profile.svh
      init_sequence.mem
      notes.md
```

## Files

- `panel_profile.svh`: dimensions, command constants, and polarity assumptions.
- `init_sequence.mem`: command-sequence-player tokens.
- `notes.md`: source, verification status, and board-specific observations.

## Sequence Token Format

`init_sequence.mem` uses one token per line:

```text
op data
```

Token operations:

- `0`: command byte in `data`.
- `1`: data byte in `data`.
- `2`: delay cycles in `data`.
- `3`: wait until the busy input is idle.
- `7`: end of sequence.

Lines beginning with `#` are comments.
