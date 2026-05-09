# 2026-05-09 - GMT Target Fix and Input Defaults

## Objective
The previous countdown logic failed on Fridays due to an intricate date-wrap issue: the original target time calculated from `TimeGMT()` incorrectly wrapped into Saturday because the broker's GMT time was technically already Saturday morning, resulting in a positive offset (`secs > 0`) that skipped the Friday post-trading-window condition entirely. The user also requested to change the default values of `Fix Lot` and `Risk Percent` inputs to `2.0`.

## Changes Made
- **TimeManager.mqh**:
  - Rewrote the countdown logic in `GetCountdownString()` to strictly compute current time versus target time **entirely within the NY timezone representation**, avoiding edge-case `TimeGMT()` rollovers across day boundaries.
  - Using `StructToTime` on identical dates natively exposes true differences in seconds without relying on broker offsets drifting into future dates.
  - This strictly enforces that on a Friday (`day_of_week == 5`), if the elapsed seconds exceed the `windowSecs` (Trading Window length), it accurately trips the `HAPPY WEEKEND!` condition.
- **mt5-kat-ORB.mq5**:
  - Altered the native MetaTrader input properties:
    - Changed `InpRiskPercent`, `Inp2MRiskPercent`, and `Inp5MRiskPercent` defaults from `1.0` to `2.0`.
    - Changed `InpFixLot`, `Inp2MFixLot`, and `Inp5MFixLot` defaults from `0.1` to `2.0`.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.17`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified logic via code review confirming the GMT bypass.
