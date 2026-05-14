//+------------------------------------------------------------------+
//|                                                 TrailManager.mqh |
//|                       KAT Opening Range Breakout EA — Trailing Stop/Breakeven |
//|                                                      Version 2.1 |
//+------------------------------------------------------------------+
#ifndef __TRAILMANAGER_MQH__
#define __TRAILMANAGER_MQH__

#include "Defines.mqh"
#include "PositionAggregator.mqh"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| CTrailManager — manages trailing stop and breakeven               |
//+------------------------------------------------------------------+
class CTrailManager
{
private:
   CTrade            m_trade;

   void              ApplyAggregateSL(const SPositionAggregate &agg, double newSL);
   void              ManageTrailing(ulong ticket, string symbol, int trailTrigger, int trailDistance, int trailStep);
   void              ManageCandleTrailShift(ulong ticket, string symbol, ENUM_TIMEFRAMES tf, int shift);

public:
                     CTrailManager();
                    ~CTrailManager() {}

   void              Init() { m_trade.SetExpertMagicNumber(CGlobalState::Instance().Magic()); }
   void              Process(const DashboardParams &params);
   void              ForceBreakeven(const DashboardParams &params);

   virtual double    GetPoint(string symbol)   { return SymbolInfoDouble(symbol, SYMBOL_POINT); }
   virtual int       GetDigits(string symbol)  { return (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS); }
   virtual double    GetAsk(string symbol)     { return SymbolInfoDouble(symbol, SYMBOL_ASK); }
   virtual double    GetBid(string symbol)     { return SymbolInfoDouble(symbol, SYMBOL_BID); }
};

//+------------------------------------------------------------------+
CTrailManager::CTrailManager()
{
   m_trade.SetExpertMagicNumber(CGlobalState::Instance().Magic());
}

//+------------------------------------------------------------------+
//| Process all positions for trailing/breakeven                      |
//+------------------------------------------------------------------+
void CTrailManager::Process(const DashboardParams &params)
{
   if(params.trailMode == TM_OFF && !params.beEnabled) return;

   string symbol = params.symbol;
   if(symbol == "") return;

   int magic = CGlobalState::Instance().Magic();

   if(params.beEnabled)
   {
      SPositionAggregate agg;
      CPositionAggregator::Collect(symbol, magic, agg);
      if(agg.totalLots > 0)
      {
         double point  = GetPoint(symbol);
         int    digits = GetDigits(symbol);
         if(point > 0)
         {
            double activateDist = params.beActivatePoints * point;
            double lockDist     = params.beLockPoints * point;
            double avgEntry     = agg.weightedEntry;
            bool triggered = false;

            if(agg.dominantType == POSITION_TYPE_BUY)
               triggered = (GetBid(symbol) - avgEntry >= activateDist);
            else
               triggered = (avgEntry - GetAsk(symbol) >= activateDist);

            if(triggered)
            {
               double newSL = (agg.dominantType == POSITION_TYPE_BUY)
                              ? NormalizeDouble(avgEntry + lockDist, digits)
                              : NormalizeDouble(avgEntry - lockDist, digits);
               ApplyAggregateSL(agg, newSL);
            }
         }
      }
   }

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic) continue;

      if(params.trailMode == TM_CHASE)
         ManageTrailing(ticket, symbol, params.trailTrigger, params.trailDistance, params.trailStep);

      if(params.trailMode >= TM_CANDLE_1 && params.trailMode <= TM_CANDLE_3)
      {
         int shift = (params.trailMode == TM_CANDLE_1) ? 1
                     : (params.trailMode == TM_CANDLE_2) ? 2 : 3;
         ManageCandleTrailShift(ticket, symbol, params.timeframe, shift);
      }
   }
}

//+------------------------------------------------------------------+
//| Apply new SL to all collected tickets (never move backwards)      |
//+------------------------------------------------------------------+
void CTrailManager::ApplyAggregateSL(const SPositionAggregate &agg, double newSL)
{
   for(int j = 0; j < agg.ticketCount; j++)
   {
      if(!PositionSelectByTicket(agg.tickets[j])) continue;
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);

      bool shouldMove = false;
      if(posType == POSITION_TYPE_BUY)
         shouldMove = (newSL > sl || sl == 0);
      else
         shouldMove = (newSL < sl || sl == 0);

      double point = SymbolInfoDouble(PositionGetString(POSITION_SYMBOL), SYMBOL_POINT);
      if(shouldMove && MathAbs(sl - newSL) > point)
      {
         if(!m_trade.PositionModify(agg.tickets[j], newSL, tp))
            PrintFormat("[TrailMgr] Aggregate BE failed: #%d err=%d", agg.tickets[j], GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
//| Force breakeven: aggregate avg entry, no trigger check             |
//+------------------------------------------------------------------+
void CTrailManager::ForceBreakeven(const DashboardParams &params)
{
   string symbol = params.symbol;
   if(symbol == "") return;

   double point  = GetPoint(symbol);
   int    digits = GetDigits(symbol);
   if(point <= 0) return;

   SPositionAggregate agg;
   CPositionAggregator::Collect(symbol, CGlobalState::Instance().Magic(), agg);
   if(agg.totalLots <= 0 || agg.ticketCount == 0) return;

   double lockDist = params.beLockPoints * point;
   double newSL = (agg.dominantType == POSITION_TYPE_BUY)
                  ? NormalizeDouble(agg.weightedEntry + lockDist, digits)
                  : NormalizeDouble(agg.weightedEntry - lockDist, digits);

   ApplyAggregateSL(agg, newSL);
}

//+------------------------------------------------------------------+
//| Trailing Stop: move SL to track price                             |
//+------------------------------------------------------------------+
void CTrailManager::ManageTrailing(ulong ticket, string symbol, int trailTrigger, int trailDistance, int trailStep)
{
   if(!PositionSelectByTicket(ticket)) return;

   double sl        = PositionGetDouble(POSITION_SL);
   double tp        = PositionGetDouble(POSITION_TP);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   long   posType   = PositionGetInteger(POSITION_TYPE);
   double point     = GetPoint(symbol);
   int    digits    = GetDigits(symbol);

   if(point <= 0 || trailTrigger <= 0 || trailDistance <= 0 || trailStep <= 0) return;

   double triggerDist = trailTrigger * point;
   double trailDist   = trailDistance * point;
   double stepDist    = trailStep * point;

   if(posType == POSITION_TYPE_BUY)
   {
      double bid = GetBid(symbol);
      if(bid - openPrice < triggerDist) return;

      double newSL = NormalizeDouble(bid - trailDist, digits);
      if(newSL > sl || sl == 0)
      {
         if(sl == 0 || (newSL - sl) >= stepDist)
         {
            if(!m_trade.PositionModify(ticket, newSL, tp))
               PrintFormat("[TrailMgr] Trail modify failed: %s ticket=%d err=%d",
                           symbol, ticket, GetLastError());
         }
      }
   }
   else if(posType == POSITION_TYPE_SELL)
   {
      double ask = GetAsk(symbol);
      if(openPrice - ask < triggerDist) return;

      double newSL = NormalizeDouble(ask + trailDist, digits);
      if(newSL < sl || sl == 0)
      {
         if(sl == 0 || (sl - newSL) >= stepDist)
         {
            if(!m_trade.PositionModify(ticket, newSL, tp))
               PrintFormat("[TrailMgr] Trail modify failed: %s ticket=%d err=%d",
                           symbol, ticket, GetLastError());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Trail SL to candle low/high                                       |
//+------------------------------------------------------------------+
void CTrailManager::ManageCandleTrailShift(ulong ticket, string symbol, ENUM_TIMEFRAMES tf, int shift)
{
   if(!PositionSelectByTicket(ticket)) return;
   double sl = PositionGetDouble(POSITION_SL);
   double tp = PositionGetDouble(POSITION_TP);
   long posType = PositionGetInteger(POSITION_TYPE);
   double point = GetPoint(symbol);
   int digits = GetDigits(symbol);
   if(point <= 0) return;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, tf, shift, 1, rates) < 1) return;

   double newSL = 0;
   if(posType == POSITION_TYPE_BUY)
   {
      newSL = NormalizeDouble(rates[0].low - point, digits);
      if(newSL > sl || sl == 0)
         if(MathAbs(newSL - sl) > point)
            m_trade.PositionModify(ticket, newSL, tp);
   }
   else if(posType == POSITION_TYPE_SELL)
   {
      newSL = NormalizeDouble(rates[0].high + point, digits);
      if(newSL < sl || sl == 0)
         if(MathAbs(sl - newSL) > point)
            m_trade.PositionModify(ticket, newSL, tp);
   }
}

#endif // __TRAILMANAGER_MQH__
