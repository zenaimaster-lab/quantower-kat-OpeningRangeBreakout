//+------------------------------------------------------------------+
//|                                                 TrailManager.mqh |
//|                       KAT Opening Range Breakout EA — Trailing Stop/Breakeven |
//|                                                      Version 2.0 |
//+------------------------------------------------------------------+
#ifndef __TRAILMANAGER_MQH__
#define __TRAILMANAGER_MQH__

#include "Defines.mqh"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| CTrailManager — manages trailing stop and breakeven               |
//+------------------------------------------------------------------+
class CTrailManager
{
private:
   CTrade            m_trade;
   
public:
                     CTrailManager();
                    ~CTrailManager() {}
   
   //--- Main processing method — call from OnTick
   void              Init() { m_trade.SetExpertMagicNumber(g_magic); }
   void              Process(const DashboardParams &params);
   
   //--- Immediate breakeven — call from BREAK EVEN button
   void              ForceBreakeven(const DashboardParams &params);
   
   //--- Virtual properties for testing
   virtual double    GetPoint(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_POINT); }
   virtual int       GetDigits(string symbol) { return (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS); }
   virtual double    GetAsk(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_ASK); }
   virtual double    GetBid(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_BID); }

private:
   //--- Internal logic
   void              ManageBreakevenAggregate(string symbol, int activatePoints, int lockPoints);
   void              ManageTrailing(ulong ticket, string symbol, int trailTrigger, int trailDistance, int trailStep);
   void              ManageCandleTrailShift(ulong ticket, string symbol, ENUM_TIMEFRAMES tf, int shift);
};

//+------------------------------------------------------------------+
CTrailManager::CTrailManager()
{
   m_trade.SetExpertMagicNumber(g_magic);
}

//+------------------------------------------------------------------+
//| Process all positions for trailing/breakeven                      |
//+------------------------------------------------------------------+
void CTrailManager::Process(const DashboardParams &params)
{
   if(params.trailMode == TM_OFF && !params.beEnabled) return;
   
   string symbol = params.symbol;
   if(symbol == "") return;
   
   // Apply aggregate breakeven if enabled (once, not per-position)
   if(params.beEnabled)
      ManageBreakevenAggregate(symbol, params.beActivatePoints, params.beLockPoints);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      
      // Apply CHASE trailing (trigger/distance/step)
      if(params.trailMode == TM_CHASE)
         ManageTrailing(ticket, symbol, params.trailTrigger, params.trailDistance, params.trailStep);
      
      // Apply candle-based trailing
      if(params.trailMode >= TM_CANDLE_1 && params.trailMode <= TM_CANDLE_3)
      {
         int shift = (params.trailMode == TM_CANDLE_1) ? 1 : (params.trailMode == TM_CANDLE_2) ? 2 : 3;
         ManageCandleTrailShift(ticket, symbol, params.timeframe, shift);
      }
   }
}

//+------------------------------------------------------------------+
//| Breakeven (Aggregate): weighted avg entry across all positions     |
//| Moves ALL SLs to avgEntry + lock when aggregate profit >= trigger  |
//+------------------------------------------------------------------+
void CTrailManager::ManageBreakevenAggregate(string symbol, int activatePoints, int lockPoints)
{
   double point  = GetPoint(symbol);
   int    digits = GetDigits(symbol);
   if(point <= 0) return;

   // Step 1: Calculate weighted average entry and dominant direction
   double totalLots = 0;
   double weightedEntry = 0;
   int    dominantType = -1;
   double buyLots = 0, sellLots = 0;
   
   // Collect all position tickets
   ulong tickets[];
   int ticketCount = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      
      double vol = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      long posType = PositionGetInteger(POSITION_TYPE);
      
      if(posType == POSITION_TYPE_BUY) buyLots += vol;
      else sellLots += vol;
      
      totalLots += vol;
      weightedEntry += price * vol;
      
      ArrayResize(tickets, ticketCount + 1);
      tickets[ticketCount] = ticket;
      ticketCount++;
   }
   
   if(totalLots <= 0 || ticketCount == 0) return;
   
   double avgEntry = weightedEntry / totalLots;
   dominantType = (buyLots >= sellLots) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   
   double activateDist = activatePoints * point;
   double lockDist     = lockPoints * point;
   
   // Step 2: Check if aggregate profit meets trigger
   bool triggered = false;
   if(dominantType == POSITION_TYPE_BUY)
   {
      double bid = GetBid(symbol);
      if(bid - avgEntry >= activateDist) triggered = true;
   }
   else
   {
      double ask = GetAsk(symbol);
      if(avgEntry - ask >= activateDist) triggered = true;
   }
   
   if(!triggered) return;
   
   // Step 3: Move all SLs to avgEntry + lock (never backwards)
   double newSL;
   if(dominantType == POSITION_TYPE_BUY)
      newSL = NormalizeDouble(avgEntry + lockDist, digits);
   else
      newSL = NormalizeDouble(avgEntry - lockDist, digits);
   
   for(int j = 0; j < ticketCount; j++)
   {
      if(!PositionSelectByTicket(tickets[j])) continue;
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);
      
      // Never move SL backwards
      bool shouldMove = false;
      if(posType == POSITION_TYPE_BUY)
         shouldMove = (newSL > sl || sl == 0);
      else
         shouldMove = (newSL < sl || sl == 0);
      
      if(shouldMove && MathAbs(sl - newSL) > point)
      {
         if(!m_trade.PositionModify(tickets[j], newSL, tp))
            PrintFormat("[TrailMgr] Aggregate BE failed: #%d err=%d", tickets[j], GetLastError());
      }
   }
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
      
      // Check if price reached trigger level
      if(bid - openPrice < triggerDist) return;
      
      double newSL = NormalizeDouble(bid - trailDist, digits);
      
      // Only move SL up, and only if the change is >= step
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
      
      // Check if price reached trigger level
      if(openPrice - ask < triggerDist) return;
      
      double newSL = NormalizeDouble(ask + trailDist, digits);
      
      // Only move SL down, and only if the change is >= step
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
//| Force breakeven: aggregate avg entry, no trigger check             |
//+------------------------------------------------------------------+
void CTrailManager::ForceBreakeven(const DashboardParams &params)
{
   string symbol = params.symbol;
   if(symbol == "") return;
   
   double point  = GetPoint(symbol);
   int    digits = GetDigits(symbol);
   if(point <= 0) return;
   
   double lockDist = params.beLockPoints * point;
   
   // Calculate weighted average entry
   double totalLots = 0;
   double weightedEntry = 0;
   double buyLots = 0, sellLots = 0;
   
   ulong tickets[];
   int ticketCount = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      
      double vol = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      long posType = PositionGetInteger(POSITION_TYPE);
      
      if(posType == POSITION_TYPE_BUY) buyLots += vol;
      else sellLots += vol;
      
      totalLots += vol;
      weightedEntry += price * vol;
      
      ArrayResize(tickets, ticketCount + 1);
      tickets[ticketCount] = ticket;
      ticketCount++;
   }
   
   if(totalLots <= 0 || ticketCount == 0) return;
   
   double avgEntry = weightedEntry / totalLots;
   int dominantType = (buyLots >= sellLots) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   
   double newSL;
   if(dominantType == POSITION_TYPE_BUY)
      newSL = NormalizeDouble(avgEntry + lockDist, digits);
   else
      newSL = NormalizeDouble(avgEntry - lockDist, digits);
   
   for(int j = 0; j < ticketCount; j++)
   {
      if(!PositionSelectByTicket(tickets[j])) continue;
      double sl = PositionGetDouble(POSITION_SL);
      double tp = PositionGetDouble(POSITION_TP);
      long posType = PositionGetInteger(POSITION_TYPE);
      
      // Never move SL backwards
      bool shouldMove = false;
      if(posType == POSITION_TYPE_BUY)
         shouldMove = (newSL > sl || sl == 0);
      else
         shouldMove = (newSL < sl || sl == 0);
      
      if(shouldMove)
      {
         if(m_trade.PositionModify(tickets[j], newSL, tp))
            PrintFormat("[TrailMgr] Force BE: #%d SL=%.5f (avgEntry=%.5f)", tickets[j], newSL, avgEntry);
         else
            PrintFormat("[TrailMgr] Force BE failed: #%d err=%d", tickets[j], GetLastError());
      }
   }
}

//+------------------------------------------------------------------+
//| Trail SL to candle open (low for buy, high for sell)              |
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
   { newSL = NormalizeDouble(rates[0].low - point, digits);
     if(newSL > sl || sl == 0) { if(MathAbs(newSL - sl) > point) m_trade.PositionModify(ticket, newSL, tp); } }
   else if(posType == POSITION_TYPE_SELL)
   { newSL = NormalizeDouble(rates[0].high + point, digits);
     if(newSL < sl || sl == 0) { if(MathAbs(sl - newSL) > point) m_trade.PositionModify(ticket, newSL, tp); } }
}

#endif // __TRAILMANAGER_MQH__
