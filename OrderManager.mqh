//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                         Opening Sniper EA - Order/State Manager  |
//|                                                      Version 2.0 |
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
   ORB_DONE = 5
};

extern int g_magic;
extern int g_winsToday;
extern int g_lossesToday;

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
   
   string            m_lastOcoTag;
   bool              m_ordersActive;
   datetime          m_placedTime;
   
   string            m_entryReason;
   string            m_cancelReason;
   
   // Helper methods
   bool              GetCandleRange(string symbol, ENUM_TIMEFRAMES tf, int shift, double &high, double &low);
   string            GenerateOcoTag(string prefix);
   double            GetEmaValue(string sym, ENUM_TIMEFRAMES tf, int period);
   
   void              DrawORBLines(string symbol, ENUM_TIMEFRAMES tf, datetime cTime, double high, double low);
   void              DrawTradeLines(string symbol, ENUM_TIMEFRAMES tf, int dir, double entry, double target);
   void              DeleteLines(ENUM_TIMEFRAMES tf);

public:
                     COrderManager();
                    ~COrderManager();
                    
   void              Init();
   void              ResetState();
   
   void              ProcessORB(const DashboardParams &params, datetime nyOpenTimeServer);
   void              CheckAutoCancel(const DashboardParams &params, datetime nyOpenTimeServer);
   void              CancelAllPending(string symbol);
   void              CleanupLines(ENUM_TIMEFRAMES tf);
   
   string            GetStatus() const;
   color             GetStatusColor() const;
   string            GetEntryReason() const { return m_entryReason; }
   string            GetCancelReason() const { return m_cancelReason; }

   virtual double    GetPoint(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_POINT); }
   virtual int       GetDigits(string symbol) { return (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS); }
   virtual int       GetSpread(string symbol) { return (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD); }
   virtual double    GetAsk(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_ASK); }
   virtual double    GetBid(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_BID); }
   virtual int       GetStopsLevel(string symbol) { return (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL); }
};

//+------------------------------------------------------------------+
COrderManager::COrderManager()
{
   ResetState();
}

COrderManager::~COrderManager()
{
}

void COrderManager::Init()
{
   m_trade.SetExpertMagicNumber(g_magic);
}

void COrderManager::ResetState()
{
   m_state = ORB_WAIT_NYO;
   m_nyoTime = 0;
   m_rangeHigh = 0;
   m_rangeLow = 0;
   m_candleTime = 0;
   m_breakDir = 0;
   m_lastOcoTag = "";
   m_ordersActive = false;
   m_placedTime = 0;
   m_entryReason = "";
   m_cancelReason = "";
}

//+------------------------------------------------------------------+
bool COrderManager::GetCandleRange(string symbol, ENUM_TIMEFRAMES tf, int shift, double &high, double &low)
{
   double h[], l[];
   ArraySetAsSeries(h, true);
   ArraySetAsSeries(l, true);
   
   if(CopyHigh(symbol, tf, shift, 1, h) <= 0) return false;
   if(CopyLow(symbol, tf, shift, 1, l) <= 0) return false;
   
   high = h[0];
   low  = l[0];
   return true;
}

//+------------------------------------------------------------------+
string COrderManager::GenerateOcoTag(string prefix)
{
   string base = (prefix != "") ? prefix : EA_COMMENT_PREFIX;
   int rn = MathRand() % 10000;
   return StringFormat("%s_ORB_%d", base, rn);
}

//+------------------------------------------------------------------+
void COrderManager::DrawORBLines(string symbol, ENUM_TIMEFRAMES tf, datetime cTime, double high, double low)
{
   string prefix = (tf == PERIOD_M2) ? "2m " : "5m ";
   color colHigh = (tf == PERIOD_M2) ? clrDodgerBlue : clrLimeGreen;
   color colLow  = (tf == PERIOD_M2) ? clrOrange : clrRed; 
   
   string nameH = "ORB_H_" + EnumToString(tf);
   string nameL = "ORB_L_" + EnumToString(tf);
   
   datetime endTime = cTime + 3600; // 1 hour
   datetime txtTime = (tf == PERIOD_M2) ? endTime : cTime;
   
   ObjectCreate(0, nameH, OBJ_TREND, 0, cTime, high, endTime, high);
   ObjectSetInteger(0, nameH, OBJPROP_COLOR, colHigh);
   ObjectSetInteger(0, nameH, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nameH, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nameH, OBJPROP_WIDTH, (tf == PERIOD_M5) ? 2 : 1);
   ObjectSetInteger(0, nameH, OBJPROP_BACK, true);
   
   string textH = nameH + "_TXT";
   ObjectCreate(0, textH, OBJ_TEXT, 0, txtTime, high);
   ObjectSetString(0, textH, OBJPROP_TEXT, prefix + "H: " + DoubleToString(high, GetDigits(symbol)));
   ObjectSetInteger(0, textH, OBJPROP_COLOR, colHigh);
   ObjectSetInteger(0, textH, OBJPROP_ANCHOR, (tf == PERIOD_M2) ? ANCHOR_LEFT_LOWER : ANCHOR_RIGHT_LOWER);
   ObjectSetInteger(0, textH, OBJPROP_BACK, true);
   
   ObjectCreate(0, nameL, OBJ_TREND, 0, cTime, low, endTime, low);
   ObjectSetInteger(0, nameL, OBJPROP_COLOR, colLow);
   ObjectSetInteger(0, nameL, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nameL, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, nameL, OBJPROP_WIDTH, (tf == PERIOD_M5) ? 2 : 1);
   ObjectSetInteger(0, nameL, OBJPROP_BACK, true);
   
   string textL = nameL + "_TXT";
   ObjectCreate(0, textL, OBJ_TEXT, 0, txtTime, low);
   ObjectSetString(0, textL, OBJPROP_TEXT, prefix + "L: " + DoubleToString(low, GetDigits(symbol)));
   ObjectSetInteger(0, textL, OBJPROP_COLOR, colLow);
   ObjectSetInteger(0, textL, OBJPROP_ANCHOR, (tf == PERIOD_M2) ? ANCHOR_LEFT_UPPER : ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0, textL, OBJPROP_BACK, true);
}

//+------------------------------------------------------------------+
void COrderManager::DrawTradeLines(string symbol, ENUM_TIMEFRAMES tf, int dir, double entry, double target)
{
   string prefix = (tf == PERIOD_M2) ? "2m " : "5m ";
   color colEntry = (dir == 1) ? clrDodgerBlue : clrOrangeRed;
   color colTarget = clrLimeGreen;
   
   datetime t = TimeTradeServer();
   int tickLen = PeriodSeconds(tf); // 1 candle width
   datetime tEnd = t + tickLen;
   
   string nameE = "ORB_ENTRY_" + EnumToString(tf);
   string nameT = "ORB_TARGET_" + EnumToString(tf);
   
   ObjectCreate(0, nameE, OBJ_TREND, 0, t, entry, tEnd, entry);
   ObjectSetInteger(0, nameE, OBJPROP_COLOR, colEntry);
   ObjectSetInteger(0, nameE, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, nameE, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, nameE, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, nameE, OBJPROP_BACK, true);
   
   string textE = nameE + "_TXT";
   ObjectCreate(0, textE, OBJ_TEXT, 0, tEnd, entry);
   string typeStr = (dir == 1) ? "Buy Stop: " : "Sell Stop: ";
   ObjectSetString(0, textE, OBJPROP_TEXT, prefix + typeStr + DoubleToString(entry, GetDigits(symbol)));
   ObjectSetInteger(0, textE, OBJPROP_COLOR, colEntry);
   ObjectSetInteger(0, textE, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   ObjectSetInteger(0, textE, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, textE, OBJPROP_BACK, true);
   
   if(target > 0) {
       ObjectCreate(0, nameT, OBJ_TREND, 0, t, target, tEnd, target);
       ObjectSetInteger(0, nameT, OBJPROP_COLOR, colTarget);
       ObjectSetInteger(0, nameT, OBJPROP_STYLE, STYLE_SOLID);
       ObjectSetInteger(0, nameT, OBJPROP_WIDTH, 2);
       ObjectSetInteger(0, nameT, OBJPROP_RAY_RIGHT, false);
       ObjectSetInteger(0, nameT, OBJPROP_BACK, true);
       
       string textT = nameT + "_TXT";
       ObjectCreate(0, textT, OBJ_TEXT, 0, tEnd, target);
       ObjectSetString(0, textT, OBJPROP_TEXT, prefix + "Target: " + DoubleToString(target, GetDigits(symbol)));
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

void COrderManager::CleanupLines(ENUM_TIMEFRAMES tf)
{
   DeleteLines(tf);
}

//+------------------------------------------------------------------+
void COrderManager::ProcessORB(const DashboardParams &params, datetime nyOpenTimeServer)
{
   string symbol = params.symbol;
   ENUM_TIMEFRAMES tf = params.timeframe;
   
   if(m_nyoTime != nyOpenTimeServer) {
       ResetState();
       m_nyoTime = nyOpenTimeServer;
   }
   
   datetime now = TimeTradeServer();
   if(nyOpenTimeServer == 0 || now < nyOpenTimeServer) return;
   
   if(m_state == ORB_WAIT_NYO) {
       m_state = ORB_WAIT_CANDLE;
   }
   
   if(m_state == ORB_WAIT_CANDLE) {
       int shift = iBarShift(symbol, tf, nyOpenTimeServer);
       datetime cTime = iTime(symbol, tf, shift);
       
       int periodSec = PeriodSeconds(tf);
       if(now >= cTime + periodSec) { // Candle closed
           m_rangeHigh = iHigh(symbol, tf, shift);
           m_rangeLow  = iLow(symbol, tf, shift);
           m_candleTime = cTime;
           
           DrawORBLines(symbol, tf, cTime, m_rangeHigh, m_rangeLow);
           m_state = ORB_WAIT_BREAK;
           PrintFormat("[%s] ORB Range formed: H=%.5f L=%.5f", EnumToString(tf), m_rangeHigh, m_rangeLow);
       }
   }
   
   if(m_state == ORB_WAIT_BREAK) {
       int shift1 = 1;
       datetime t1 = iTime(symbol, tf, shift1);
       if(t1 > m_candleTime) {
           double c = iClose(symbol, tf, shift1);
           if(c > m_rangeHigh) {
               m_breakDir = 1;
               m_state = ORB_WAIT_RETEST;
               PrintFormat("[%s] Breakout UP detected. Waiting for retest.", EnumToString(tf));
           } else if(c < m_rangeLow) {
               m_breakDir = -1;
               m_state = ORB_WAIT_RETEST;
               PrintFormat("[%s] Breakout DOWN detected. Waiting for retest.", EnumToString(tf));
           }
       }
   }
   
   if(m_state == ORB_WAIT_RETEST) {
       bool hasPos = false;
       for(int i = PositionsTotal() - 1; i >= 0; i--) {
           ulong ticket = PositionGetTicket(i);
           if(PositionGetInteger(POSITION_MAGIC) == g_magic && PositionGetString(POSITION_SYMBOL) == symbol) {
               hasPos = true; break;
           }
       }
       if(hasPos) return;
       
       int shift1 = 1;
       datetime t1 = iTime(symbol, tf, shift1);
       
       double c = iClose(symbol, tf, shift1);
       double o = iOpen(symbol, tf, shift1);
       double h = iHigh(symbol, tf, shift1);
       double l = iLow(symbol, tf, shift1);
       
       double point = GetPoint(symbol);
       int digits = GetDigits(symbol);
       int spread = GetSpread(symbol);
       int buffer = params.entryBufferPoints;
       
       if(m_breakDir == 1) { // Break UP, waiting for RED candle touching High
           if(c < o && l <= m_rangeHigh) {
               double entryPrice = NormalizeDouble(h + (buffer + spread) * point, digits);
               double sl = params.slCandle ? NormalizeDouble(l - buffer * point, digits) : NormalizeDouble(entryPrice - params.slPoints * point, digits);
               double tp = (params.tpPoints > 0) ? NormalizeDouble(entryPrice + params.tpPoints * point, digits) : 0;
               
               double lot = m_riskMgr.CalcLotSize(symbol, params.riskPercent, (int)MathRound(MathAbs(entryPrice - sl)/point));
               if(lot > 0) {
                   m_lastOcoTag = GenerateOcoTag(params.comment);
                   if(m_trade.BuyStop(lot, entryPrice, symbol, sl, tp, ORDER_TIME_GTC, 0, m_lastOcoTag)) {
                       m_state = ORB_WAIT_ENTRY;
                       m_ordersActive = true;
                       m_placedTime = TimeTradeServer();
                       m_entryReason = "M" + IntegerToString(PeriodSeconds(tf)/60) + " Break UP Retest";
                       DrawTradeLines(symbol, tf, 1, entryPrice, tp);
                       PrintFormat("[%s] BUY STOP placed at %.5f on retest", EnumToString(tf), entryPrice);
                   }
               }
           }
       } else if(m_breakDir == -1) { // Break DOWN, waiting for GREEN candle touching Low
           if(c > o && h >= m_rangeLow) {
               double entryPrice = NormalizeDouble(l - buffer * point, digits);
               double sl = params.slCandle ? NormalizeDouble(h + (buffer + spread) * point, digits) : NormalizeDouble(entryPrice + params.slPoints * point, digits);
               double tp = (params.tpPoints > 0) ? NormalizeDouble(entryPrice - params.tpPoints * point, digits) : 0;
               
               double lot = m_riskMgr.CalcLotSize(symbol, params.riskPercent, (int)MathRound(MathAbs(entryPrice - sl)/point));
               if(lot > 0) {
                   m_lastOcoTag = GenerateOcoTag(params.comment);
                   if(m_trade.SellStop(lot, entryPrice, symbol, sl, tp, ORDER_TIME_GTC, 0, m_lastOcoTag)) {
                       m_state = ORB_WAIT_ENTRY;
                       m_ordersActive = true;
                       m_placedTime = TimeTradeServer();
                       m_entryReason = "M" + IntegerToString(PeriodSeconds(tf)/60) + " Break DOWN Retest";
                       DrawTradeLines(symbol, tf, -1, entryPrice, tp);
                       PrintFormat("[%s] SELL STOP placed at %.5f on retest", EnumToString(tf), entryPrice);
                   }
               }
           }
       }
   }
}

//+------------------------------------------------------------------+
string COrderManager::GetStatus() const
{
   switch(m_state) {
      case ORB_WAIT_NYO: return "Wait NYO";
      case ORB_WAIT_CANDLE: return "Wait Range";
      case ORB_WAIT_BREAK: return "Wait Break";
      case ORB_WAIT_RETEST: return (m_breakDir == 1) ? "Break Out ▲" : "Break Down ▼";
      case ORB_WAIT_ENTRY: return "Wait Entry";
      case ORB_DONE: return "Done";
   }
   return "Idle";
}

color COrderManager::GetStatusColor() const
{
   switch(m_state) {
      case ORB_WAIT_RETEST: return (m_breakDir == 1) ? CLR_MONEY_GREEN : CLR_MONEY_RED;
      case ORB_WAIT_ENTRY: return CLR_WARNING;
      default: return CLR_TEXT_DIM;
   }
}

//+------------------------------------------------------------------+
void COrderManager::CancelAllPending(string symbol)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;
      if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
      
      if(m_trade.OrderDelete(ticket))
         PrintFormat("[OrderMgr] Cancelled pending #%d for %s", ticket, symbol);
   }
   m_ordersActive = false;
   if(m_state == ORB_WAIT_ENTRY) m_state = ORB_DONE; // Simple fallback
}

//+------------------------------------------------------------------+
double COrderManager::GetEmaValue(string sym, ENUM_TIMEFRAMES tf, int period)
{
   if(period <= 0) return 0;
   int h = iMA(sym, tf, period, 0, MODE_EMA, PRICE_CLOSE);
   if(h != INVALID_HANDLE)
   {
      double ema[1];
      if(CopyBuffer(h, 0, 0, 1, ema) > 0) return ema[0];
   }
   return 0;
}

//+------------------------------------------------------------------+
void COrderManager::CheckAutoCancel(const DashboardParams &p, datetime nyOpenTimeServer)
{
   if(!m_ordersActive) return;
   
   string symbol = p.symbol;
   if(symbol == "") return;
   
   bool shouldCancel = false;
   string reason = "";
   
   // 1. Unfilled Candles
   if(p.unfilledCandlesOn && m_placedTime > 0)
   {
      int candlesPassed = iBarShift(symbol, p.timeframe, m_placedTime);
      if(candlesPassed >= p.unfilledCandles)
      {
         shouldCancel = true;
         reason = "Unfilled candles > " + IntegerToString(p.unfilledCandles);
      }
   }
   
   // 2. After Minutes from NY Open
   if(!shouldCancel && p.afterMinutesOn && nyOpenTimeServer > 0)
   {
      datetime now = TimeTradeServer();
      if(now >= nyOpenTimeServer + p.afterMinutes * 60)
      {
         shouldCancel = true;
         reason = "Passed " + IntegerToString(p.afterMinutes) + " mins after NY Open";
      }
   }
   
   // Check price-based conditions only if not already cancelled
   if(!shouldCancel && (p.unfavorMoveOn || p.touchMidOn))
   {
      double bid = GetBid(symbol);
      double ask = GetAsk(symbol);
      double point = GetPoint(symbol);
      double midPrice = (m_rangeHigh + m_rangeLow) / 2.0;
      
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(!OrderSelect(ticket)) continue;
         if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;
         if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
         
         string comment = OrderGetString(ORDER_COMMENT);
         if(StringFind(comment, m_lastOcoTag) >= 0)
         {
            ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            double openPrice = OrderGetDouble(ORDER_PRICE_OPEN);
            
            if(type == ORDER_TYPE_BUY_STOP)
            {
               if(p.unfavorMoveOn && bid <= openPrice - p.unfavorMovePts * point)
               {
                  shouldCancel = true;
                  reason = "Unfavor move (BuyStop)";
                  break;
               }
               if(p.touchMidOn && bid <= midPrice)
               {
                  shouldCancel = true;
                  reason = "Touch Mid (BuyStop)";
                  break;
               }
            }
            else if(type == ORDER_TYPE_SELL_STOP)
            {
               if(p.unfavorMoveOn && ask >= openPrice + p.unfavorMovePts * point)
               {
                  shouldCancel = true;
                  reason = "Unfavor move (SellStop)";
                  break;
               }
               if(p.touchMidOn && ask >= midPrice)
               {
                  shouldCancel = true;
                  reason = "Touch Mid (SellStop)";
                  break;
               }
            }
         }
      }
   }
   
   // 4. EMA based Auto Cancel
   if(!shouldCancel && (p.ema1On || p.ema2On || p.ema3On))
   {
      double bid = GetBid(symbol);
      double ask = GetAsk(symbol);
      double ema1 = 0, ema2 = 0, ema3 = 0;
      if(p.ema1On) ema1 = GetEmaValue(symbol, p.timeframe, p.ema1Period);
      if(p.ema2On) ema2 = GetEmaValue(symbol, p.timeframe, p.ema2Period);
      if(p.ema3On) ema3 = GetEmaValue(symbol, p.timeframe, p.ema3Period);
      
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(!OrderSelect(ticket)) continue;
         if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;
         if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
         
         string comment = OrderGetString(ORDER_COMMENT);
         if(StringFind(comment, m_lastOcoTag) >= 0)
         {
            ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            
            if(type == ORDER_TYPE_BUY_STOP)
            {
               if(p.ema1On && ema1 > 0 && bid < ema1) { shouldCancel = true; reason = "Price < EMA1 (Buy)"; break; }
               if(p.ema2On && ema2 > 0 && bid < ema2) { shouldCancel = true; reason = "Price < EMA2 (Buy)"; break; }
               if(p.ema3On && ema3 > 0 && bid < ema3) { shouldCancel = true; reason = "Price < EMA3 (Buy)"; break; }
            }
            else if(type == ORDER_TYPE_SELL_STOP)
            {
               if(p.ema1On && ema1 > 0 && ask > ema1) { shouldCancel = true; reason = "Price > EMA1 (Sell)"; break; }
               if(p.ema2On && ema2 > 0 && ask > ema2) { shouldCancel = true; reason = "Price > EMA2 (Sell)"; break; }
               if(p.ema3On && ema3 > 0 && ask > ema3) { shouldCancel = true; reason = "Price > EMA3 (Sell)"; break; }
            }
         }
      }
   }
   
   if(shouldCancel)
   {
      m_cancelReason = reason;
      PrintFormat("[OrderMgr] Auto Cancel Triggered: %s", reason);
      CancelAllPending(symbol);
      m_lastOcoTag = "";
      
      bool limitHit = false;
      if(p.maxSuccessOn && g_winsToday >= p.maxSuccess) limitHit = true;
      if(p.maxLossOn && g_lossesToday >= p.maxLoss) limitHit = true;
      
      if(p.contAfter1st && !limitHit) m_state = ORB_WAIT_BREAK;
   }
   else if(m_lastOcoTag != "")
   {
      bool exists = false;
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
          ulong ticket = OrderGetTicket(i);
          if(OrderSelect(ticket)) {
              if(OrderGetString(ORDER_COMMENT) == m_lastOcoTag) {
                  exists = true; break;
              }
          }
      }
      if(!exists) {
          m_ordersActive = false;
          m_lastOcoTag = "";
          
          bool limitHit = false;
          if(p.maxSuccessOn && g_winsToday >= p.maxSuccess) limitHit = true;
          if(p.maxLossOn && g_lossesToday >= p.maxLoss) limitHit = true;
          
          if(p.contAfter1st && !limitHit) {
              m_state = ORB_WAIT_BREAK;
              PrintFormat("[%s] Order triggered. Resuming WAIT_BREAK due to ContAfter1st.", symbol);
          } else {
              m_state = ORB_DONE;
          }
      }
   }
}

#endif // __ORDERMANAGER_MQH__
