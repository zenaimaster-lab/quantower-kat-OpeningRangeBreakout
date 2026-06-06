# Graph Report - quantower-kat-OpeningRangeBreakout  (2026-06-06)

## Corpus Check
- 12 files · ~9,858 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 113 nodes · 194 edges · 13 communities (12 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `239164cc`
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
2. `ORBRunner` - 20 edges
3. `ORBRunner` - 19 edges
4. `KatOpeningRangeIndicator` - 14 edges
5. `TimeManager` - 6 edges
6. `TimeManager` - 6 edges
7. `DateTime` - 5 edges
8. `int` - 4 edges
9. `RiskManager` - 4 edges
10. `TrailManager` - 4 edges

## Surprising Connections (you probably didn't know these)
- `KatOpeningRangeBreakout` --references--> `string`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → ORBRunner.cs
- `KatOpeningRangeBreakout` --references--> `bool`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `KatOpeningRangeBreakout` --references--> `HistoricalData`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `KatOpeningRangeBreakout` --references--> `Dictionary`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `KatOpeningRangeBreakout` --references--> `int`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → TimeManager.cs

## Communities (13 total, 1 thin omitted)

### Community 1 - "Community 1"
Cohesion: 0.17
Nodes (3): KatORB, ORBRunner, string

### Community 2 - "Community 2"
Cohesion: 0.2
Nodes (6): bool, Dictionary, HistoricalData, Indicator, KatOpeningRangeIndicator, KatORB

### Community 3 - "Community 3"
Cohesion: 0.18
Nodes (5): DateTime, int, TimeManager, KatORB, TimeManager

### Community 4 - "Community 4"
Cohesion: 0.16
Nodes (8): Account, List, KatOpeningRangeBreakout, RiskManager, Strategy, Symbol, TimeManager, TrailManager

### Community 5 - "Community 5"
Cohesion: 0.22
Nodes (5): KatOpeningRangeBreakout, KatORB, RiskManager, KatORB, TrailManager

### Community 6 - "Community 6"
Cohesion: 0.32
Nodes (3): KatORB, RiskManager, TrailManager

## Knowledge Gaps
- **12 isolated node(s):** `KatORB`, `Symbol`, `Account`, `TimeManager`, `RiskManager` (+7 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `KatOpeningRangeBreakout` connect `Community 4` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 6`?**
  _High betweenness centrality (0.508) - this node is a cross-community bridge._
- **Why does `ORBRunner` connect `Community 1` to `Community 3`, `Community 5`?**
  _High betweenness centrality (0.412) - this node is a cross-community bridge._
- **Why does `DateTime` connect `Community 3` to `Community 0`, `Community 1`, `Community 4`?**
  _High betweenness centrality (0.295) - this node is a cross-community bridge._
- **What connects `KatORB`, `Symbol`, `Account` to the rest of the system?**
  _12 weakly-connected nodes found - possible documentation gaps or missing edges._