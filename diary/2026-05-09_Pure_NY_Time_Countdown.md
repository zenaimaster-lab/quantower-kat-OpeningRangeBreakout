# 2026-05-09 - Hard Fix for Friday Rollover Countdown Bug

## Objective
The previous implementation of `GetCountdownString` still implicitly relied on `m_targetTimeServer`, which was being calculated based on `TimeGMT()`. Because `TimeGMT()` was rolling over into Saturday early (relative to NY time), `m_targetTimeServer` was jumping to Saturday, making the system think NYO was in the future and skipping the "Friday after trading window" check.

## Changes Made
- **TimeManager.mqh**:
  - Removed all dependencies on `m_targetTimeServer` inside `GetCountdownString()`.
  - The logic now strictly computes `nyTargetTime` and `nyTime` dynamically on the fly, directly constructing the target day based on the currently perceived `nyDt`.
  - Because `StructToTime()` translates a struct directly into seconds from an epoch, subtracting `nyTime` from `nyTargetTime` yields the precise, absolute second difference regardless of what day `TimeGMT()` thinks it is.
  - This guarantees that when `nyTime` is Friday 10:31 AM, it will be accurately assessed as being past the Friday NYO, past the trading window, and cleanly trigger the `HAPPY WEEKEND!` state.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.18`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified that Friday after-hours will no longer attempt to count down to a phantom Saturday target.
