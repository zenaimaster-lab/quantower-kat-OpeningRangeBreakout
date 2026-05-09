# 2026-05-09 - Countdown Logic Refinement

## Objective
The user requested refinements to the NYO countdown text on the dashboard:
1. It should display "HAPPY WEEKEND!" during Saturday and Sunday (NY Time).
2. During the Trading Window (calculated from NYO start time + the `afterMinutes` setting from the dashboard), it should display "TRADING WINDOW" instead of counting down into negative numbers or jumping straight to the next day.
3. Once the Trading Window ends on a regular weekday, it should start counting down to the *next* day's NY Open.
4. If the Trading Window ends on a Friday, it should immediately switch to "HAPPY WEEKEND!" since the market won't open until Monday.

## Changes Made
- **TimeManager.mqh**:
  - Updated the signature of `GetCountdownString()` to `GetCountdownString(const DashboardParams &params)` so it can access the user's `afterMinutes` and `afterMinutesOn` settings.
  - Added weekend detection at the very beginning of the function: if the current NY Time falls on Saturday (`day_of_week == 6`) or Sunday (`day_of_week == 0`), it returns `"HAPPY WEEKEND!"`.
  - Inside the post-NYO logic branch (`secs < 0`):
    - Calculated `elapsedSecs = -secs` and compared it against `windowSecs` (derived from `params.afterMinutes`). If the trading window feature is OFF, it defaults to a full trading day (390 mins = 6.5 hours to NY close).
    - If `elapsedSecs <= windowSecs`, returns `"TRADING WINDOW"`.
    - If the trading window has elapsed and the current day is Friday (`day_of_week == 5`), returns `"HAPPY WEEKEND!"`.
    - Otherwise, proceeds to calculate the countdown to the next valid business day's NY Open.
- **mt5-kat-ORB.mq5**:
  - Updated the `OnTimer()` event handler to pass `cfg.main` into `GetCountdownString(p)` so the `TimeManager` has the correct dashboard configuration context.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.16`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified logic correctly covers all the edge cases requested by the user.
