using System;
using System.Collections.Generic;
using System.Linq;
using System.ComponentModel;
using TradingPlatform.BusinessLayer;

namespace KatORB
{
    public class KatOpeningRangeBreakout : Strategy
    {
        [Category("1. GENERAL & SCHEDULE")]
        [InputParameter("Symbol", 1)]
        public Symbol CurrentSymbol { get; set; }

        [Category("1. GENERAL & SCHEDULE")]
        [InputParameter("Account", 2)]
        public Account CurrentAccount { get; set; }

        [Category("1. GENERAL & SCHEDULE")]
        [InputParameter("Magic Number", 10)]
        public int InpMagicNumber = 1618;

        [Category("1. GENERAL & SCHEDULE")]
        [InputParameter("Broker UTC Offset", 30)]
        public int InpUtcOffset = -4; // NY standard daylight offset

        private const int InpNyHour = 9;
        private const int InpNyMinute = 30;
        private const int InpNySecond = 0;

        //--- Timeframe Toggles
        [Category("2. TIMEFRAMES")]
        [InputParameter("Run 2m", 40)]
        public bool Inp2mActive = true;
        
        [Category("2. TIMEFRAMES")]
        [InputParameter("Run 5m", 50)]
        public bool Inp5mActive = true;

        [Category("2. TIMEFRAMES")]
        [InputParameter("Run 15m", 60)]
        public bool Inp15mActive = false;

        [Category("2. TIMEFRAMES")]
        [InputParameter("Run 30m", 70)]
        public bool Inp30mActive = false;

        [Category("2. TIMEFRAMES")]
        [InputParameter("Retest TF candle min", 90)]
        public int InpCustomRetestMin = 1;

        //--- Order Settings
        [Category("3. ORDER SETTINGS")]
        [InputParameter("Stop Loss", 100)]
        public int InpSlTicks = 60;

        [Category("3. ORDER SETTINGS")]
        [InputParameter("Take Profit", 110)]
        public int InpTpTicks = 600;

        public bool InpContAfter1st = true;

        //--- Risk & Contracts
        [Category("4. RISK & CONTRACTS")]
        [InputParameter("Contract", 160)]
        public int InpFixContract = 1;

        //--- Safeguards & Limits
        [Category("5. SAFEGUARDS & LIMITS")]
        [InputParameter("Max Wins", 180)]
        public int InpMaxSuccess = 2;

        [Category("5. SAFEGUARDS & LIMITS")]
        [InputParameter("Max Losses", 200)]
        public int InpMaxLoss = 1;

        [Category("5. SAFEGUARDS & LIMITS")]
        [InputParameter("Max Boundary Distance", 220)]
        public int InpMaxDistRange = 240;

        //--- Trailing Settings
        public int InpTrailMode = 1; // 1 = TM_CHASE
        
        [Category("6. TRAILING STOPLOSS")]
        [InputParameter("Trail Trigger", 240)]
        public int InpTrailTrigger = 60;

        [Category("6. TRAILING STOPLOSS")]
        [InputParameter("Trail Distance", 250)]
        public int InpTrailDistance = 20;

        public const int InpTrailStep = 1;

        //--- Auto-Flatten Conditions
        [Category("7. FLATTEN & CANCEL")]
        [InputParameter("Cancel pending if unfilled (candle)", 280)]
        public int InpUnfilledCandles = 2;

        public bool InpAfterFilledMinutesOn = true;

        [Category("7. FLATTEN & CANCEL")]
        [InputParameter("Flatten if not hit Trigger, after min", 300)]
        public int InpAfterFilledMinutes = 5;

        [Category("7. FLATTEN & CANCEL")]
        [InputParameter("Stop trading after min", 320)]
        public int InpAfterMinutes = 60;

        [Category("7. FLATTEN & CANCEL")]
        [InputParameter("Flatten on Bad Move", 340)]
        public int InpUnfavorMoveTicks = 320;

        [Category("7. FLATTEN & CANCEL")]
        [InputParameter("Flatten on Mid Touch", 350)]
        public bool InpTouchMidOn = true;

        //--- Favor EMA Trend Filters
        [Category("8. EMA TREND FILTERS")]
        [InputParameter("Favor EMA 9 (Entry)", 360)]
        public bool InpFavorEma9On = false;

        [Category("8. EMA TREND FILTERS")]
        [InputParameter("Favor EMA 21 (Entry)", 370)]
        public bool InpFavorEma21On = false;

        [Category("8. EMA TREND FILTERS")]
        [InputParameter("Favor EMA 34 (Entry)", 380)]
        public bool InpFavorEma34On = false;

        //--- Obstacles Settings
        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("Max Obstacle Distance", 420)]
        public int InpObsMaxDist = 64;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To 5m H/L", 430)]
        public bool InpObsRange5mOn = true;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To 15m H/L", 440)]
        public bool InpObsRange15mOn = true;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To 30m H/L", 450)]
        public bool InpObsRange30mOn = true;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To Prev Day H/L", 460)]
        public bool InpObsPrevDayHLOn = true;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To VWAP (day) line", 470)]
        public bool InpObsDayVwapOn = true;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To VWAP (week) line", 480)]
        public bool InpObsWeekVwapOn = true;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To EMA 250 line", 490)]
        public bool InpObsEma250On = true;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To EMA 255 line", 500)]
        public bool InpObsEma255On = true;

        [Category("9. OBSTACLE FILTERS")]
        [InputParameter("To EMA 34 line", 510)]
        public bool InpObsEma34On = true;

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

        public const string STRATEGY_VERSION = "1.0";

        public int MagicNumber => InpMagicNumber;

        public new void Log(string message, StrategyLoggingLevel level = StrategyLoggingLevel.Info)
        {
            base.Log(message, level);
        }

        public KatOpeningRangeBreakout()
        {
            this.Name = $"kat-ORB {STRATEGY_VERSION}";
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
            DateTime loadFrom = Core.Instance.TimeUtils.DateTimeUtcNow.AddDays(-5);
            this.historicalDataM1 = this.CurrentSymbol.GetHistory(Period.MIN1, loadFrom);
            this.historicalDataM2 = this.CurrentSymbol.GetHistory(Period.MIN2, loadFrom);
            this.historicalDataM5 = this.CurrentSymbol.GetHistory(Period.MIN5, loadFrom);
            this.historicalDataM15 = this.CurrentSymbol.GetHistory(Period.MIN15, loadFrom);
            this.historicalDataM30 = this.CurrentSymbol.GetHistory(Period.MIN30, loadFrom);
            this.dailyHistory = this.CurrentSymbol.GetHistory(Period.DAY1, loadFrom);

            // Subscribe to the custom retest timeframe (always active)
            Period retestPeriod = MapMinutesToPeriod(InpCustomRetestMin);
            this.historicalDataRetest = this.CurrentSymbol.GetHistory(retestPeriod, loadFrom);

            //--- Initialize the runners for active timeframes
            this.runners.Clear();
            if (Inp2mActive)  this.runners.Add(new ORBRunner(this, Period.MIN2, 0, "orb-2m", this.historicalDataM2));
            if (Inp5mActive)  this.runners.Add(new ORBRunner(this, Period.MIN5, 1, "orb-5m", this.historicalDataM5));
            if (Inp15mActive) this.runners.Add(new ORBRunner(this, Period.MIN15, 2, "orb-15m", this.historicalDataM15));
            if (Inp30mActive) this.runners.Add(new ORBRunner(this, Period.MIN30, 3, "orb-30m", this.historicalDataM30));

            this.Log($"kat-ORB {STRATEGY_VERSION} Initialized. Active Runners count: {this.runners.Count}");

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
        public HistoricalData GetM2History() => this.historicalDataM2;
        public HistoricalData GetDailyHistory() => this.dailyHistory;
        public HistoricalData? GetRetestHistory() => this.historicalDataRetest;

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
        public bool TrailTriggerHit { get; set; } = false;

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
            this.TrailTriggerHit = false;
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
                    var targetBar = this.History.Cast<HistoryItemBar>().FirstOrDefault(b => b.TimeLeft == nyoTime);
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
                if (m1History == null || m1History.Count == 0) return;

                int expectedBars = tfSeconds / 60;
                var rangeBars = m1History
                    .Where(b => b.TimeLeft >= nyoTime && b.TimeLeft < nyoTime.AddSeconds(tfSeconds))
                    .Cast<HistoryItemBar>()
                    .ToList();

                if (rangeBars.Count > 0)
                {
                    // Cho phép tạo Range nếu đã qua thời gian tạo nến hoặc đủ số nến
                    if (serverTime >= nyoTime.AddSeconds(tfSeconds + 10) || rangeBars.Count >= expectedBars)
                    {
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
            var retestHistory = strategy.GetRetestHistory();
            if (retestHistory == null || retestHistory.Count < 2) return;

            // Retrieve last closed bar on retest timeframe
            var lastClosedBar = (HistoryItemBar)retestHistory[retestHistory.Count - 2];
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
                    double sl = entryPrice - strategy.InpSlTicks * tickSize;
                    double tp = strategy.InpTpTicks > 0 ? (entryPrice + strategy.InpTpTicks * tickSize) : 0;
                    sl = Math.Round(sl / tickSize) * tickSize;
                    tp = Math.Round(tp / tickSize) * tickSize;

                    double lot = strategy.RiskManager.NormalizeLot(strategy.InpFixContract);

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
            else if (this.BreakDir == -1)
            {
                double midPrice = (this.RangeHigh + this.RangeLow) / 2.0;
                // Opposite color candle (bullish: close > open) touching or penetrating the broken low range
                // and the candle high must not penetrate above the range mid-point
                if (closePrice > openPrice && highPrice >= this.RangeLow && highPrice <= midPrice)
                {
                    double entryPrice = lowPrice - (buffer * tickSize);
                    entryPrice = Math.Round(entryPrice / tickSize) * tickSize;

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

                    // Risk Sizing
                    double sl = entryPrice + strategy.InpSlTicks * tickSize;
                    double tp = strategy.InpTpTicks > 0 ? (entryPrice - strategy.InpTpTicks * tickSize) : 0;
                    sl = Math.Round(sl / tickSize) * tickSize;
                    tp = Math.Round(tp / tickSize) * tickSize;

                    double lot = strategy.RiskManager.NormalizeLot(strategy.InpFixContract);

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
                    this.TrailTriggerHit = false;

                    // Calculate stats by tracking account updates
                    UpdateWinLossCounter();

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
                if (oldestPos != null && serverTime >= oldestPos.OpenTime.AddMinutes(strategy.InpAfterFilledMinutes))
                {
                    if (!this.TrailTriggerHit)
                    {
                        shouldFlatten = true;
                        reason = $"Trigger not hit after {strategy.InpAfterFilledMinutes} minutes";
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

            double multiplier = 2.0 / (period + 1);

            // Starting SMA seed (average of the first 'period' bars: index 0 to period - 1)
            double sum = 0;
            for (int i = 0; i < period; i++)
            {
                sum += ((HistoryItemBar)historyStream[i]).Close;
            }
            double ema = sum / period;

            // Recurse from index 'period' to targetIdx to get fully smoothed EMA
            for (int i = period; i <= targetIdx; i++)
            {
                double close = ((HistoryItemBar)historyStream[i]).Close;
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

            int targetIdx = dailyHistory.Count - 2; // last closed daily bar
            if (targetIdx < period - 1) return 0;

            double multiplier = 2.0 / (period + 1);

            // Starting SMA seed (average of the first 'period' bars: index 0 to period - 1)
            double sum = 0;
            for (int i = 0; i < period; i++)
            {
                sum += ((HistoryItemBar)dailyHistory[i]).Close;
            }
            double ema = sum / period;

            // Recurse to targetIdx to get fully smoothed EMA
            for (int i = period; i <= targetIdx; i++)
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
                if (dailyHistory != null && dailyHistory.Count >= 2)
                {
                    var prevDayBar = (HistoryItemBar)dailyHistory[dailyHistory.Count - 2];
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
                .Cast<HistoryItemBar>()
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
            return Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(Core.Instance.TimeUtils.DateTimeUtcNow);
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

            // Tạo targetUtc sử dụng năm/tháng/ngày của serverNow để không bị lệch múi giờ
            DateTime targetUtc = new DateTime(
                serverNow.Year, serverNow.Month, serverNow.Day,
                utcHour, nyMin, nySec, DateTimeKind.Utc
            ).AddDays(dayAdjust);

            // Chuyển đổi trực tiếp thông qua Quantower API mà không cần tự tính offset
            targetTimeServer = Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(targetUtc);
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

        public double CalcLotSize(double riskPercent, int slTicks)
        {
            if (riskPercent <= 0 || slTicks <= 0) return NormalizeLot(strategy.InpFixContract);

            double balance = strategy.CurrentAccount.Balance;
            double riskAmt = balance * (riskPercent / 100.0);

            // Fetch TickValue and TickSize directly from current symbol
            double tickValue = strategy.CurrentSymbol.TickSize * strategy.CurrentSymbol.LotSize;
            double tickSize = strategy.CurrentSymbol.TickSize;

            if (tickValue <= 0 || tickSize <= 0) return NormalizeLot(strategy.InpFixContract);

            // Dynamic loss per lot size
            double lossPerLot = slTicks * tickValue;

            if (lossPerLot <= 0) return NormalizeLot(strategy.InpFixContract);

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
            if (strategy.InpTrailMode != 1) return;
            if (string.IsNullOrEmpty(runner.LastOrderTag)) return;

            // Process Trail Stop modifiers on active positions
            var matchingPositions = Core.Instance.Positions
                .Where(p => p.Symbol == strategy.CurrentSymbol && p.Comment == runner.LastOrderTag)
                .ToList();

            foreach (var pos in matchingPositions)
            {
                ManageChaseTrailing(pos, strategy.InpTrailTrigger, strategy.InpTrailDistance, 1);
            }
        }

        private void ManageChaseTrailing(Position pos, int triggerTicks, int distanceTicks, int stepTicks)
        {
            var slOrder = pos.StopLoss;
            if (slOrder == null) return;

            double slPrice = slOrder.TriggerPrice;
            double tickSize = strategy.CurrentSymbol.TickSize;

            double triggerDist = triggerTicks * tickSize;
            double trailDist = distanceTicks * tickSize;
            double stepDist = stepTicks * tickSize;

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
    }
}

