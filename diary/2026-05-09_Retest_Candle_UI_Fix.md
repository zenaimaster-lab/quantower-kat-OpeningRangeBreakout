# 2026-05-09 - Fixed Retest Candle UI Layout Alignment

## Objective
The user requested UI alignment adjustments for the `Retest candle (min)` setting in the ENTRY section to exactly match the design pattern and size of the `Max succesful order` and `Max loss order` controls. The default configuration of the feature was also updated to `ON`.

## Changes Made
- **Dashboard.mqh**:
  - Remapped coordinates: Input field is now at `cx+155` and the ON/OFF toggle is aligned to the right-most edge (`smallBtnX`) using `smallBtnW`.
  - Reordered element rendering from `[Label] [Toggle] [Input]` to `[Label] [Input] [Toggle]` to match sibling elements.
  - Changed the "ON" color profile from `CLR_BTN_ON` (Blue) to `CLR_SUCCESS` (Green) to match the other ON toggles in that section.
- **Defines.mqh**:
  - Updated `customRetestOn` initialization in `DashboardParams` to default to `true` globally.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.13`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified UI consistency against sibling components visually.
