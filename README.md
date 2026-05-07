# KAT Opening Range Breakout (mt5-kat-ORB)

A MetaTrader 5 Expert Advisor that trades the **Opening Range Breakout & Retest** strategy on dual timeframes (2m and 5m) around New York Open.

## Strategy

1. **Range Detection** — Captures the High/Low of the first candle after NY Open on both M2 and M5.
2. **Breakout Confirmation** — Waits for a candle body to close outside the range (not just wicks).
3. **Retest Entry** — On the first opposite-color candle touching the range boundary, places a pending stop order beyond the retest candle to catch the engulfing move.
4. **Auto Cancel** — Multiple cancel conditions: Unfavor move, Touch mid-range, Unfilled candles, After X minutes, EMA crossover.

## Architecture

| Module | File | Role |
|--------|------|------|
| **Main Loop** | `mt5-kat-ORB.mq5` | OnTick/OnTimer orchestration |
| **Dashboard** | `Dashboard.mqh` | 4-tab UI (Main, 2m, 5m, Stats) |
| **Order Engine** | `OrderManager.mqh` | ORB state machine, entry/cancel logic |
| **Time Manager** | `TimeManager.mqh` | NY timezone, NYO countdown |
| **Risk Manager** | `RiskManager.mqh` | Lot sizing by % risk |
| **Trail Manager** | `TrailManager.mqh` | Trailing stop, breakeven |
| **News Manager** | `NewsManager.mqh` | Session awareness |
| **Defines** | `Defines.mqh` | Shared structs, enums, constants |

## Features

- **Dual Timeframe** — Independent 2m and 5m strategies running simultaneously
- **Global Override** — Share settings across both timeframes or configure independently
- **Visual ORB Lines** — H/L range, entry, and target lines drawn on chart
- **Auto Cancel System** — 6 conditions: Unfavor move, Touch mid, Unfilled candles, After minutes, EMA 1/2/3
- **Trail Modes** — Chase (trigger/distance/step), Candle-based (shift 1/2/3)
- **Aggregate Breakeven** — Volume-weighted average entry across all positions
- **3 Presets** — Quick parameter switching (Set A/B/C)
- **Stats Dashboard** — Per-timeframe P/L, order status, entry/cancel reasons
- **Continue After 1st** — Re-enters WAIT_BREAK after fill/cancel
- **Max Win/Loss Limits** — Daily trade count caps
- **Minimizable UI** — Compact dark theme dashboard

## Deployment

```powershell
./deploy.ps1   # Copy to MT5 + compile
```

## Version

Current: **v1.0** | 08 May 2026
