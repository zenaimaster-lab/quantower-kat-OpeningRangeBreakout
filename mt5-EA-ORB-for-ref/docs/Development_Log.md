# Development and Fix Log

## 2026-05-18_NYO_Time_Sync_Fix.md

# Session Diary: NYO Time Sync Fix
**Date:** 18 May 2026
**Version:** 1.41

## Objective
Fix a critical bug where the EA calculates the NY Open time incorrectly due to sub-second tick delays between `TimeTradeServer()` and `TimeGMT()`, causing the Opening Range Breakout lines to draw very early (e.g., 9:00 or 9:15 NYT).

## Changes Made
- **TimeManager.mqh**:
  - Updated `GetBrokerGMTOffset()` to round the computed broker offset to the nearest 15 minutes (900 seconds). This eliminates 1-2 second inaccuracies caused by MT5 tick delays.
  - Previously, an offset of 10799 seconds instead of 10800 caused `m_nyoTime` to be computed as 15:29:59 instead of 15:30:00. This caused `iBarShift` to match the *preceding* candle (e.g., the 15:15 candle for M15, or 15:00 for H1/M30), completely misaligning the range calculation.
- **mt5-kat-ORB.mq5**:
  - Fixed misleading tooltip on the `InpNyHour` parameter from `(Broker Time)` to `(NY Time)` to prevent user confusion.
- **Defines.mqh**:
  - Bumped `EA_VERSION` to 1.41 and updated `EA_BUILD_DATE` to 18 May 2026.


## 2026-05-07_18_15_UI_Removal.md

# Phiên làm việc: Loại bỏ UI Countdown và Target Timing
**Thời gian:** 2026-05-07
**Mục tiêu:** Tinh gọn giao diện (UI) bằng cách xóa bỏ hoàn toàn phần Target Timing và Countdown, đồng thời reset version về 0.01 theo yêu cầu để bắt đầu bản Auto-Run mới.

### 1. Các thay đổi chính:
* **Reset Version:**
  * Cập nhật `EA_VERSION` thành `0.01` và `EA_BUILD_DATE` thành `07 May 2026` trong `Defines.mqh`.
* **Loại bỏ UI Countdown & Target Timing:**
  * Đã xóa các khai báo label và edit box liên quan đến `Target H:M:S`, `Trigger before sec`, và `Countdown` trong `Dashboard.mqh`.
  * Xóa các nút chọn ngày (Day Picker) và logic cập nhật (ApplyTimingFromNews, OnDayPicker, UpdateCountdown).
* **Điều chỉnh Logic Auto-Run:**
  * Giữ lại các input `InpNyHour`, `InpNyMinute`, `InpNySecond` trong `kat-Orb-Breakout.mq5` để thiết lập thời điểm ban đầu. 
  * Cập nhật `DashboardParams` chỉ lưu trữ thông tin nội bộ mà không gán/lấy từ UI đối với các trường thời gian nữa. EA tự động kích hoạt thông qua `TimeManager` và `NewsManager` thay vì dựa vào UI.
  * Phương thức `ApplyNewsToTiming` trong file chính cập nhật thẳng vào struct `DashboardParams` nội bộ thay vì update thông qua giao diện văn bản.

### 2. Trạng thái hiện tại:
* EA biên dịch thành công (0 lỗi, 0 cảnh báo).
* Giao diện đã gọn gàng hơn, chỉ còn tập trung vào Risk/Reward, Quản lý lệnh (OCO) và bộ lọc News.
* Cấu trúc Auto-Run hoàn toàn tự động, người dùng không cần can thiệp thông qua UI để đặt thời gian.

### 3. Bước tiếp theo:
* Tối ưu hóa lại `OrderManager` và `TimeManager` nếu có thay đổi thêm về luồng break-out/oco orders.
* Kiểm tra tích hợp tin tức tự động.

---

## 2026-05-07_18_25_NewsManager_Simplification.md

# Phiên làm việc: Tối giản NewsManager thành SessionManager
**Thời gian:** 2026-05-07
**Mục tiêu:** Loại bỏ tính năng bắt Red News từ bộ lịch kinh tế (Economic Calendar). Thay thế hoàn toàn bằng việc hiển thị "Next session: NY Open". Đảm bảo quy trình Auto-Run chỉ tập trung vào NY Open.

### 1. Các thay đổi chính:
* **Tự động Version Bump:**
  * Cập nhật `EA_VERSION` thành `0.02` (tăng 0.01 theo workflow) trong `Defines.mqh`.
* **Loại bỏ tính năng News Filter:**
  * Xóa hoàn toàn cấu trúc gọi tin tức từ `CalendarValueHistory` trong `NewsManager.mqh`. Class này hiện đã được viết lại, chỉ đóng vai trò như một **Session Manager**, tính toán và cung cấp mốc thời gian NY Open kế tiếp dựa trên các input `InpNyHour`, `InpNyMinute`, `InpNySecond` và hiển thị chuỗi "NY Open | HH:MM".
  * Xóa hoàn toàn nhóm tham số input `=== NEWS FILTER ===` trong `kat-Orb-Breakout.mq5`.
* **Dọn dẹp Giao diện (Dashboard.mqh):**
  * Sửa nhãn `"Next:"` thành `"Next session:"`.
  * Xóa các nút chọn chế độ tin tức: `m_btnNyoOnly` (NYO ONLY), `m_btnAutoApply` (AUTO APPLY), và `m_btnApplyNext` (APPLY NEXT) vì chúng không còn tác dụng.
  * Xóa các biến boolean `NYOOnlyMode`, `AutoNewsEnabled`, cùng mã xử lý `CMD_APPLY_NEXT` trong hàng đợi lệnh.

### 2. Trạng thái hiện tại:
* EA biên dịch thành công (0 lỗi, 0 cảnh báo).
* Giao diện đã gọn gàng tối đa. Phần "Next session" giờ đây chỉ dự báo thời gian phiên NY Open tiếp theo một cách độc lập và chính xác dựa vào múi giờ (UTC Offset).

### 3. Bước tiếp theo:
* Sẵn sàng chuyển trọng tâm sang logic Breakout và thực thi lệnh OCO theo đúng khung giờ NY Open.

---

## 2026-05-07_18_33_UI_Layout_and_CandleSrc_Cleanup.md

# Phiên làm việc: Tinh chỉnh Layout và xóa Candle Source
**Thời gian:** 2026-05-07
**Mục tiêu:** Căn chỉnh lại hiển thị chữ "Next session" và xóa hoàn toàn cấu hình Candle Source (Current/Previous).

### 1. Các thay đổi chính:
* **Tự động Version Bump:**
  * Cập nhật `EA_VERSION` thành `0.03` trong `Defines.mqh`.
* **Căn chỉnh UI (Dashboard.mqh):**
  * Đổi chiều dài vùng hiển thị label `"Next session:"` thành `LABEL_WIDTH` thay vì hardcode độ dài 80 (vốn bị cắt xén thành "Next sessio").
  * Đổi tọa độ bắt đầu của text hiển thị "NY Open | ..." từ `cx+84` sang biến chuẩn `rx` và độ rộng `rw`, giúp nó thẳng hàng dọc một cách hoàn hảo với các giá trị khác bên dưới (như M2, SL/TP...).
* **Loại bỏ Candle Source:**
  * Xóa hoàn toàn `m_lblCsTag` và `m_btnCandleSrc` khỏi giao diện, triệt tiêu tùy chọn "CURRENT"/"PREVIOUS".
  * Gỡ bỏ logic cập nhật `UpdCandleSrc`, `OnCandleSrc` trong `Dashboard.mqh`.
  * Xóa bỏ enum `ENUM_CANDLE_SOURCE` và tham số cấu hình `p.candleSource` trong `Defines.mqh` và `kat-Orb-Breakout.mq5` (`InpCandleSrc`).
  * **Core logic:** Cấu hình index `cIdx = 0` (tương đương với CURRENT candle) được đặt cố định (hardcoded) khi vẽ đường SL nến `iHigh()`/`iLow()` trong `OnTimer()` và thiết lập shift=0 trong `OrderManager.mqh` `PlaceOCOOrders()`. 

### 2. Trạng thái hiện tại:
* EA biên dịch thành công (0 lỗi, 0 cảnh báo).
* Giao diện rất gọn gàng và không còn bị lẹm chữ.

### 3. Bước tiếp theo:
* Sẵn sàng tùy biến sâu hơn vào logic giao dịch Breakout.

---

## 2026-05-07_Add_ENTRY_Section.md

# Session: 2026-05-07 — Add ENTRY Section & Layout Update

## Objective
Add a new `ENTRY` section above `AUTO CANCEL PENDING ORDER` in the MT5 Dashboard with toggles and parameters for continuation and momentum logic.

## Changes
- Updated `Defines.mqh`:
  - Added new states to `DashboardParams`: `contAfter1st`, `maxSuccessOn`, `maxSuccess` (default 5), `maxLossOn`, `maxLoss` (default 1), `bigMomentum`.
  - Increased `PANEL_HEIGHT` from 1420 to 1550 to accommodate the new UI rows.
  - Bumped version from 0.09 to 0.10.
- Updated `Dashboard.mqh`:
  - Added class members for `ENTRY` section UI (Labels, Edits, Buttons).
  - Wired UI elements to `SaveTab` and `LoadTab`.
  - Created click handlers: `OnContToggle`, `OnMaxSToggle`, `OnMaxLToggle`, `OnBigMToggle`.
  - Implemented `HandleDirectClick` logic for all new buttons.
  - Rendered `ENTRY` section with proper spacing above the Auto Cancel section.

## Files Modified
- `Dashboard.mqh`
- `Defines.mqh`

## Result
Code compiled successfully (0 errors, 0 warnings). UI successfully accommodates new layout configurations. All parameters are ready to be integrated into `OrderManager` and trading logic in future steps.

---

## 2026-05-07_Add_STATS_Tab.md

# Session: 2026-05-07 — Add STATS Tab & Dashboard Reorganization

## Objective
1. Rename the "MAIN" tab to "Global".
2. Add a new tab `💸` (`TAB_STATS`) to hold all trading status, statistics, and realtime calculations.
3. Clean up the configuration tabs (Global, 2m CONF, 5m CONF) so that status information is hidden there, providing more vertical space and a cleaner UI.

## Changes
- `Defines.mqh`:
  - Added `TAB_STATS=3` to `ENUM_TAB`.
- `Dashboard.mqh`:
  - Added `m_btnTabStats` to the layout with `💸` icon.
  - Adjusted Tab buttons' width (`cw-12`/4).
  - Implemented overlapping rendering in `CreatePanel`: the `STATUS` section is drawn underneath the tabs starting at `startCy`, occupying the exact physical space as the `INPUTS` sections.
  - Restructured `UpdTabs()`:
    - If `TAB_STATS` is active, hide all input fields, labels, toggles, preset buttons, and their respective horizontal separators. Show only the `STATUS` items.
    - If any other tab is active, hide all `STATUS` items and show the inputs/presets.
  - Guarded `LoadTab()` and `SaveTab()` to exit early if `tab == TAB_STATS` since the stats tab does not hold config inputs.

## Result
Code compiled successfully (0 errors, 0 warnings). The dashboard layout is successfully reorganized, creating a dedicated space for monitoring without cluttering the parameter configurations.

---

## 2026-05-07_Adjust_Panel_Height.md

# Session: 2026-05-07 — Adjust Panel Height for Full Form Visibility

## Objective
Increase the `PANEL_HEIGHT` of the EA dashboard to ensure the entire configuration form (up to the Presets section) is fully visible, as it was being clipped due to the previous height reduction.

## Changes
- `Defines.mqh`:
  - Increased `PANEL_HEIGHT` from 1000 to 1350. This provides enough vertical space to comfortably fit all newly added inputs (ENTRY section, expanded AUTO CANCEL options) and the PRESETS buttons, leaving a nice margin at the bottom.

## Result
Code compiled successfully (0 errors, 0 warnings). The dashboard now fully accommodates the configuration layout while maintaining the optimized STATUS tab overlap.

---

## 2026-05-07_Cleanup_AutoRun.md

# Session Diary: 2026-05-07 - Codebase Cleanup for Auto-Run Mode

## Context & Objectives
The goal of this session was to clean up the `mt5-kat-Orb-Breakout` codebase (forked from `mt5-kat-Strike`) to transition the Expert Advisor into a fully automated "Auto-Run" system. This required stripping out all manual trading functionalities, the Origami mathematical engine, and associated UI elements from the native MT5 Dashboard.

## Actions Taken
1.  **Removed Origami Module:**
    *   Completely deleted `OrigamiManager.mqh`.
    *   Removed all related inputs, Enums (`ENUM_ORIGAMI_SL_MODE`), and UI controls from `Dashboard.mqh` and `Defines.mqh`.
    *   Stripped the Origami logic loop from `OnTick` and `OnTimer` in `kat-Orb-Breakout.mq5`.

2.  **Removed Manual Trading Module:**
    *   Removed manual operations (`FlattenAll`, `BuyMarket`, `SellMarket`, `LockAll`, `ReverseAll`, `ApplyBE`, `ApplyTrail`, `CancelPend`, `PlaceStop`) from `OrderManager.mqh`.
    *   Stripped all associated Command Queue references (`ENUM_DASHBOARD_CMD`) in `Defines.mqh`.
    *   Removed manual UI buttons and their corresponding `HandleDirectClick` logic from `Dashboard.mqh`.
    *   Cleared keyboard shortcut handlers (`OnChartEvent`) tied to these commands in `kat-Orb-Breakout.mq5`.

3.  **Documentation & Deployment Verification:**
    *   Cleaned and updated documentation. Removed `ORIGAMI_DIAD_MATH.md` and refactored `v1.0_Architecture.md` into `Architecture.md` to accurately reflect the stripped-down, Auto-Run execution flow.
    *   Executed the `deploy.ps1` script to auto-copy to the MT5 directory and recompiled the EA to confirm 0 errors and 0 warnings.

## Current State & Next Steps
*   **State:** The codebase is now a clean, Auto-Run-focused template. The project compiles successfully.
*   **Next Steps:** Refine the precise automated logic for the breakout strategy, refine the OCO logic tailored strictly to time-based entry, and build upon this stable foundation.

---

## 2026-05-07_Layout_Workflow_Fixes.md

# Session: 2026-05-07 — Layout and Workflow Fixes

## Objective
Adjust the input sizes for the Auto Cancel module to accommodate larger numeric values and fix layout issues on specific MT5 tabs. Rename repository folder path dependencies to ensure GitHub syncing, Graphify, and other automation workflows operate flawlessly under `mt5-kat-ORB`.

## Changes
- Realigned "KAT Opening Range Breakout" title by adding 12px margin.
- Hidden `Global setting` component in `2m CONF` and `5m CONF` tabs.
- Removed bottom separator below PRESETS in `2m CONF` and `5m CONF` tabs.
- Increased input field widths from 35px to 50px for `Unfavor move`, `Touch middle range`, `After unfilled candles`, `After minutes`, and all `Unfavor EMA` settings to support 4-digit inputs.
- Cleaned up `skill-mt5-workflow/SKILL.md` to reference the renamed `mt5-kat-ORB` path and `mt5-kat-ORB.mq5` file.
- Version bumped: 0.06 → 0.07

## Files Modified
- `Dashboard.mqh`
- `Defines.mqh`
- `skill-mt5-workflow/SKILL.md`

## Compile Result
0 errors, 0 warnings

---

## 2026-05-07_ORB_Break_Retest_Refactor.md

# Session Summary: KAT-ORB Breakout & Retest Refactoring (v0.10 -> v0.11)

In this session, I completed the major structural shift in the ORB logic. The EA no longer operates based on a specific "target time." Instead, it operates through a state-machine that continuously analyzes the NY Open candle to execute a precise Break & Retest.

## 1. Core Logic Refactoring (`OrderManager.mqh`)
-   **State Machine Setup:** Implemented `ENUM_ORB_STATE` encompassing `WAIT_NYO`, `WAIT_CANDLE`, `WAIT_BREAK`, `WAIT_RETEST`, `WAIT_ENTRY`, and `DONE`.
-   **Range Tracking:** Added logic to extract the High/Low of the very first NYO candle (`GetCandleRange`) dynamically based on the 2m/5m timeframe.
-   **Breakout & Retest:** 
    -   `Breakout` is confirmed by evaluating candle closes against the established range boundaries.
    -   `Retest` expects an opposite-colored candle (counter-trend) whose extreme (tail/wick) touches the broken range High or Low.
-   **Order Placement:** When the retest condition is met, pending stops (Buy Stop/Sell Stop) are deployed just above/below the retest candle. The `entryBufferPoints` input parameter is correctly utilized to calculate the buffer and spread spacing.
-   **Auto-Cancel Adjustments:** Removed obsolete variables related to OCO timing blocks. `CheckAutoCancel` was rewired to manage the pending stop entry seamlessly.

## 2. Visual Chart Rendering
-   **Range Drawing (`DrawORBLines`):** Renders the 2m and 5m NY Open candle range using trendlines (Orange for Low, DodgerBlue/LimeGreen for 2m/5m High), accompanied by anchored text labels showing "2m H:", "5m L:", etc., extending 1 hour forward.
-   **Trade Lines (`DrawTradeLines`):** Visualizes the impending Buy Stop / Sell Stop lines alongside potential Targets (TP) using dashed/dotted trendlines, maintaining the dashboard's high visual standards.

## 3. Architecture Adjustments (`mt5-kat-ORB.mq5`)
-   **Removed Target Time Checks:** Fully replaced the previous `IsTimeToTrade()` condition and `ProcessMissingOrders` functions inside `OnTick()`.
-   **Streamlined Execution Loop:** Rewired the main `OnTick()` loop to continually invoke `ProcessORB` and `CheckAutoCancel` for both the 2m and 5m engines as long as the NY Open trigger time is active.
-   **Cleaned Artifacts:** Unused methods, including the legacy risk manager initialization method and `OnTradeTransaction` interceptor callbacks, were cleanly excised to ensure `0 errors, 0 warnings` during compilation.

## Current Project State & Next Steps
-   **Standards Assured:** Caveman mode applied. The codebase compiles successfully with 0 errors/warnings.
-   **Synchronization:** `graphify update` and `git push` executed perfectly.
-   **Next Goals:** Currently, `ContAfter1st` parameter logic (to continue evaluating trades until Max Success/Loss is reached) has not been completely expanded in `ORB_DONE` reversion. Next phase will require refining the loop restart sequence, engulfing evaluation improvements, and finalizing the Status Stats Tab visual populators.

---

## 2026-05-07_ORB_Stats_Continue.md

# Auto-Diary Entry: 07 May 2026 - Stats & Continue Logic Implementation

## Task Summary
Implemented advanced statistical polling and the core logical flow for the "Continue after 1st Fired" mechanism.

## Completed Work
1.  **Trade History Statistics:**
    -   Implemented `UpdateTradeStats()` inside `mt5-kat-ORB.mq5`, mapped to the 1-second `OnTimer()`.
    -   Added queries to MQL5 `HistoryDealsTotal()` to extract current day, week, and month profit, accurately fetching `wins`, `losses`, `netToday`, `netWeek`, and `netMonth`.
    -   Wired up the values directly into the `CDashboard::UpdateStatsTab()` API so that the "💸" tab actively updates when the user minimizes or visits it.
2.  **Tracking Strategy Justification:**
    -   Created `m_entryReason` and `m_cancelReason` tracking within `COrderManager`.
    -   Pushed strings matching the timeframe engines up into the Dashboard variables natively.
3.  **ContAfter1st Logic Validation:**
    -   Adjusted `COrderManager::CheckAutoCancel()` to actively check if the pending stop order has shifted out of the order pool.
    -   If an order drops from the list (triggered), the system evaluates `p.contAfter1st` AND `limitHit` (`maxSuccess` or `maxLoss` derived from `g_winsToday`/`g_lossesToday`).
    -   If allowable, the state shifts safely back to `ORB_WAIT_BREAK`.
    -   Placed an open positions lock in `ProcessORB()`: `if (hasPos) return;` prevents multiple overlapping concurrent trades from spamming when `ContAfter1st` causes sequential re-entries.
4.  **Deployment:**
    -   Successful zero-error compile and copy across into MT5 AppData using `deploy.ps1`.

## Next Steps
The logic is fully wired, verified, and complete. Future updates will focus on incorporating the `Big momentum only` trigger as the backend logic matures to support it.

---

## 2026-05-07_Optimize_Tab_Order.md

# Session: 2026-05-07 — Optimize Tab Order & Panel Height

## Objective
1. Make the `💸` (STATS) tab the default and move it to the first position.
2. Shorten the Dashboard height so it fits compactly below the PRESETS section.

## Changes
- `Defines.mqh`:
  - Reduced `PANEL_HEIGHT` from 1550 to 1000. Because the STATUS section overlaps with the INPUTS section, the maximum height required is exactly the bottom of the PRESETS section (~950 pixels).
- `Dashboard.mqh`:
  - Switched initialization in constructor: `m_activeTab = TAB_STATS;` so it opens by default.
  - Rearranged the rendering order of Tab buttons in `CreatePanel` so that `💸` is at the far left (index 0), followed by `Global`, `2m CONF`, and `5m CONF`.

## Result
Code compiled successfully (0 errors, 0 warnings). The MT5 panel is now significantly more compact, saving valuable screen real estate on the chart, and defaults to the monitoring view (STATS) as requested.

---

## 2026-05-07_Trailing_Trigger_Layout.md

# Session: 2026-05-07 — Trailing Trigger Layout Fix

## Objective
Increase the width of the `Trailing Trigger` input field (and surrounding `Distance` and `Step` fields) to comfortably accommodate larger numbers (like 1500+). 

## Changes
- Adjusted label widths and positions for Trailing logic row in `Dashboard.mqh`.
- Expanded `Trigger`, `Distance`, and `Step` inputs to a width of `50px`.
- Version bumped: 0.07 → 0.08.

## Files Modified
- `Dashboard.mqh`
- `Defines.mqh`

## Compile Result
Pending.

---

## 2026-05-07_Trailing_Trigger_Layout_Fix.md

# Session: 2026-05-07 — Trailing Trigger Layout & Countdown Formatting Fix

## Objective
Fix text overlap issues on the `Trailing mode` inputs (Trigger, Distance, Step) and restructure the `CLOCK` section to match the NY Time & Countdown visual reference.

## Changes
- Adjusted `Trailing mode` layout: 
  - Trigger label width: 55px
  - Distance label width: 65px
  - Step label width: 35px
  - All input fields widened to 50px without overlaps.
- Restructured `CLOCK` section:
  - Hidden the `Next session` label and value.
  - Formatted `Countdown` to align directly beneath `NY Time` with `FONT_SIZE_MED`.
  - Set `Countdown` value color to `CLR_WARNING` (orange).
- Version bumped: 0.08 → 0.09.

## Files Modified
- `Dashboard.mqh`
- `Defines.mqh`

## Compile Result
0 errors, 0 warnings

---

## 2026-05-07_session2.md

# Session Update (2026-05-07) 

## Summary 
- Completed logic implementation for Auto Cancel module (Unfavor Move, Touch Mid, Unfilled Candles). 
- Fixed UI buttons layout and color formatting. 
- Restored Countdown to NY Open timer dynamically fetched from TimeManager. 
- Re-compiled and validated the EA with zero errors.
- Added 'After minutes' condition for Auto Cancel based on NY Open time.
- Resized the Auto Cancel buttons to 1/3 of previous size to fix UI text overlap.


---

## 2026-05-08_Audit_Jules_Version_Bump.md

# 2026-05-08: Audit Merge and Version Bump

## Changes Made
- Updated `EA_VERSION` to `1.10` and verified `EA_BUILD_DATE` in `Defines.mqh` following Jules' audit and PR merge.
- Fixed the source directory path `$src` in `deploy.ps1` to match the correct project repository name (`mt5-kat-OpenRangeBreakout`).
- Executed `graphify update .` to rebuild the knowledge graph based on recent file updates.
- Deployed and compiled the code successfully with 0 errors via `deploy.ps1`.
- Committed and pushed the changes to the GitHub repository.

## State Check
- `mt5-kat-ORB.mq5` compiled successfully.
- Codebase graph updated.

---

## 2026-05-08_Dashboard_FavorEMA_Refinement.md

# Session Diary: Dashboard UI Refinements & Favor EMA Logic
**Date:** 08 May 2026
**Version:** 1.08

## 🎯 Objective
Refine the KAT ORB Dashboard UI by aligning toggle buttons, modernizing color indicators, and successfully integrating the new "Favor EMA" condition directly into the `OrderManager` as a strict pre-entry filter.

## 🛠️ Key Implementation Details

### 1. UI & Aesthetics Redesign
* **Compact Inline EMA Rows:** 
  The "Favor EMA" (ENTRY section) and "Unfavor EMA" (AUTO CANCEL section) were redesigned to exist on single rows respectively. This drastically reduced vertical bloat and optimized dashboard real estate.
* **Right-Alignment & Separators:**
  * To ensure visual consistency, the EMA rows were specifically calculated to right-align with the standalone ON/OFF buttons above them. 
  * They now utilize custom separator labels `+` (`m_lblFemPlus1`, `m_lblEmaPlus1`, etc.) dividing the `[input][tick]` combinations for enhanced readability.
* **Smart Toggle Indicators:**
  * Enabled (ON) state displays a Unicode checkmark `✓` (`0x2713`).
  * Disabled (OFF) state displays a clean, empty string `""` instead of `x`, avoiding visual clutter.
* **Standardized Color Scheme:**
  * All active ENTRY buttons (e.g., `Max dist from range`, `Continue after 1st fired`) and `Favor EMA` ticks now strictly use `CLR_SUCCESS` (Green) when ON.
  * Auto Cancel section buttons (`Unfavor EMA`, etc.) retain `CLR_WARNING` (Yellow) when ON.
  * Inactive elements revert to `CLR_BTN_OFF`.

### 2. Logic: "Favor EMA" Pre-Entry Condition
* Integrated heavily requested "Favor EMA" (9, 21, 34 default inputs) logic directly into `OrderManager.mqh`. 
* **Execution Constraint:** This is explicitly processed as a **pre-entry** check. 
  * If a Buy Stop is initiated, the current `Bid` price MUST be *above* the active Favor EMAs.
  * If a Sell Stop is initiated, the current `Ask` price MUST be *below* the active Favor EMAs.
* Orders violating this rule are dynamically skipped before calling `OrderSend()`.

### 3. Workflow Improvement
* **AGENTS.md Updated:** Added a **"🔖 Mandatory Workflow: Auto Version Bump"** clause instructing AI agents to automatically bump the version number in `Defines.mqh` and append the correct build date immediately following any logic or feature modifications.

## 🐛 Resolved Issues
* Adjusted height of UI elements (`CTRL_HEIGHT+2` vs `CTRL_HEIGHT`) to perfectly align tick buttons alongside text inputs horizontally.
* Assured all dashboard variables appropriately loaded (`LoadTab`), saved (`SaveTab`), and displayed (`Upd`) correctly mapped to the updated GUI configurations. 
* Ensured `Minimize()` and standard `CtrlHide/CtrlShow` handle the newly added `+` separators so layout bugs do not occur during EA panel minimization.

## 🔜 Next Steps
* Continuously observe "Favor EMA" filtering across actual momentum candles to gauge whether it restricts entries excessively in ranging zones.

---

## 2026-05-08_Legacy_Cleanup_Logic_Audit.md

# Session: Legacy Cleanup + Logic Audit — 2026-05-08

## Changes Made

### 1. Legacy OCO Sniper Purge (v0.12 → v0.13)
- Renamed `EA_COMMENT_PREFIX` from `"OCO_SNIPER_"` → `"KAT_ORB_"`
- Renamed `m_lastOcoTag` → `m_lastOrderTag`, `GenerateOcoTag` → `GenerateOrderTag`
- Removed dead `triggerBeforeSec` field + `InpTriggerBefore` input
- Removed dead TimeManager trigger system (`IsTimeToTrade`, `GetSecondsToTrigger`, `m_triggerTimeServer`)
- Removed dead Origami fields (`targetGrowthPercent`, `customTiming`, `targetDayOffset`)
- Renamed `CalculateTriggerTime` → `CalculateTargetTime`
- Fixed all 6 file headers from "Opening Sniper EA" → "KAT Opening Range Breakout EA"
- Fixed description from "Scaling into winners" → "Break & Retest range strategy"

### 2. Logic Audit + Fixes (v0.13 → v0.14)
- **CRITICAL FIX:** OnTick now forces correct timeframe (M2/M5) for CheckAutoCancel + TrailManager under Global Override
- **FIX:** Added ORDER_MODE filter in ProcessORB retest — MODE_BUY_ONLY/MODE_SELL_ONLY now respected
- **FIX:** Added ORB_STOPPED state for afterMinutes timeout — no continuation allowed
- **FIX:** Explicit state transitions after cancel (ORB_DONE or ORB_STOPPED instead of relying on side effects)

### 3. Stats Tab Redesign (v0.11 → v0.12)
- New sections: ORDERS (2m/5m status), LAST ENTRY, TOTAL P/L, 2m P/L, 5m P/L
- Color-coded status: Break Out (green), Break Down (red), Wait Entry (yellow), Stop Trading (red)
- Per-timeframe PL tracking via DEAL_COMMENT filtering
- Single-stat-per-line layout to prevent text overlap

### 4. Documentation Update
- Rewrote README.md with accurate strategy/architecture description
- Rewrote docs/Architecture.md with full state machine, data flow, and logic reference
- Updated graphify knowledge graph

## Known Items
- `bigMomentum` toggle exists in UI but has no logic implementation
- TrailManager applies to all positions regardless of 2m/5m origin

## Files Modified
- `Defines.mqh`, `OrderManager.mqh`, `TimeManager.mqh`, `mt5-kat-ORB.mq5`
- `Dashboard.mqh`, `RiskManager.mqh`, `TrailManager.mqh`, `NewsManager.mqh`
- `README.md`, `docs/Architecture.md`

---

## 2026-05-09_Countdown_Refinement.md

# 2026-05-09 - Countdown Logic Refinement

## Objective
The user requested refinements to the NYO countdown text on the dashboard:
1. It should display "HAPPY WEEKEND!" during Saturday and Sunday (NY Time).
2. During the Trading Window (calculated from NYO start time + the `afterMinutes` setting from the dashboard), it should display "TRADING WINDOW" instead of counting down into negative numbers or jumping straight to the next day.
3. Once the Trading Window ends on a regular weekday, it should start counting down to the *next* day's NY Open.
4. If the Trading Window ends on a Friday, it should immediately switch to "HAPPY WEEKEND!" since the market won't open until Monday.

## Changes Made
- **TimeManager.mqh**:
  - Updated the signature of `GetCountdownString()` to `GetCountdownString(const DashboardParams &params)` so it can access the user's `afterMinutes` and `afterMinutesOn` settings.
  - Added weekend detection at the very beginning of the function: if the current NY Time falls on Saturday (`day_of_week == 6`) or Sunday (`day_of_week == 0`), it returns `"HAPPY WEEKEND!"`.
  - Inside the post-NYO logic branch (`secs < 0`):
    - Calculated `elapsedSecs = -secs` and compared it against `windowSecs` (derived from `params.afterMinutes`). If the trading window feature is OFF, it defaults to a full trading day (390 mins = 6.5 hours to NY close).
    - If `elapsedSecs <= windowSecs`, returns `"TRADING WINDOW"`.
    - If the trading window has elapsed and the current day is Friday (`day_of_week == 5`), returns `"HAPPY WEEKEND!"`.
    - Otherwise, proceeds to calculate the countdown to the next valid business day's NY Open.
- **mt5-kat-ORB.mq5**:
  - Updated the `OnTimer()` event handler to pass `cfg.main` into `GetCountdownString(p)` so the `TimeManager` has the correct dashboard configuration context.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.16`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified logic correctly covers all the edge cases requested by the user.

---

## 2026-05-09_Dashboard_Height_Fix.md

# 2026-05-09 - Reverted Dashboard Padding and Fixed Panel Height

## Objective
The previous edit accidentally shrunk the `PANEL_HEIGHT` to `830`, causing the UI to truncate mid-way through the ENTRY section. The user requested to revert the internal `cy += 50` spacing and correctly expand the Dashboard background height to show all elements properly.

## Changes Made
- **Dashboard.mqh**:
  - Removed the `cy += 50;` spacing below the preset buttons.
- **Defines.mqh**:
  - Restored and slightly increased `PANEL_HEIGHT` from the erroneous `830` to `1270` (the original functional height was `1245`). This gives enough space to render all controls fully and leaves a natural gap at the bottom of the scrollable panel.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.15`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified that `PANEL_HEIGHT` now correctly encompasses the entire dashboard layout natively.

---

## 2026-05-09_Fix_Lot_UI.md

# 2026-05-09 - Added Fix Lot Mode and UI Toggle

## Objective
The user requested the addition of a `Fix lot [input] ON/OFF` feature alongside the existing `Risk %` setting on the EA dashboard. 

## Changes Made
- **Defines.mqh**:
  - Added `bool riskModeOn` and `double fixLot` to `DashboardParams` structure.
  - Bumped `EA_VERSION` to "1.11" and `EA_BUILD_DATE` to "09 May 2026".
- **Dashboard.mqh**:
  - Restructured the Risk section UI layout to include `Risk %` button toggle + input field and `Fix lot` button toggle + input field on the same line.
  - Added `m_btnRiskMode` and `m_btnFixLot` toggle controls and `m_edtFixLot` input.
  - Implemented `OnRiskModeToggle()` and `OnLotModeToggle()` with mutually exclusive states.
  - Updated `CtrlHide` and `CtrlShow` routines to manage the visibility of the new UI controls.
  - Updated `SetParams()` and `GetParams()` to load/save the new variables appropriately.
- **RiskManager.mqh**:
  - Modified `CalcRiskRewardInfo` signature to accept `riskModeOn` and `fixLot`.
  - Added internal conditional logic: If `riskModeOn` is true, use `CalcLotSize()` using Risk %, else use `NormalizeLot()` with the fixed lot value. 
  - Adjusted `$Risk` value estimation to accurately calculate real exposed dollar value derived from the ultimate lot size calculation instead of the theoretical balance percentage.
- **OrderManager.mqh & mt5-kat-ORB.mq5**:
  - Handled conditional usage of Risk % vs Fixed Lot execution inside the `CalcLotSize` instantiation logic inside `BuyStop` and `SellStop` routines.
  - Synced `CalcRiskRewardInfo` call inside `OnTick()` to match the updated method signature.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed local deploy script (`deploy.ps1`). 
- Validated mutual exclusivity between Risk Mode and Fixed Lot states logically and visually in code structure.

---

## 2026-05-09_GMT_Target_Fix_Input_Defaults.md

# 2026-05-09 - GMT Target Fix and Input Defaults

## Objective
The previous countdown logic failed on Fridays due to an intricate date-wrap issue: the original target time calculated from `TimeGMT()` incorrectly wrapped into Saturday because the broker's GMT time was technically already Saturday morning, resulting in a positive offset (`secs > 0`) that skipped the Friday post-trading-window condition entirely. The user also requested to change the default values of `Fix Lot` and `Risk Percent` inputs to `2.0`.

## Changes Made
- **TimeManager.mqh**:
  - Rewrote the countdown logic in `GetCountdownString()` to strictly compute current time versus target time **entirely within the NY timezone representation**, avoiding edge-case `TimeGMT()` rollovers across day boundaries.
  - Using `StructToTime` on identical dates natively exposes true differences in seconds without relying on broker offsets drifting into future dates.
  - This strictly enforces that on a Friday (`day_of_week == 5`), if the elapsed seconds exceed the `windowSecs` (Trading Window length), it accurately trips the `HAPPY WEEKEND!` condition.
- **mt5-kat-ORB.mq5**:
  - Altered the native MetaTrader input properties:
    - Changed `InpRiskPercent`, `Inp2MRiskPercent`, and `Inp5MRiskPercent` defaults from `1.0` to `2.0`.
    - Changed `InpFixLot`, `Inp2MFixLot`, and `Inp5MFixLot` defaults from `0.1` to `2.0`.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.17`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified logic via code review confirming the GMT bypass.

---

## 2026-05-09_Inputs_Rework_Dashboard_Padding.md

# 2026-05-09 - EA Inputs Refactoring and Dashboard Padding

## Objective
The user requested two final polishes to the EA setup:
1. Increase vertical space at the bottom of the Dashboard UI "Settings" tab (under the "Set mA, mB, mC" preset section) for visual breathing room.
2. Refactor the MetaTrader 5 Expert Properties (Input Panel) before the Dashboard launches:
   - Break down the single `ORDER` and `RISK` sections into separated `GLOBAL SETTING`, `2M SETTING`, and `5M SETTING` groups.
   - Introduce missing parameters to these input groups, such as the `Fix lot` amount, the toggle for Risk Management (`Risk Mode ON` / `Fix Lot ON`), and the `Retest candle` custom configurations.

## Changes Made
- **Dashboard.mqh**:
  - Inserted `cy += 50;` immediately after the preset buttons (Set A/B/C) to pad the bottom of the scrollable client area, making the panel feel more spacious.
- **Defines.mqh**:
  - Increased `PANEL_HEIGHT` from `780` to `830` to physically expand the main container background, ensuring the extra scrollable space maps visually onto a longer panel.
- **mt5-kat-ORB.mq5**:
  - Removed the simple `ORDER` and `RISK` input groups.
  - Added new cleanly formatted input groups: `------------- GLOBAL SETTING -------------`, `------------- 2M SETTING -------------`, and `------------- 5M SETTING -------------`.
  - Added `InpGlobalOverride`, `InpFixLot`, `InpRiskModeOn`, `InpCustomRetestOn`, and `InpCustomRetestMin` with friendly UI names for all three config contexts.
  - Rewrote the initial configuration mapping logic inside `OnInit()`, binding the new inputs safely to `cfg.main`, `cfg.m2`, and `cfg.m5` structs before handing them off to the Dashboard.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.14`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified that EA Inputs properties window structurally supports independent Timeframe variables natively via `OnInit`.

---

## 2026-05-09_Pure_NY_Time_Countdown.md

# 2026-05-09 - Hard Fix for Friday Rollover Countdown Bug

## Objective
The previous implementation of `GetCountdownString` still implicitly relied on `m_targetTimeServer`, which was being calculated based on `TimeGMT()`. Because `TimeGMT()` was rolling over into Saturday early (relative to NY time), `m_targetTimeServer` was jumping to Saturday, making the system think NYO was in the future and skipping the "Friday after trading window" check.

## Changes Made
- **TimeManager.mqh**:
  - Removed all dependencies on `m_targetTimeServer` inside `GetCountdownString()`.
  - The logic now strictly computes `nyTargetTime` and `nyTime` dynamically on the fly, directly constructing the target day based on the currently perceived `nyDt`.
  - Because `StructToTime()` translates a struct directly into seconds from an epoch, subtracting `nyTime` from `nyTargetTime` yields the precise, absolute second difference regardless of what day `TimeGMT()` thinks it is.
  - This guarantees that when `nyTime` is Friday 10:31 AM, it will be accurately assessed as being past the Friday NYO, past the trading window, and cleanly trigger the `HAPPY WEEKEND!` state.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.18`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified that Friday after-hours will no longer attempt to count down to a phantom Saturday target.

---

## 2026-05-09_Retest_Candle_TF.md

# 2026-05-09 - Added Custom Retest Candle Timeframe Feature

## Objective
The user requested an addition to the ENTRY section of the dashboard: "Retest candle (min) [input] ON/OFF", defaulting to 1 minute and OFF. The feature allows overriding the timeframe used to detect the retest candle from the strategy's native timeframe (e.g., 2m or 5m) to a custom timeframe, such as 1m.

## Changes Made
- **Defines.mqh**:
  - Added `customRetestOn` (bool) and `customRetestMin` (int) to the `DashboardParams` structure.
  - Set default values to `false` and `1` respectively.
  - Bumped `EA_VERSION` to 1.12.
- **Dashboard.mqh**:
  - Inserted UI elements: `m_lblRtcTag` (label), `m_btnRtc` (ON/OFF button toggle), and `m_edtRtc` (input field) into the ENTRY section.
  - Implemented logic variables and UI updating routines (`m_rtcOn`, `OnRtcToggle()`, `UpdRtc()`).
  - Added proper control visibility management to `CtrlShow()` and `CtrlHide()`.
  - Hooked up parameters saving and loading logic with `DashboardParams`.
- **OrderManager.mqh**:
  - Updated the `ORB_WAIT_RETEST` state execution block.
  - Introduced conditional logic to map `params.customRetestMin` to an explicit `ENUM_TIMEFRAMES` representation (e.g., `PERIOD_M1`).
  - Fetched market data (`iTime`, `iClose`, `iOpen`, `iHigh`, `iLow`) using `retestTf` instead of the base strategy `tf`.
  - Updated the entry reason label appended to MetaTrader orders (`m_entryReason`) to reflect if a custom retest timeframe was used.

## Verification
- Code successfully compiled (0 errors, 0 warnings) after the logic replacement.
- Successfully ran `deploy.ps1` script to export binaries to MetaTrader folder.
- Verified visual alignment on Dashboard coordinates mapping exactly beneath other ENTRY elements without conflict.

---

## 2026-05-09_Retest_Candle_UI_Fix.md

# 2026-05-09 - Fixed Retest Candle UI Layout Alignment

## Objective
The user requested UI alignment adjustments for the `Retest candle (min)` setting in the ENTRY section to exactly match the design pattern and size of the `Max succesful order` and `Max loss order` controls. The default configuration of the feature was also updated to `ON`.

## Changes Made
- **Dashboard.mqh**:
  - Remapped coordinates: Input field is now at `cx+155` and the ON/OFF toggle is aligned to the right-most edge (`smallBtnX`) using `smallBtnW`.
  - Reordered element rendering from `[Label] [Toggle] [Input]` to `[Label] [Input] [Toggle]` to match sibling elements.
  - Changed the "ON" color profile from `CLR_BTN_ON` (Blue) to `CLR_SUCCESS` (Green) to match the other ON toggles in that section.
- **Defines.mqh**:
  - Updated `customRetestOn` initialization in `DashboardParams` to default to `true` globally.
- **Version bump**:
  - Bumped `EA_VERSION` to `1.13`.

## Verification
- Code successfully compiled (0 errors, 0 warnings).
- Executed `deploy.ps1`.
- Verified UI consistency against sibling components visually.

---
