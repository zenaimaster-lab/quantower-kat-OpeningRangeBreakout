using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Linq;
using TradingPlatform.BusinessLayer;

namespace KatORB
{
    public class KatOpeningRangeIndicator : Indicator
    {
        //--- Input parameters
        [InputParameter("Broker UTC Offset", 10)]
        public int InpBrokerUtcOffset = -4;

        [InputParameter("NY Open Hour", 20, 0, 23)]
        public int InpNyOpenHour = 9;

        [InputParameter("NY Open Minute", 30, 0, 59)]
        public int InpNyOpenMin = 30;

        [InputParameter("NY Open Second", 40, 0, 59)]
        public int InpNyOpenSec = 0;

        [InputParameter("Draw Telemetry HUD", 50)]
        public bool InpDrawHud = true;

        [InputParameter("Draw Range Shaded Zone", 60)]
        public bool InpDrawRangeZone = true;

        //--- History references
        private HistoricalData dailyHistory = default!;
        private HistoricalData historicalDataM1 = default!;
        private HistoricalData historicalDataM2 = default!;

        //--- Range caching by Date to maintain 100% performance
        private readonly Dictionary<DateTime, (double High, double Low, double Mid)> rangeCache = new Dictionary<DateTime, (double High, double Low, double Mid)>();

        public KatOpeningRangeIndicator()
        {
            this.Name = "Kat ORB Companion Indicator";
            this.Description = "Plots opening ranges, EMAs, VWAPs, and previous day levels with premium telemetry HUD styling.";
            this.SeparateWindow = false;

            // Define standard line series so they can be modified by the user in settings
            this.AddLineSeries("Range High", Color.OrangeRed, 2, LineStyle.Dash);
            this.AddLineSeries("Range Low", Color.OrangeRed, 2, LineStyle.Dash);
            this.AddLineSeries("Range Mid", Color.DarkGray, 1, LineStyle.Dot);

            this.AddLineSeries("EMA 9", Color.RoyalBlue, 1, LineStyle.Solid);
            this.AddLineSeries("EMA 21", Color.Orange, 1, LineStyle.Solid);
            this.AddLineSeries("EMA 34", Color.LimeGreen, 1, LineStyle.Solid);

            this.AddLineSeries("EMA 250 (2m)", Color.Plum, 1, LineStyle.Solid);
            this.AddLineSeries("EMA 255 (2m)", Color.MediumOrchid, 1, LineStyle.Solid);

            this.AddLineSeries("VWAP (Day)", Color.Gold, 1, LineStyle.Solid);
            this.AddLineSeries("Prev Day High", Color.DodgerBlue, 1, LineStyle.Dash);
            this.AddLineSeries("Prev Day Low", Color.DodgerBlue, 1, LineStyle.Dash);
        }

        protected override void OnInit()
        {
            // Initializations are handled safely in first-run block of OnUpdate
        }

        public override void Dispose()
        {
            if (this.dailyHistory != null)
            {
                this.dailyHistory.Dispose();
                this.dailyHistory = null!;
            }
            if (this.historicalDataM1 != null)
            {
                this.historicalDataM1.Dispose();
                this.historicalDataM1 = null!;
            }
            if (this.historicalDataM2 != null)
            {
                this.historicalDataM2.Dispose();
                this.historicalDataM2 = null!;
            }
            base.Dispose();
        }

        protected override void OnUpdate(UpdateArgs args)
        {
            if (this.Symbol == null) return;

            // Initialize history streams safely
            if (this.dailyHistory == null)
            {
                try
                {
                    DateTime loadFrom = Core.Instance.TimeUtils.DateTimeUtcNow.AddDays(-6);
                    this.dailyHistory = this.Symbol.GetHistory(Period.DAY1, loadFrom);
                    this.historicalDataM1 = this.Symbol.GetHistory(Period.MIN1, loadFrom);
                    this.historicalDataM2 = this.Symbol.GetHistory(Period.MIN2, loadFrom);
                }
                catch (Exception ex)
                {
                    Core.Instance.Loggers.Log($"[Indicator] Failed to load historical timeframes: {ex.Message}", LoggingLevel.Error, "System");
                }
            }

            // Ensure we have enough bars to process
            if (this.Count == 0) return;

            // Fetch current bar details
            DateTime barTime = this.Time(0);
            DateTime barDate = barTime.Date;

            // 1. Calculate or fetch NY Open Range for this bar's date
            var range = GetRangeForDate(barDate);
            if (range.High > 0 && range.Low > 0)
            {
                // Only plot the Range lines if the current bar is after or equal to the NY Open Time
                DateTime targetTimeServer = GetNYOpenServerTime(barDate);
                if (barTime >= targetTimeServer)
                {
                    this.SetValue(range.High, 0, 0);
                    this.SetValue(range.Low, 1, 0);
                    this.SetValue(range.Mid, 2, 0);
                }
            }

            // 2. Calculate own TF EMAs using exact strategy convergence logic
            double ema9 = CalculateEMA(this.HistoricalData, 9, this.HistoricalData.Count - 1);
            double ema21 = CalculateEMA(this.HistoricalData, 21, this.HistoricalData.Count - 1);
            double ema34 = CalculateEMA(this.HistoricalData, 34, this.HistoricalData.Count - 1);

            if (ema9 > 0) this.SetValue(ema9, 3, 0);
            if (ema21 > 0) this.SetValue(ema21, 4, 0);
            if (ema34 > 0) this.SetValue(ema34, 5, 0);

            // 3. Calculate 2m EMAs (EMA 250 & 255) using exact strategy convergence logic
            if (this.historicalDataM2 != null && this.historicalDataM2.Count > 255)
            {
                // Find matching index in M2 history
                int m2Idx = (int)this.historicalDataM2.GetIndexByTime(barTime.Ticks, SeekOriginHistory.Begin);
                if (m2Idx >= 0 && m2Idx < this.historicalDataM2.Count)
                {
                    double ema250 = CalculateEMA(this.historicalDataM2, 250, m2Idx);
                    double ema255 = CalculateEMA(this.historicalDataM2, 255, m2Idx);

                    if (ema250 > 0) this.SetValue(ema250, 6, 0);
                    if (ema255 > 0) this.SetValue(ema255, 7, 0);
                }
            }

            // 4. Calculate Day VWAP
            DateTime todayNYOpen = GetNYOpenServerTime(barDate);
            double vwapVal = CalculateVWAP(this.HistoricalData, todayNYOpen);
            if (vwapVal > 0)
            {
                this.SetValue(vwapVal, 8, 0);
            }

            // 5. Calculate Previous Day High/Low
            if (this.dailyHistory != null && this.dailyHistory.Count >= 2)
            {
                // Find the last completed daily bar before today
                int dailyIdx = -1;
                for (int i = this.dailyHistory.Count - 1; i >= 0; i--)
                {
                    if (this.dailyHistory[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                    {
                        if (bar.TimeLeft.Date < barDate)
                        {
                            dailyIdx = i;
                            break;
                        }
                    }
                }

                if (dailyIdx >= 0 && this.dailyHistory[dailyIdx, SeekOriginHistory.Begin] is HistoryItemBar prevDailyBar)
                {
                    this.SetValue(prevDailyBar.High, 9, 0);
                    this.SetValue(prevDailyBar.Low, 10, 0);
                }
            }
        }

        //--- Helper Method: Get NY Open Server Time for a specific date
        private DateTime GetNYOpenServerTime(DateTime date)
        {
            int utcHour = InpNyOpenHour - InpBrokerUtcOffset;
            int dayAdjust = 0;

            if (utcHour >= 24) { utcHour -= 24; dayAdjust = 1; }
            if (utcHour < 0) { utcHour += 24; dayAdjust = -1; }

            DateTime targetUtc = new DateTime(
                date.Year, date.Month, date.Day,
                utcHour, InpNyOpenMin, InpNyOpenSec, DateTimeKind.Utc
            ).AddDays(dayAdjust);

            return Core.Instance.TimeUtils.ConvertFromUTCToSelectedTimeZone(targetUtc);
        }

        //--- Helper Method: Calculate Range historically with Caching
        private (double High, double Low, double Mid) GetRangeForDate(DateTime date)
        {
            if (this.rangeCache.TryGetValue(date, out var range))
            {
                return range;
            }

            DateTime targetTimeServer = GetNYOpenServerTime(date);
            int tfSeconds = 0;
            if (this.HistoricalData.Aggregation is HistoryAggregationTime timeAgg)
                tfSeconds = (int)timeAgg.Period.Duration.TotalSeconds;
            else
                tfSeconds = 60;

            double high = 0;
            double low = 0;

            // 1. Try to find the range bar in own timeframe first
            var targetBar = this.HistoricalData.OfType<HistoryItemBar>().FirstOrDefault(b => b.TimeLeft == targetTimeServer);
            if (targetBar != null)
            {
                high = targetBar.High;
                low = targetBar.Low;
            }
            // 2. Fallback to M1 history if own TF doesn't have it (or low liquidity gaps)
            else if (this.historicalDataM1 != null && this.historicalDataM1.Count > 0)
            {
                int expectedBars = tfSeconds / 60;
                var rangeBars = this.historicalDataM1.OfType<HistoryItemBar>()
                    .Where(b => b.TimeLeft >= targetTimeServer && b.TimeLeft < targetTimeServer.AddSeconds(tfSeconds))
                    .ToList();

                if (rangeBars.Count >= expectedBars)
                {
                    double maxH = double.MinValue;
                    double minL = double.MaxValue;
                    foreach (var bar in rangeBars)
                    {
                        if (bar.High > maxH) maxH = bar.High;
                        if (bar.Low < minL) minL = bar.Low;
                    }
                    high = maxH;
                    low = minL;
                }
            }

            if (high > 0 && low > 0)
            {
                double mid = (high + low) / 2.0;
                var calculated = (high, low, mid);
                this.rangeCache[date] = calculated;
                return calculated;
            }

            return (0, 0, 0);
        }

        //--- Helper Method: Calculate high-accuracy convergence EMA
        private double CalculateEMA(HistoricalData historyStream, int period, int targetIdx)
        {
            if (historyStream == null || historyStream.Count < period || targetIdx < 0 || targetIdx >= historyStream.Count)
                return 0;

            if (targetIdx < period - 1)
                return 0;

            double multiplier = 2.0 / (period + 1);

            // Starting SMA seed (average of the first 'period' bars: index 0 to period - 1)
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
            double ema = sum / period;

            // Recurse to targetIdx to get fully smoothed EMA
            for (int i = period; i <= targetIdx; i++)
            {
                if (historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar)
                {
                    double close = bar.Close;
                    ema = (close - ema) * multiplier + ema;
                }
            }

            return ema;
        }

        //--- Helper Method: Calculate VWAP
        private double CalculateVWAP(HistoricalData historyStream, DateTime startDay)
        {
            if (historyStream == null || historyStream.Count == 0) return 0;

            double sumPV = 0;
            double sumV = 0;

            for (int i = historyStream.Count - 1; i >= 0; i--)
            {
                if (!(historyStream[i, SeekOriginHistory.Begin] is HistoryItemBar bar)) continue;
                if (bar.TimeLeft < startDay) break;

                double typicalPrice = (bar.High + bar.Low + bar.Close) / 3.0;
                double vol = bar.Volume;
                sumPV += typicalPrice * vol;
                sumV += vol;
            }

            return sumV > 0 ? sumPV / sumV : 0;
        }

        //--- Premium GDI+ Rendering (Tactical Telemetry & CRT UI)
        public override void OnPaintChart(PaintChartEventArgs args)
        {
            base.OnPaintChart(args);

            Graphics gr = args.Graphics;
            gr.SmoothingMode = SmoothingMode.AntiAlias;

            // 1. Access the coordinate converter of the chart
            var converter = this.CurrentChart?.MainWindow?.CoordinatesConverter;
            if (converter == null) return;

            DateTime barTime = this.Time(0);
            DateTime barDate = barTime.Date;

            var range = GetRangeForDate(barDate);

            //--- 2. Shaded zone for Opening Range (Brutalist style)
            if (InpDrawRangeZone && range.High > 0 && range.Low > 0)
            {
                DateTime targetTimeServer = GetNYOpenServerTime(barDate);
                if (barTime >= targetTimeServer)
                {
                    double xStart = converter.GetChartX(targetTimeServer);
                    double xEnd = converter.GetChartX(barTime);
                    double yHigh = converter.GetChartY(range.High);
                    double yLow = converter.GetChartY(range.Low);

                    if (xEnd > xStart && yLow > yHigh)
                    {
                        // Semi-transparent Tactical Orange Shading
                        using (Brush zoneBrush = new SolidBrush(Color.FromArgb(15, 255, 69, 0)))
                        {
                            gr.FillRectangle(zoneBrush, (float)xStart, (float)yHigh, (float)(xEnd - xStart), (float)(yLow - yHigh));
                        }

                        // Outline the shaded zone edges
                        using (Pen boundaryPen = new Pen(Color.FromArgb(40, 255, 69, 0), 1))
                        {
                            gr.DrawLine(boundaryPen, (float)xStart, (float)yHigh, (float)xStart, (float)yLow);
                        }
                    }
                }
            }

            //--- 3. Stark Monospace Labels at the right edge next to active lines
            if (range.High > 0 && range.Low > 0)
            {
                using (Font labelFont = new Font("Consolas", 9, FontStyle.Bold))
                {
                    double xEdge = args.Rectangle.Width - 145; // Placed right before price scale

                    // Draw Range High label
                    double yHigh = converter.GetChartY(range.High);
                    gr.DrawString($"[ NY RANGE HIGH: {range.High:F2} ]", labelFont, Brushes.Tomato, (float)xEdge, (float)yHigh - 14);

                    // Draw Range Low label
                    double yLow = converter.GetChartY(range.Low);
                    gr.DrawString($"[ NY RANGE LOW : {range.Low:F2} ]", labelFont, Brushes.Tomato, (float)xEdge, (float)yLow + 2);

                    // Draw Mid-point label
                    double yMid = converter.GetChartY(range.Mid);
                    gr.DrawString($"[ RANGE MID    : {range.Mid:F2} ]", labelFont, Brushes.DarkGray, (float)xEdge - 15, (float)yMid - 6);
                }
            }

            //--- 4. Premium Tactical Telemetry HUD Overlay
            if (InpDrawHud)
            {
                // UI container dimensions & grid
                int hudX = 20;
                int hudY = 60;
                int hudW = 270;
                int hudH = 110;

                // Translucent raw matte background
                using (Brush hudBg = new SolidBrush(Color.FromArgb(180, 10, 10, 10)))
                using (Pen hudBorder = new Pen(Color.FromArgb(120, 255, 69, 0), 1))
                using (Font titleFont = new Font("Consolas", 10, FontStyle.Bold))
                using (Font bodyFont = new Font("Consolas", 8, FontStyle.Regular))
                {
                    // Draw main telemetry grid box (90 degrees, no rounded corners)
                    gr.FillRectangle(hudBg, hudX, hudY, hudW, hudH);
                    gr.DrawRectangle(hudBorder, hudX, hudY, hudW, hudH);

                    // Crosshair technical markers at HUD corners
                    gr.DrawLine(hudBorder, hudX - 3, hudY, hudX + 3, hudY);
                    gr.DrawLine(hudBorder, hudX, hudY - 3, hudX, hudY + 3);
                    gr.DrawLine(hudBorder, hudX + hudW - 3, hudY, hudX + hudW + 3, hudY);
                    gr.DrawLine(hudBorder, hudX + hudW, hudY - 3, hudX + hudW, hudY + 3);
                    gr.DrawLine(hudBorder, hudX - 3, hudY + hudH, hudX + 3, hudY + hudH);
                    gr.DrawLine(hudBorder, hudX, hudY + hudH - 3, hudX, hudY + hudH + 3);
                    gr.DrawLine(hudBorder, hudX + hudW - 3, hudY + hudH, hudX + hudW + 3, hudY + hudH);
                    gr.DrawLine(hudBorder, hudX + hudW, hudY + hudH - 3, hudX + hudW, hudY + hudH + 3);

                    // HUD Content
                    gr.DrawString(">>> KAT-ORB TELEMETRY SYSTEM", titleFont, Brushes.Tomato, hudX + 10, hudY + 8);
                    gr.DrawLine(Pens.DimGray, hudX + 10, hudY + 24, hudX + hudW - 10, hudY + 24);

                    gr.DrawString($"* SYS STATE : RUNNING (COMPANION)", bodyFont, Brushes.LightGreen, hudX + 12, hudY + 32);
                    gr.DrawString($"* SYMBOL    : {this.Symbol.Name}", bodyFont, Brushes.White, hudX + 12, hudY + 46);

                    if (range.High > 0 && range.Low > 0)
                    {
                        gr.DrawString($"* NY RANGE  : {range.High:F2} - {range.Low:F2}", bodyFont, Brushes.Tomato, hudX + 12, hudY + 60);
                        gr.DrawString($"* RANGE MID : {range.Mid:F2}", bodyFont, Brushes.Tomato, hudX + 12, hudY + 74);
                    }
                    else
                    {
                        gr.DrawString("* NY RANGE  : PENDING FORMATION", bodyFont, Brushes.Gold, hudX + 12, hudY + 60);
                        gr.DrawString("* RANGE MID : PENDING FORMATION", bodyFont, Brushes.Gold, hudX + 12, hudY + 74);
                    }

                    gr.DrawLine(Pens.DimGray, hudX + 10, hudY + 92, hudX + hudW - 10, hudY + 92);
                    gr.DrawString($"SYS ACTIVE // NY OPEN SESSION", bodyFont, Brushes.DimGray, hudX + 12, hudY + 95);
                }
            }
        }
    }
}
