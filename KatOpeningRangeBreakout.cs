using System;
using System.Collections.Generic;
using System.Linq;
using TradingPlatform.BusinessLayer;

namespace KatORB
{
    public class KatOpeningRangeBreakout : Strategy
    {
        [InputParameter("Symbol", 1)]
        public Symbol CurrentSymbol { get; set; }

        [InputParameter("Account", 2)]
        public Account CurrentAccount { get; set; }

        //--- Instance Settings
        [InputParameter("Magic Number", 10)]
        public int InpMagicNumber = 202605011;

        [InputParameter("EA Operating Mode (0=Auto, 1=Manual)", 20)]
        public int InpEaMode = 0; // 0=Auto, 1=Manual

        //--- Schedule Settings
        [InputParameter("NY Open Hour (NY Time)", 30)]
        public int InpNyHour = 9;

        [InputParameter("NY Open Minute", 40)]
        public int InpNyMinute = 30;

        [InputParameter("NY Open Second", 50)]
        public int InpNySecond = 0;

        [InputParameter("Broker UTC Offset (NY Time)", 60)]
        public int InpUtcOffset = -4; // NY standard daylight offset

        //--- Timeframe Toggles
        [InputParameter("Run 2m Timeframe", 70)]
        public bool Inp2mActive = true;
        
        [InputParameter("Run 5m Timeframe", 80)]
        public bool Inp5mActive = true;

        [InputParameter("Run 15m Timeframe", 90)]
        public bool Inp15mActive = true;

        [InputParameter("Run 30m Timeframe", 100)]
        public bool Inp30mActive = true;

        [InputParameter("Default Stop Loss (Points)", 110)]
        public int InpSlPoints = 1500;

        [InputParameter("Default Take Profit (Points)", 120)]
        public int InpTpPoints = 15000;

        [InputParameter("Use Candle Extremes for SL", 130)]
        public bool InpSlCandle = false;

        [InputParameter("Allowed Trade Directions (0=Both, 1=BuyOnly, 2=SellOnly)", 140)]
        public int InpOrderMode = 0; // 0=Both, 1=Buy, 2=Sell

        [InputParameter("Entry/SL Buffer (Points)", 150)]
        public int InpEntryBufferPoints = 5;

        [InputParameter("Use Custom Retest Candle", 160)]
        public bool InpCustomRetestOn = true;

        [InputParameter("Retest Candle Timeframe (Min)", 170)]
        public int InpCustomRetestMin = 1;

        [InputParameter("Risk per Trade (%)", 180)]
        public double InpRiskPercent = 2.0;

        [InputParameter("Fix Lot Size", 190)]
        public double InpFixLot = 2.0;

        [InputParameter("Risk Management (true=Risk%, false=Fix Lot)", 200)]
        public bool InpRiskModeOn = true;

        [InputParameter("Allow Entry Continue After 1st", 205)]
        public bool InpContAfter1st = true;

        [InputParameter("Max Success Wins Today", 206)]
        public bool InpMaxSuccessOn = true;
        
        [InputParameter("Max Success Value", 207)]
        public int InpMaxSuccess = 2;

        [InputParameter("Max Losses Today", 208)]
        public bool InpMaxLossOn = true;

        [InputParameter("Max Losses Value", 209)]
        public int InpMaxLoss = 1;

        [InputParameter("Max Entry Dist from Boundary (Points)", 210)]
        public bool InpMaxDistRangeOn = true;

        [InputParameter("Max Entry Dist Value", 211)]
        public int InpMaxDistRange = 6000;

        //--- Trailing settings
        [InputParameter("Trailing Stop Mode (0=Off, 1=Chase, 2=Candle1, 3=Candle2, 4=Candle3)", 220)]
        public int InpTrailMode = 1; // 1 = TM_CHASE
        
        [InputParameter("Trailing Trigger (Points)", 230)]
        public int InpTrailTrigger = 1500;

        [InputParameter("Trailing Distance (Points)", 240)]
        public int InpTrailDistance = 500;

        [InputParameter("Trailing Step (Points)", 250)]
        public int InpTrailStep = 1;

        [InputParameter("Breakeven Activation (Points)", 260)]
        public int InpBeActivatePts = 200;

        [InputParameter("Breakeven Lock Profit (Points)", 270)]
        public int InpBeLockPts = 50;

        [InputParameter("Enable Breakeven", 280)]
        public bool InpBeEnabled = false;

        //--- Auto-Flatten Conditions
        [InputParameter("Touch Mid Auto-Flatten", 281)]
        public bool InpTouchMidOn = true;

        [InputParameter("Unfavor Move Auto-Flatten", 282)]
        public bool InpUnfavorMoveOn = true;

        [InputParameter("Unfavor Move Distance (Points)", 283)]
        public int InpUnfavorMovePts = 8000;

        [InputParameter("Unfilled Candles Auto-Flatten", 284)]
        public bool InpUnfilledCandlesOn = false;

        [InputParameter("Unfilled Candles Count", 285)]
        public int InpUnfilledCandles = 2;

        [InputParameter("After Filled Minutes Flatten", 286)]
        public bool InpAfterFilledMinutesOn = true;

        [InputParameter("After Filled Minutes", 287)]
        public int InpAfterFilledMinutes = 5;

        [InputParameter("After Session Minutes Flatten", 288)]
        public bool InpAfterMinutesOn = true;

        [InputParameter("After Session Minutes", 289)]
        public int InpAfterMinutes = 60;

        //--- Favor EMA Trend Filters
        [InputParameter("Favor EMA 1 Filter", 291)]
        public bool InpFavorEma1On = false;

        [InputParameter("Favor EMA 1 Period", 292)]
        public int InpFavorEma1Period = 9;

        [InputParameter("Favor EMA 2 Filter", 293)]
        public bool InpFavorEma2On = false;

        [InputParameter("Favor EMA 2 Period", 294)]
        public int InpFavorEma2Period = 21;

        [InputParameter("Favor EMA 3 Filter", 295)]
        public bool InpFavorEma3On = false;

        [InputParameter("Favor EMA 3 Period", 296)]
        public int InpFavorEma3Period = 34;

        //--- Active Trailing EMA Trend Filters
        [InputParameter("Active Price < EMA 1 Flatten", 297)]
        public bool InpEma1On = false;

        [InputParameter("Active EMA 1 Period", 298)]
        public int InpEma1Period = 9;

        [InputParameter("Active Price < EMA 2 Flatten", 299)]
        public bool InpEma2On = false;

        [InputParameter("Active EMA 2 Period", 300)]
        public int InpEma2Period = 21;

        [InputParameter("Active Price < EMA 3 Flatten", 301)]
        public bool InpEma3On = false;

        [InputParameter("Active EMA 3 Period", 302)]
        public int InpEma3Period = 34;

        //--- Obstacles Settings
        [InputParameter("Max dist to obstacle (Points)", 310)]
        public int InpObsMaxDist = 1600;

        [InputParameter("Block on 5m Range obstacle", 320)]
        public bool InpObsRange5mOn = true;

        [InputParameter("Block on 15m Range obstacle", 330)]
        public bool InpObsRange15mOn = true;

        [InputParameter("Block on 30m Range obstacle", 340)]
        public bool InpObsRange30mOn = true;

        [InputParameter("Block on Prev Day H/L obstacle", 350)]
        public bool InpObsPrevDayHLOn = true;

        [InputParameter("Block on Day VWAP obstacle", 360)]
        public bool InpObsDayVwapOn = true;

        [InputParameter("Block on Week VWAP obstacle", 370)]
        public bool InpObsWeekVwapOn = true;

        [InputParameter("Block on EMA 1 obstacle", 380)]
        public bool InpObsEma1On = true;

        [InputParameter("EMA 1 Period (M2)", 390)]
        public int InpObsEma1Period = 250;

        [InputParameter("Block on EMA 2 obstacle", 400)]
        public bool InpObsEma2On = true;

        [InputParameter("EMA 2 Period (M2)", 410)]
        public int InpObsEma2Period = 255;

        [InputParameter("Block on EMA 3 obstacle", 420)]
        public bool InpObsEma3On = true;

        [InputParameter("EMA 3 Period (M2)", 430)]
        public int InpObsEma3Period = 34;

        //--- Core State Variables
        private TimeManager timeManager;
        private RiskManager riskManager;
        private TrailManager trailManager;
        private List<ORBRunner> runners;

        public TimeManager TimeManager => timeManager;
        public RiskManager RiskManager => riskManager;
        public TrailManager TrailManager => trailManager;

        private HistoricalData historicalDataM1;
        private HistoricalData historicalDataM2;
        private HistoricalData historicalDataM5;
        private HistoricalData historicalDataM15;
        private HistoricalData historicalDataM30;
        private HistoricalData historicalDataRetest;
        private HistoricalData dailyHistory;

        // Trade tracking for stats (wins/losses per timeframe)
        private Dictionary<int, int> winsToday = new Dictionary<int, int>();
        private Dictionary<int, int> lossesToday = new Dictionary<int, int>();
        private DateTime lastStatsDate = DateTime.MinValue;

        public int MagicNumber => InpMagicNumber;

        public void Log(string message, StrategyLoggingLevel level = StrategyLoggingLevel.Info)
        {
            base.Log(message, level);
        }

        public KatOpeningRangeBreakout()
        {
            this.Name = "KAT Opening Range Breakout";
            this.Description = "Automated Break & Retest range strategy on 2m/5m/15m/30m NYO candles";
        }

        protected override void OnCreated()
        {
            base.OnCreated();
            this.timeManager = new TimeManager();
            this.riskManager = new RiskManager(this);
            this.trailManager = new TrailManager(this);
            this.runners = new List<ORBRunner>();

            for (int i = 0; i < 4; i++)
            {
                this.winsToday[i] = 0;
                this.lossesToday[i] = 0;
            }
        }

        protected override void OnRun()
        {
            if (this.CurrentSymbol == null)
            {
                this.Log("ERROR: Symbol is null. Strategy cannot start.", StrategyLoggingLevel.Error);
                return;
            }

            //--- Subscriptions to required historical data streams
            DateTime loadFrom = DateTime.UtcNow.AddDays(-5);
            this.historicalDataM1 = this.CurrentSymbol.GetHistory(Period.MIN1, loadFrom);
            this.historicalDataM2 = this.CurrentSymbol.GetHistory(Period.MIN2, loadFrom);
            this.historicalDataM5 = this.CurrentSymbol.GetHistory(Period.MIN5, loadFrom);
            this.historicalDataM15 = this.CurrentSymbol.GetHistory(Period.MIN15, loadFrom);
            this.historicalDataM30 = this.CurrentSymbol.GetHistory(Period.MIN30, loadFrom);
            this.dailyHistory = this.CurrentSymbol.GetHistory(Period.DAY1, loadFrom);

            // Subscribe to the custom retest timeframe if enabled and different
            if (InpCustomRetestOn)
            {
                Period retestPeriod = MapMinutesToPeriod(InpCustomRetestMin);
                this.historicalDataRetest = this.CurrentSymbol.GetHistory(retestPeriod, loadFrom);
            }
            else
            {
                this.historicalDataRetest = this.historicalDataM2; // fallback
            }

            //--- Initialize the runners for active timeframes
            this.runners.Clear();
            if (Inp2mActive)  this.runners.Add(new ORBRunner(this, Period.MIN2, 0, "orb-2m", this.historicalDataM2));
            if (Inp5mActive)  this.runners.Add(new ORBRunner(this, Period.MIN5, 1, "orb-5m", this.historicalDataM5));
            if (Inp15mActive) this.runners.Add(new ORBRunner(this, Period.MIN15, 2, "orb-15m", this.historicalDataM15));
            if (Inp30mActive) this.runners.Add(new ORBRunner(this, Period.MIN30, 3, "orb-30m", this.historicalDataM30));

            this.Log($"KAT ORB Initialized. Active Runners count: {this.runners.Count}");

            // Subscribe to real-time quote updates
            this.CurrentSymbol.NewQuote += CurrentSymbol_NewQuote;
        }

        protected override void OnStop()
        {
            if (this.CurrentSymbol != null)
            {
                this.CurrentSymbol.NewQuote -= CurrentSymbol_NewQuote;
            }

            // Clean up resources and unsubscribe
            if (this.historicalDataM1 != null) this.historicalDataM1.Dispose();
            if (this.historicalDataM2 != null) this.historicalDataM2.Dispose();
            if (this.historicalDataM5 != null) this.historicalDataM5.Dispose();
            if (this.historicalDataM15 != null) this.historicalDataM15.Dispose();
            if (this.historicalDataM30 != null) this.historicalDataM30.Dispose();
            if (this.dailyHistory != null) this.dailyHistory.Dispose();
            if (this.historicalDataRetest != null && this.historicalDataRetest != this.historicalDataM2) this.historicalDataRetest.Dispose();

            this.Log("KAT ORB Stopped.");
        }

        private void CurrentSymbol_NewQuote(Symbol symbol, Quote quote)
        {
            OnQuoteUpdate();
        }

        private void OnQuoteUpdate()
        {
            if (this.runners.Count == 0) return;

            DateTime serverTime = this.timeManager.GetServerTime();
            this.timeManager.UpdateTargetTime(InpNyHour, InpNyMinute, InpNySecond, InpUtcOffset);
            DateTime nyoServerTime = this.timeManager.GetTargetTime();

            // Daily stats reset at NY Open
            ResetStatsOnNewDay(nyoServerTime);

            // Periodically refresh history counts or triggers
            foreach (var runner in this.runners)
            {
                runner.Process(nyoServerTime, serverTime);
                this.trailManager.Process(runner);
            }
        }

        private void ResetStatsOnNewDay(DateTime nyoTime)
        {
            if (nyoTime != this.lastStatsDate && nyoTime > DateTime.MinValue)
            {
                for (int i = 0; i < 4; i++)
                {
                    this.winsToday[i] = 0;
                    this.lossesToday[i] = 0;
                }
                this.lastStatsDate = nyoTime;
                this.Log($"New trading day detected at {nyoTime}. Strategy win/loss stats have been reset.");
            }
        }

        public int GetWinsToday(int tfIndex) => this.winsToday.ContainsKey(tfIndex) ? this.winsToday[tfIndex] : 0;
        public int GetLossesToday(int tfIndex) => this.lossesToday.ContainsKey(tfIndex) ? this.lossesToday[tfIndex] : 0;
        public void IncrementWins(int tfIndex) { if (this.winsToday.ContainsKey(tfIndex)) this.winsToday[tfIndex]++; }
        public void IncrementLosses(int tfIndex) { if (this.lossesToday.ContainsKey(tfIndex)) this.lossesToday[tfIndex]++; }

        //--- Helper methods for historical access
        public HistoricalData GetM1History() => this.historicalDataM1;
        public HistoricalData GetDailyHistory() => this.dailyHistory;
        public HistoricalData? GetRetestHistory() => InpCustomRetestOn ? this.historicalDataRetest : null;

        public static Period MapMinutesToPeriod(int minutes)
        {
            switch (minutes)
            {
                case 1: return Period.MIN1;
                case 2: return Period.MIN2;
                case 3: return Period.MIN3;
                case 4: return Period.MIN4;
                case 5: return Period.MIN5;
                case 10: return Period.MIN10;
                case 15: return Period.MIN15;
                case 30: return Period.MIN30;
                case 60: return Period.HOUR1;
                default: return Period.MIN1;
            }
        }
    }

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

        private DateTime lastNYOTime = DateTime.MinValue;

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
        }

        public void Process(DateTime nyoTime, DateTime serverTime)
        {
            if (nyoTime == DateTime.MinValue || serverTime == DateTime.MinValue) return;

            // Reset state on a new trading day's NY Open
            if (nyoTime != this.lastNYOTime)
            {
                ResetState();
                this.lastNYOTime = nyoTime;
            }

            if (serverTime < nyoTime) return;

            // Maintain order active synchronization using actual position/order checks
            SyncOrderAndPositionStatus();

            // Check safeguards and trade window limits
            if (!this.OrdersActive)
            {
                bool limitHit = (strategy.InpMaxSuccessOn && strategy.GetWinsToday(TfIndex) >= strategy.InpMaxSuccess)
                             || (strategy.InpMaxLossOn   && strategy.GetLossesToday(TfIndex) >= strategy.InpMaxLoss);
                if (limitHit && this.State != ORBState.ORB_DONE && this.State != ORBState.ORB_STOPPED)
                {
                    this.State = ORBState.ORB_DONE;
                    strategy.Log($"[{Comment}] Win/Loss limit hit today. Forcing state to DONE.");
                }
            }

            // Exceeded daily trading session window check
            int tfSeconds = (int)this.Period.Duration.TotalSeconds;
            if (!this.OrdersActive && strategy.InpAfterMinutesOn && serverTime >= nyoTime.AddMinutes(strategy.InpAfterMinutes))
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
                var m1History = strategy.GetM1History();
                if (m1History == null || m1History.Count == 0) return;

                int expectedBars = tfSeconds / 60;
                var rangeBars = m1History
                    .Where(b => b.TimeLeft >= nyoTime && b.TimeLeft < nyoTime.AddSeconds(tfSeconds))
                    .Cast<HistoryItemBar>()
                    .ToList();

                // Wait for strict bar synchronization to ensure M1 closed candles match exactly
                if (rangeBars.Count < expectedBars) return;

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
                strategy.Log($"[{Comment}] Range Formed: High={RangeHigh}, Low={RangeLow}");
            }
        }

        private void HandleWaitBreak()
        {
            if (this.History == null || this.History.Count < 2) return;

            // index Count - 1 is current forming bar, Count - 2 is the last closed bar
            var lastClosedBar = (HistoryItemBar)this.History[this.History.Count - 2];
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
            var retestHistory = strategy.InpCustomRetestOn ? strategy.GetRetestHistory() : (HistoricalData?)this.History;
            if (retestHistory == null || retestHistory.Count < 2) return;

            // Retrieve last closed bar on retest timeframe
            var lastClosedBar = (HistoryItemBar)retestHistory[retestHistory.Count - 2];
            if (lastClosedBar.TimeLeft <= this.CandleTime) return;

            double openPrice = lastClosedBar.Open;
            double closePrice = lastClosedBar.Close;
            double highPrice = lastClosedBar.High;
            double lowPrice = lastClosedBar.Low;

            double tickSize = strategy.CurrentSymbol.TickSize;
            int buffer = strategy.InpEntryBufferPoints;
            double spread = strategy.CurrentSymbol.Ask - strategy.CurrentSymbol.Bid;

            //--- Break UP (Bullish Retest Validation)
            if (this.BreakDir == 1 && strategy.InpOrderMode != 2) // not sell only
            {
                // Opposite color candle (bearish: close < open) touching or penetrating the broken high range
                if (closePrice < openPrice && lowPrice <= this.RangeHigh)
                {
                    double entryPrice = highPrice + (buffer * tickSize) + spread;
                    entryPrice = Math.Round(entryPrice / tickSize) * tickSize;

                    // Obstacle/EMA Filter Validation
                    if (strategy.InpMaxDistRangeOn)
                    {
                        double dist = (entryPrice - this.RangeHigh) / tickSize;
                        if (dist > strategy.InpMaxDistRange)
                        {
                            strategy.Log($"[{Comment}] Buy Entry skipped. Distance {dist} pts > max {strategy.InpMaxDistRange}.");
                            this.CancelReason = $"Max dist reached ({dist} > {strategy.InpMaxDistRange})";
                            this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                            return;
                        }
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
                    if (!CheckEmaFilters(1, out filterReason, true))
                    {
                        strategy.Log($"[{Comment}] Buy Entry skipped: {filterReason}");
                        this.CancelReason = filterReason;
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    // Risk Sizing
                    double sl = strategy.InpSlCandle ? (lowPrice - buffer * tickSize) : (entryPrice - strategy.InpSlPoints * tickSize);
                    double tp = strategy.InpTpPoints > 0 ? (entryPrice + strategy.InpTpPoints * tickSize) : 0;
                    sl = Math.Round(sl / tickSize) * tickSize;
                    tp = Math.Round(tp / tickSize) * tickSize;

                    int slPointsCalculated = (int)Math.Max(50, Math.Abs(entryPrice - sl) / tickSize);
                    double lot = strategy.InpRiskModeOn
                        ? strategy.RiskManager.CalcLotSize(strategy.InpRiskPercent, slPointsCalculated)
                        : strategy.RiskManager.NormalizeLot(strategy.InpFixLot);

                    if (lot > 0)
                    {
                        this.LastOrderTag = $"{Comment}_{strategy.MagicNumber}_{new Random().Next(1000, 9999)}";
                        
                        var request = new PlaceOrderRequestParameters
                        {
                            Account = strategy.CurrentAccount,
                            Symbol = strategy.CurrentSymbol,
                            Side = Side.Buy,
                            OrderTypeId = OrderType.Stop,
                            Quantity = lot,
                            Price = entryPrice,
                            TriggerPrice = entryPrice,
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
                            this.EntryReason = $"Up breakout retest confirmed on custom timeframe";
                            strategy.Log($"[{Comment}] BUY PENDING PLACED: Entry={entryPrice}, SL={sl}, TP={tp}, Lot={lot}");
                        }
                        else
                        {
                            strategy.Log($"[{Comment}] BUY PLACEMENT FAILED: {result.Message}", StrategyLoggingLevel.Error);
                        }
                    }
                }
            }
            //--- Break DOWN (Bearish Retest Validation)
            else if (this.BreakDir == -1 && strategy.InpOrderMode != 1) // not buy only
            {
                // Opposite color candle (bullish: close > open) touching or penetrating the broken low range
                if (closePrice > openPrice && highPrice >= this.RangeLow)
                {
                    double entryPrice = lowPrice - (buffer * tickSize);
                    entryPrice = Math.Round(entryPrice / tickSize) * tickSize;

                    // Obstacle/EMA Filter Validation
                    if (strategy.InpMaxDistRangeOn)
                    {
                        double dist = (this.RangeLow - entryPrice) / tickSize;
                        if (dist > strategy.InpMaxDistRange)
                        {
                            strategy.Log($"[{Comment}] Sell Entry skipped. Distance {dist} pts > max {strategy.InpMaxDistRange}.");
                            this.CancelReason = $"Max dist reached ({dist} > {strategy.InpMaxDistRange})";
                            this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                            return;
                        }
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
                    if (!CheckEmaFilters(-1, out filterReason, true))
                    {
                        strategy.Log($"[{Comment}] Sell Entry skipped: {filterReason}");
                        this.CancelReason = filterReason;
                        this.State = strategy.InpContAfter1st ? ORBState.ORB_WAIT_BREAK : ORBState.ORB_DONE;
                        return;
                    }

                    // Risk Sizing
                    double sl = strategy.InpSlCandle ? (highPrice + (buffer * tickSize) + spread) : (entryPrice + strategy.InpSlPoints * tickSize);
                    double tp = strategy.InpTpPoints > 0 ? (entryPrice - strategy.InpTpPoints * tickSize) : 0;
                    sl = Math.Round(sl / tickSize) * tickSize;
                    tp = Math.Round(tp / tickSize) * tickSize;

                    int slPointsCalculated = (int)Math.Max(50, Math.Abs(entryPrice - sl) / tickSize);
                    double lot = strategy.InpRiskModeOn
                        ? strategy.RiskManager.CalcLotSize(strategy.InpRiskPercent, slPointsCalculated)
                        : strategy.RiskManager.NormalizeLot(strategy.InpFixLot);

                    if (lot > 0)
                    {
                        this.LastOrderTag = $"{Comment}_{strategy.MagicNumber}_{new Random().Next(1000, 9999)}";

                        var request = new PlaceOrderRequestParameters
                        {
                            Account = strategy.CurrentAccount,
                            Symbol = strategy.CurrentSymbol,
                            Side = Side.Sell,
                            OrderTypeId = OrderType.Stop,
                            Quantity = lot,
                            Price = entryPrice,
                            TriggerPrice = entryPrice,
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
                            this.EntryReason = $"Down breakout retest confirmed on custom timeframe";
                            strategy.Log($"[{Comment}] SELL PENDING PLACED: Entry={entryPrice}, SL={sl}, TP={tp}, Lot={lot}");
                        }
                        else
                        {
                            strategy.Log($"[{Comment}] SELL PLACEMENT FAILED: {result.Message}", StrategyLoggingLevel.Error);
                        }
                    }
                }
            }
        }

        private void SyncOrderAndPositionStatus()
        {
            if (string.IsNullOrEmpty(this.LastOrderTag)) return;

            bool activeOrderExists = Core.Instance.Orders.Any(o => o.Comment == this.LastOrderTag && (o.Status == OrderStatus.Opened || o.Status == OrderStatus.PartiallyFilled));
            bool activePosExists = Core.Instance.Positions.Any(p => p.Symbol == strategy.CurrentSymbol && p.Comment == this.LastOrderTag);

            if (activePosExists)
            {
                this.OrdersActive = true;
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
                    this.OrdersActive = false;
                    this.LastOrderTag = "";

                    // Calculate stats by tracking account updates
                    UpdateWinLossCounter();

                    bool limitHit = (strategy.InpMaxSuccessOn && strategy.GetWinsToday(TfIndex) >= strategy.InpMaxSuccess)
                                 || (strategy.InpMaxLossOn   && strategy.GetLossesToday(TfIndex) >= strategy.InpMaxLoss);
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
            if (strategy.InpUnfilledCandlesOn && hasPending && !hasPosition && this.PlacedTime > DateTime.MinValue)
            {
                int barsPassed = CalculateBarsShift(this.PlacedTime);
                if (barsPassed >= strategy.InpUnfilledCandles)
                {
                    shouldFlatten = true;
                    reason = $"Unfilled candles threshold hit ({barsPassed} >= {strategy.InpUnfilledCandles})";
                }
            }

            // 1.b After filled minutes check (close positions after X minutes)
            if (!shouldFlatten && strategy.InpAfterFilledMinutesOn && hasPosition)
            {
                var oldestPos = activePositions.OrderBy(x => x.OpenTime).FirstOrDefault();
                if (oldestPos != null && serverTime >= oldestPos.OpenTime.AddMinutes(strategy.InpAfterFilledMinutes))
                {
                    shouldFlatten = true;
                    reason = $"No TP hit after {strategy.InpAfterFilledMinutes} minutes";
                }
            }

            // 2. Max session minutes passed check
            if (!shouldFlatten && strategy.InpAfterMinutesOn && nyoTime > DateTime.MinValue)
            {
                if (serverTime >= nyoTime.AddMinutes(strategy.InpAfterMinutes))
                {
                    shouldFlatten = true;
                    reason = $"Trading session active window closed ({strategy.InpAfterMinutes} min)";
                }
            }

            // 3. Price boundary validations (Touch Mid & Unfavor Moves)
            double tickSize = strategy.CurrentSymbol.TickSize;
            double midPrice = (this.RangeHigh + this.RangeLow) / 2.0;
            double bid = strategy.CurrentSymbol.Bid;
            double ask = strategy.CurrentSymbol.Ask;

            if (!shouldFlatten && (strategy.InpTouchMidOn || strategy.InpUnfavorMoveOn))
            {
                // Check pending orders bounds
                foreach (var order in activeOrders)
                {
                    double open = order.Price;
                    if (order.Side == Side.Buy)
                    {
                        if (strategy.InpUnfavorMoveOn && bid <= open - strategy.InpUnfavorMovePts * tickSize)
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
                        if (strategy.InpUnfavorMoveOn && ask >= open + strategy.InpUnfavorMovePts * tickSize)
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
                            if (strategy.InpUnfavorMoveOn && bid <= open - strategy.InpUnfavorMovePts * tickSize)
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
                            if (strategy.InpUnfavorMoveOn && ask >= open + strategy.InpUnfavorMovePts * tickSize)
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

            // 4. Indicator EMA cancel/flatten validations
            if (!shouldFlatten)
            {
                string filterReason = "";
                foreach (var order in activeOrders)
                {
                    int dir = order.Side == Side.Buy ? 1 : -1;
                    if (!CheckEmaFilters(dir, out filterReason, false))
                    {
                        shouldFlatten = true;
                        reason = filterReason;
                        break;
                    }
                }

                if (!shouldFlatten)
                {
                    foreach (var pos in activePositions)
                    {
                        int dir = pos.Side == Side.Buy ? 1 : -1;
                        if (!CheckEmaFilters(dir, out filterReason, false))
                        {
                            shouldFlatten = true;
                            reason = filterReason;
                            break;
                        }
                    }
                }
            }

            if (shouldFlatten)
            {
                strategy.Log($"[{Comment}] Auto-Flatten Triggered: {reason}. Flattening tag: {LastOrderTag}");
                this.CancelReason = reason;
                FlattenAll();

                bool sessionClosed = strategy.InpAfterMinutesOn && serverTime >= nyoTime.AddMinutes(strategy.InpAfterMinutes);
                if (sessionClosed)
                {
                    this.State = ORBState.ORB_STOPPED;
                }
                else
                {
                    bool limitHit = (strategy.InpMaxSuccessOn && strategy.GetWinsToday(TfIndex) >= strategy.InpMaxSuccess)
                                 || (strategy.InpMaxLossOn   && strategy.GetLossesToday(TfIndex) >= strategy.InpMaxLoss);
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
                Core.Instance.CancelOrder(order);
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
                if (this.History[i].TimeLeft >= placeTime)
                    count++;
                else
                    break;
            }
            return count;
        }

        public bool CheckEmaFilters(int direction, out string outReason, bool isEntry)
        {
            outReason = "";
            double currentPrice = direction == 1 ? strategy.CurrentSymbol.Bid : strategy.CurrentSymbol.Ask;

            bool[] emaOn = new bool[3];
            int[] emaPeriod = new int[3];
            string label;

            if (isEntry)
            {
                emaOn[0] = strategy.InpFavorEma1On; emaPeriod[0] = strategy.InpFavorEma1Period;
                emaOn[1] = strategy.InpFavorEma2On; emaPeriod[1] = strategy.InpFavorEma2Period;
                emaOn[2] = strategy.InpFavorEma3On; emaPeriod[2] = strategy.InpFavorEma3Period;
                label = "Favor EMA";
            }
            else
            {
                emaOn[0] = strategy.InpEma1On; emaPeriod[0] = strategy.InpEma1Period;
                emaOn[1] = strategy.InpEma2On; emaPeriod[1] = strategy.InpEma2Period;
                emaOn[2] = strategy.InpEma3On; emaPeriod[2] = strategy.InpEma3Period;
                label = "Price < EMA";
            }

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
            if (this.History == null || this.History.Count < period || targetIdx < 0 || targetIdx >= this.History.Count)
                return 0;

            double multiplier = 2.0 / (period + 1);

            // Starting SMA seed
            double sum = 0;
            int startIdx = targetIdx - period + 1;
            if (startIdx < 0) return 0;

            for (int i = 0; i < period; i++)
            {
                sum += ((HistoryItemBar)this.History[startIdx + i]).Close;
            }
            double ema = sum / period;

            // Recurse to find precise EMA at the target index
            for (int i = startIdx + period; i <= targetIdx; i++)
            {
                double close = ((HistoryItemBar)this.History[i]).Close;
                ema = (close - ema) * multiplier + ema;
            }

            return ema;
        }

        public double CalculateVWAP(HistoricalData historyStream, DateTime startDay)
        {
            if (historyStream == null || historyStream.Count == 0) return 0;

            double sumPV = 0;
            double sumV = 0;

            for (int i = historyStream.Count - 1; i >= 0; i--)
            {
                var bar = (HistoryItemBar)historyStream[i];
                if (bar.TimeLeft < startDay) break;

                double typicalPrice = (bar.High + bar.Low + bar.Close) / 3.0;
                double vol = bar.Volume;
                sumPV += typicalPrice * vol;
                sumV += vol;
            }

            return sumV > 0 ? sumPV / sumV : 0;
        }

        public double GetPrevDayEMA(int period)
        {
            var dailyHistory = strategy.GetDailyHistory();
            if (dailyHistory == null || dailyHistory.Count < period) return 0;

            double multiplier = 2.0 / (period + 1);
            int targetIdx = dailyHistory.Count - 2; // last closed daily bar

            double sum = 0;
            int startIdx = targetIdx - period + 1;
            if (startIdx < 0) return 0;

            for (int i = 0; i < period; i++)
            {
                sum += ((HistoryItemBar)dailyHistory[startIdx + i]).Close;
            }
            double ema = sum / period;

            for (int i = startIdx + period; i <= targetIdx; i++)
            {
                double close = ((HistoryItemBar)dailyHistory[i]).Close;
                ema = (close - ema) * multiplier + ema;
            }

            return ema;
        }

        private bool CheckObstacles(double entryPrice, DateTime nyoTime, out string outReason)
        {
            outReason = "";
            double tickSize = strategy.CurrentSymbol.TickSize;

            // 1. Range 5m Obstacle
            if (strategy.InpObsRange5mOn && TfIndex != 1)
            {
                double rHigh = 0, rLow = 0;
                if (GetOtherTimeframeRange(Period.MIN5, nyoTime, out rHigh, out rLow))
                {
                    if (Math.Abs(entryPrice - rHigh) / tickSize < strategy.InpObsMaxDist ||
                        Math.Abs(entryPrice - rLow) / tickSize < strategy.InpObsMaxDist)
                    {
                        outReason = "5m Range boundary obstacle";
                        return true;
                    }
                }
            }

            // 2. Range 15m Obstacle
            if (strategy.InpObsRange15mOn && TfIndex != 2)
            {
                double rHigh = 0, rLow = 0;
                if (GetOtherTimeframeRange(Period.MIN15, nyoTime, out rHigh, out rLow))
                {
                    if (Math.Abs(entryPrice - rHigh) / tickSize < strategy.InpObsMaxDist ||
                        Math.Abs(entryPrice - rLow) / tickSize < strategy.InpObsMaxDist)
                    {
                        outReason = "15m Range boundary obstacle";
                        return true;
                    }
                }
            }

            // 2.b Range 30m Obstacle
            if (strategy.InpObsRange30mOn && TfIndex != 3)
            {
                double rHigh = 0, rLow = 0;
                if (GetOtherTimeframeRange(Period.MIN30, nyoTime, out rHigh, out rLow))
                {
                    if (Math.Abs(entryPrice - rHigh) / tickSize < strategy.InpObsMaxDist ||
                        Math.Abs(entryPrice - rLow) / tickSize < strategy.InpObsMaxDist)
                    {
                        outReason = "30m Range boundary obstacle";
                        return true;
                    }
                }
            }

            // Previous Day High/Low Obstacle
            if (strategy.InpObsPrevDayHLOn)
            {
                var dailyHistory = strategy.GetDailyHistory();
                if (dailyHistory != null && dailyHistory.Count >= 2)
                {
                    var prevDayBar = (HistoryItemBar)dailyHistory[dailyHistory.Count - 2];
                    double prevHigh = prevDayBar.High;
                    double prevLow = prevDayBar.Low;

                    if (Math.Abs(entryPrice - prevHigh) / tickSize < strategy.InpObsMaxDist)
                    {
                        outReason = $"Prev Day High obstacle (Dist={Math.Abs(entryPrice - prevHigh) / tickSize} pts)";
                        return true;
                    }
                    if (Math.Abs(entryPrice - prevLow) / tickSize < strategy.InpObsMaxDist)
                    {
                        outReason = $"Prev Day Low obstacle (Dist={Math.Abs(entryPrice - prevLow) / tickSize} pts)";
                        return true;
                    }
                }
            }

            // M2 EMAs Obstacle
            if (strategy.InpObsEma1On && strategy.InpObsEma1Period > 0)
            {
                double emaVal = CalculateEMA(strategy.InpObsEma1Period, this.History.Count - 2);
                if (emaVal > 0 && Math.Abs(entryPrice - emaVal) / tickSize < strategy.InpObsMaxDist)
                {
                    outReason = $"M2 EMA {strategy.InpObsEma1Period} obstacle";
                    return true;
                }
            }

            if (strategy.InpObsEma2On && strategy.InpObsEma2Period > 0)
            {
                double emaVal = CalculateEMA(strategy.InpObsEma2Period, this.History.Count - 2);
                if (emaVal > 0 && Math.Abs(entryPrice - emaVal) / tickSize < strategy.InpObsMaxDist)
                {
                    outReason = $"M2 EMA {strategy.InpObsEma2Period} obstacle";
                    return true;
                }
            }

            if (strategy.InpObsEma3On && strategy.InpObsEma3Period > 0)
            {
                double emaVal = CalculateEMA(strategy.InpObsEma3Period, this.History.Count - 2);
                if (emaVal > 0 && Math.Abs(entryPrice - emaVal) / tickSize < strategy.InpObsMaxDist)
                {
                    outReason = $"M2 EMA {strategy.InpObsEma3Period} obstacle";
                    return true;
                }
            }

            // Day / Week VWAP Obstacles
            DateTime startDay = strategy.TimeManager.GetServerTime().Date;
            if (strategy.InpObsDayVwapOn)
            {
                double dVwapVal = CalculateVWAP(strategy.GetM1History(), startDay);
                if (dVwapVal > 0 && Math.Abs(entryPrice - dVwapVal) / tickSize < strategy.InpObsMaxDist)
                {
                    outReason = "Day VWAP obstacle";
                    return true;
                }
            }

            if (strategy.InpObsWeekVwapOn)
            {
                DateTime nowServer = strategy.TimeManager.GetServerTime();
                int diff = (7 + (nowServer.DayOfWeek - DayOfWeek.Monday)) % 7;
                DateTime startWeek = nowServer.AddDays(-diff).Date;

                double wVwapVal = CalculateVWAP(strategy.GetM1History(), startWeek);
                if (wVwapVal > 0 && Math.Abs(entryPrice - wVwapVal) / tickSize < strategy.InpObsMaxDist)
                {
                    outReason = "Week VWAP obstacle";
                    return true;
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
                .Cast<HistoryItemBar>()
                .ToList();

            if (bars.Count < minutes) return false;

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

    //+------------------------------------------------------------------+
    //| TimeManager — handles NY timezone conversion                     |
    //+------------------------------------------------------------------+
    public class TimeManager
    {
        private DateTime targetTimeServer = DateTime.MinValue;
        private int lastCalculatedDay = -1;

        public DateTime GetServerTime()
        {
            var conn = Core.Instance.Connections.Connected.FirstOrDefault();
            if (conn != null)
                return conn.ServerTime;
            return Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(DateTime.UtcNow);
        }

        public DateTime GetTargetTime() => targetTimeServer;

        public void UpdateTargetTime(int nyHour, int nyMin, int nySec, int utcOffset)
        {
            DateTime serverNow = GetServerTime();
            if (serverNow.Day == lastCalculatedDay && targetTimeServer > DateTime.MinValue) return;

            // Target NY time in UTC: NY = UTC + offset -> UTC = NY - offset
            // utcOffset is negative for NY (e.g. -4), so subtracting negative adds offset hours
            int utcHour = nyHour - utcOffset;
            int dayAdjust = 0;

            if (utcHour >= 24) { utcHour -= 24; dayAdjust = 1; }
            if (utcHour < 0) { utcHour += 24; dayAdjust = -1; }

            DateTime utcNow = DateTime.UtcNow;
            DateTime targetUtc = new DateTime(
                utcNow.Year, utcNow.Month, utcNow.Day,
                utcHour, nyMin, nySec, DateTimeKind.Utc
            ).AddDays(dayAdjust);

            // Server target time = Target UTC time + server-to-UTC offset
            TimeSpan serverToUtcOffset = serverNow - DateTime.UtcNow;
            targetTimeServer = targetUtc + serverToUtcOffset;
            lastCalculatedDay = serverNow.Day;
        }
    }

    //+------------------------------------------------------------------+
    //| RiskManager — sizer sizer                                       |
    //+------------------------------------------------------------------+
    public class RiskManager
    {
        private readonly KatOpeningRangeBreakout strategy;

        public RiskManager(KatOpeningRangeBreakout strategy)
        {
            this.strategy = strategy;
        }

        public double CalcLotSize(double riskPercent, int slPoints)
        {
            if (riskPercent <= 0 || slPoints <= 0) return NormalizeLot(strategy.InpFixLot);

            double balance = strategy.CurrentAccount.Balance;
            double riskAmt = balance * (riskPercent / 100.0);

            // Fetch TickValue and TickSize directly from current symbol
            double tickValue = strategy.CurrentSymbol.TickSize * strategy.CurrentSymbol.LotSize;
            double tickSize = strategy.CurrentSymbol.TickSize;

            if (tickValue <= 0 || tickSize <= 0) return NormalizeLot(strategy.InpFixLot);

            // Dynamic loss per lot size
            double valuePerPoint = tickValue / tickSize * tickSize;
            double lossPerLot = slPoints * valuePerPoint;

            if (lossPerLot <= 0) return NormalizeLot(strategy.InpFixLot);

            double lot = riskAmt / lossPerLot;
            return NormalizeLot(lot);
        }

        public double NormalizeLot(double lot)
        {
            double min = strategy.CurrentSymbol.MinLot;
            double max = strategy.CurrentSymbol.MaxLot;
            double step = strategy.CurrentSymbol.LotStep;

            if (step <= 0) step = 0.01;

            double normalized = Math.Floor(lot / step + 0.000000001) * step;
            normalized = Math.Max(min, Math.Min(max, normalized));

            return Math.Round(normalized, 2);
        }
    }

    //+------------------------------------------------------------------+
    //| PositionAggregator — average statistics aggregator               |
    //+------------------------------------------------------------------+
    public class PositionAggregate
    {
        public double TotalQuantity { get; set; } = 0;
        public double WeightedEntry { get; set; } = 0;
        public double BuyQuantity { get; set; } = 0;
        public double SellQuantity { get; set; } = 0;
        public int TicketCount { get; set; } = 0;
        public Side DominantSide { get; set; } = Side.Buy;
        public List<Position> Positions { get; } = new List<Position>();
    }

    public static class PositionAggregator
    {
        public static void Collect(Symbol symbol, int magic, string strategyTagPrefix, PositionAggregate aggregate)
        {
            aggregate.TotalQuantity = 0;
            aggregate.WeightedEntry = 0;
            aggregate.BuyQuantity = 0;
            aggregate.SellQuantity = 0;
            aggregate.TicketCount = 0;
            aggregate.Positions.Clear();

            // Filters active positions matching Symbol and Strategy Comment Tag
            var matching = Core.Instance.Positions
                .Where(p => p.Symbol == symbol && !string.IsNullOrEmpty(p.Comment) && p.Comment.StartsWith(strategyTagPrefix))
                .ToList();

            foreach (var pos in matching)
            {
                double qty = pos.Quantity;
                double price = pos.OpenPrice;

                if (pos.Side == Side.Buy)
                    aggregate.BuyQuantity += qty;
                else
                    aggregate.SellQuantity += qty;

                aggregate.TotalQuantity += qty;
                aggregate.WeightedEntry += price * qty;
                aggregate.TicketCount++;
                aggregate.Positions.Add(pos);
            }

            if (aggregate.TotalQuantity > 0)
            {
                aggregate.WeightedEntry /= aggregate.TotalQuantity;
                aggregate.DominantSide = aggregate.BuyQuantity >= aggregate.SellQuantity ? Side.Buy : Side.Sell;
            }
        }
    }

    //+------------------------------------------------------------------+
    //| TrailManager — handles trailing stop and breakeven              |
    //+------------------------------------------------------------------+
    public class TrailManager
    {
        private readonly KatOpeningRangeBreakout strategy;

        public TrailManager(KatOpeningRangeBreakout strategy)
        {
            this.strategy = strategy;
        }

        public void Process(ORBRunner runner)
        {
            if (strategy.InpTrailMode == 0 && !strategy.InpBeEnabled) return;
            if (string.IsNullOrEmpty(runner.LastOrderTag)) return;

            double tickSize = strategy.CurrentSymbol.TickSize;

            // 1. Process Global Volume-Weighted Average Breakeven
            if (strategy.InpBeEnabled)
            {
                var aggregate = new PositionAggregate();
                PositionAggregator.Collect(strategy.CurrentSymbol, strategy.MagicNumber, runner.Comment, aggregate);

                if (aggregate.TotalQuantity > 0 && aggregate.TicketCount > 0)
                {
                    double activateDist = strategy.InpBeActivatePts * tickSize;
                    double lockDist = strategy.InpBeLockPts * tickSize;
                    double avgEntry = aggregate.WeightedEntry;
                    bool triggered = false;

                    double bid = strategy.CurrentSymbol.Bid;
                    double ask = strategy.CurrentSymbol.Ask;

                    if (aggregate.DominantSide == Side.Buy)
                        triggered = (bid - avgEntry >= activateDist);
                    else
                        triggered = (avgEntry - ask >= activateDist);

                    if (triggered)
                    {
                        double newSL = aggregate.DominantSide == Side.Buy
                            ? (avgEntry + lockDist)
                            : (avgEntry - lockDist);

                        newSL = Math.Round(newSL / tickSize) * tickSize;
                        ApplyAggregateSL(aggregate, newSL);
                    }
                }
            }

            // 2. Process Trail Stop modifiers on active positions
            var matchingPositions = Core.Instance.Positions
                .Where(p => p.Symbol == strategy.CurrentSymbol && p.Comment == runner.LastOrderTag)
                .ToList();

            foreach (var pos in matchingPositions)
            {
                if (strategy.InpTrailMode == 1) // Chase Trail Stop
                {
                    ManageChaseTrailing(pos, strategy.InpTrailTrigger, strategy.InpTrailDistance, strategy.InpTrailStep);
                }
                else if (strategy.InpTrailMode >= 2 && strategy.InpTrailMode <= 4) // Candle extreme trail shifts
                {
                    int shift = strategy.InpTrailMode - 1; // Candle1 = shift 1, Candle2 = shift 2, etc.
                    ManageCandleTrailing(pos, runner.History, shift);
                }
            }
        }

        private void ApplyAggregateSL(PositionAggregate aggregate, double newSL)
        {
            double tickSize = strategy.CurrentSymbol.TickSize;
            foreach (var pos in aggregate.Positions)
            {
                var slOrder = pos.StopLoss;
                double slPrice = slOrder != null ? slOrder.TriggerPrice : 0;

                bool shouldMove = false;
                if (pos.Side == Side.Buy)
                    shouldMove = (newSL > slPrice || slPrice == 0);
                else
                    shouldMove = (newSL < slPrice || slPrice == 0);

                if (shouldMove && Math.Abs(slPrice - newSL) > tickSize)
                {
                    var res = Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, slOrder.TotalQuantity, newSL, newSL, slOrder.TrailOffset);
                    if (res.Status == TradingOperationResultStatus.Failure)
                    {
                        strategy.Log($"[{aggregate.DominantSide} BE Modify failed on position {pos.Id}]: {res.Message}", StrategyLoggingLevel.Error);
                    }
                }
            }
        }

        private void ManageChaseTrailing(Position pos, int triggerPts, int distancePts, int stepPts)
        {
            var slOrder = pos.StopLoss;
            double slPrice = slOrder != null ? slOrder.TriggerPrice : 0;
            double tickSize = strategy.CurrentSymbol.TickSize;

            double triggerDist = triggerPts * tickSize;
            double trailDist = distancePts * tickSize;
            double stepDist = stepPts * tickSize;

            double open = pos.OpenPrice;

            if (pos.Side == Side.Buy)
            {
                double bid = strategy.CurrentSymbol.Bid;
                if (bid - open < triggerDist) return;

                double newSL = bid - trailDist;
                newSL = Math.Round(newSL / tickSize) * tickSize;

                if (newSL > slPrice || slPrice == 0)
                {
                    if (slPrice == 0 || (newSL - slPrice) >= stepDist)
                    {
                        Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, slOrder.TotalQuantity, newSL, newSL, slOrder.TrailOffset);
                    }
                }
            }
            else if (pos.Side == Side.Sell)
            {
                double ask = strategy.CurrentSymbol.Ask;
                if (open - ask < triggerDist) return;

                double newSL = ask + trailDist;
                newSL = Math.Round(newSL / tickSize) * tickSize;

                if (newSL < slPrice || slPrice == 0)
                {
                    if (slPrice == 0 || (slPrice - newSL) >= stepDist)
                    {
                        Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, slOrder.TotalQuantity, newSL, newSL, slOrder.TrailOffset);
                    }
                }
            }
        }

        private void ManageCandleTrailing(Position pos, HistoricalData historyStream, int shift)
        {
            if (historyStream == null || historyStream.Count < shift + 2) return;

            var slOrder = pos.StopLoss;
            double slPrice = slOrder != null ? slOrder.TriggerPrice : 0;
            double tickSize = strategy.CurrentSymbol.TickSize;

            // shift 1 = historyStream[historyStream.Count - 2]
            var targetBar = (HistoryItemBar)historyStream[historyStream.Count - 1 - shift];

            if (pos.Side == Side.Buy)
            {
                double newSL = targetBar.Low - tickSize;
                newSL = Math.Round(newSL / tickSize) * tickSize;

                if (newSL > slPrice || slPrice == 0)
                {
                    if (Math.Abs(newSL - slPrice) > tickSize)
                    {
                        Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, slOrder.TotalQuantity, newSL, newSL, slOrder.TrailOffset);
                    }
                }
            }
            else if (pos.Side == Side.Sell)
            {
                double newSL = targetBar.High + tickSize;
                newSL = Math.Round(newSL / tickSize) * tickSize;

                if (newSL < slPrice || slPrice == 0)
                {
                    if (Math.Abs(slPrice - newSL) > tickSize)
                    {
                        Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, slOrder.TotalQuantity, newSL, newSL, slOrder.TrailOffset);
                    }
                }
            }
        }
    }
}
