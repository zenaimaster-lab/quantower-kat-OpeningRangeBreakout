# KAT-ORB Architecture & Logic Reference

## 1. Frontend UI Architecture

The EA uses a `CAppDialog`-based dashboard with 4 tabs (Main, 2m, 5m, Stats) rendered on the MT5 chart.

### Click Handling (The "3 Pillars" Fix)
1. **Purged `EVENT_MAP`** — Eliminates MQL5's broken internal bounding-box hit testing.
2. **Native `CHARTEVENT_OBJECT_CLICK`** — `OnChartEvent` intercepts clicks instantly.
3. **`HandleDirectClick` + Debouncing** — 500ms debounce guard prevents double-fires.

### Tab Structure
- **Main** — Symbol, schedule (NY Hour/Min/Sec), UTC offset, risk %, order mode, presets
- **2m/5m** — Per-timeframe overrides for SL/TP, trail, auto-cancel, EMA filters
- **Stats** — ORDERS status (2m/5m), LAST ENTRY reasons, TOTAL/2m/5m P/L

## 2. Data Flow

```
OnInit → SetInitialParams(SystemConfig) → Dashboard stores config
                                          ↓
OnTimer (1s) → GetParams() → SystemConfig{main, m2, m5}
   ├─ CalculateTargetTime(p)     → NYO countdown
   ├─ ProcessORB(pm2, nyoTime)   → 2m state machine
   ├─ ProcessORB(pm5, nyoTime)   → 5m state machine
   ├─ CheckAutoCancel(pm2/pm5)   → Pending order cancellation (also in OnTick)
   ├─ UpdateTradeStats()         → Per-TF win/loss/PL from deal history
   └─ Trail/BE updates           → From OnTick for tick-level precision

OnTick → CheckAutoCancel(pm2, pm5) + TrailManager.Process(pm2, pm5)
```

### Global Override Logic
When `globalOverride=true`, the main tab settings apply to both strategies.
**Critical:** Both OnTick and OnTimer force `pm2.timeframe=PERIOD_M2` and `pm5.timeframe=PERIOD_M5` regardless of global override, ensuring EMA/candle calculations always use the correct timeframe.

## 3. ORB State Machine (`COrderManager`)

```
ORB_WAIT_NYO → ORB_WAIT_CANDLE → ORB_WAIT_BREAK → ORB_WAIT_RETEST → ORB_WAIT_ENTRY → ORB_DONE
                                       ↑                                    │
                                       └──── contAfter1st ────────────────┘
                                                                    ORB_STOPPED (afterMinutes timeout)
```

| State | Condition to advance |
|-------|---------------------|
| WAIT_NYO | `now >= nyOpenTimeServer` |
| WAIT_CANDLE | First candle after NYO has closed |
| WAIT_BREAK | Candle body closes outside range H/L |
| WAIT_RETEST | Opposite-color candle touches range boundary |
| WAIT_ENTRY | Pending stop placed, waiting for fill or cancel |
| STOPPED | afterMinutes expired — hard stop, no continuation |
| DONE | Trade cycle complete |

### Order Mode Filtering
- `MODE_BOTH` — Both Buy Stop and Sell Stop allowed
- `MODE_BUY_ONLY` — Only Break UP retest → Buy Stop
- `MODE_SELL_ONLY` — Only Break DOWN retest → Sell Stop

## 4. Auto Cancel System

Evaluated on every tick via `CheckAutoCancel()`:

| Condition | Logic |
|-----------|-------|
| Unfilled Candles | `iBarShift(sym, tf, placedTime) >= N` |
| After Minutes | `now >= nyoTime + N*60` → sets ORB_STOPPED |
| Unfavor Move | BuyStop: `bid <= entry - Npts` / SellStop: `ask >= entry + Npts` |
| Touch Mid | Price reaches `(rangeHigh + rangeLow) / 2` |
| EMA 1/2/3 | BuyStop: `bid < EMA` / SellStop: `ask > EMA` (each EMA computed on correct TF) |

### Cancel → State Transition
- afterMinutes → `ORB_STOPPED` (no continuation)
- Other cancels + `contAfter1st=true` → `ORB_WAIT_BREAK` (re-enter)
- Other cancels + `contAfter1st=false` → `ORB_DONE`
- Max Success/Loss hit → `ORB_DONE`

## 5. Trail & Breakeven

| Mode | Logic |
|------|-------|
| OFF | No trailing |
| CHASE | trigger→distance→step classic trailing |
| CANDLE_1/2/3 | Trail SL to candle[N] low (buy) or high (sell) |
| Breakeven | Aggregate weighted avg entry + lock offset |

## 6. Risk Management

- Lot size = `Balance * riskPercent / (SL_points * tickValue / tickSize)`
- SL Candle mode: SL = retest candle extreme ± buffer
- SL Points mode: SL = entry ± fixed points
- Per-trade risk visualization in dashboard

## 7. Chart Objects

All ORB lines/labels use `OBJPROP_BACK=true` to render behind the dashboard:
- Range H/L lines (blue for 2m, green/red for 5m)
- Entry/Target short marks (dash style)
- BE line (yellow)
