# KAT Orb Breakout Architecture & Logic Reference

This document serves as the canonical reference for the KAT Orb Breakout EA, which has been refactored into a fully automated "Auto-Run" system. It records the core logic and architecture after the removal of manual trading interventions and the Origami module.

## 1. Frontend UI Architecture (The "3 Pillars" Fix)

The EA retains a streamlined dashboard for configuring parameters natively on the MT5 chart. The core responsiveness optimizations remain:

1.  **Purging `EVENT_MAP`:**
    *   Eliminates MQL5's broken internal bounding-box hit testing.
2.  **Native `CHARTEVENT_OBJECT_CLICK` Interception:**
    *   `OnChartEvent` intercepts `CHARTEVENT_OBJECT_CLICK` instantly.
3.  **`HandleDirectClick` & Debouncing:**
    *   Button clicks route to `CDashboard::HandleDirectClick(const string &objName)` with a rigid 500ms debounce guard.

*Note: All manual action buttons (Flatten, Lock, Reverse, Buy/Sell Market) and their handlers have been completely removed to enforce the Auto-Run architecture.*

## 2. Backend Engine & Data Synchronization

The bridge between the Frontend UI and Backend execution is managed by the `DashboardParams` struct and the `GetParams()` method.

**The Current Data Flow:**
1.  **Initialization:** `OnInit` calls `SetInitialParams()` to establish baseline settings from the UI fields.
2.  **Synchronization (`GetParams`):**
    *   Extracts `symbol` and timing components (`nyHour`, `nyMinute`, `nySecond`, `utcOffset`, `triggerBeforeSec`).
    *   Extracts trading parameters (SL, TP, Risk %, Timeframe, Trail settings).
3.  **Consumption (`OnTimer` & `OnTick`):**
    *   `OnTimer()` fires every 1 second, fetching the latest `DashboardParams` for auto-trading schedules.
    *   Calculates Real-time Risk/Reward, Total Exposed Lots, and evaluates the `CTimeMgr`.

## 3. Core Logic Modules

### Time Management & Auto-Trading (`CTimeMgr`)
*   Manages the News timing and NYO (New York Open) schedules.
*   Calculates the exact trigger time based on `targetDayOffset`, `nyHour:Minute:Second`, and `triggerBeforeSec`.
*   Continuously feeds the Countdown string to the Dashboard.
*   Executes `g_orderMgr.PlaceOCOOrders()` when the exact trigger second is hit.

### Order Management (`COrderMgr`)
*   Handles execution of Stop orders (OCO Breakout entries) automatically.
*   Manages pending order expiration (`CheckExpire`).
*   *Manual execution helpers have been deprecated and stripped from the codebase.*

### Risk & Reward Calculation
*   **Static Risk:** Computed via `g_riskMgr.CalcRiskRewardInfo` before entering trades. Determines the correct lot size to risk X% of the balance over Y points.
*   **Dynamic Risk:** `OnTimer` loops through open positions matching the Magic Number and Symbol. Computes `totalProfitAtTP` and `totalLossAtSL` based on current active order volumes to provide real-time portfolio exposure.
*   **Breakeven (BE) Line:** Calculates a volume-weighted average entry price, adds/subtracts the spread, and draws a visual yellow line on the chart representing the true Breakeven point for the net position.

## 4. Stability Guarantees

*   **100% Reliable Execution:** The EA focuses purely on placing precision OCO orders at the defined breakout trigger without risking MT5 threading collisions from manual overrides.
*   **Graceful Degradation:** If no symbol is detected, the EA safely returns early from core loops, preventing zero-divide or invalid handle errors.
