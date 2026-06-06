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

            double beTriggerPrice = strategy.InpBreakEvenTrigger * tickSize;
            double beOffsetPrice = strategy.InpBreakEvenOffset * tickSize;

            double open = pos.OpenPrice;
            double currentQty = pos.Quantity;

            double targetSL = slPrice;

            if (pos.Side == Side.Buy)
            {
                double bid = strategy.CurrentSymbol.Bid;

                // 1. Calculate Break-Even SL
                if (strategy.InpUseBreakEven && bid - open >= beTriggerPrice)
                {
                    double beSL = open + beOffsetPrice;
                    beSL = Math.Round(beSL / tickSize) * tickSize;
                    if (targetSL == 0 || beSL > targetSL)
                    {
                        targetSL = beSL;
                    }
                }

                // 2. Calculate Trailing Stop SL
                if (bid - open >= triggerDist)
                {
                    double trailSL = bid - trailDist;
                    trailSL = Math.Round(trailSL / tickSize) * tickSize;
                    if (targetSL == 0 || trailSL > targetSL)
                    {
                        targetSL = trailSL;
                    }
                }

                // Apply modification if targetSL is better or quantity changed
                if (targetSL > slPrice || slPrice == 0 || slOrder.TotalQuantity != currentQty)
                {
                    if (slPrice == 0 || (targetSL - slPrice) >= stepDist || slOrder.TotalQuantity != currentQty)
                    {
                        Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, currentQty, slOrder.Price, targetSL, slOrder.TrailOffset);
                    }
                }
            }
            else if (pos.Side == Side.Sell)
            {
                double ask = strategy.CurrentSymbol.Ask;

                // 1. Calculate Break-Even SL
                if (strategy.InpUseBreakEven && open - ask >= beTriggerPrice)
                {
                    double beSL = open - beOffsetPrice;
                    beSL = Math.Round(beSL / tickSize) * tickSize;
                    if (targetSL == 0 || beSL < targetSL)
                    {
                        targetSL = beSL;
                    }
                }

                // 2. Calculate Trailing Stop SL
                if (open - ask >= triggerDist)
                {
                    double trailSL = ask + trailDist;
                    trailSL = Math.Round(trailSL / tickSize) * tickSize;
                    if (targetSL == 0 || trailSL < targetSL)
                    {
                        targetSL = trailSL;
                    }
                }

                // Apply modification if targetSL is better or quantity changed
                if (targetSL < slPrice || slPrice == 0 || slOrder.TotalQuantity != currentQty)
                {
                    if (slPrice == 0 || (slPrice - targetSL) >= stepDist || slOrder.TotalQuantity != currentQty)
                    {
                        Core.Instance.ModifyOrder(slOrder, slOrder.TimeInForce, currentQty, slOrder.Price, targetSL, slOrder.TrailOffset);
                    }
                }
            }
        }
    }
}
