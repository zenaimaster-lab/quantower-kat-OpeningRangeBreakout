using System;
using System.Collections.Generic;
using System.Linq;
using TradingPlatform.BusinessLayer;

namespace KatORB
{
    //+------------------------------------------------------------------+
    //| ORBRunner — bundles state machine for one timeframe             |
    //+------------------------------------------------------------------+
    public enum ORBState
    {
        ORB_WAIT_NYO = 0,
        ORB_WAIT_CANDLE = 1,
        ORB_WAIT_BREAK = 2,
        ORB_WAIT_RETEST = 3,
        ORB_WAIT_ENTRY = 4,
        ORB_STOPPED = 5,
        ORB_DONE = 6
    }

    public class ORBRunner
    {
        private readonly KatOpeningRangeBreakout strategy;
        public Period Period { get; }
        public int TfIndex { get; }
        public string Comment { get; }
        public HistoricalData History { get; }

        public ORBState State { get; set; } = ORBState.ORB_WAIT_NYO;
        public double RangeHigh { get; set; } = 0;
        public double RangeLow { get; set; } = 0;
        public DateTime CandleTime { get; set; } = DateTime.MinValue;
        public int BreakDir { get; set; } = 0; // 1 = UP, -1 = DOWN

        public string LastOrderTag { get; set; } = "";
        public bool OrdersActive { get; set; } = false;
        public DateTime PlacedTime { get; set; } = DateTime.MinValue;
        public string EntryReason { get; set; } = "";
        public string CancelReason { get; set; } = "";
        public int EntryBreakDir { get; set; } = 0;
        public bool TrailTriggerHit { get; set; } = false;
        public bool HasBeenFilled { get; set; } = false;

        private string pendingStatsTag = "";
        private DateTime statsCheckStartTime = DateTime.MinValue;
        private DateTime lastNYOTime = DateTime.MinValue;
        private DateTime lastHistoryWarningTime = DateTime.MinValue;

        // Caching structures for performance optimizations
        private class EmaCache
        {
            public int LastIndex = -1;
            public double LastValue = 0;
        }

        private class VwapCache
        {
            public DateTime StartDay = DateTime.MinValue;
            public int LastIndex = -1;
            public double SumPV = 0;
            public double SumV = 0;
        }

        private readonly Dictionary<string, EmaCache> emaCaches = new Dictionary<string, EmaCache>();
        private readonly Dictionary<string, VwapCache> vwapCaches = new Dictionary<string, VwapCache>();

        public ORBRunner(KatOpeningRangeBreakout strategy, Period period, int tfIndex, string comment, HistoricalData history)
        {
            this.strategy = strategy;
            this.Period = period;
            this.TfIndex = tfIndex;
            this.Comment = comment;
            this.History = history;
        }

        public void ResetState()
        {
            this.State = ORBState.ORB_WAIT_NYO;
            this.RangeHigh = 0;
            this.RangeLow = 0;
            this.CandleTime = DateTime.MinValue;
            this.BreakDir = 0;
            this.LastOrderTag = "";
            this.OrdersActive = false;
            this.PlacedTime = DateTime.MinValue;
            this.EntryReason = "";
            this.CancelReason = "";
            this.EntryBreakDir = 0;
            this.TrailTriggerHit = false;
            this.HasBeenFilled = false;
            this.pendingStatsTag = "";
            this.statsCheckStartTime = DateTime.MinValue;
            this.lastHistoryWarningTime = DateTime.MinValue;
            this.emaCaches.Clear();
            this.vwapCaches.Clear();
        }

        public void Process(DateTime nyoTime, DateTime serverTime)
        {
            if (nyoTime == DateTime.MinValue || serverTime == DateTime.MinValue) return;

            // Poll for closed position stats if we have a pending stats check tag
            if (!string.IsNullOrEmpty(this.pendingStatsTag))
            {
                var closedPositions = Core.Instance.ClosedPositions.Where(p => p.Comment == this.pendingStatsTag).ToList();
                if (closedPositions.Count > 0)
                {
                    double totalP = closedPositions.Sum(x => x.GrossPnL != null ? x.GrossPnL.Value : 0.0);
                    if (totalP > 0)
                        strategy.IncrementWins(TfIndex);
                    else if (totalP < 0)
                        strategy.IncrementLosses(TfIndex);

                    strategy.Log($"[{Comment}] Stats updated for tag {this.pendingStatsTag}: PnL={totalP}. Daily Wins={strategy.GetWinsToday(TfIndex)}, Losses={strategy.GetLossesToday(TfIndex)}");
                    this.pendingStatsTag = "";
                }
                else if (serverTime - this.statsCheckStartTime > TimeSpan.FromSeconds(30))
                {
                    // Timeout fallback - stop checking after 30 seconds
                    strategy.Log($"[{Comment}] Stats check timeout for tag {this.pendingStatsTag}. Closed position not found in cache.");
                    this.pendingStatsTag = "";
                }
            }

            // Reset state on a new trading day's NY Open
            if (nyoTime != this.lastNYOTime)
            {
                ResetState();
                this.lastNYOTime = nyoTime;
            }

            if (serverTime < nyoTime) return;

            // Maintain order active synchronization using actual position/order checks
            SyncOrderAndPositionStatus(serverTime);

            // Update trail trigger hit state if position is active
            if (this.OrdersActive && !this.TrailTriggerHit)
            {
                var activePositions = Core.Instance.Positions.Where(p => p.Symbol == strategy.CurrentSymbol && p.Comment == this.LastOrderTag).ToList();
                if (activePositions.Count > 0)
                {
                    var pos = activePositions[0];
                    double open = pos.OpenPrice;
                    double tickSize = strategy.CurrentSymbol.TickSize;
                    double triggerDist = strategy.InpTrailTrigger * tickSize;
                    if (pos.Side == Side.Buy)
                    {
                        double bid = strategy.CurrentSymbol.Bid;
                        if (bid - open >= triggerDist)
                        {
                            this.TrailTriggerHit = true;
                            strategy.Log($"[{Comment}] Trail trigger hit: Buy Price reached/exceeded trigger distance.");
                        }
                    }
                    else if (pos.Side == Side.Sell)
                    {
                        double ask = strategy.CurrentSymbol.Ask;
                        if (open - ask >= triggerDist)
                        {
                            this.TrailTriggerHit = true;
                            strategy.Log($"[{Comment}] Trail trigger hit: Sell Price reached/exceeded trigger distance.");
                        }
                    }
                }
            }

            // Check safeguards and trade window limits
            if (!this.OrdersActive)
            {
                bool limitHit = (strategy.GetWinsToday(TfIndex) >= strategy.InpMaxSuccess)
                             || (strategy.GetLossesToday(TfIndex) >= strategy.InpMaxLoss);
                if (limitHit && this.State != ORBState.ORB_DONE && this.State != ORBState.ORB_STOPPED)
                {
                    this.State = ORBState.ORB_DONE;
                    strategy.Log($"[{Comment}] Win/Loss limit hit today. Forcing state to DONE.");
                }
            }

            // Exceeded daily trading session window check
            int tfSeconds = (int)this.Period.Duration.TotalSeconds;
            if (!this.OrdersActive && serverTime >= nyoTime.AddMinutes(strategy.InpAfterMinutes))
            {
                if (this.State != ORBState.ORB_STOPPED && this.State != ORBState.ORB_DONE)
                {
                    if (this.State == ORBState.ORB_WAIT_NYO) this.State = ORBState.ORB_WAIT_CANDLE;
                    if (this.State == ORBState.ORB_WAIT_CANDLE) HandleWaitCandle(nyoTime, serverTime);

                    if (this.State == ORBState.ORB_WAIT_BREAK || this.State == ORBState.ORB_WAIT_RETEST || this.State == ORBState.ORB_WAIT_ENTRY)
                    {
                        this.State = ORBState.ORB_STOPPED;
                        strategy.Log($"[{Comment}] Session trading window closed. Set to STOPPED.");
                    }
                }
                return;
            }

            // State Machine Progression
            if (this.State == ORBState.ORB_WAIT_NYO)
            {
                this.State = ORBState.ORB_WAIT_CANDLE;
            }

            if (this.State == ORBState.ORB_WAIT_CANDLE)
            {
                HandleWaitCandle(nyoTime, serverTime);
            }

            if (this.State == ORBState.ORB_WAIT_BREAK)
            {
                HandleWaitBreak();
            }

            if (this.State == ORBState.ORB_WAIT_RETEST)
            {
                HandleWaitRetest(nyoTime, serverTime);
            }

            if (this.OrdersActive)
            {
                CheckAutoFlatten(nyoTime, serverTime);
            }
        }

        private void HandleWaitCandle(DateTime nyoTime, DateTime serverTime)
        {
            int tfSeconds = (int)this.Period.Duration.TotalSeconds;
            if (serverTime >= nyoTime.AddSeconds(tfSeconds))
            {
                // 1. Ưu tiên tìm trực tiếp nến đã đóng trong lịch sử của runner
                if (this.History != null && this.History.Count > 0)
                {
                    var targetBar = this.History.OfType<HistoryItemBar>().FirstOrDefault(b => 
                        b.TimeLeft.Year == nyoTime.Year &&
                        b.TimeLeft.Month == nyoTime.Month &&
                        b.TimeLeft.Day == nyoTime.Day &&
                        b.TimeLeft.Hour == nyoTime.Hour &&
                        b.TimeLeft.Minute == nyoTime.Minute);
                    if (targetBar != null)
                    {
                        this.RangeHigh = targetBar.High;
                        this.RangeLow = targetBar.Low;
                        this.CandleTime = nyoTime;
                        this.State = ORBState.ORB_WAIT_BREAK;
                        strategy.Log($"[{Comment}] Range Formed (from own TF): High={RangeHigh}, Low={RangeLow}");
                        return;
                    }
                }

                // 2. Fallback sang M1 nếu nến chính chưa kịp cập nhật hoặc bị trễ dữ liệu
                var m1History = strategy.GetM1History();
                if (m1History == null || m1History.Count == 0)
                {
                    if (serverTime - this.lastHistoryWarningTime >= TimeSpan.FromSeconds(10))
                    {
                        strategy.Log($"[{Comment}] Waiting for M1 history to initialize (currently null or empty)");
                        this.lastHistoryWarningTime = serverTime;
                    }
                    return;
                }

                int expectedBars = tfSeconds / 60;
                var rangeBars = m1History
                    .Where(b => b.TimeLeft >= nyoTime && b.TimeLeft < nyoTime.AddSeconds(tfSeconds))
                    .OfType<HistoryItemBar>()
                    .ToList();

                if (rangeBars.Count < expectedBars)
                {
                    if (serverTime - this.lastHistoryWarningTime >= TimeSpan.FromSeconds(10))
                    {
                        strategy.Log($"[{Comment}] Waiting for complete M1 history (Copied {rangeBars.Count}/{expectedBars} bars)");
                        this.lastHistoryWarningTime = serverTime;
                    }
                    return;
                }

                // Calculate range safely with complete history
                double maxH = double.MinValue;
                double minL = double.MaxValue;
                foreach (var bar in rangeBars)
                {
                    if (bar.High > maxH) maxH = bar.High;
                    if (bar.Low < minL) minL = bar.Low;
                }

                this.RangeHigh = maxH;
                this.RangeLow = minL;
                this.CandleTime = nyoTime;
                this.State = ORBState.ORB_WAIT_BREAK;
                strategy.Log($"[{Comment}] Range Formed (Fallback M1): High={RangeHigh}, Low={RangeLow}, Bars={rangeBars.Count}/{expectedBars}");
            }
        }

        private void HandleWaitBreak()
        {
            if (this.History == null || this.History.Count < 2) return;

            // index Count - 1 is current forming bar, Count - 2 is the last closed bar
            if (!(this.History[this.History.Count - 2, SeekOriginHistory.Begin] is HistoryItemBar lastClosedBar)) return;
            if (lastClosedBar.TimeLeft <= this.CandleTime) return;

            double closePrice = lastClosedBar.Close;
            if (closePrice > this.RangeHigh)
            {
                this.BreakDir = 1;
                this.State = ORBState.ORB_WAIT_RETEST;
                strategy.Log($"[{Comment}] Bullish breakout detected. Waiting for retest.");
            }
            else if (closePrice < this.RangeLow)
            {
                this.BreakDir = -1;
                this.State = ORBState.ORB_WAIT_RETEST;
                strategy.Log($"[{Comment}] Bearish breakout detected. Waiting for retest.");
            }
        }

        private void HandleWaitRetest(DateTime nyoTime, DateTime serverTime)
        {
            if (this.OrdersActive) return;

            // Subscription lists check
            var retestHistory = strategy.GetRetestHistory();
            if (retestHistory == null || retestHistory.Count < 2) return;

            // Retrieve last closed bar on retest timeframe
            if (!(retestHistory[retestHistory.Count - 2, SeekOriginHistory.Begin] is HistoryItemBar lastClosedBar)) return;
            if (lastClosedBar.TimeLeft <= this.CandleTime) return;

            double openPrice = lastClosedBar.Open;
            double closePrice = lastClosedBar.Close;
            double highPrice = lastClosedBar.High;
            double lowPrice = lastClosedBar.Low;

            double tickSize = strategy.CurrentSymbol.TickSize;
            int buffer = 1;
            double spread = strategy.CurrentSymbol.Ask - strategy.CurrentSymbol.Bid;

            //--- Break UP (Bullish Retest Validation)
            if (this.BreakDir == 1)
            {
                double midPrice = (this.RangeHigh + this.RangeLow) / 2.0;
                // Opposite color candle (bearish: close < open) touching or penetrating the broken high range
                // and the candle low must not penetrate below the range mid-point
                if (closePrice < openPrice && lowPrice <= this.RangeHigh && lowPrice >= midPrice)
                {
                    double entryPrice = highPrice + (buffer * tickSize) + spread;
                    entryPrice = Math.Round(entryPrice / tickSize) * tickSize;

                    // Safety Guard: Check if Entry Price is inside the Range
                    if (entryPrice <= this.RangeHigh)
                    {
                        strategy.Log($"[{Comment}] Buy Entry skipped. Entry price {entryPrice} is inside range (<= High {this.RangeHigh}).");
                        this.CancelReason = $"Entry price inside range ({entryPrice} <= {this.RangeHigh})";
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    // Obstacle/EMA Filter Validation
                    double dist = (entryPrice - this.RangeHigh) / tickSize;
                    if (dist > strategy.InpMaxDistRange)
                    {
                        strategy.Log($"[{Comment}] Buy Entry skipped. Distance {dist} ticks > max {strategy.InpMaxDistRange}.");
                        this.CancelReason = $"Max dist reached ({dist} > {strategy.InpMaxDistRange})";
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    string obsReason = "";
                    if (CheckObstacles(entryPrice, nyoTime, out obsReason))
                    {
                        strategy.Log($"[{Comment}] Buy Entry skipped due to Obstacle: {obsReason}");
                        this.CancelReason = $"Obstacle: {obsReason}";
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    string filterReason = "";
                    if (!CheckEmaFilters(1, out filterReason))
                    {
                        strategy.Log($"[{Comment}] Buy Entry skipped: {filterReason}");
                        this.CancelReason = filterReason;
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    // Risk Sizing
                    double lot = strategy.InpUseRiskSizing 
                        ? strategy.RiskManager.CalcLotSize(strategy.InpRiskPercent, strategy.InpSlTicks)
                        : strategy.RiskManager.NormalizeLot(strategy.InpFixContract);

                    if (lot > 0)
                    {
                        this.LastOrderTag = $"{Comment}_{strategy.MagicNumber}_{new Random().Next(1000, 9999)}";
                        
                        double currentAsk = strategy.CurrentSymbol.Ask;
                        string orderType = OrderType.Stop;
                        double limitPrice = 0;
                        double triggerPrice = 0;
                        double entryReferencePrice = entryPrice; // Will be entryPrice for Stop/Limit, currentAsk for Market

                        if (entryPrice > currentAsk)
                        {
                            // State 3: Stop Order (Normal breakout waiting)
                            orderType = OrderType.Stop;
                            triggerPrice = entryPrice;
                            entryReferencePrice = entryPrice;
                        }
                        else if (currentAsk - entryPrice <= strategy.InpMaxChaseTicks * tickSize)
                        {
                            // State 1: Market Order (Within Max Chase Ticks - execute immediately to avoid missing wave)
                            orderType = OrderType.Market;
                            entryReferencePrice = currentAsk;
                            strategy.Log($"[{Comment}] Price slightly past entry (Ask={currentAsk} >= Entry={entryPrice}, within {strategy.InpMaxChaseTicks} ticks). Placing BUY MARKET order.");
                        }
                        else
                        {
                            // State 2: Limit Order (Price has run too far - place limit at breakout level and wait for pullback)
                            orderType = OrderType.Limit;
                            limitPrice = entryPrice;
                            entryReferencePrice = entryPrice;
                            strategy.Log($"[{Comment}] Price is too far past entry (Ask={currentAsk} >= Entry={entryPrice}, > {strategy.InpMaxChaseTicks} ticks). Placing BUY LIMIT at original entry to wait for pullback.");
                        }

                        // Risk Sizing based on the correct reference price (either entryPrice or currentAsk)
                        double sl = entryReferencePrice - strategy.InpSlTicks * tickSize;
                        double tp = strategy.InpTpTicks > 0 ? (entryReferencePrice + strategy.InpTpTicks * tickSize) : 0;
                        sl = Math.Round(sl / tickSize) * tickSize;
                        tp = Math.Round(tp / tickSize) * tickSize;

                        var request = new PlaceOrderRequestParameters
                        {
                            Account = strategy.CurrentAccount,
                            Symbol = strategy.CurrentSymbol,
                            Side = Side.Buy,
                            OrderTypeId = orderType,
                            Quantity = lot,
                            Price = limitPrice,
                            TriggerPrice = triggerPrice,
                            StopLoss = SlTpHolder.CreateSL(sl, PriceMeasurement.Absolute),
                            TakeProfit = tp > 0 ? SlTpHolder.CreateTP(tp, PriceMeasurement.Absolute) : null,
                            Comment = this.LastOrderTag,
                            TimeInForce = TimeInForce.GTC
                        };

                        var result = Core.Instance.PlaceOrder(request);
                        if (result.Status == TradingOperationResultStatus.Success)
                        {
                            this.State = ORBState.ORB_WAIT_ENTRY;
                            this.OrdersActive = true;
                            this.PlacedTime = serverTime;
                            this.EntryBreakDir = 1;
                            this.EntryReason = $"Up breakout retest confirmed on custom timeframe (Type={orderType})";
                            strategy.Log($"[{Comment}] BUY PENDING PLACED: Type={orderType}, EntryRef={entryReferencePrice}, SL={sl}, TP={tp}, Lot={lot}");
                        }
                        else
                        {
                            strategy.Log($"[{Comment}] BUY PLACEMENT FAILED: {result.Message}", StrategyLoggingLevel.Error);
                            this.CancelReason = $"Placement failed: {result.Message}";
                            this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        }
                    }
                }
            }
            //--- Break DOWN (Bearish Retest Validation)
            else if (this.BreakDir == -1)
            {
                double midPrice = (this.RangeHigh + this.RangeLow) / 2.0;
                // Opposite color candle (bullish: close > open) touching or penetrating the broken low range
                // and the candle high must not penetrate above the range mid-point
                if (closePrice > openPrice && highPrice >= this.RangeLow && highPrice <= midPrice)
                {
                    double entryPrice = lowPrice - (buffer * tickSize);
                    entryPrice = Math.Round(entryPrice / tickSize) * tickSize;

                    // Safety Guard: Check if Entry Price is inside the Range
                    if (entryPrice >= this.RangeLow)
                    {
                        strategy.Log($"[{Comment}] Sell Entry skipped. Entry price {entryPrice} is inside range (>= Low {this.RangeLow}).");
                        this.CancelReason = $"Entry price inside range ({entryPrice} >= {this.RangeLow})";
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    // Obstacle/EMA Filter Validation
                    double dist = (this.RangeLow - entryPrice) / tickSize;
                    if (dist > strategy.InpMaxDistRange)
                    {
                        strategy.Log($"[{Comment}] Sell Entry skipped. Distance {dist} ticks > max {strategy.InpMaxDistRange}.");
                        this.CancelReason = $"Max dist reached ({dist} > {strategy.InpMaxDistRange})";
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    string obsReason = "";
                    if (CheckObstacles(entryPrice, nyoTime, out obsReason))
                    {
                        strategy.Log($"[{Comment}] Sell Entry skipped due to Obstacle: {obsReason}");
                        this.CancelReason = $"Obstacle: {obsReason}";
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    string filterReason = "";
                    if (!CheckEmaFilters(-1, out filterReason))
                    {
                        strategy.Log($"[{Comment}] Sell Entry skipped: {filterReason}");
                        this.CancelReason = filterReason;
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    double lot = strategy.InpUseRiskSizing 
                        ? strategy.RiskManager.CalcLotSize(strategy.InpRiskPercent, strategy.InpSlTicks)
                        : strategy.RiskManager.NormalizeLot(strategy.InpFixContract);

                    if (lot > 0)
                    {
                        this.LastOrderTag = $"{Comment}_{strategy.MagicNumber}_{new Random().Next(1000, 9999)}";

                        double currentBid = strategy.CurrentSymbol.Bid;
                        string orderType = OrderType.Stop;
                        double limitPrice = 0;
                        double triggerPrice = 0;
                        double entryReferencePrice = entryPrice; // Will be entryPrice for Stop/Limit, currentBid for Market

                        if (entryPrice < currentBid)
                        {
                            // State 3: Stop Order (Normal breakout waiting)
                            orderType = OrderType.Stop;
                            triggerPrice = entryPrice;
                            entryReferencePrice = entryPrice;
                        }
                        else if (entryPrice - currentBid <= strategy.InpMaxChaseTicks * tickSize)
                        {
                            // State 1: Market Order (Within Max Chase Ticks - execute immediately to avoid missing wave)
                            orderType = OrderType.Market;
                            entryReferencePrice = currentBid;
                            strategy.Log($"[{Comment}] Price slightly past entry (Bid={currentBid} <= Entry={entryPrice}, within {strategy.InpMaxChaseTicks} ticks). Placing SELL MARKET order.");
                        }
                        else
                        {
                            // State 2: Limit Order (Price has run too far - place limit at breakout level and wait for pullback)
                            orderType = OrderType.Limit;
                            limitPrice = entryPrice;
                            entryReferencePrice = entryPrice;
                            strategy.Log($"[{Comment}] Price is too far past entry (Bid={currentBid} <= Entry={entryPrice}, > {strategy.InpMaxChaseTicks} ticks). Placing SELL LIMIT at original entry to wait for pullback.");
                        }

                        // Risk Sizing based on the correct reference price (either entryPrice or currentBid)
                        double sl = entryReferencePrice + strategy.InpSlTicks * tickSize;
                        double tp = strategy.InpTpTicks > 0 ? (entryReferencePrice - strategy.InpTpTicks * tickSize) : 0;
                        sl = Math.Round(sl / tickSize) * tickSize;
                        tp = Math.Round(tp / tickSize) * tickSize;

                        var request = new PlaceOrderRequestParameters
                        {
                            Account = strategy.CurrentAccount,
                            Symbol = strategy.CurrentSymbol,
                            Side = Side.Sell,
                            OrderTypeId = orderType,
                            Quantity = lot,
                            Price = limitPrice,
                            TriggerPrice = triggerPrice,
                            StopLoss = SlTpHolder.CreateSL(sl, PriceMeasurement.Absolute),
                            TakeProfit = tp > 0 ? SlTpHolder.CreateTP(tp, PriceMeasurement.Absolute) : null,
                            Comment = this.LastOrderTag,
                            TimeInForce = TimeInForce.GTC
                        };

                        var result = Core.Instance.PlaceOrder(request);
                        if (result.Status == TradingOperationResultStatus.Success)
                        {
                            this.State = ORBState.ORB_WAIT_ENTRY;
                            this.OrdersActive = true;
                            this.PlacedTime = serverTime;
                            this.EntryBreakDir = -1;
                            this.EntryReason = $"Down breakout retest confirmed on custom timeframe (Type={orderType})";
                            strategy.Log($"[{Comment}] SELL PENDING PLACED: Type={orderType}, EntryRef={entryReferencePrice}, SL={sl}, TP={tp}, Lot={lot}");
                        }
                        else
                        {
                            strategy.Log($"[{Comment}] SELL PLACEMENT FAILED: {result.Message}", StrategyLoggingLevel.Error);
                            this.CancelReason = $"Placement failed: {result.Message}";
                            this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        }
                    }
                }
            }
        }

        private void SyncOrderAndPositionStatus(DateTime serverTime)
        {
            if (string.IsNullOrEmpty(this.LastOrderTag)) return;

            bool activeOrderExists = Core.Instance.Orders.Any(o => o.Comment == this.LastOrderTag && (o.Status == OrderStatus.Opened || o.Status == OrderStatus.PartiallyFilled));
            bool activePosExists = Core.Instance.Positions.Any(p => p.Symbol == strategy.CurrentSymbol && p.Comment == this.LastOrderTag);

            if (activePosExists)
            {
                this.OrdersActive = true;
                this.HasBeenFilled = true;
            }
            else if (activeOrderExists)
            {
                this.OrdersActive = true;
            }
            else
            {
                // Both order and position resolved (either profit taken, stop hit, or cancelled)
                if (this.OrdersActive)
                {
                    // Introduce a grace period (e.g., 5 seconds) to prevent race conditions
                    // before the broker confirms the order placement
                    if (serverTime - this.PlacedTime < TimeSpan.FromSeconds(5))
                    {
                        return;
                    }

                    if (this.HasBeenFilled)
                    {
                        this.pendingStatsTag = this.LastOrderTag;
                        this.statsCheckStartTime = serverTime;
                    }
                    else
                    {
                        // Check if order was rejected
                        var rejectedOrder = Core.Instance.Orders.FirstOrDefault(o => o.Comment == this.LastOrderTag && o.Status == OrderStatus.Refused);
                        if (rejectedOrder != null)
                        {
                            strategy.Log($"[{Comment}] Trade failed. Order ID: {rejectedOrder.Id} was REJECTED by broker.", StrategyLoggingLevel.Error);
                        }
                    }

                    this.OrdersActive = false;
                    this.LastOrderTag = "";
                    this.TrailTriggerHit = false;
                    this.HasBeenFilled = false;

                    bool limitHit = (strategy.GetWinsToday(TfIndex) >= strategy.InpMaxSuccess)
                                 || (strategy.GetLossesToday(TfIndex) >= strategy.InpMaxLoss);
                    this.State = (strategy.InpContAfter1st && !limitHit) ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                    strategy.Log($"[{Comment}] Active trades closed. Resuming ORB breakout scan.");
                }
            }
        }

        private void UpdateWinLossCounter()
        {
            // Scan trading history to determine if last resolved position closed in profit or loss
            // (Standard strategy logging aggregates performance counters)
            // For backtester metrics simulation:
            // Compare average closed deals profit matching this Tag
            // (Quantower records historical trades dynamically)
            // Here, we increment wins or losses to simulate MQL5 counters
            // We can look at historical trades to check real profit
            var closedPositions = Core.Instance.ClosedPositions.Where(p => p.Comment == this.LastOrderTag).ToList();
            if (closedPositions.Count > 0)
            {
                double totalP = closedPositions.Sum(x => x.GrossPnL != null ? x.GrossPnL.Value : 0.0);
                if (totalP > 0)
                    strategy.IncrementWins(TfIndex);
                else if (totalP < 0)
                    strategy.IncrementLosses(TfIndex);
            }
        }

        private void CheckAutoFlatten(DateTime nyoTime, DateTime serverTime)
        {
            if (!this.OrdersActive) return;

            bool shouldFlatten = false;
            string reason = "";

            var activeOrders = Core.Instance.Orders.Where(o => o.Comment == this.LastOrderTag && (o.Status == OrderStatus.Opened || o.Status == OrderStatus.PartiallyFilled)).ToList();
            var activePositions = Core.Instance.Positions.Where(p => p.Symbol == strategy.CurrentSymbol && p.Comment == this.LastOrderTag).ToList();

            bool hasPending = activeOrders.Count > 0;
            bool hasPosition = activePositions.Count > 0;

            // 1. Unfilled candles check (for pending stop orders only)
            if (hasPending && !hasPosition && this.PlacedTime > DateTime.MinValue)
            {
                int barsPassed = CalculateBarsShift(this.PlacedTime);
                if (barsPassed >= strategy.InpUnfilledCandles)
                {
                    shouldFlatten = true;
                    reason = $"Unfilled candles threshold hit ({barsPassed} >= {strategy.InpUnfilledCandles})";
                }
            }

            // 1.b After filled minutes check (close positions after X minutes if trail trigger not hit)
            if (!shouldFlatten && strategy.InpAfterFilledMinutesOn && hasPosition)
            {
                var oldestPos = activePositions.OrderBy(x => x.OpenTime).FirstOrDefault();
                if (oldestPos != null)
                {
                    DateTime openTimeSelected = Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(oldestPos.OpenTime.ToUniversalTime());
                    if (serverTime >= openTimeSelected.AddMinutes(strategy.InpAfterFilledMinutes))
                    {
                        if (!this.TrailTriggerHit)
                        {
                            shouldFlatten = true;
                            reason = $"Trigger not hit after {strategy.InpAfterFilledMinutes} minutes";
                        }
                    }
                }
            }

            // 3. Price boundary validations (Touch Mid & Unfavor Moves)
            double tickSize = strategy.CurrentSymbol.TickSize;
            double midPrice = (this.RangeHigh + this.RangeLow) / 2.0;
            double bid = strategy.CurrentSymbol.Bid;
            double ask = strategy.CurrentSymbol.Ask;

            if (!shouldFlatten)
            {
                // Check pending orders bounds
                foreach (var order in activeOrders)
                {
                    double open = order.Price;
                    if (order.Side == Side.Buy)
                    {
                        if (bid <= open - strategy.InpUnfavorMoveTicks * tickSize)
                        {
                            shouldFlatten = true;
                            reason = "Unfavor move (Buy Stop)";
                            break;
                        }
                        if (strategy.InpTouchMidOn && bid <= midPrice)
                        {
                            shouldFlatten = true;
                            reason = "Price touched mid-range (Buy Stop)";
                            break;
                        }
                    }
                    else if (order.Side == Side.Sell)
                    {
                        if (ask >= open + strategy.InpUnfavorMoveTicks * tickSize)
                        {
                            shouldFlatten = true;
                            reason = "Unfavor move (Sell Stop)";
                            break;
                        }
                        if (strategy.InpTouchMidOn && ask >= midPrice)
                        {
                            shouldFlatten = true;
                            reason = "Price touched mid-range (Sell Stop)";
                            break;
                        }
                    }
                }

                // Check active positions bounds
                if (!shouldFlatten)
                {
                    foreach (var pos in activePositions)
                    {
                        double open = pos.OpenPrice;
                        if (pos.Side == Side.Buy)
                        {
                            if (bid <= open - strategy.InpUnfavorMoveTicks * tickSize)
                            {
                                shouldFlatten = true;
                                reason = "Unfavor move (Buy Position)";
                                break;
                            }
                            if (strategy.InpTouchMidOn && bid <= midPrice)
                            {
                                shouldFlatten = true;
                                reason = "Price touched mid-range (Buy Position)";
                                break;
                            }
                        }
                        else if (pos.Side == Side.Sell)
                        {
                            if (ask >= open + strategy.InpUnfavorMoveTicks * tickSize)
                            {
                                shouldFlatten = true;
                                reason = "Unfavor move (Sell Position)";
                                break;
                            }
                            if (strategy.InpTouchMidOn && ask >= midPrice)
                            {
                                shouldFlatten = true;
                                reason = "Price touched mid-range (Sell Position)";
                                break;
                            }
                        }
                    }
                }
            }

            if (shouldFlatten)
            {
                strategy.Log($"[{Comment}] Auto-Flatten Triggered: {reason}. Flattening tag: {LastOrderTag}");
                this.CancelReason = reason;
                FlattenAll();

                bool sessionClosed = serverTime >= nyoTime.AddMinutes(strategy.InpAfterMinutes);
                if (sessionClosed)
                {
                    this.State = ORBState.ORB_STOPPED;
                }
                else
                {
                    bool limitHit = (strategy.GetWinsToday(TfIndex) >= strategy.InpMaxSuccess)
                                 || (strategy.GetLossesToday(TfIndex) >= strategy.InpMaxLoss);
                    this.State = (strategy.InpContAfter1st && !limitHit) ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                }
            }
        }

        public void FlattenAll()
        {
            // Cancel pending orders under this strategy instance tag
            var pending = Core.Instance.Orders.Where(o => o.Comment == this.LastOrderTag && (o.Status == OrderStatus.Opened || o.Status == OrderStatus.PartiallyFilled)).ToList();
            foreach (var order in pending)
            {
                Core.Instance.CancelOrder((IOrder)order);
                strategy.Log($"[{Comment}] Cancelled pending order ID: {order.Id}");
            }

            // Close positions under this strategy instance tag
            var positions = Core.Instance.Positions.Where(p => p.Symbol == strategy.CurrentSymbol && p.Comment == this.LastOrderTag).ToList();
            foreach (var pos in positions)
            {
                pos.Close();
                strategy.Log($"[{Comment}] Flattened position ID: {pos.Id}");
            }

            this.OrdersActive = false;
        }

        private int CalculateBarsShift(DateTime placeTime)
        {
            if (this.History == null || this.History.Count == 0) return 0;
            int count = 0;
            for (int i = this.History.Count - 1; i >= 0; i--)
            {
                if (this.History[i, SeekOriginHistory.Begin].TimeLeft >= placeTime)
                    count++;
                else
                    break;
            }
            return count;
        }

        public bool CheckEmaFilters(int direction, out string outReason)
        {
            outReason = "";
            double currentPrice = direction == 1 ? strategy.CurrentSymbol.Bid : strategy.CurrentSymbol.Ask;

            bool[] emaOn = new bool[] { strategy.InpFavorEma9On, strategy.InpFavorEma21On, strategy.InpFavorEma34On };
            int[] emaPeriod = new int[] { 9, 21, 34 };
            string label = "Favor EMA";

            for (int i = 0; i < 3; i++)
            {
                if (!emaOn[i]) continue;
                double emaVal = CalculateEMA(emaPeriod[i], this.History.Count - 2); // on last closed bar
                if (emaVal <= 0) continue;

                if (direction == 1 && currentPrice < emaVal)
                {
                    outReason = $"{label} {emaPeriod[i]} Filter blocked Buy (Price below EMA)";
                    return false;
                }
                else if (direction == -1 && currentPrice > emaVal)
                {
                    outReason = $"{label} {emaPeriod[i]} Filter blocked Sell (Price above EMA)";
                    return false;
                }
            }

            return true;
        }

        public double CalculateEMA(int period, int targetIdx)
        {
            return CalculateEMA(this.History, period, targetIdx);
        }

        public double CalculateEMA(HistoricalData historyStream, int period, int targetIdx)
        {
            if (historyStream == null || historyStream.Count < period || targetIdx < 0 || targetIdx >= historyStream.Count)
                return 0;

            if (targetIdx < period - 1)
                return 0;

            string cacheKey = historyStream.GetHashCode().ToString() + "_" + period;
            if (!emaCaches.TryGetValue(cacheKey, out var cache))
            {
                cache = new EmaCache();
                emaCaches[cacheKey] = cache;
            }

            double multiplier = 2.0 / (period + 1);

            bool isFormingBar = (targetIdx == historyStream.Count - 1);
            int baseIdx = isFormingBar ? targetIdx - 1 : targetIdx;

            if (baseIdx < period - 1)
            {
                double sum = 0;
                int validBars = 0;
                for (int i = 0; i < period; i++)
                {
                    if (historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                    {
                        sum += bar.Close;
                        validBars++;
                    }
                }
                return validBars < period ? 0 : sum / period;
            }

            double baseEma = 0;
            if (cache.LastIndex != -1 && cache.LastIndex <= baseIdx && baseIdx < historyStream.Count)
            {
                baseEma = cache.LastValue;
                for (int i = cache.LastIndex + 1; i <= baseIdx; i++)
                {
                    if (historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                    {
                        baseEma = (bar.Close - baseEma) * multiplier + baseEma;
                    }
                }
                cache.LastIndex = baseIdx;
                cache.LastValue = baseEma;
            }
            else
            {
                double sum = 0;
                int validBars = 0;
                for (int i = 0; i < period; i++)
                {
                    if (historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                    {
                        sum += bar.Close;
                        validBars++;
                    }
                }
                if (validBars < period) return 0;
                baseEma = sum / period;

                for (int i = period; i <= baseIdx; i++)
                {
                    if (historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                    {
                        baseEma = (bar.Close - baseEma) * multiplier + baseEma;
                    }
                }
                cache.LastIndex = baseIdx;
                cache.LastValue = baseEma;
            }

            if (isFormingBar)
            {
                if (historyStream[targetIdx, SeekOriginHistory.Begin] is HistoryItemBar bar)
                {
                    return (bar.Close - baseEma) * multiplier + baseEma;
                }
            }

            return baseEma;
        }

        public double CalculateVWAP(HistoricalData historyStream, DateTime startDay)
        {
            if (historyStream == null || historyStream.Count == 0) return 0;

            string cacheKey = historyStream.GetHashCode().ToString() + "_" + startDay.Ticks;
            if (!vwapCaches.TryGetValue(cacheKey, out var cache))
            {
                cache = new VwapCache { StartDay = startDay };
                vwapCaches[cacheKey] = cache;
            }

            int count = historyStream.Count;
            int baseIdx = count - 2;

            if (cache.LastIndex == -1 || cache.StartDay != startDay)
            {
                cache.StartDay = startDay;
                double sumPV = 0;
                double sumV = 0;
                
                int startIdx = -1;
                for (int i = 0; i <= baseIdx; i++)
                {
                    if (historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar && bar.TimeLeft >= startDay)
                    {
                        startIdx = i;
                        break;
                    }
                }

                if (startIdx != -1)
                {
                    for (int i = startIdx; i <= baseIdx; i++)
                    {
                        if (historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                        {
                            double typicalPrice = (bar.High + bar.Low + bar.Close) / 3.0;
                            double vol = bar.Volume;
                            sumPV += typicalPrice * vol;
                            sumV += vol;
                        }
                    }
                }

                cache.LastIndex = baseIdx;
                cache.SumPV = sumPV;
                cache.SumV = sumV;
            }
            else if (cache.LastIndex < baseIdx)
            {
                double sumPV = cache.SumPV;
                double sumV = cache.SumV;

                for (int i = cache.LastIndex + 1; i <= baseIdx; i++)
                {
                    if (historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar && bar.TimeLeft >= startDay)
                    {
                        double typicalPrice = (bar.High + bar.Low + bar.Close) / 3.0;
                        double vol = bar.Volume;
                        sumPV += typicalPrice * vol;
                        sumV += vol;
                    }
                }

                cache.LastIndex = baseIdx;
                cache.SumPV = sumPV;
                cache.SumV = sumV;
            }
            else if (cache.LastIndex > baseIdx)
            {
                cache.LastIndex = -1;
                cache.SumPV = 0;
                cache.SumV = 0;
                return CalculateVWAP(historyStream, startDay);
            }

            double finalSumPV = cache.SumPV;
            double finalSumV = cache.SumV;

            if (count - 1 >= 0 && historyStream[count - 1, SeekOriginHistory.Begin] is HistoryItemBar currentBar && currentBar.TimeLeft >= startDay)
            {
                double typicalPrice = (currentBar.High + currentBar.Low + currentBar.Close) / 3.0;
                double vol = currentBar.Volume;
                finalSumPV += typicalPrice * vol;
                finalSumV += vol;
            }

            return finalSumV > 0 ? finalSumPV / finalSumV : 0;
        }

        public double GetPrevDayEMA(int period)
        {
            var dailyHistory = strategy.GetDailyHistory();
            if (dailyHistory == null || dailyHistory.Count < period) return 0;

            int targetIdx = dailyHistory.Count - 2; // last closed daily bar
            if (targetIdx < period - 1) return 0;

            double multiplier = 2.0 / (period + 1);

            // Starting SMA seed (average of the first 'period' bars: index 0 to period - 1)
            double sum = 0;
            int validBars = 0;
            for (int i = 0; i < period; i++)
            {
                if (dailyHistory[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                {
                    sum += bar.Close;
                    validBars++;
                }
            }
            if (validBars < period) return 0;
            double ema = sum / period;

            // Recurse to targetIdx to get fully smoothed EMA
            for (int i = period; i <= targetIdx; i++)
            {
                if (dailyHistory[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                {
                    double close = bar.Close;
                    ema = (close - ema) * multiplier + ema;
                }
            }

            return ema;
        }

        private bool CheckObstacles(double entryPrice, DateTime nyoTime, out string outReason)
        {
            outReason = "";
            double tickSize = strategy.CurrentSymbol.TickSize;
            int dir = this.BreakDir; // 1 = Buy, -1 = Sell

            // 1. Range 5m Obstacle
            if (strategy.InpObsRange5mOn && TfIndex != 1)
            {
                double rHigh = 0, rLow = 0;
                if (GetOtherTimeframeRange(Period.MIN5, nyoTime, out rHigh, out rLow))
                {
                    if (dir == 1) // Buy
                    {
                        if (rHigh > entryPrice && (rHigh - entryPrice) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"5m Range High obstacle (Dist={Math.Round((rHigh - entryPrice) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                    else if (dir == -1) // Sell
                    {
                        if (rLow < entryPrice && (entryPrice - rLow) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"5m Range Low obstacle (Dist={Math.Round((entryPrice - rLow) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                }
            }

            // 2. Range 15m Obstacle
            if (strategy.InpObsRange15mOn && TfIndex != 2)
            {
                double rHigh = 0, rLow = 0;
                if (GetOtherTimeframeRange(Period.MIN15, nyoTime, out rHigh, out rLow))
                {
                    if (dir == 1) // Buy
                    {
                        if (rHigh > entryPrice && (rHigh - entryPrice) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"15m Range High obstacle (Dist={Math.Round((rHigh - entryPrice) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                    else if (dir == -1) // Sell
                    {
                        if (rLow < entryPrice && (entryPrice - rLow) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"15m Range Low obstacle (Dist={Math.Round((entryPrice - rLow) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                }
            }

            // 2.b Range 30m Obstacle
            if (strategy.InpObsRange30mOn && TfIndex != 3)
            {
                double rHigh = 0, rLow = 0;
                if (GetOtherTimeframeRange(Period.MIN30, nyoTime, out rHigh, out rLow))
                {
                    if (dir == 1) // Buy
                    {
                        if (rHigh > entryPrice && (rHigh - entryPrice) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"30m Range High obstacle (Dist={Math.Round((rHigh - entryPrice) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                    else if (dir == -1) // Sell
                    {
                        if (rLow < entryPrice && (entryPrice - rLow) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"30m Range Low obstacle (Dist={Math.Round((entryPrice - rLow) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                }
            }

            // Previous Day High/Low Obstacle
            if (strategy.InpObsPrevDayHLOn)
            {
                var dailyHistory = strategy.GetDailyHistory();
                if (dailyHistory != null && dailyHistory.Count >= 1)
                {
                    DateTime today = strategy.TimeManager.GetServerTime().Date;
                    HistoryItemBar? prevDayBar = null;
                    for (int i = dailyHistory.Count - 1; i >= 0; i--)
                    {
                        if (dailyHistory[i, SeekOriginHistory.Begin] is HistoryItemBar bar && bar.TimeLeft.Date < today)
                        {
                            prevDayBar = bar;
                            break;
                        }
                    }

                    if (prevDayBar != null)
                    {
                        double prevHigh = prevDayBar.High;
                        double prevLow = prevDayBar.Low;

                        if (dir == 1) // Buy
                        {
                            if (prevHigh > entryPrice && (prevHigh - entryPrice) / tickSize < strategy.InpObsMaxDist)
                            {
                                outReason = $"Prev Day High obstacle (Dist={Math.Round((prevHigh - entryPrice) / tickSize, 1)} ticks)";
                                return true;
                            }
                        }
                        else if (dir == -1) // Sell
                        {
                            if (prevLow < entryPrice && (entryPrice - prevLow) / tickSize < strategy.InpObsMaxDist)
                            {
                                outReason = $"Prev Day Low obstacle (Dist={Math.Round((entryPrice - prevLow) / tickSize, 1)} ticks)";
                                return true;
                            }
                        }
                    }
                }
            }

            // M2 EMAs Obstacle
            var m2History = strategy.GetM2History();
            if (m2History != null && m2History.Count > 0)
            {
                int targetIdx = m2History.Count - 2;

                if (strategy.InpObsEma250On)
                {
                    double emaVal = CalculateEMA(m2History, 250, targetIdx);
                    if (emaVal > 0)
                    {
                        if (dir == 1) // Buy
                        {
                            if (emaVal > entryPrice && (emaVal - entryPrice) / tickSize < strategy.InpObsMaxDist)
                            {
                                outReason = $"M2 EMA 250 obstacle (Dist={Math.Round((emaVal - entryPrice) / tickSize, 1)} ticks)";
                                return true;
                            }
                        }
                        else if (dir == -1) // Sell
                        {
                            if (emaVal < entryPrice && (entryPrice - emaVal) / tickSize < strategy.InpObsMaxDist)
                            {
                                outReason = $"M2 EMA 250 obstacle (Dist={Math.Round((entryPrice - emaVal) / tickSize, 1)} ticks)";
                                return true;
                            }
                        }
                    }
                }

                if (strategy.InpObsEma255On)
                {
                    double emaVal = CalculateEMA(m2History, 255, targetIdx);
                    if (emaVal > 0)
                    {
                        if (dir == 1) // Buy
                        {
                            if (emaVal > entryPrice && (emaVal - entryPrice) / tickSize < strategy.InpObsMaxDist)
                            {
                                outReason = $"M2 EMA 255 obstacle (Dist={Math.Round((emaVal - entryPrice) / tickSize, 1)} ticks)";
                                return true;
                            }
                        }
                        else if (dir == -1) // Sell
                        {
                            if (emaVal < entryPrice && (entryPrice - emaVal) / tickSize < strategy.InpObsMaxDist)
                            {
                                outReason = $"M2 EMA 255 obstacle (Dist={Math.Round((entryPrice - emaVal) / tickSize, 1)} ticks)";
                                return true;
                            }
                        }
                    }
                }

                if (strategy.InpObsEma34On)
                {
                    double emaVal = CalculateEMA(m2History, 34, targetIdx);
                    if (emaVal > 0)
                    {
                        if (dir == 1) // Buy
                        {
                            if (emaVal > entryPrice && (emaVal - entryPrice) / tickSize < strategy.InpObsMaxDist)
                            {
                                outReason = $"M2 EMA 34 obstacle (Dist={Math.Round((emaVal - entryPrice) / tickSize, 1)} ticks)";
                                return true;
                            }
                        }
                        else if (dir == -1) // Sell
                        {
                            if (emaVal < entryPrice && (entryPrice - emaVal) / tickSize < strategy.InpObsMaxDist)
                            {
                                outReason = $"M2 EMA 34 obstacle (Dist={Math.Round((entryPrice - emaVal) / tickSize, 1)} ticks)";
                                return true;
                            }
                        }
                    }
                }
            }

            // Day / Week VWAP Obstacles
            DateTime startDay = strategy.TimeManager.GetServerTime().Date;
            if (strategy.InpObsDayVwapOn)
            {
                double dVwapVal = CalculateVWAP(strategy.GetM1History(), startDay);
                if (dVwapVal > 0)
                {
                    if (dir == 1) // Buy
                    {
                        if (dVwapVal > entryPrice && (dVwapVal - entryPrice) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"Day VWAP obstacle (Dist={Math.Round((dVwapVal - entryPrice) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                    else if (dir == -1) // Sell
                    {
                        if (dVwapVal < entryPrice && (entryPrice - dVwapVal) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"Day VWAP obstacle (Dist={Math.Round((entryPrice - dVwapVal) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                }
            }

            if (strategy.InpObsWeekVwapOn)
            {
                DateTime nowServer = strategy.TimeManager.GetServerTime();
                int diff = (7 + (nowServer.DayOfWeek - DayOfWeek.Monday)) % 7;
                DateTime startWeek = nowServer.AddDays(-diff).Date;

                double wVwapVal = CalculateVWAP(strategy.GetM1History(), startWeek);
                if (wVwapVal > 0)
                {
                    if (dir == 1) // Buy
                    {
                        if (wVwapVal > entryPrice && (wVwapVal - entryPrice) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"Week VWAP obstacle (Dist={Math.Round((wVwapVal - entryPrice) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                    else if (dir == -1) // Sell
                    {
                        if (wVwapVal < entryPrice && (entryPrice - wVwapVal) / tickSize < strategy.InpObsMaxDist)
                        {
                            outReason = $"Week VWAP obstacle (Dist={Math.Round((entryPrice - wVwapVal) / tickSize, 1)} ticks)";
                            return true;
                        }
                    }
                }
            }

            return false;
        }

        private bool GetOtherTimeframeRange(Period p, DateTime nyoTime, out double high, out double low)
        {
            high = 0; low = 0;
            var m1History = strategy.GetM1History();
            if (m1History == null || m1History.Count == 0) return false;

            int minutes = (int)p.Duration.TotalMinutes;
            int seconds = minutes * 60;

            var bars = m1History
                .Where(b => b.TimeLeft >= nyoTime && b.TimeLeft < nyoTime.AddSeconds(seconds))
                .OfType<HistoryItemBar>()
                .ToList();

            if (bars.Count == 0) return false;

            // Cho phép tính toán nếu đã qua thời điểm tạo xong nến hoặc đã đủ số nến
            DateTime serverTime = strategy.TimeManager.GetServerTime();
            if (serverTime < nyoTime.AddSeconds(seconds) && bars.Count < minutes) return false;

            double maxH = double.MinValue;
            double minL = double.MaxValue;
            foreach (var bar in bars)
            {
                if (bar.High > maxH) maxH = bar.High;
                if (bar.Low < minL) minL = bar.Low;
            }

            high = maxH;
            low = minL;
            return true;
        }
    }
}
