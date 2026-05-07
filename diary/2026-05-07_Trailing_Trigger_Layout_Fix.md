# Session: 2026-05-07 — Trailing Trigger Layout & Countdown Formatting Fix

## Objective
Fix text overlap issues on the `Trailing mode` inputs (Trigger, Distance, Step) and restructure the `CLOCK` section to match the NY Time & Countdown visual reference.

## Changes
- Adjusted `Trailing mode` layout: 
  - Trigger label width: 55px
  - Distance label width: 65px
  - Step label width: 35px
  - All input fields widened to 50px without overlaps.
- Restructured `CLOCK` section:
  - Hidden the `Next session` label and value.
  - Formatted `Countdown` to align directly beneath `NY Time` with `FONT_SIZE_MED`.
  - Set `Countdown` value color to `CLR_WARNING` (orange).
- Version bumped: 0.08 → 0.09.

## Files Modified
- `Dashboard.mqh`
- `Defines.mqh`

## Compile Result
0 errors, 0 warnings
