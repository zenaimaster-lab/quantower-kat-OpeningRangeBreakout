# Session: 2026-05-07 — Add STATS Tab & Dashboard Reorganization

## Objective
1. Rename the "MAIN" tab to "Global".
2. Add a new tab `💸` (`TAB_STATS`) to hold all trading status, statistics, and realtime calculations.
3. Clean up the configuration tabs (Global, 2m CONF, 5m CONF) so that status information is hidden there, providing more vertical space and a cleaner UI.

## Changes
- `Defines.mqh`:
  - Added `TAB_STATS=3` to `ENUM_TAB`.
- `Dashboard.mqh`:
  - Added `m_btnTabStats` to the layout with `💸` icon.
  - Adjusted Tab buttons' width (`cw-12`/4).
  - Implemented overlapping rendering in `CreatePanel`: the `STATUS` section is drawn underneath the tabs starting at `startCy`, occupying the exact physical space as the `INPUTS` sections.
  - Restructured `UpdTabs()`:
    - If `TAB_STATS` is active, hide all input fields, labels, toggles, preset buttons, and their respective horizontal separators. Show only the `STATUS` items.
    - If any other tab is active, hide all `STATUS` items and show the inputs/presets.
  - Guarded `LoadTab()` and `SaveTab()` to exit early if `tab == TAB_STATS` since the stats tab does not hold config inputs.

## Result
Code compiled successfully (0 errors, 0 warnings). The dashboard layout is successfully reorganized, creating a dedicated space for monitoring without cluttering the parameter configurations.
