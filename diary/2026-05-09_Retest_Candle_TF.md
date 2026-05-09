# 2026-05-09 - Added Custom Retest Candle Timeframe Feature

## Objective
The user requested an addition to the ENTRY section of the dashboard: "Retest candle (min) [input] ON/OFF", defaulting to 1 minute and OFF. The feature allows overriding the timeframe used to detect the retest candle from the strategy's native timeframe (e.g., 2m or 5m) to a custom timeframe, such as 1m.

## Changes Made
- **Defines.mqh**:
  - Added `customRetestOn` (bool) and `customRetestMin` (int) to the `DashboardParams` structure.
  - Set default values to `false` and `1` respectively.
  - Bumped `EA_VERSION` to 1.12.
- **Dashboard.mqh**:
  - Inserted UI elements: `m_lblRtcTag` (label), `m_btnRtc` (ON/OFF button toggle), and `m_edtRtc` (input field) into the ENTRY section.
  - Implemented logic variables and UI updating routines (`m_rtcOn`, `OnRtcToggle()`, `UpdRtc()`).
  - Added proper control visibility management to `CtrlShow()` and `CtrlHide()`.
  - Hooked up parameters saving and loading logic with `DashboardParams`.
- **OrderManager.mqh**:
  - Updated the `ORB_WAIT_RETEST` state execution block.
  - Introduced conditional logic to map `params.customRetestMin` to an explicit `ENUM_TIMEFRAMES` representation (e.g., `PERIOD_M1`).
  - Fetched market data (`iTime`, `iClose`, `iOpen`, `iHigh`, `iLow`) using `retestTf` instead of the base strategy `tf`.
  - Updated the entry reason label appended to MetaTrader orders (`m_entryReason`) to reflect if a custom retest timeframe was used.

## Verification
- Code successfully compiled (0 errors, 0 warnings) after the logic replacement.
- Successfully ran `deploy.ps1` script to export binaries to MetaTrader folder.
- Verified visual alignment on Dashboard coordinates mapping exactly beneath other ENTRY elements without conflict.
