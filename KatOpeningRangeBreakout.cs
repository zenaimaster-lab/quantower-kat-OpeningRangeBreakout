using System;
using System.Collections.Generic;
using System.Linq;
using System.ComponentModel;
using TradingPlatform.BusinessLayer;

namespace KatORB
{
    public class KatOpeningRangeBreakout : Strategy
    {
        [Category("0. METADATA & SYSTEM INFO")]
        [InputParameter("Bot Description", 0)]
        public string InpBotDescription = "Automated Break & Retest range strategy on 2m/5m/15m/30m NYO candles";

        [Category("0. METADATA & SYSTEM INFO")]
        [InputParameter("Strategy Version", 1)]
        public string InpStrategyVersion = "1.9";

        [Category("0. METADATA & SYSTEM INFO")]
        [InputParameter("Adapter Version", 2)]
        public string InpAdapterVersion = "v1.145.17";

        [Category("0. METADATA & SYSTEM INFO")]
        [InputParameter("Last Updated (UTC)", 3)]
        public string InpLastUpdated = "2026-06-06 14:18:00";

        [Category("1. GENERAL & SCHEDULE")]
        [InputParameter("Symbol", 5)]
        public Symbol CurrentSymbol = default!;

        [Category("1. GENERAL & SCHEDULE")]
        [InputParameter("Account", 6)]
        public Account CurrentAccount = default!;

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

        [Category("3. ORDER SETTINGS")]
        [InputParameter("Continue After First Trade", 115)]
        public bool InpContAfter1st = true;
        
        [Category("3. ORDER SETTINGS")]
        [InputParameter("Max Chase Ticks (Market Entry)", 120)]
        public int InpMaxChaseTicks = 10;

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

        [Category("7. FLATTEN & CANCEL")]
        [InputParameter("Flatten if not hit Trigger (Enable)", 290)]
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
        private TimeManager timeManager = default!;
        private RiskManager riskManager = default!;
        private TrailManager trailManager = default!;
        private List<ORBRunner> runners = default!;

        public TimeManager TimeManager => timeManager;
        public RiskManager RiskManager => riskManager;
        public TrailManager TrailManager => trailManager;

        private HistoricalData historicalDataM1 = default!;
        private HistoricalData historicalDataM2 = default!;
        private HistoricalData historicalDataM5 = default!;
        private HistoricalData historicalDataM15 = default!;
        private HistoricalData historicalDataM30 = default!;
        private HistoricalData historicalDataRetest = default!;
        private HistoricalData dailyHistory = default!;

        // Trade tracking for stats (wins/losses per timeframe)
        private Dictionary<int, int> winsToday = new Dictionary<int, int>();
        private Dictionary<int, int> lossesToday = new Dictionary<int, int>();
        private DateTime lastStatsDate = DateTime.MinValue;

        public const string STRATEGY_VERSION = "1.9";

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
                this.Log("ERROR: Symbol is null. Strategy cannot start. Please make sure a Symbol is selected in settings.", StrategyLoggingLevel.Error);
                return;
            }

            if (this.CurrentAccount == null)
            {
                this.Log("ERROR: Account is null. Strategy cannot start. Please make sure an Account is selected in settings.", StrategyLoggingLevel.Error);
                return;
            }

            //--- Subscriptions to required historical data streams
            DateTime loadFrom = Core.Instance.TimeUtils.DateTimeUtcNow.AddDays(-5);
            this.historicalDataM1 = this.CurrentSymbol.GetHistory(Period.MIN1, loadFrom);
            this.historicalDataM2 = this.CurrentSymbol.GetHistory(Period.MIN2, loadFrom);
            
            if (Inp5mActive || InpObsRange5mOn)
                this.historicalDataM5 = this.CurrentSymbol.GetHistory(Period.MIN5, loadFrom);
            
            if (Inp15mActive || InpObsRange15mOn)
                this.historicalDataM15 = this.CurrentSymbol.GetHistory(Period.MIN15, loadFrom);
            
            if (Inp30mActive || InpObsRange30mOn)
                this.historicalDataM30 = this.CurrentSymbol.GetHistory(Period.MIN30, loadFrom);
                
            this.dailyHistory = this.CurrentSymbol.GetHistory(Period.DAY1, loadFrom);

            // Subscribe to the custom retest timeframe (always active)
            Period retestPeriod = MapMinutesToPeriod(InpCustomRetestMin);
            if (retestPeriod == Period.MIN1)
                this.historicalDataRetest = this.historicalDataM1;
            else if (retestPeriod == Period.MIN2)
                this.historicalDataRetest = this.historicalDataM2;
            else if (retestPeriod == Period.MIN5 && this.historicalDataM5 != null)
                this.historicalDataRetest = this.historicalDataM5;
            else if (retestPeriod == Period.MIN15 && this.historicalDataM15 != null)
                this.historicalDataRetest = this.historicalDataM15;
            else if (retestPeriod == Period.MIN30 && this.historicalDataM30 != null)
                this.historicalDataRetest = this.historicalDataM30;
            else
                this.historicalDataRetest = this.CurrentSymbol.GetHistory(retestPeriod, loadFrom);

            //--- Initialize the runners for active timeframes
            this.runners.Clear();
            if (Inp2mActive)
            {
                if (this.historicalDataM2 != null)
                    this.runners.Add(new ORBRunner(this, Period.MIN2, 0, "orb-2m", this.historicalDataM2));
                else
                    this.Log("ERROR: Could not load 2m historical data. 2m runner disabled.", StrategyLoggingLevel.Error);
            }
            if (Inp5mActive)
            {
                if (this.historicalDataM5 != null)
                    this.runners.Add(new ORBRunner(this, Period.MIN5, 1, "orb-5m", this.historicalDataM5));
                else
                    this.Log("ERROR: Could not load 5m historical data. 5m runner disabled.", StrategyLoggingLevel.Error);
            }
            if (Inp15mActive)
            {
                if (this.historicalDataM15 != null)
                    this.runners.Add(new ORBRunner(this, Period.MIN15, 2, "orb-15m", this.historicalDataM15));
                else
                    this.Log("ERROR: Could not load 15m historical data. 15m runner disabled.", StrategyLoggingLevel.Error);
            }
            if (Inp30mActive)
            {
                if (this.historicalDataM30 != null)
                    this.runners.Add(new ORBRunner(this, Period.MIN30, 3, "orb-30m", this.historicalDataM30));
                else
                    this.Log("ERROR: Could not load 30m historical data. 30m runner disabled.", StrategyLoggingLevel.Error);
            }

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
            if (this.historicalDataM1 != null) { this.historicalDataM1.Dispose(); this.historicalDataM1 = null!; }
            if (this.historicalDataM2 != null) { this.historicalDataM2.Dispose(); this.historicalDataM2 = null!; }
            if (this.historicalDataM5 != null) { this.historicalDataM5.Dispose(); this.historicalDataM5 = null!; }
            if (this.historicalDataM15 != null) { this.historicalDataM15.Dispose(); this.historicalDataM15 = null!; }
            if (this.historicalDataM30 != null) { this.historicalDataM30.Dispose(); this.historicalDataM30 = null!; }
            if (this.dailyHistory != null) { this.dailyHistory.Dispose(); this.dailyHistory = null!; }

            if (this.historicalDataRetest != null)
            {
                if (this.historicalDataRetest != this.historicalDataM1 &&
                    this.historicalDataRetest != this.historicalDataM2 &&
                    this.historicalDataRetest != this.historicalDataM5 &&
                    this.historicalDataRetest != this.historicalDataM15 &&
                    this.historicalDataRetest != this.historicalDataM30)
                {
                    this.historicalDataRetest.Dispose();
                }
                this.historicalDataRetest = null!;
            }

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
            this.timeManager.UpdateTargetTime(InpNyHour, InpNyMinute, InpNySecond, InpUtcOffset, InpAfterMinutes);
            DateTime nyoServerTime = this.timeManager.GetTargetTime();

            // Daily stats reset at NY Open
            ResetStatsOnNewDay(nyoServerTime, serverTime);

            // Periodically refresh history counts or triggers
            foreach (var runner in this.runners)
            {
                runner.Process(nyoServerTime, serverTime);
                this.trailManager.Process(runner);
            }
        }

        private void ResetStatsOnNewDay(DateTime nyoTime, DateTime serverTime)
        {
            if (serverTime >= nyoTime && nyoTime.Date != this.lastStatsDate.Date && nyoTime > DateTime.MinValue)
            {
                for (int i = 0; i < 4; i++)
                {
                    this.winsToday[i] = 0;
                    this.lossesToday[i] = 0;
                }
                this.lastStatsDate = nyoTime;
                this.Log($"New trading session started at {nyoTime}. Strategy win/loss stats have been reset.");
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
}

