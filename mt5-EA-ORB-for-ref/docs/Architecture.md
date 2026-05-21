# KAT-ORB Architecture & Logic Reference

## 1. Frontend UI Architecture

The EA uses a custom `CAppDialog`-based dashboard with 5 tabs (Main, 2m, 5m, 15m, Stats) rendered directly on the MT5 chart.

### Click Handling & UX
1. **Purged `EVENT_MAP`** — Bypasses MQL5's default bounding-box hit testing for precision.
2. **Native `CHARTEVENT_OBJECT_CLICK`** — `OnChartEvent` intercepts clicks instantly.
3. **`HandleDirectClick` + Debouncing** — A 500ms debounce guard prevents UI double-fires.
4. **Minimizable UI** — The dashboard can be collapsed to free up chart space while maintaining active logic.

### Tab Structure
- **Main:** Symbol selection, NY Open Schedule (Hour/Min/Sec), UTC offset, Global Risk %, Order Mode, and Presets.
- **2m / 5m / 15m:** Per-timeframe overrides. Users configure unique SL/TP, trailing modes, auto-cancel parameters, and EMA filters.
- **Stats:** Live feedback loop. Shows active ORDERS status, a chronological LAST ENTRIES log (1-6) detailing entry/cancel reasons, and P/L metrics (Net, Wins, Losses) broken down globally and by timeframe.

## 2. Data Flow

```text
OnInit → SetInitialParams(SystemConfig) → Dashboard stores config
                                          ↓
OnTimer (1s) → GetParams() → SystemConfig{main, m2, m5, m15}
   ├─ CalculateTargetTime(p)      → NYO countdown calculation
   ├─ RunORBRunners(cfg)          → Triggers process for active timeframes
   │    ├─ ProcessORB(m2)         → 2m state machine
   │    ├─ ProcessORB(m5)         → 5m state machine
   │    └─ ProcessORB(m15)        → 15m state machine
   ├─ CheckAutoFlatten(m2/m5/m15) → Auto-cancels / Max hold closures
   ├─ UpdateTradeStats()          → Per-TF win/loss/PL parsed from MT5 deal history
   └─ AccumulateDayEntries()      → Caches new entry/cancel reasons for Stats tab

OnTick → CheckAutoFlatten() + TrailManager.Process() for all active timeframes
```

### Global Override Logic
When `globalOverride=true`, the settings defined in the Main tab forcefully apply to all active strategies (2m, 5m, 15m). 
**Critical Constraint:** The system explicitly sets `pm2.timeframe=PERIOD_M2`, `pm5.timeframe=PERIOD_M5`, and `pm15.timeframe=PERIOD_M15` before execution, ensuring that EMA and candle indexing *always* evaluate on the correct timeframe regardless of global inputs.

## 3. ORB State Machine (`COrderManager`)

```text
ORB_WAIT_NYO → ORB_WAIT_CANDLE → ORB_WAIT_BREAK → ORB_WAIT_RETEST → ORB_WAIT_ENTRY → ORB_DONE
                                       ↑                                    │
                                       └──── contAfter1st ──────────────────┘
                                                                    ORB_STOPPED (afterMinutes timeout)
```

| State | Condition to Advance |
|-------|----------------------|
| `WAIT_NYO` | `now >= nyOpenTimeServer` |
| `WAIT_CANDLE` | The first candle strictly after NYO completes forming. |
| `WAIT_BREAK` | A candle body closes completely outside the captured H/L range. |
| `WAIT_RETEST` | An opposite-color candle touches/penetrates the range boundary. |
| `WAIT_ENTRY` | A pending stop order is placed; system awaits fill or a cancellation trigger. |
| `STOPPED` | Strategy exceeded `afterMinutes` timeout — hard stop. |
| `DONE` | Trade cycle complete (TP, SL, or manual close). |

## 4. Auto-Flatten / Auto-Cancel System

Evaluated continuously via `CheckAutoFlatten()`:

| Condition | Logic / Action |
|-----------|----------------|
| **Unfilled Candles** | `iBarShift >= N` → Cancels pending order if not triggered in time. |
| **Max Hold Candles** | `iBarShift(fill_time) >= N` → Flattens (market close) active trades if TP isn't hit in time. |
| **After Minutes** | `now >= nyoTime + N*60` → Triggers `ORB_STOPPED`. |
| **Unfavor Move** | Cancels if price moves `N` points away from the pending entry price. |
| **Touch Mid** | Cancels if price retraces to exactly `(rangeHigh + rangeLow) / 2`. |
| **EMA 1/2/3** | Cancels if price action crosses the defined moving averages (trend invalidation). |

## 5. Trail & Breakeven

| Mode | Logic |
|------|-------|
| **OFF** | No trailing applied. |
| **CHASE** | Classic step trailing (`trigger` → `distance` → `step`). |
| **CANDLE_1/2/3** | Trails SL to the extreme (High/Low) of candle[N]. |
| **Breakeven** | Calculates an aggregate volume-weighted average entry across all open positions. Sets a hard visual `BE_Line` on the chart. |

## 6. Risk Management & Stat Tracking

- **Lot Sizing:** Auto-calculated: `Balance * riskPercent / (SL_points * tickValue / tickSize)`.
- **Per-TF Counters:** Win/Loss and P/L metrics are independently parsed from the `DEAL_COMMENT` history (e.g., `orb-2m`, `orb-15m`) ensuring accurate metrics even if MT5 replaces exit comments.
- **Daily Limits:** Trades stop firing if `maxSuccess` or `maxLoss` thresholds are breached per timeframe.

## 7. Chart Objects

All ORB visual lines/labels use `OBJPROP_BACK=true` to render neatly behind the UI dashboard:
- Range H/L boundaries (Color coded by timeframe).
- Dash-style entry and target marks.
- Aggregate Breakeven line (`BE_Line` in Yellow).
