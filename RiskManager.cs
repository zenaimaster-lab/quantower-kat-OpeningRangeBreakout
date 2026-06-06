using System;
using TradingPlatform.BusinessLayer;

namespace KatORB
{
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
            if (strategy.CurrentAccount == null || strategy.CurrentSymbol == null) return NormalizeLot(strategy.InpFixContract);

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
            if (strategy.CurrentSymbol == null) return lot;
            double min = strategy.CurrentSymbol.MinLot;
            double max = strategy.CurrentSymbol.MaxLot;
            double step = strategy.CurrentSymbol.LotStep;

            if (step <= 0) step = 0.01;

            double normalized = Math.Floor(lot / step + 0.000000001) * step;
            normalized = Math.Max(min, Math.Min(max, normalized));

            return Math.Round(normalized, 2);
        }
    }
}
