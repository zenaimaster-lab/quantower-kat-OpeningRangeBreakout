//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                  KAT Opening Range Breakout EA — Order/State Mgr  |
//|                                                      Version 2.1 |
//+------------------------------------------------------------------+
#ifndef __ORDERMANAGER_MQH__
#define __ORDERMANAGER_MQH__

#include <Trade\Trade.mqh>
#include "Defines.mqh"
#include "RiskManager.mqh"

enum ENUM_ORB_STATE {
   ORB_WAIT_NYO = 0,
   ORB_WAIT_CANDLE = 1,
   ORB_WAIT_BREAK = 2,
   ORB_WAIT_RETEST = 3,
   ORB_WAIT_ENTRY = 4,
   ORB_STOPPED = 5,
   ORB_DONE = 6
};

//+------------------------------------------------------------------+
//| COrderManager — state machine for ORB entry logic                 |
//+------------------------------------------------------------------+
class COrderManager
{
private:
   CTrade            m_trade;
   CRiskManager      m_riskMgr;

   ENUM_ORB_STATE    m_state;
   datetime          m_nyoTime;
   double            m_rangeHigh;
   double            m_rangeLow;
   datetime          m_candleTime;
   int               m_breakDir; // 1 = UP, -1 = DOWN

   string            m_lastOrderTag;
   bool              m_ordersActive;
   datetime          m_placedTime;

   string            m_entryReason;
   string            m_cancelReason;
   int               m_entryBreakDir; // Track break direction for cancel reason

   //--- State handlers
   void              HandleWaitNyo(datetime nyOpenTimeServer);
   void              HandleWaitCandle(const DashboardParams &params, datetime now);
   void              HandleWaitBreak(const DashboardParams &params);
   void              HandleWaitRetest(const DashboardParams &params);

   //--- Helpers
   ENUM_TIMEFRAMES   MapRetestMinutesToTimeframe(int minutes) const;
   bool              CheckEmaFilters(const DashboardParams &params, int direction, string &outReason, bool isEntry);
   double            GetEmaValue(string sym, ENUM_TIMEFRAMES tf, int period);
   bool              HasPendingOrderForComment(string symbol, string commentPrefix);
   bool              CheckObstacles(const DashboardParams &p, double price, string &outReason);
   bool              GetRangeLines(string symbol, ENUM_TIMEFRAMES tf, datetime nyoTime, double &high, double &low);
   double            GetM2EmaValue(string sym, int period);
   double            CalculateVWAP(string symbol, ENUM_TIMEFRAMES tf, int startShift);

   string            GenerateOrderTag(string prefix);
   void              DrawORBLines(string symbol, ENUM_TIMEFRAMES tf, datetime cTime, double high, double low);
   void              DrawTradeLines(string symbol, ENUM_TIMEFRAMES tf, int dir, double entry, double target);
   void              DeleteLines(ENUM_TIMEFRAMES tf);

   int               Magic() const { return g_gs.Magic(); }

public:
                     COrderManager();
                    ~COrderManager();

   void              Init();
   void              ResetState();

   void              ProcessORB(const DashboardParams &params, datetime nyOpenTimeServer);
   void              CheckAutoFlatten(const DashboardParams &params, datetime nyOpenTimeServer);
   void              FlattenAll(string symbol);
   void              CleanupLines(ENUM_TIMEFRAMES tf);
   double            GetDayVwapValue(string sym, ENUM_TIMEFRAMES tf);
   double            GetWeekVwapValue(string sym, ENUM_TIMEFRAMES tf);

   string            GetStatus() const;
   color             GetStatusColor() const;
   string            GetEntryReason() const { return m_entryReason; }
   string            GetCancelReason() const { return m_cancelReason; }

   virtual double    GetPoint(string symbol)    { return SymbolInfoDouble(symbol, SYMBOL_POINT); }
   virtual int       GetDigits(string symbol)   { return (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS); }
   virtual int       GetSpread(string symbol)   { return (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD); }
   virtual double    GetAsk(string symbol)      { return SymbolInfoDouble(symbol, SYMBOL_ASK); }
   virtual double    GetBid(string symbol)      { return SymbolInfoDouble(symbol, SYMBOL_BID); }
   virtual int       GetStopsLevel(string symbol){ return (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL); }
};

//+------------------------------------------------------------------+
COrderManager::COrderManager() { ResetState(); }
COrderManager::~COrderManager() {}

void COrderManager::Init() { m_trade.SetExpertMagicNumber(Magic()); }

void COrderManager::ResetState()
{
   m_state = ORB_WAIT_NYO;
   m_nyoTime = 0;
   m_rangeHigh = 0;
   m_rangeLow = 0;
   m_candleTime = 0;
   m_breakDir = 0;
   m_lastOrderTag = "";
   m_ordersActive = false;
   m_placedTime = 0;
   m_entryReason = "";
   m_cancelReason = "";
   m_entryBreakDir = 0;
}

//+------------------------------------------------------------------+
void COrderManager::ProcessORB(const DashboardParams &params, datetime nyOpenTimeServer)
{
   if(m_nyoTime != nyOpenTimeServer) { ResetState(); m_nyoTime = nyOpenTimeServer; }

   datetime now = TimeTradeServer();
   if(nyOpenTimeServer == 0 || now < nyOpenTimeServer) return;

   // Safeguard: Check if max successful/loss limit has been hit before running wait handlers
   if(!m_ordersActive)
   {
      bool limitHit = (params.maxSuccessOn && g_gs.WinsTodayTF(params.tfIndex) >= params.maxSuccess)
                   || (params.maxLossOn   && g_gs.LossesTodayTF(params.tfIndex) >= params.maxLoss);
      if(limitHit && m_state != ORB_DONE && m_state != ORB_STOPPED)
      {
         m_state = ORB_DONE;
         PrintFormat("[%s] Limit hit (Wins=%d/%d, Losses=%d/%d). State forced to ORB_DONE.", 
                     EnumToString(params.timeframe), 
                     g_gs.WinsTodayTF(params.tfIndex), params.maxSuccess,
                     g_gs.LossesTodayTF(params.tfIndex), params.maxLoss);
      }
   }

   // If trading window has passed and no active trade is running, stop state progression
   if(!m_ordersActive && params.afterMinutesOn && now >= nyOpenTimeServer + params.afterMinutes * 60)
   {
      if(m_state != ORB_STOPPED && m_state != ORB_DONE)
      {
         if(m_state == ORB_WAIT_NYO)      m_state = ORB_WAIT_CANDLE;
         if(m_state == ORB_WAIT_CANDLE)   HandleWaitCandle(params, now);
         
         if(m_state == ORB_WAIT_BREAK || m_state == ORB_WAIT_RETEST || m_state == ORB_WAIT_ENTRY)
         {
            m_state = ORB_STOPPED;
            PrintFormat("[%s] Trading window closed (Passed %d mins). State set to ORB_STOPPED.", 
                        EnumToString(params.timeframe), params.afterMinutes);
         }
      }
      return;
   }

   HandleWaitNyo(nyOpenTimeServer);
   HandleWaitCandle(params, now);
   HandleWaitBreak(params);
   HandleWaitRetest(params);
}

//+------------------------------------------------------------------+
void COrderManager::HandleWaitNyo(datetime nyOpenTimeServer)
{
   if(m_state == ORB_WAIT_NYO)
      m_state = ORB_WAIT_CANDLE;
}

//+------------------------------------------------------------------+
void COrderManager::HandleWaitCandle(const DashboardParams &params, datetime now)
{
   if(m_state != ORB_WAIT_CANDLE) return;

   string symbol = params.symbol;
   ENUM_TIMEFRAMES tf = params.timeframe;

   if(now >= m_nyoTime + PeriodSeconds(tf))
   {
      datetime startRange = m_nyoTime;
      datetime endRange   = m_nyoTime + PeriodSeconds(tf) - 1;

      // Strict M1 synchronization guards to prevent caching pre-market or incomplete bars
      int expectedBars = (int)(PeriodSeconds(tf) / 60);
      datetime times[];
      int copiedT = CopyTime(symbol, PERIOD_M1, startRange, endRange, times);
      if(copiedT <= 0) return;
      if(times[0] < startRange) return; // Prevent copying pre-market bars

      int elapsedAfterClose = (int)(now - (startRange + PeriodSeconds(tf)));
      bool strict = (elapsedAfterClose < 60);
      if(strict && copiedT < expectedBars) return; // Wait for full synchronization on bar close

      double highs[], lows[];
      int copiedH = CopyHigh(symbol, PERIOD_M1, startRange, endRange, highs);
      int copiedL = CopyLow(symbol, PERIOD_M1, startRange, endRange, lows);

      if(copiedH > 0 && copiedL > 0 && copiedH == copiedT && copiedL == copiedT)
      {
         double maxH = highs[0];
         double minL = lows[0];
         for(int k = 1; k < copiedH; k++) {
            if(highs[k] > maxH) maxH = highs[k];
         }
         for(int k = 1; k < copiedL; k++) {
            if(lows[k] < minL) minL = lows[k];
         }
         m_rangeHigh = maxH;
         m_rangeLow  = minL;
         m_candleTime = startRange;
         DrawORBLines(symbol, tf, startRange, m_rangeHigh, m_rangeLow);
         m_state = ORB_WAIT_BREAK;
         PrintFormat("[%s] ORB Range formed (M1-based): H=%.5f L=%.5f", EnumToString(tf), m_rangeHigh, m_rangeLow);
      }
   }
}

//+------------------------------------------------------------------+
void COrderManager::HandleWaitBreak(const DashboardParams &params)
{
   if(m_state != ORB_WAIT_BREAK) return;

   string symbol = params.symbol;
   ENUM_TIMEFRAMES tf = params.timeframe;
   datetime t1 = iTime(symbol, tf, 1);
   if(t1 <= m_candleTime) return;

   double c = iClose(symbol, tf, 1);
   if(c > m_rangeHigh)
   {
      m_breakDir = 1;
      m_state = ORB_WAIT_RETEST;
      PrintFormat("[%s] Break Out detected. Waiting for retest.", EnumToString(tf));
   }
   else if(c < m_rangeLow)
   {
      m_breakDir = -1;
      m_state = ORB_WAIT_RETEST;
      PrintFormat("[%s] Break Down detected. Waiting for retest.", EnumToString(tf));
   }
}

//+------------------------------------------------------------------+
ENUM_TIMEFRAMES COrderManager::MapRetestMinutesToTimeframe(int minutes) const
{
   switch(minutes)
   {
      case 1:  return PERIOD_M1;
      case 2:  return PERIOD_M2;
      case 3:  return PERIOD_M3;
      case 4:  return PERIOD_M4;
      case 5:  return PERIOD_M5;
      case 6:  return PERIOD_M6;
      case 10: return PERIOD_M10;
      case 12: return PERIOD_M12;
      case 15: return PERIOD_M15;
      case 20: return PERIOD_M20;
      case 30: return PERIOD_M30;
      case 60: return PERIOD_H1;
      default: return PERIOD_M1;
   }
}

//+------------------------------------------------------------------+
void COrderManager::HandleWaitRetest(const DashboardParams &params)
{
   if(m_state != ORB_WAIT_RETEST) return;

   string symbol = params.symbol;
   ENUM_TIMEFRAMES tf = params.timeframe;

   // Skip if a pending order already exists for this strategy (prevent duplicates)
   if(HasPendingOrderForComment(symbol, params.comment))
   {
      PrintFormat("[%s] SKIP: Pending order already exists for %s", EnumToString(tf), params.comment);
      return;
   }

   // Skip if a position already open for this SAME strategy (filter by comment prefix)
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != Magic()) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if(StringFind(PositionGetString(POSITION_COMMENT), params.comment) >= 0)
         return;
   }

   ENUM_TIMEFRAMES retestTf = params.customRetestOn ? MapRetestMinutesToTimeframe(params.customRetestMin) : tf;

   double c = iClose(symbol, retestTf, 1);
   double o = iOpen(symbol, retestTf, 1);
   double h = iHigh(symbol, retestTf, 1);
   double l = iLow(symbol, retestTf, 1);

   double point  = GetPoint(symbol);
   int    digits = GetDigits(symbol);
   int    spread = GetSpread(symbol);
   int    buffer = params.entryBufferPoints;

   //--- Break UP
   if(m_breakDir == 1 && params.orderMode != MODE_SELL_ONLY)
   {
      if(c < o && l <= m_rangeHigh)
      {
         double entryPrice = NormalizeDouble(h + (buffer + spread) * point, digits);

         if(params.maxDistRangeOn)
         {
            int dist = (int)MathRound((entryPrice - m_rangeHigh) / point);
            if(dist > params.maxDistRange)
            {
               PrintFormat("[%s] SKIP BuyStop: dist %d > max %d pts", EnumToString(tf), dist, params.maxDistRange);
               m_cancelReason = "Up " + IntegerToString(PeriodSeconds(tf) / 60) + "m, stop Entry (Max dist " + IntegerToString(dist) + ">" + IntegerToString(params.maxDistRange) + ")";
               m_state = params.contAfter1st ? ORB_WAIT_BREAK : ORB_DONE;
               return;
            }
         }

         string obsReason = "";
         if(CheckObstacles(params, entryPrice, obsReason))
         {
            PrintFormat("[%s] SKIP BuyStop: Obstacle detected near entryPrice %.5f. %s", EnumToString(tf), entryPrice, obsReason);
            m_cancelReason = "Up " + IntegerToString(PeriodSeconds(tf) / 60) + "m, skip Entry (" + obsReason + ")";
            m_state = params.contAfter1st ? ORB_WAIT_BREAK : ORB_DONE;
            return;
         }

         string filterReason = "";
         if(!CheckEmaFilters(params, 1, filterReason, true))
         {
            m_cancelReason = "Up " + IntegerToString(PeriodSeconds(tf) / 60) + "m, " + filterReason;
            m_state = params.contAfter1st ? ORB_WAIT_BREAK : ORB_DONE;
            return;
         }

         double sl = params.slCandle ? NormalizeDouble(l - buffer * point, digits)
                                     : NormalizeDouble(entryPrice - params.slPoints * point, digits);
         double tp = (params.tpPoints > 0) ? NormalizeDouble(entryPrice + params.tpPoints * point, digits) : 0;
         double lot = params.riskModeOn
                      ? m_riskMgr.CalcLotSize(symbol, params.riskPercent, (int)MathRound(MathAbs(entryPrice - sl) / point))
                      : m_riskMgr.NormalizeLot(symbol, params.fixLot);

         if(lot > 0)
         {
            m_lastOrderTag = GenerateOrderTag(params.comment);
            if(m_trade.BuyStop(lot, entryPrice, symbol, sl, tp, ORDER_TIME_GTC, 0, m_lastOrderTag))
            {
               m_state = ORB_WAIT_ENTRY;
               m_ordersActive = true;
               m_placedTime = TimeTradeServer();
               m_entryBreakDir = 1;
               m_entryReason = "Up " + IntegerToString(PeriodSeconds(tf) / 60) + "m"
                               + (params.customRetestOn ? ", retest " + IntegerToString(params.customRetestMin) + "m" : "");
               double triggerSLPrice = (params.trailTrigger > 0) ? NormalizeDouble(entryPrice + params.trailTrigger * point, digits) : 0;
               DrawTradeLines(symbol, tf, 1, entryPrice, triggerSLPrice);
               PrintFormat("[%s] BUY STOP placed at %.5f on retest", EnumToString(tf), entryPrice);
            }
         }
      }
   }
   //--- Break DOWN
   else if(m_breakDir == -1 && params.orderMode != MODE_BUY_ONLY)
   {
      if(c > o && h >= m_rangeLow)
      {
         double entryPrice = NormalizeDouble(l - buffer * point, digits);

         if(params.maxDistRangeOn)
         {
            int dist = (int)MathRound((m_rangeLow - entryPrice) / point);
            if(dist > params.maxDistRange)
            {
               PrintFormat("[%s] SKIP SellStop: dist %d > max %d pts", EnumToString(tf), dist, params.maxDistRange);
               m_cancelReason = "Down " + IntegerToString(PeriodSeconds(tf) / 60) + "m, stop Entry (Max dist " + IntegerToString(dist) + ">" + IntegerToString(params.maxDistRange) + ")";
               m_state = params.contAfter1st ? ORB_WAIT_BREAK : ORB_DONE;
               return;
            }
         }

         string obsReason = "";
         if(CheckObstacles(params, entryPrice, obsReason))
         {
            PrintFormat("[%s] SKIP SellStop: Obstacle detected near entryPrice %.5f. %s", EnumToString(tf), entryPrice, obsReason);
            m_cancelReason = "Down " + IntegerToString(PeriodSeconds(tf) / 60) + "m, skip Entry (" + obsReason + ")";
            m_state = params.contAfter1st ? ORB_WAIT_BREAK : ORB_DONE;
            return;
         }

         string filterReason = "";
         if(!CheckEmaFilters(params, -1, filterReason, true))
         {
            m_cancelReason = "Down " + IntegerToString(PeriodSeconds(tf) / 60) + "m, " + filterReason;
            m_state = params.contAfter1st ? ORB_WAIT_BREAK : ORB_DONE;
            return;
         }

         double sl = params.slCandle ? NormalizeDouble(h + (buffer + spread) * point, digits)
                                     : NormalizeDouble(entryPrice + params.slPoints * point, digits);
         double tp = (params.tpPoints > 0) ? NormalizeDouble(entryPrice - params.tpPoints * point, digits) : 0;
         double lot = params.riskModeOn
                      ? m_riskMgr.CalcLotSize(symbol, params.riskPercent, (int)MathRound(MathAbs(entryPrice - sl) / point))
                      : m_riskMgr.NormalizeLot(symbol, params.fixLot);

         if(lot > 0)
         {
            m_lastOrderTag = GenerateOrderTag(params.comment);
            if(m_trade.SellStop(lot, entryPrice, symbol, sl, tp, ORDER_TIME_GTC, 0, m_lastOrderTag))
            {
               m_state = ORB_WAIT_ENTRY;
               m_ordersActive = true;
               m_placedTime = TimeTradeServer();
               m_entryBreakDir = -1;
               m_entryReason = "Down " + IntegerToString(PeriodSeconds(tf) / 60) + "m"
                               + (params.customRetestOn ? ", retest " + IntegerToString(params.customRetestMin) + "m" : "");
               double triggerSLPrice = (params.trailTrigger > 0) ? NormalizeDouble(entryPrice - params.trailTrigger * point, digits) : 0;
               DrawTradeLines(symbol, tf, -1, entryPrice, triggerSLPrice);
               PrintFormat("[%s] SELL STOP placed at %.5f on retest", EnumToString(tf), entryPrice);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
string COrderManager::GetStatus() const
{
   switch(m_state)
   {
      case ORB_WAIT_NYO:    return "Awaiting NY Open";
      case ORB_WAIT_CANDLE: return "Defining Range";
      case ORB_WAIT_BREAK:  return "Scanning Breakout";
      case ORB_WAIT_RETEST: return (m_breakDir == 1) ? "Bullish Break ▲" : "Bearish Break ▼";
      case ORB_WAIT_ENTRY:  return "Awaiting Retest";
      case ORB_STOPPED:     return "Trading Paused";
      case ORB_DONE:        return "Session Complete";
   }
   return "Inactive";
}

color COrderManager::GetStatusColor() const
{
   switch(m_state)
   {
      case ORB_WAIT_RETEST: return (m_breakDir == 1) ? CLR_MONEY_GREEN : CLR_MONEY_RED;
      case ORB_WAIT_ENTRY:  return CLR_WARNING;
      case ORB_STOPPED:     return CLR_MONEY_RED;
      default:              return CLR_TEXT_DIM;
   }
}

//+------------------------------------------------------------------+
void COrderManager::FlattenAll(string symbol)
{
   int magic = Magic();
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != magic) continue;
      if(OrderGetString(ORDER_SYMBOL) != symbol) continue;

      if(m_trade.OrderDelete(ticket))
         PrintFormat("[OrderMgr] Cancelled pending #%d for %s", ticket, symbol);
   }
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;

      if(m_trade.PositionClose(ticket))
         PrintFormat("[OrderMgr] Closed position #%d for %s", ticket, symbol);
   }
   m_ordersActive = false;
   if(m_state == ORB_WAIT_ENTRY) m_state = ORB_DONE;
}

//+------------------------------------------------------------------+
void COrderManager::CheckAutoFlatten(const DashboardParams &p, datetime nyOpenTimeServer)
{
   if(!m_ordersActive) return;
   string symbol = p.symbol;
   if(symbol == "") return;

   bool shouldFlatten = false;
   string reason = "";
   datetime now = TimeTradeServer();

   int magic = Magic();
   
   // Figure out if we have pending orders and/or open positions
   bool hasPending = false;
   bool hasPosition = false;
   datetime earliestPosTime = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != magic) continue;
      if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
      if(StringFind(OrderGetString(ORDER_COMMENT), m_lastOrderTag) < 0) continue;
      hasPending = true;
   }
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if(StringFind(PositionGetString(POSITION_COMMENT), m_lastOrderTag) < 0) continue;
      hasPosition = true;
      datetime pt = (datetime)PositionGetInteger(POSITION_TIME);
      if(earliestPosTime == 0 || pt < earliestPosTime) earliestPosTime = pt;
   }

   // 1. Unfilled candles (for pending orders only)
   if(p.unfilledCandlesOn && hasPending && !hasPosition && m_placedTime > 0)
   {
      if(iBarShift(symbol, p.timeframe, m_placedTime) >= p.unfilledCandles)
      {
         shouldFlatten = true;
         reason = "Unfilled candles > " + IntegerToString(p.unfilledCandles);
      }
   }
   
   // 1.b After filled minutes (close position if TP not hit within X minutes)
   if(!shouldFlatten && p.afterFilledMinutesOn && hasPosition && earliestPosTime > 0)
   {
      if(now - earliestPosTime >= p.afterFilledMinutes * 60)
      {
         shouldFlatten = true;
         reason = "No TP after " + IntegerToString(p.afterFilledMinutes) + " min";
      }
   }

   // 2. After minutes from NYO
   if(!shouldFlatten && p.afterMinutesOn && nyOpenTimeServer > 0)
   {
      if(now >= nyOpenTimeServer + p.afterMinutes * 60)
      {
         shouldFlatten = true;
         reason = "Passed " + IntegerToString(p.afterMinutes) + " mins after NY Open";
      }
   }

   // 3. Price-based conditions (for both pending and open positions)
   if(!shouldFlatten && (p.unfavorMoveOn || p.touchMidOn))
   {
      double bid = GetBid(symbol);
      double ask = GetAsk(symbol);
      double point = GetPoint(symbol);
      double midPrice = (m_rangeHigh + m_rangeLow) / 2.0;

      // Check pending orders
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(!OrderSelect(ticket)) continue;
         if(OrderGetInteger(ORDER_MAGIC) != magic) continue;
         if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
         if(StringFind(OrderGetString(ORDER_COMMENT), m_lastOrderTag) < 0) continue;

         ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         double openPrice = OrderGetDouble(ORDER_PRICE_OPEN);

         if(type == ORDER_TYPE_BUY_STOP)
         {
            if(p.unfavorMoveOn && bid <= openPrice - p.unfavorMovePts * point) { shouldFlatten = true; reason = "Unfavor move (BuyStop)"; break; }
            if(p.touchMidOn && bid <= midPrice)                               { shouldFlatten = true; reason = "Touch Mid (BuyStop)"; break; }
         }
         else if(type == ORDER_TYPE_SELL_STOP)
         {
            if(p.unfavorMoveOn && ask >= openPrice + p.unfavorMovePts * point) { shouldFlatten = true; reason = "Unfavor move (SellStop)"; break; }
            if(p.touchMidOn && ask >= midPrice)                               { shouldFlatten = true; reason = "Touch Mid (SellStop)"; break; }
         }
      }
      
      // Check open positions
      if(!shouldFlatten)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket <= 0) continue;
            if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
            if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
            if(StringFind(PositionGetString(POSITION_COMMENT), m_lastOrderTag) < 0) continue;

            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);

            if(type == POSITION_TYPE_BUY)
            {
               if(p.unfavorMoveOn && bid <= openPrice - p.unfavorMovePts * point) { shouldFlatten = true; reason = "Unfavor move (BuyPos)"; break; }
               if(p.touchMidOn && bid <= midPrice)                               { shouldFlatten = true; reason = "Touch Mid (BuyPos)"; break; }
            }
            else if(type == POSITION_TYPE_SELL)
            {
               if(p.unfavorMoveOn && ask >= openPrice + p.unfavorMovePts * point) { shouldFlatten = true; reason = "Unfavor move (SellPos)"; break; }
               if(p.touchMidOn && ask >= midPrice)                               { shouldFlatten = true; reason = "Touch Mid (SellPos)"; break; }
            }
         }
      }
   }

   // 4. Indicator-based auto cancel/flatten
   if(!shouldFlatten)
   {
      string filterReason = "";
      
      // First check pending orders
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(!OrderSelect(ticket)) continue;
         if(OrderGetInteger(ORDER_MAGIC) != magic) continue;
         if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
         if(StringFind(OrderGetString(ORDER_COMMENT), m_lastOrderTag) < 0) continue;

         ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         int direction = (type == ORDER_TYPE_BUY_STOP) ? 1 : -1;
         if(!CheckEmaFilters(p, direction, filterReason, false))
         {
            shouldFlatten = true;
            reason = filterReason;
            break;
         }
      }

      // Obstacle filter cancel for pending orders
      if(!shouldFlatten)
      {
         for(int i = OrdersTotal() - 1; i >= 0; i--)
         {
            ulong ticket = OrderGetTicket(i);
            if(!OrderSelect(ticket)) continue;
            if(OrderGetInteger(ORDER_MAGIC) != magic) continue;
            if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
            if(StringFind(OrderGetString(ORDER_COMMENT), m_lastOrderTag) < 0) continue;

            double openPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            string obsReason = "";
            if(CheckObstacles(p, openPrice, obsReason))
            {
               shouldFlatten = true;
               reason = obsReason;
               break;
            }
         }
      }

      // If not flattened by pending orders, check positions
      if(!shouldFlatten)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket <= 0) continue;
            if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
            if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
            if(StringFind(PositionGetString(POSITION_COMMENT), m_lastOrderTag) < 0) continue;

            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            int direction = (type == POSITION_TYPE_BUY) ? 1 : -1;
            if(!CheckEmaFilters(p, direction, filterReason, false))
            {
               shouldFlatten = true;
               reason = filterReason;
               break;
            }
         }
      }
   }

   if(shouldFlatten)
   {
      string dir = (m_entryBreakDir == 1) ? "Up" : "Down";
      string tfStr = IntegerToString(PeriodSeconds(p.timeframe) / 60) + "m";
      m_cancelReason = dir + " " + tfStr + ", cancelled (" + reason + ")";
      PrintFormat("[OrderMgr] Auto Flatten Triggered: %s", reason);
      FlattenAll(symbol);
      m_lastOrderTag = "";

      bool hardStop = p.afterMinutesOn && nyOpenTimeServer > 0 && now >= nyOpenTimeServer + p.afterMinutes * 60;
      if(hardStop)
      {
         m_state = ORB_STOPPED;
      }
      else
      {
          bool limitHit = (p.maxSuccessOn && g_gs.WinsTodayTF(p.tfIndex) >= p.maxSuccess)
                       || (p.maxLossOn   && g_gs.LossesTodayTF(p.tfIndex) >= p.maxLoss);
         m_state = (p.contAfter1st && !limitHit) ? ORB_WAIT_BREAK : ORB_DONE;
      }
   }
   else if(m_lastOrderTag != "")
   {
      // Keep checking if any order or position is active
      bool exists = false;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(OrderSelect(ticket) && OrderGetString(ORDER_COMMENT) == m_lastOrderTag)
         { exists = true; break; }
      }
      if(!exists)
      {
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket > 0 && PositionGetString(POSITION_COMMENT) == m_lastOrderTag)
            { exists = true; break; }
         }
      }
      
      if(!exists)
      {
         m_ordersActive = false;
         m_lastOrderTag = "";
          bool limitHit = (p.maxSuccessOn && g_gs.WinsTodayTF(p.tfIndex) >= p.maxSuccess)
                       || (p.maxLossOn   && g_gs.LossesTodayTF(p.tfIndex) >= p.maxLoss);
         m_state = (p.contAfter1st && !limitHit) ? ORB_WAIT_BREAK : ORB_DONE;
         PrintFormat("[%s] Order/Pos closed. Resuming WAIT_BREAK=%s", symbol, (m_state == ORB_WAIT_BREAK) ? "true" : "false");
      }
   }
}

//+------------------------------------------------------------------+
//| Unified EMA filter check (entry=true uses FavorEMA, else EMA1/2/3) |
//+------------------------------------------------------------------+
bool COrderManager::CheckEmaFilters(const DashboardParams &params, int direction, string &outReason, bool isEntry)
{
   string symbol = params.symbol;
   ENUM_TIMEFRAMES tf = params.timeframe;
   outReason = "";

   bool   emaOn[3];
   int    emaPeriod[3];
   string emaLabel;

   if(isEntry)
   {
      emaOn[0] = params.favorEma1On; emaPeriod[0] = params.favorEma1Period;
      emaOn[1] = params.favorEma2On; emaPeriod[1] = params.favorEma2Period;
      emaOn[2] = params.favorEma3On; emaPeriod[2] = params.favorEma3Period;
      emaLabel = "Favor EMA";
   }
   else
   {
      emaOn[0] = params.ema1On; emaPeriod[0] = params.ema1Period;
      emaOn[1] = params.ema2On; emaPeriod[1] = params.ema2Period;
      emaOn[2] = params.ema3On; emaPeriod[2] = params.ema3Period;
      emaLabel = "Price < EMA";
   }

   if(direction == 1) // Buy
   {
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      for(int i = 0; i < 3; i++)
      {
         if(!emaOn[i]) continue;
         double v = GetEmaValue(symbol, tf, emaPeriod[i]);
         if(v > 0 && bid < v)
         {
            outReason = emaLabel + IntegerToString(emaPeriod[i]) + " (Buy below)";
            return false;
         }
      }
   }
   else if(direction == -1) // Sell
   {
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      for(int i = 0; i < 3; i++)
      {
         if(!emaOn[i]) continue;
         double v = GetEmaValue(symbol, tf, emaPeriod[i]);
         if(v > 0 && ask > v)
         {
            outReason = emaLabel + IntegerToString(emaPeriod[i]) + " (Sell above)";
            return false;
         }
      }
   }
   return true;
}

//+------------------------------------------------------------------+
double COrderManager::GetEmaValue(string sym, ENUM_TIMEFRAMES tf, int period)
{
   if(period <= 0) return 0;
   int h = iMA(sym, tf, period, 0, MODE_EMA, PRICE_CLOSE);
   if(h != INVALID_HANDLE)
   {
      double ema[1];
      double result = 0;
      if(CopyBuffer(h, 0, 0, 1, ema) > 0) result = ema[0];
      IndicatorRelease(h);
      return result;
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Get custom timeframe range lines dynamically                     |
//+------------------------------------------------------------------+
bool COrderManager::GetRangeLines(string symbol, ENUM_TIMEFRAMES tf, datetime nyoTime, double &high, double &low)
{
   if(nyoTime == 0) return false;
   datetime now = TimeTradeServer();
   if(now < nyoTime + PeriodSeconds(tf)) return false; // Bar not closed yet

   datetime startRange = nyoTime;
   datetime endRange   = nyoTime + PeriodSeconds(tf) - 1;

   // Strict M1 synchronization guards to prevent caching pre-market or incomplete bars
   int expectedBars = (int)(PeriodSeconds(tf) / 60);
   datetime times[];
   int copiedT = CopyTime(symbol, PERIOD_M1, startRange, endRange, times);
   if(copiedT <= 0) return false;
   if(times[0] < startRange) return false; // Prevent copying pre-market bars

   int elapsedAfterClose = (int)(now - (startRange + PeriodSeconds(tf)));
   bool strict = (elapsedAfterClose < 60);
   if(strict && copiedT < expectedBars) return false; // Wait for full synchronization on bar close

   double highs[], lows[];
   int copiedH = CopyHigh(symbol, PERIOD_M1, startRange, endRange, highs);
   int copiedL = CopyLow(symbol, PERIOD_M1, startRange, endRange, lows);

   if(copiedH > 0 && copiedL > 0 && copiedH == copiedT && copiedL == copiedT)
   {
      double maxH = highs[0];
      double minL = lows[0];
      for(int k = 1; k < copiedH; k++) {
         if(highs[k] > maxH) maxH = highs[k];
      }
      for(int k = 1; k < copiedL; k++) {
         if(lows[k] < minL) minL = lows[k];
      }
      high = maxH;
      low  = minL;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Get M2 EMA value at index 1                                      |
//+------------------------------------------------------------------+
double COrderManager::GetM2EmaValue(string sym, int period)
{
   if(period <= 0) return 0;
   int h = iMA(sym, PERIOD_M2, period, 0, MODE_EMA, PRICE_CLOSE);
   if(h != INVALID_HANDLE)
   {
      double ema[1];
      double result = 0;
      if(CopyBuffer(h, 0, 1, 1, ema) > 0) result = ema[0];
      IndicatorRelease(h);
      return result;
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Calculate VWAP from a starting shift to current shift           |
//+------------------------------------------------------------------+
double COrderManager::CalculateVWAP(string symbol, ENUM_TIMEFRAMES tf, int startShift)
{
   if(startShift < 0) return 0;
   
   double highArray[];
   double lowArray[];
   double closeArray[];
   long volumeArray[];
   
   int toCopy = startShift + 1;
   
   int copied = CopyHigh(symbol, tf, 0, toCopy, highArray);
   if(copied <= 0) return 0;
   
   if(CopyLow(symbol, tf, 0, toCopy, lowArray) <= 0) return 0;
   if(CopyClose(symbol, tf, 0, toCopy, closeArray) <= 0) return 0;
   if(CopyTickVolume(symbol, tf, 0, toCopy, volumeArray) <= 0) return 0;
   
   double sumPV = 0;
   long sumV = 0;
   
   for(int i = 0; i < copied; i++)
   {
      double typPrice = (highArray[i] + lowArray[i] + closeArray[i]) / 3.0;
      long vol = volumeArray[i];
      sumPV += typPrice * vol;
      sumV += vol;
   }
   
   return (sumV > 0) ? (sumPV / sumV) : 0;
}

//+------------------------------------------------------------------+
//| Get Day VWAP value                                               |
//+------------------------------------------------------------------+
double COrderManager::GetDayVwapValue(string sym, ENUM_TIMEFRAMES tf)
{
   datetime dayStart = iTime(sym, PERIOD_D1, 0);
   if(dayStart == 0)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      dayStart = TimeCurrent() - (dt.hour * 3600 + dt.min * 60 + dt.sec);
   }
   
   int startShift = iBarShift(sym, tf, dayStart, false);
   if(startShift < 0) startShift = 0;
   
   double vwap = CalculateVWAP(sym, tf, startShift);
   if(vwap > 0) return vwap;
   
   if(tf != _Period)
   {
      startShift = iBarShift(sym, _Period, dayStart, false);
      if(startShift < 0) startShift = 0;
      vwap = CalculateVWAP(sym, _Period, startShift);
   }
   return vwap;
}

//+------------------------------------------------------------------+
//| Get Week VWAP value                                              |
//+------------------------------------------------------------------+
double COrderManager::GetWeekVwapValue(string sym, ENUM_TIMEFRAMES tf)
{
   datetime weekStart = iTime(sym, PERIOD_W1, 0);
   if(weekStart == 0)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int daysToSubtract = (dt.day_of_week == 0) ? 6 : (dt.day_of_week - 1);
      datetime dayStart = TimeCurrent() - (dt.hour * 3600 + dt.min * 60 + dt.sec);
      weekStart = dayStart - (daysToSubtract * 86400);
   }
   
   int startShift = iBarShift(sym, tf, weekStart, false);
   if(startShift < 0) startShift = 0;
   
   double vwap = CalculateVWAP(sym, tf, startShift);
   if(vwap > 0) return vwap;
   
   if(tf != _Period)
   {
      startShift = iBarShift(sym, _Period, weekStart, false);
      if(startShift < 0) startShift = 0;
      vwap = CalculateVWAP(sym, _Period, startShift);
   }
   return vwap;
}

//+------------------------------------------------------------------+
//| Check if there is any obstacle within obsMaxDist of the price    |
//+------------------------------------------------------------------+
bool COrderManager::CheckObstacles(const DashboardParams &p, double price, string &outReason)
{
   outReason = "";
   string symbol = p.symbol;
   double point = GetPoint(symbol);
   if(point <= 0) return false;

   // 1. Range 5m Obstacle
   if(p.obsRange5mOn)
   {
      double rHigh = 0, rLow = 0;
      if(GetRangeLines(symbol, PERIOD_M5, m_nyoTime, rHigh, rLow))
      {
         double distH = MathAbs(price - rHigh) / point;
         double distL = MathAbs(price - rLow) / point;
         if(distH < p.obsMaxDist)
         {
            outReason = "5m Range High obstacle (" + IntegerToString((int)MathRound(distH)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
         if(distL < p.obsMaxDist)
         {
            outReason = "5m Range Low obstacle (" + IntegerToString((int)MathRound(distL)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   // 2. Range 15m Obstacle
   if(p.obsRange15mOn)
   {
      double rHigh = 0, rLow = 0;
      if(GetRangeLines(symbol, PERIOD_M15, m_nyoTime, rHigh, rLow))
      {
         double distH = MathAbs(price - rHigh) / point;
         double distL = MathAbs(price - rLow) / point;
         if(distH < p.obsMaxDist)
         {
            outReason = "15m Range High obstacle (" + IntegerToString((int)MathRound(distH)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
         if(distL < p.obsMaxDist)
         {
            outReason = "15m Range Low obstacle (" + IntegerToString((int)MathRound(distL)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   // 2.b Range 30m Obstacle
   if(p.obsRange30mOn)
   {
      double rHigh = 0, rLow = 0;
      if(GetRangeLines(symbol, PERIOD_M30, m_nyoTime, rHigh, rLow))
      {
         double distH = MathAbs(price - rHigh) / point;
         double distL = MathAbs(price - rLow) / point;
         if(distH < p.obsMaxDist)
         {
            outReason = "30m Range High obstacle (" + IntegerToString((int)MathRound(distH)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
         if(distL < p.obsMaxDist)
         {
            outReason = "30m Range Low obstacle (" + IntegerToString((int)MathRound(distL)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   // Previous Day H/L Obstacle
   if(p.obsPrevDayHLOn)
   {
      double prevHigh = iHigh(symbol, PERIOD_D1, 1);
      double prevLow = iLow(symbol, PERIOD_D1, 1);
      if(prevHigh > 0 && prevLow > 0)
      {
         double distH = MathAbs(price - prevHigh) / point;
         double distL = MathAbs(price - prevLow) / point;
         if(distH < p.obsMaxDist)
         {
            outReason = "Prev Day High obstacle (" + IntegerToString((int)MathRound(distH)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
         if(distL < p.obsMaxDist)
         {
            outReason = "Prev Day Low obstacle (" + IntegerToString((int)MathRound(distL)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   // 3. EMA1 M2 Obstacle
   if(p.obsEma1On && p.obsEma1Period > 0)
   {
      double emaVal = GetM2EmaValue(symbol, p.obsEma1Period);
      if(emaVal > 0)
      {
         double dist = MathAbs(price - emaVal) / point;
         if(dist < p.obsMaxDist)
         {
            outReason = "M2 EMA " + IntegerToString(p.obsEma1Period) + " obstacle (" + IntegerToString((int)MathRound(dist)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   // 4. EMA2 M2 Obstacle
   if(p.obsEma2On && p.obsEma2Period > 0)
   {
      double emaVal = GetM2EmaValue(symbol, p.obsEma2Period);
      if(emaVal > 0)
      {
         double dist = MathAbs(price - emaVal) / point;
         if(dist < p.obsMaxDist)
         {
            outReason = "M2 EMA " + IntegerToString(p.obsEma2Period) + " obstacle (" + IntegerToString((int)MathRound(dist)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   // 5. EMA3 M2 Obstacle
   if(p.obsEma3On && p.obsEma3Period > 0)
   {
      double emaVal = GetM2EmaValue(symbol, p.obsEma3Period);
      if(emaVal > 0)
      {
         double dist = MathAbs(price - emaVal) / point;
         if(dist < p.obsMaxDist)
         {
            outReason = "M2 EMA " + IntegerToString(p.obsEma3Period) + " obstacle (" + IntegerToString((int)MathRound(dist)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   // Day VWAP Obstacle
   if(p.obsDayVwapOn)
   {
      double dVwapVal = GetDayVwapValue(symbol, PERIOD_M1);
      if(dVwapVal > 0)
      {
         double dist = MathAbs(price - dVwapVal) / point;
         if(dist < p.obsMaxDist)
         {
            outReason = "Day VWAP obstacle (" + IntegerToString((int)MathRound(dist)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   // Week VWAP Obstacle
   if(p.obsWeekVwapOn)
   {
      double wVwapVal = GetWeekVwapValue(symbol, PERIOD_M1);
      if(wVwapVal > 0)
      {
         double dist = MathAbs(price - wVwapVal) / point;
         if(dist < p.obsMaxDist)
         {
            outReason = "Week VWAP obstacle (" + IntegerToString((int)MathRound(dist)) + " < " + IntegerToString(p.obsMaxDist) + " pts)";
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if a pending order already exists for this strategy          |
//+------------------------------------------------------------------+
bool COrderManager::HasPendingOrderForComment(string symbol, string commentPrefix)
{
   int magic = Magic();
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != magic) continue;
      if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
      if(StringFind(OrderGetString(ORDER_COMMENT), commentPrefix) >= 0)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
string COrderManager::GenerateOrderTag(string prefix)
{
   string base = (prefix != "") ? prefix : EA_COMMENT_PREFIX;
   int rn = MathRand() % 10000;
   return StringFormat("%s_ORB_%d", base, rn);
}

//+------------------------------------------------------------------+
void COrderManager::DrawORBLines(string symbol, ENUM_TIMEFRAMES tf, datetime cTime, double high, double low)
{
   string prefix;
   color colHigh, colLow;
   datetime endTime = cTime + 3600;
   
   if(tf == PERIOD_M2) { prefix = "2m "; colHigh = clrDodgerBlue; colLow = clrOrange; }
   else if(tf == PERIOD_M5) { prefix = "5m "; colHigh = clrLimeGreen; colLow = clrRed; }
   else if(tf == PERIOD_M15) { prefix = "15m "; colHigh = clrMagenta; colLow = clrGold; }
   else { prefix = "30m "; colHigh = clrMediumPurple; colLow = clrOrangeRed; endTime = cTime + 4500; }

   string nameH = "ORB_H_" + EnumToString(tf);
   string nameL = "ORB_L_" + EnumToString(tf);
   
   // M15: center text, 5m: right end, 2m: left end, 30m: shifted right end (4500s)
   datetime txtTime;
   ENUM_ANCHOR_POINT anchorH, anchorL;
   if(tf == PERIOD_M15)
   {
      txtTime = cTime + (endTime - cTime) / 2;
      anchorH = ANCHOR_LOWER; // Text above line
      anchorL = ANCHOR_UPPER; // Text below line
   }
   else if(tf == PERIOD_M5)
   {
      txtTime = endTime;
      anchorH = ANCHOR_LEFT_LOWER;
      anchorL = ANCHOR_LEFT_UPPER;
   }
   else if(tf == PERIOD_M30)
   {
      txtTime = endTime;
      anchorH = ANCHOR_LEFT_LOWER; // Text above line
      anchorL = ANCHOR_LEFT_UPPER; // Text below line
   }
   else // M2
   {
      txtTime = cTime;
      anchorH = ANCHOR_RIGHT_LOWER;
      anchorL = ANCHOR_RIGHT_UPPER;
   }
   int width = (tf == PERIOD_M30) ? 2 : ((tf == PERIOD_M15) ? 2 : ((tf == PERIOD_M5) ? 2 : 1));
   int digits = GetDigits(symbol);

   ObjectCreate(0, nameH, OBJ_TREND, 0, cTime, high, endTime, high);
   ObjectSetInteger(0, nameH, OBJPROP_COLOR, colHigh);
   ObjectSetInteger(0, nameH, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nameH, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nameH, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, nameH, OBJPROP_BACK, true);

   string textH = nameH + "_TXT";
   ObjectCreate(0, textH, OBJ_TEXT, 0, txtTime, high);
   ObjectSetString(0, textH, OBJPROP_TEXT, prefix + "H");
   ObjectSetInteger(0, textH, OBJPROP_COLOR, colHigh);
   ObjectSetInteger(0, textH, OBJPROP_ANCHOR, anchorH);
   ObjectSetInteger(0, textH, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, textH, OBJPROP_BACK, true);

   ObjectCreate(0, nameL, OBJ_TREND, 0, cTime, low, endTime, low);
   ObjectSetInteger(0, nameL, OBJPROP_COLOR, colLow);
   ObjectSetInteger(0, nameL, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nameL, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nameL, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, nameL, OBJPROP_BACK, true);

   string textL = nameL + "_TXT";
   ObjectCreate(0, textL, OBJ_TEXT, 0, txtTime, low);
   ObjectSetString(0, textL, OBJPROP_TEXT, prefix + "L");
   ObjectSetInteger(0, textL, OBJPROP_COLOR, colLow);
   ObjectSetInteger(0, textL, OBJPROP_ANCHOR, anchorL);
   ObjectSetInteger(0, textL, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, textL, OBJPROP_BACK, true);
}

//+------------------------------------------------------------------+
void COrderManager::DrawTradeLines(string symbol, ENUM_TIMEFRAMES tf, int dir, double entry, double target)
{
   string prefix;
   if(tf == PERIOD_M2) prefix = "2m ";
   else if(tf == PERIOD_M5) prefix = "5m ";
   else if(tf == PERIOD_M15) prefix = "15m ";
   else prefix = "30m ";
   color colEntry = (dir == 1) ? clrDodgerBlue : clrOrangeRed;
   color colTarget = clrLimeGreen;

   datetime t = TimeTradeServer();
   datetime tEnd = t + PeriodSeconds(tf);
   int digits = GetDigits(symbol);

   string nameE = "ORB_ENTRY_" + EnumToString(tf);
   string nameT = "ORB_TARGET_" + EnumToString(tf);

   ObjectCreate(0, nameE, OBJ_TREND, 0, t, entry, tEnd, entry);
   ObjectSetInteger(0, nameE, OBJPROP_COLOR, colEntry);
   ObjectSetInteger(0, nameE, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, nameE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, nameE, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nameE, OBJPROP_BACK, true);

   string textE = nameE + "_TXT";
   ObjectCreate(0, textE, OBJ_TEXT, 0, tEnd, entry);
   ObjectSetString(0, textE, OBJPROP_TEXT, prefix + ((dir == 1) ? "Buy" : "Sell"));
   ObjectSetInteger(0, textE, OBJPROP_COLOR, colEntry);
   ObjectSetInteger(0, textE, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, textE, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, textE, OBJPROP_BACK, true);

   if(target > 0)
   {
      ObjectCreate(0, nameT, OBJ_TREND, 0, t, target, tEnd, target);
      ObjectSetInteger(0, nameT, OBJPROP_COLOR, colTarget);
      ObjectSetInteger(0, nameT, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, nameT, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, nameT, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, nameT, OBJPROP_BACK, true);

      string textT = nameT + "_TXT";
      ObjectCreate(0, textT, OBJ_TEXT, 0, tEnd, target);
      ObjectSetString(0, textT, OBJPROP_TEXT, prefix + "Trigger");
      ObjectSetInteger(0, textT, OBJPROP_COLOR, colTarget);
      ObjectSetInteger(0, textT, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, textT, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, textT, OBJPROP_BACK, true);
   }
}

//+------------------------------------------------------------------+
void COrderManager::DeleteLines(ENUM_TIMEFRAMES tf)
{
   string sfx = EnumToString(tf);
   ObjectDelete(0, "ORB_H_" + sfx);
   ObjectDelete(0, "ORB_H_" + sfx + "_TXT");
   ObjectDelete(0, "ORB_L_" + sfx);
   ObjectDelete(0, "ORB_L_" + sfx + "_TXT");
   ObjectDelete(0, "ORB_ENTRY_" + sfx);
   ObjectDelete(0, "ORB_ENTRY_" + sfx + "_TXT");
   ObjectDelete(0, "ORB_TARGET_" + sfx);
   ObjectDelete(0, "ORB_TARGET_" + sfx + "_TXT");
}

//+------------------------------------------------------------------+
void COrderManager::CleanupLines(ENUM_TIMEFRAMES tf) { DeleteLines(tf); }

#endif // __ORDERMANAGER_MQH__
