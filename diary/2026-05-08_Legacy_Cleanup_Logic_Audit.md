# Session: Legacy Cleanup + Logic Audit — 2026-05-08

## Changes Made

### 1. Legacy OCO Sniper Purge (v0.12 → v0.13)
- Renamed `EA_COMMENT_PREFIX` from `"OCO_SNIPER_"` → `"KAT_ORB_"`
- Renamed `m_lastOcoTag` → `m_lastOrderTag`, `GenerateOcoTag` → `GenerateOrderTag`
- Removed dead `triggerBeforeSec` field + `InpTriggerBefore` input
- Removed dead TimeManager trigger system (`IsTimeToTrade`, `GetSecondsToTrigger`, `m_triggerTimeServer`)
- Removed dead Origami fields (`targetGrowthPercent`, `customTiming`, `targetDayOffset`)
- Renamed `CalculateTriggerTime` → `CalculateTargetTime`
- Fixed all 6 file headers from "Opening Sniper EA" → "KAT Opening Range Breakout EA"
- Fixed description from "Scaling into winners" → "Break & Retest range strategy"

### 2. Logic Audit + Fixes (v0.13 → v0.14)
- **CRITICAL FIX:** OnTick now forces correct timeframe (M2/M5) for CheckAutoCancel + TrailManager under Global Override
- **FIX:** Added ORDER_MODE filter in ProcessORB retest — MODE_BUY_ONLY/MODE_SELL_ONLY now respected
- **FIX:** Added ORB_STOPPED state for afterMinutes timeout — no continuation allowed
- **FIX:** Explicit state transitions after cancel (ORB_DONE or ORB_STOPPED instead of relying on side effects)

### 3. Stats Tab Redesign (v0.11 → v0.12)
- New sections: ORDERS (2m/5m status), LAST ENTRY, TOTAL P/L, 2m P/L, 5m P/L
- Color-coded status: Break Out (green), Break Down (red), Wait Entry (yellow), Stop Trading (red)
- Per-timeframe PL tracking via DEAL_COMMENT filtering
- Single-stat-per-line layout to prevent text overlap

### 4. Documentation Update
- Rewrote README.md with accurate strategy/architecture description
- Rewrote docs/Architecture.md with full state machine, data flow, and logic reference
- Updated graphify knowledge graph

## Known Items
- `bigMomentum` toggle exists in UI but has no logic implementation
- TrailManager applies to all positions regardless of 2m/5m origin

## Files Modified
- `Defines.mqh`, `OrderManager.mqh`, `TimeManager.mqh`, `mt5-kat-ORB.mq5`
- `Dashboard.mqh`, `RiskManager.mqh`, `TrailManager.mqh`, `NewsManager.mqh`
- `README.md`, `docs/Architecture.md`
