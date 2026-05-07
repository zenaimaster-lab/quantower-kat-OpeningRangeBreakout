# Session: 2026-05-07 — Add ENTRY Section & Layout Update

## Objective
Add a new `ENTRY` section above `AUTO CANCEL PENDING ORDER` in the MT5 Dashboard with toggles and parameters for continuation and momentum logic.

## Changes
- Updated `Defines.mqh`:
  - Added new states to `DashboardParams`: `contAfter1st`, `maxSuccessOn`, `maxSuccess` (default 5), `maxLossOn`, `maxLoss` (default 1), `bigMomentum`.
  - Increased `PANEL_HEIGHT` from 1420 to 1550 to accommodate the new UI rows.
  - Bumped version from 0.09 to 0.10.
- Updated `Dashboard.mqh`:
  - Added class members for `ENTRY` section UI (Labels, Edits, Buttons).
  - Wired UI elements to `SaveTab` and `LoadTab`.
  - Created click handlers: `OnContToggle`, `OnMaxSToggle`, `OnMaxLToggle`, `OnBigMToggle`.
  - Implemented `HandleDirectClick` logic for all new buttons.
  - Rendered `ENTRY` section with proper spacing above the Auto Cancel section.

## Files Modified
- `Dashboard.mqh`
- `Defines.mqh`

## Result
Code compiled successfully (0 errors, 0 warnings). UI successfully accommodates new layout configurations. All parameters are ready to be integrated into `OrderManager` and trading logic in future steps.
