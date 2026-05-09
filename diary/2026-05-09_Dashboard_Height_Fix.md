# 2026-05-09 - Reverted Dashboard Padding and Fixed Panel Height

## Objective
The previous edit accidentally shrunk the `PANEL_HEIGHT` to `830`, causing the UI to truncate mid-way through the ENTRY section. The user requested to revert the internal `cy += 50` spacing and correctly expand the Dashboard background height to show all elements properly.

## Changes Made
- **Dashboard.mqh**:
  - Removed the `cy += 50;` spacing below the preset buttons.
- **Defines.mqh**:
  - Restored and slightly increased `PANEL_HEIGHT` from the erroneous `830` to `1270` (the original functional height was `1245`). This gives enough space to render all controls fully and leaves a natural gap at the bottom of the scrollable panel.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.15`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified that `PANEL_HEIGHT` now correctly encompasses the entire dashboard layout natively.
