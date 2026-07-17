# Panel Profile Template

Copy this directory when adding a local panel profile.

Recommended steps:

1. Fill in `panel_profile.svh`.
2. Record the source and uncertainty in `notes.md`.
3. Add the smallest known-good sequence to `init_sequence.mem`.
4. Test reset, busy behavior, RAM write polarity, and refresh commands
   separately.

Do not treat a display update as fully understood just because one pattern is
visible. Many controllers tolerate incomplete setup but fail on partial update,
sleep/wake, or different temperature ranges.
