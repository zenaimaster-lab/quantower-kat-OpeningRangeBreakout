# Graph Report - .  (2026-05-08)

## Corpus Check
- Corpus is ~16,237 words - fits in a single context window. You may not need a graph.

## Summary
- 157 nodes · 279 edges · 16 communities (11 shown, 5 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Dashboard UI Controls|Dashboard UI Controls]]
- [[_COMMUNITY_Risk Manager|Risk Manager]]
- [[_COMMUNITY_Dashboard Core|Dashboard Core]]
- [[_COMMUNITY_Shared Definitions|Shared Definitions]]
- [[_COMMUNITY_Order Engine|Order Engine]]
- [[_COMMUNITY_Time Manager|Time Manager]]
- [[_COMMUNITY_Stats & PL Display|Stats & P/L Display]]
- [[_COMMUNITY_News Manager|News Manager]]
- [[_COMMUNITY_Panel Layout|Panel Layout]]
- [[_COMMUNITY_Trade Toggles|Trade Toggles]]
- [[_COMMUNITY_Trail Mode UI|Trail Mode UI]]
- [[_COMMUNITY_Big Momentum Toggle|Big Momentum Toggle]]
- [[_COMMUNITY_Breakeven Toggle|Breakeven Toggle]]
- [[_COMMUNITY_Max Loss Toggle|Max Loss Toggle]]
- [[_COMMUNITY_Dashboard Constructor|Dashboard Constructor]]

## God Nodes (most connected - your core abstractions)
1. `HandleDirectClick()` - 28 edges
2. `LoadTab()` - 19 edges
3. `UpdTabs()` - 11 edges
4. `GetPoint()` - 9 edges
5. `FormatMoneyRound()` - 7 edges
6. `ProcessORB()` - 7 edges
7. `CalcLotSize()` - 7 edges
8. `SaveTab()` - 6 edges
9. `CalcRiskRewardInfo()` - 6 edges
10. `CreatePanel()` - 5 edges

## Surprising Connections (you probably didn't know these)
- `ProcessORB()` --calls--> `GetPoint()`  [INFERRED]
  OrderManager.mqh → RiskManager.mqh
- `ProcessORB()` --calls--> `GetSpread()`  [INFERRED]
  OrderManager.mqh → RiskManager.mqh
- `CheckAutoCancel()` --calls--> `GetPoint()`  [INFERRED]
  OrderManager.mqh → RiskManager.mqh
- `ForceBreakeven()` --calls--> `GetPoint()`  [INFERRED]
  TrailManager.mqh → RiskManager.mqh
- `OnInit()` --calls--> `InitPreset()`  [INFERRED]
  mt5-kat-ORB.mq5 → Defines.mqh

## Communities (16 total, 5 thin omitted)

### Community 0 - "Dashboard UI Controls"
Cohesion: 0.08
Nodes (38): CtrlShow(), CtrlShowEdit(), GetParams(), HandleDirectClick(), LoadTab(), Maximize(), OnA2(), OnA3() (+30 more)

### Community 1 - "Risk Manager"
Cohesion: 0.19
Nodes (17): CalcLotSize(), CalcRiskRewardInfo(), CRiskManager, GetLotStep(), GetMaxLot(), GetMinLot(), GetPoint(), GetSpread() (+9 more)

### Community 2 - "Dashboard Core"
Cohesion: 0.12
Nodes (4): CtrlHide(), CtrlShowBtn(), Minimize(), OnA1()

### Community 3 - "Shared Definitions"
Cohesion: 0.12
Nodes (6): InitPreset(), IsMarketOpen(), OnInit(), OnTick(), OnTimer(), UpdateTradeStats()

### Community 4 - "Order Engine"
Cohesion: 0.19
Nodes (11): CancelAllPending(), CheckAutoCancel(), CleanupLines(), COrderManager, DeleteLines(), DrawORBLines(), DrawTradeLines(), GenerateOrderTag() (+3 more)

### Community 5 - "Time Manager"
Cohesion: 0.21
Nodes (5): CalculateTargetTime(), CTimeManager, GetBrokerGMTOffset(), NYTimeToServerTime(), Reset()

### Community 6 - "Stats & P/L Display"
Cohesion: 0.29
Nodes (7): FormatMoneyRound(), Update2mPL(), Update5mPL(), UpdateBalanceInfo(), UpdateEquityPL(), UpdateRealtimeRR(), UpdateStatsTab()

### Community 7 - "News Manager"
Cohesion: 0.38
Nodes (4): CalcNextNYOEvent(), CNewsManager, NYOToUTC(), Update()

### Community 8 - "Panel Layout"
Cohesion: 0.4
Nodes (5): CreatePanel(), MB(), ME(), ML(), MSep()

### Community 9 - "Trade Toggles"
Cohesion: 0.5
Nodes (4): OnToggleGlobal(), OnToggleM2(), OnToggleM5(), UpdToggles()

## Knowledge Gaps
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GetPoint()` connect `Risk Manager` to `Order Engine`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `ProcessORB()` connect `Order Engine` to `Risk Manager`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `HandleDirectClick()` connect `Dashboard UI Controls` to `Dashboard Core`, `Trade Toggles`, `Trail Mode UI`, `Big Momentum Toggle`, `Breakeven Toggle`, `Max Loss Toggle`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `GetPoint()` (e.g. with `ProcessORB()` and `CheckAutoCancel()`) actually correct?**
  _`GetPoint()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Should `Dashboard UI Controls` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Dashboard Core` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Should `Shared Definitions` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._