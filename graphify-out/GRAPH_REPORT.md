# Graph Report - mt5-kat-OpeningRangeBreakout  (2026-05-19)

## Corpus Check
- 1 files · ~7,599 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 157 nodes · 279 edges · 16 communities (11 shown, 5 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b11a042f`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]

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

### Community 0 - "Community 0"
Cohesion: 0.08
Nodes (38): CtrlShow(), CtrlShowEdit(), GetParams(), HandleDirectClick(), LoadTab(), Maximize(), OnA2(), OnA3() (+30 more)

### Community 1 - "Community 1"
Cohesion: 0.19
Nodes (17): CalcLotSize(), CalcRiskRewardInfo(), CRiskManager, GetLotStep(), GetMaxLot(), GetMinLot(), GetPoint(), GetSpread() (+9 more)

### Community 2 - "Community 2"
Cohesion: 0.12
Nodes (4): CtrlShowBtn(), OnA1(), OnTrM(), UpdTrail()

### Community 3 - "Community 3"
Cohesion: 0.12
Nodes (6): InitPreset(), IsMarketOpen(), OnInit(), OnTick(), OnTimer(), UpdateTradeStats()

### Community 4 - "Community 4"
Cohesion: 0.19
Nodes (11): CancelAllPending(), CheckAutoCancel(), CleanupLines(), COrderManager, DeleteLines(), DrawORBLines(), DrawTradeLines(), GenerateOrderTag() (+3 more)

### Community 5 - "Community 5"
Cohesion: 0.21
Nodes (5): CalculateTargetTime(), CTimeManager, GetBrokerGMTOffset(), NYTimeToServerTime(), Reset()

### Community 6 - "Community 6"
Cohesion: 0.29
Nodes (7): FormatMoneyRound(), Update2mPL(), Update5mPL(), UpdateBalanceInfo(), UpdateEquityPL(), UpdateRealtimeRR(), UpdateStatsTab()

### Community 7 - "Community 7"
Cohesion: 0.38
Nodes (4): CalcNextNYOEvent(), CNewsManager, NYOToUTC(), Update()

### Community 8 - "Community 8"
Cohesion: 0.4
Nodes (5): CreatePanel(), MB(), ME(), ML(), MSep()

### Community 9 - "Community 9"
Cohesion: 0.5
Nodes (4): OnToggleGlobal(), OnToggleM2(), OnToggleM5(), UpdToggles()

## Knowledge Gaps
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `GetPoint()` connect `Community 1` to `Community 4`?**
  _High betweenness centrality (0.030) - this node is a cross-community bridge._
- **Why does `ProcessORB()` connect `Community 4` to `Community 1`?**
  _High betweenness centrality (0.016) - this node is a cross-community bridge._
- **Why does `HandleDirectClick()` connect `Community 0` to `Community 2`, `Community 9`, `Community 10`, `Community 11`, `Community 12`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `GetPoint()` (e.g. with `ProcessORB()` and `CheckAutoCancel()`) actually correct?**
  _`GetPoint()` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._
- **Should `Community 3` be split into smaller, more focused modules?**
  _Cohesion score 0.12 - nodes in this community are weakly interconnected._