# KAT Opening Range Breakout (mt5-kat-ORB)

A MetaTrader 5 Expert Advisor that trades the **Opening Range Breakout & Retest** strategy across multiple timeframes (M2, M5, M15) synchronously around the New York Open (NYO).

## Core Strategy Logic

1. **Range Detection** — Captures the High/Low of the first candle after NY Open for each active timeframe independently.
2. **Breakout Confirmation** — Waits for a candle body to close completely outside the detected range (wicks are ignored).
3. **Retest Entry** — On the first opposite-color candle touching the range boundary, places a pending stop order beyond the retest candle to catch the engulfing continuation move.
4. **Auto-Flatten & Cancel System** — Manages trade lifecycles strictly to prevent adverse entries:
   - **Unfavor Move:** Cancels if price moves significantly away from the entry before filling.
   - **Touch Mid:** Cancels if price reverts to the mid-point of the ORB range.
   - **Unfilled Candles:** Cancels if the pending order isn't filled within X candles.
   - **Max Hold Candles:** Automatically closes filled trades if they don't hit TP within X candles.
   - **After X Minutes:** Hard stop on the strategy after NYO + X minutes.
   - **EMA Filters:** Dynamic trend filtering using 3 EMAs.

## Architecture

| Module | File | Role |
|--------|------|------|
| **Main Loop** | `mt5-kat-ORB.mq5` | OnTick/OnTimer orchestration and trade stat aggregation |
| **Dashboard** | `Dashboard.mqh` | Comprehensive UI (Main, 2m, 5m, 15m, Stats tabs) |
| **Order Engine** | `OrderManager.mqh` | ORB state machine, entry logic, cancel logic |
| **Time Manager** | `TimeManager.mqh` | NY timezone, UTC offset, NYO countdown |
| **Risk Manager** | `RiskManager.mqh` | Lot sizing by % risk or fixed lot, balance/equity tracking |
| **Trail Manager** | `TrailManager.mqh` | Trailing stops (Chase, Candle shift) and breakeven logic |
| **News Manager** | `NewsManager.mqh` | Session awareness and news event integration |
| **Defines** | `Defines.mqh` | Shared structs, enums, constants, and UI styling tokens |
| **Global State**| `GlobalState.mqh` | Centralized state for Win/Loss counters across timeframes |

## UX / UI Design

The Dashboard is built using an interactive `CAppDialog` with a sleek, dark-themed aesthetic (`CLR_PANEL_BG`). It features 5 primary tabs:
- **MAIN:** Global settings, Symbol selection, NY Schedule, Risk %, Order Modes, and Preset buttons. Features "Global Override" to enforce these settings across all timeframes.
- **2M / 5M / 15M:** Timeframe-specific configurations. Users can toggle strategies ON/OFF, set unique SL/TP, Auto-Cancels, and EMA filters.
- **STATS:** Real-time P/L tracking. Includes a numbered `LAST ENTRIES` queue (1-6) that logs exactly why trades were entered or canceled, categorized by timeframe. It also aggregates Total, 2m, 5m, and 15m P/L, Wins, and Losses.

**Visual Indicators (Chart):**
- **ORB Lines:** Draws horizontal H/L range lines (colored by timeframe).
- **Entry/Target Marks:** Dash style visual cues.
- **BE Line:** An aggregate yellow line showing the volume-weighted average entry point of all active positions.
- **UI Responsiveness:** The dashboard is minimizable to avoid chart clutter and uses a strict 500ms debounce on clicks to prevent misfires.

## Advanced Features

- **Multi-Timeframe Concurrency** — M2, M5, and M15 strategies run simultaneously and independently unless constrained by Global Override.
- **Aggregate Breakeven** — Calculates a volume-weighted average entry across all positions to manage risk holistically.
- **12 Presets System** — Fast parameter switching (mA/B/C, 2A/B/C, 5A/B/C, 15A/B/C).
- **Daily Caps** — Max Win / Max Loss daily limiters per timeframe to protect capital.
- **Big Momentum Mode** — Optional toggle for volatile conditions.

## Deployment & Setup

- **`deploy.ps1`**: PowerShell script to automatically copy `.mq5`/`.mqh` files into the MT5 directory and invoke the compiler.
- **`skill-mt5-workflow`**: AI Agent skill folder containing definitions for workflow execution.
- **`agents.md`**: Behavioral rules and coding standards for AI agents interacting with this repo.
