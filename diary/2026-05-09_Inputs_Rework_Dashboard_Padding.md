# 2026-05-09 - EA Inputs Refactoring and Dashboard Padding

## Objective
The user requested two final polishes to the EA setup:
1. Increase vertical space at the bottom of the Dashboard UI "Settings" tab (under the "Set mA, mB, mC" preset section) for visual breathing room.
2. Refactor the MetaTrader 5 Expert Properties (Input Panel) before the Dashboard launches:
   - Break down the single `ORDER` and `RISK` sections into separated `GLOBAL SETTING`, `2M SETTING`, and `5M SETTING` groups.
   - Introduce missing parameters to these input groups, such as the `Fix lot` amount, the toggle for Risk Management (`Risk Mode ON` / `Fix Lot ON`), and the `Retest candle` custom configurations.

## Changes Made
- **Dashboard.mqh**:
  - Inserted `cy += 50;` immediately after the preset buttons (Set A/B/C) to pad the bottom of the scrollable client area, making the panel feel more spacious.
- **Defines.mqh**:
  - Increased `PANEL_HEIGHT` from `780` to `830` to physically expand the main container background, ensuring the extra scrollable space maps visually onto a longer panel.
- **mt5-kat-ORB.mq5**:
  - Removed the simple `ORDER` and `RISK` input groups.
  - Added new cleanly formatted input groups: `------------- GLOBAL SETTING -------------`, `------------- 2M SETTING -------------`, and `------------- 5M SETTING -------------`.
  - Added `InpGlobalOverride`, `InpFixLot`, `InpRiskModeOn`, `InpCustomRetestOn`, and `InpCustomRetestMin` with friendly UI names for all three config contexts.
  - Rewrote the initial configuration mapping logic inside `OnInit()`, binding the new inputs safely to `cfg.main`, `cfg.m2`, and `cfg.m5` structs before handing them off to the Dashboard.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.14`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified that EA Inputs properties window structurally supports independent Timeframe variables natively via `OnInit`.
