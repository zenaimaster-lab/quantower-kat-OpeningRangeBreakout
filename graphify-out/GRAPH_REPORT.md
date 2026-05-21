# Graph Report - quantower-kat-OpeningRangeBreakout  (2026-05-22)

## Corpus Check
- 8 files · ~8,051 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 74 nodes · 136 edges · 12 communities (11 shown, 1 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `09872044`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]

## God Nodes (most connected - your core abstractions)
1. `KatOpeningRangeBreakout` - 31 edges
2. `ORBRunner` - 19 edges
3. `KatOpeningRangeIndicator` - 13 edges
4. `TimeManager` - 6 edges
5. `RiskManager` - 4 edges
6. `TrailManager` - 4 edges
7. `int` - 3 edges
8. `DateTime` - 3 edges
9. `bool` - 2 edges
10. `HistoricalData` - 2 edges

## Surprising Connections (you probably didn't know these)
- `KatOpeningRangeBreakout` --references--> `bool`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `KatOpeningRangeBreakout` --references--> `HistoricalData`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `KatOpeningRangeBreakout` --references--> `Dictionary`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `KatOpeningRangeBreakout` --references--> `int`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs
- `TimeManager` --references--> `int`  [EXTRACTED]
  KatOpeningRangeBreakout.cs → KatOpeningRangeIndicator.cs

## Communities (12 total, 1 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.22
Nodes (6): bool, Dictionary, HistoricalData, Indicator, KatOpeningRangeIndicator, KatORB

### Community 1 - "Community 1"
Cohesion: 0.18
Nodes (7): List, KatOpeningRangeBreakout, RiskManager, Strategy, string, TimeManager, TrailManager

### Community 4 - "Community 4"
Cohesion: 0.31
Nodes (3): DateTime, int, TimeManager

### Community 5 - "Community 5"
Cohesion: 0.32
Nodes (3): KatORB, RiskManager, TrailManager

## Knowledge Gaps
- **7 isolated node(s):** `KatORB`, `TimeManager`, `RiskManager`, `TrailManager`, `List` (+2 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `KatOpeningRangeBreakout` connect `Community 1` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 5`?**
  _High betweenness centrality (0.571) - this node is a cross-community bridge._
- **Why does `KatOpeningRangeIndicator` connect `Community 0` to `Community 4`?**
  _High betweenness centrality (0.231) - this node is a cross-community bridge._
- **Why does `ORBRunner` connect `Community 2` to `Community 1`, `Community 3`, `Community 4`, `Community 5`?**
  _High betweenness centrality (0.201) - this node is a cross-community bridge._
- **What connects `KatORB`, `TimeManager`, `RiskManager` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._