using System;
using System.Linq;
using TradingPlatform.BusinessLayer;

namespace KatORB
{
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
            if (strategy.CurrentSymbol == null) return;

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

            if (slOrder.Status != OrderStatus.Opened && slOrder.Status != OrderStatus.PartiallyFilled) return;

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
                        Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, slOrder.TotalQuantity, slOrder.Price, newSL, slOrder.TrailOffset);
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
                        Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, slOrder.TotalQuantity, slOrder.Price, newSL, slOrder.TrailOffset);
                    }
                }
            }
        }
    }
}
