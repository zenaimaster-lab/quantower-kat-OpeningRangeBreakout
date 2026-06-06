# Graph Report - quantower-kat-OpeningRangeBreakout  (2026-06-06)

## Corpus Check
- 12 files · ~10,853 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 118 nodes · 209 edges · 13 communities (11 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `3fa268b8`
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

## God Nodes (most connected - your core abstractions)
1. `KatOpeningRangeBreakout` - 33 edges
2. `ORBRunner` - 21 edges
3. `ORBRunner` - 19 edges
4. `KatOpeningRangeIndicator` - 14 edges
5. `int` - 8 edges
6. `DateTime` - 7 edges
7. `TimeManager` - 6 edges
8. `TimeManager` - 6 edges
9. `double` - 4 edges
10. `VwapCache` - 4 edges

## Surprising Connections (you probably didn't know these)
- `KatOpeningRangeBreakout` --references--> `bool`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `KatOpeningRangeBreakout` --references--> `HistoricalData`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `KatOpeningRangeBreakout` --references--> `string`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → ORBRunner.cs
- `KatOpeningRangeBreakout` --references--> `int`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → TimeManager.cs
- `KatOpeningRangeBreakout` --references--> `Dictionary`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → ORBRunner.cs

## Communities (13 total, 2 thin omitted)

### Community 1 - "Community 1"
Cohesion: 0.13
Nodes (9): Account, List, KatOpeningRangeBreakout, RiskManager, Strategy, string, Symbol, TimeManager (+1 more)

### Community 2 - "Community 2"
Cohesion: 0.18
Nodes (11): DateTime, double, int, EmaCache, KatORB, VwapCache, EmaCache, KatORB (+3 more)

### Community 4 - "Community 4"
Cohesion: 0.19
Nodes (4): KatORB, RiskManager, TimeManager, TrailManager

### Community 5 - "Community 5"
Cohesion: 0.24
Nodes (5): bool, Dictionary, HistoricalData, Indicator, KatOpeningRangeIndicator

### Community 6 - "Community 6"
Cohesion: 0.22
Nodes (5): KatOpeningRangeBreakout, KatORB, RiskManager, KatORB, TrailManager

## Knowledge Gaps
- **12 isolated node(s):** `KatORB`, `Symbol`, `Account`, `TimeManager`, `RiskManager` (+7 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `KatOpeningRangeBreakout` connect `Community 1` to `Community 0`, `Community 2`, `Community 4`, `Community 5`?**
  _High betweenness centrality (0.439) - this node is a cross-community bridge._
- **Why does `ORBRunner` connect `Community 3` to `Community 1`, `Community 2`, `Community 5`, `Community 6`?**
  _High betweenness centrality (0.386) - this node is a cross-community bridge._
- **Why does `DateTime` connect `Community 2` to `Community 0`, `Community 1`, `Community 3`, `Community 4`?**
  _High betweenness centrality (0.247) - this node is a cross-community bridge._
- **What connects `KatORB`, `Symbol`, `Account` to the rest of the system?**
  _12 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.13 - nodes in this community are weakly interconnected._