//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                  KAT Opening Range Breakout EA — Order/State Mgr  |
//|                                                                  |
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
   
   string            m_lastOrderTag;
   bool              m_ordersActive;
   datetime          m_placedTime;
   
   string            m_entryReason;
   string            m_cancelReason;
   
   // Helper methods
   bool              GetCandleRange(string symbol, ENUM_TIMEFRAMES tf, int shift, double &high, double &low);
   string            GenerateOrderTag(string prefix);
   double            GetEmaValue(string sym, ENUM_TIMEFRAMES tf, int period);
   bool              CheckIndicatorFilters(const DashboardParams &params, int direction, string &outReason);
   bool              CheckAutoCancelFilters(const DashboardParams &params, int direction, string &outReason);
   
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
   m_lastOrderTag = "";
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
string COrderManager::GenerateOrderTag(string prefix)
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
   ObjectSetInteger(0, nameE, OBJPROP_STYLE, STYLE_DOT);
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
       ObjectSetInteger(0, nameT, OBJPROP_STYLE, STYLE_DOT);
       ObjectSetInteger(0, nameT, OBJPROP_WIDTH, 1);
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
       
       ENUM_TIMEFRAMES retestTf = tf;
       if(params.customRetestOn) {
           switch(params.customRetestMin) {
               case 1: retestTf = PERIOD_M1; break;
               case 2: retestTf = PERIOD_M2; break;
               case 3: retestTf = PERIOD_M3; break;
               case 4: retestTf = PERIOD_M4; break;
               case 5: retestTf = PERIOD_M5; break;
               case 6: retestTf = PERIOD_M6; break;
               case 10: retestTf = PERIOD_M10; break;
               case 12: retestTf = PERIOD_M12; break;
               case 15: retestTf = PERIOD_M15; break;
               case 20: retestTf = PERIOD_M20; break;
               case 30: retestTf = PERIOD_M30; break;
               case 60: retestTf = PERIOD_H1; break;
               default: retestTf = PERIOD_M1; break;
           }
       }
       
       int shift1 = 1;
       datetime t1 = iTime(symbol, retestTf, shift1);
       
       double c = iClose(symbol, retestTf, shift1);
       double o = iOpen(symbol, retestTf, shift1);
       double h = iHigh(symbol, retestTf, shift1);
       double l = iLow(symbol, retestTf, shift1);
       
       double point = GetPoint(symbol);
       int digits = GetDigits(symbol);
       int spread = GetSpread(symbol);
       int buffer = params.entryBufferPoints;
       
       if(m_breakDir == 1 && params.orderMode != MODE_SELL_ONLY) { // Break UP
           if(c < o && l <= m_rangeHigh) {
               double entryPrice = NormalizeDouble(h + (buffer + spread) * point, digits);
               
               // Max distance from range check — skip if retest candle too large
               if(params.maxDistRangeOn) {
                   int distFromRange = (int)MathRound((entryPrice - m_rangeHigh) / point);
                   if(distFromRange > params.maxDistRange) {
                       PrintFormat("[%s] SKIP BuyStop: dist %d > max %d pts from range", 
                                   EnumToString(tf), distFromRange, params.maxDistRange);
                       m_cancelReason = "Max dist range (Buy " + IntegerToString(distFromRange) + ">" + IntegerToString(params.maxDistRange) + ")";
                       if(params.contAfter1st) m_state = ORB_WAIT_BREAK;
                       else m_state = ORB_DONE;
                       return;
                   }
               }
               
               // Run Indicator Filters
               string filterReason = "";
               if(!CheckIndicatorFilters(params, 1, filterReason)) {
                   m_cancelReason = filterReason;
                   if(params.contAfter1st) m_state = ORB_WAIT_BREAK;
                   else m_state = ORB_DONE;
                   return;
               }
               
               double sl = params.slCandle ? NormalizeDouble(l - buffer * point, digits) : NormalizeDouble(entryPrice - params.slPoints * point, digits);
               double tp = (params.tpPoints > 0) ? NormalizeDouble(entryPrice + params.tpPoints * point, digits) : 0;
               
               double lot = params.riskModeOn ? m_riskMgr.CalcLotSize(symbol, params.riskPercent, (int)MathRound(MathAbs(entryPrice - sl)/point)) : m_riskMgr.NormalizeLot(symbol, params.fixLot);
               if(lot > 0) {
                   m_lastOrderTag = GenerateOrderTag(params.comment);
                   if(m_trade.BuyStop(lot, entryPrice, symbol, sl, tp, ORDER_TIME_GTC, 0, m_lastOrderTag)) {
                       m_state = ORB_WAIT_ENTRY;
                       m_ordersActive = true;
                       m_placedTime = TimeTradeServer();
                       m_entryReason = "M" + IntegerToString(PeriodSeconds(tf)/60) + " Break UP Retest" + (params.customRetestOn ? " M" + IntegerToString(params.customRetestMin) : "");
                       DrawTradeLines(symbol, tf, 1, entryPrice, tp);
                       PrintFormat("[%s] BUY STOP placed at %.5f on retest", EnumToString(tf), entryPrice);
                   }
               }
           }
       }
       else if(m_breakDir == -1 && params.orderMode != MODE_BUY_ONLY) { // Break DOWN
           if(c > o && h >= m_rangeLow) {
               double entryPrice = NormalizeDouble(l - buffer * point, digits);
               
               // Max distance from range check — skip if retest candle too large
               if(params.maxDistRangeOn) {
                   int distFromRange = (int)MathRound((m_rangeLow - entryPrice) / point);
                   if(distFromRange > params.maxDistRange) {
                       PrintFormat("[%s] SKIP SellStop: dist %d > max %d pts from range", 
                                   EnumToString(tf), distFromRange, params.maxDistRange);
                       m_cancelReason = "Max dist range (Sell " + IntegerToString(distFromRange) + ">" + IntegerToString(params.maxDistRange) + ")";
                       if(params.contAfter1st) m_state = ORB_WAIT_BREAK;
                       else m_state = ORB_DONE;
                       return;
                   }
                }
                
               // Run Indicator Filters
               string filterReason = "";
               if(!CheckIndicatorFilters(params, -1, filterReason)) {
                   m_cancelReason = filterReason;
                   if(params.contAfter1st) m_state = ORB_WAIT_BREAK;
                   else m_state = ORB_DONE;
                   return;
               }

               double sl = params.slCandle ? NormalizeDouble(h + (buffer + spread) * point, digits) : NormalizeDouble(entryPrice + params.slPoints * point, digits);
               double tp = (params.tpPoints > 0) ? NormalizeDouble(entryPrice - params.tpPoints * point, digits) : 0;
               
               double lot = params.riskModeOn ? m_riskMgr.CalcLotSize(symbol, params.riskPercent, (int)MathRound(MathAbs(entryPrice - sl)/point)) : m_riskMgr.NormalizeLot(symbol, params.fixLot);
               if(lot > 0) {
                   m_lastOrderTag = GenerateOrderTag(params.comment);
                   if(m_trade.SellStop(lot, entryPrice, symbol, sl, tp, ORDER_TIME_GTC, 0, m_lastOrderTag)) {
                       m_state = ORB_WAIT_ENTRY;
                       m_ordersActive = true;
                       m_placedTime = TimeTradeServer();
                       m_entryReason = "M" + IntegerToString(PeriodSeconds(tf)/60) + " Break DOWN Retest" + (params.customRetestOn ? " M" + IntegerToString(params.customRetestMin) : "");
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
      case ORB_STOPPED: return "Stop Trading";
      case ORB_DONE: return "Done";
   }
   return "Idle";
}

color COrderManager::GetStatusColor() const
{
   switch(m_state) {
      case ORB_WAIT_RETEST: return (m_breakDir == 1) ? CLR_MONEY_GREEN : CLR_MONEY_RED;
      case ORB_WAIT_ENTRY: return CLR_WARNING;
      case ORB_STOPPED: return CLR_MONEY_RED;
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
//| Check Indicator Filters (e.g. Favor EMA)                          |
//| Returns true if trade is allowed, false if it should be filtered. |
//| direction: 1 (Buy), -1 (Sell)                                     |
//+------------------------------------------------------------------+
bool COrderManager::CheckIndicatorFilters(const DashboardParams &params, int direction, string &outReason)
{
   string symbol = params.symbol;
   ENUM_TIMEFRAMES tf = params.timeframe;
   outReason = "";

   if(direction == 1) // Buy rules
   {
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      if(params.favorEma1On) { double v = GetEmaValue(symbol, tf, params.favorEma1Period); if(v > 0 && bid < v) { outReason = "Favor EMA" + IntegerToString(params.favorEma1Period) + " (Buy below)"; return false; } }
      if(params.favorEma2On) { double v = GetEmaValue(symbol, tf, params.favorEma2Period); if(v > 0 && bid < v) { outReason = "Favor EMA" + IntegerToString(params.favorEma2Period) + " (Buy below)"; return false; } }
      if(params.favorEma3On) { double v = GetEmaValue(symbol, tf, params.favorEma3Period); if(v > 0 && bid < v) { outReason = "Favor EMA" + IntegerToString(params.favorEma3Period) + " (Buy below)"; return false; } }
   }
   else if(direction == -1) // Sell rules
   {
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      if(params.favorEma1On) { double v = GetEmaValue(symbol, tf, params.favorEma1Period); if(v > 0 && ask > v) { outReason = "Favor EMA" + IntegerToString(params.favorEma1Period) + " (Sell above)"; return false; } }
      if(params.favorEma2On) { double v = GetEmaValue(symbol, tf, params.favorEma2Period); if(v > 0 && ask > v) { outReason = "Favor EMA" + IntegerToString(params.favorEma2Period) + " (Sell above)"; return false; } }
      if(params.favorEma3On) { double v = GetEmaValue(symbol, tf, params.favorEma3Period); if(v > 0 && ask > v) { outReason = "Favor EMA" + IntegerToString(params.favorEma3Period) + " (Sell above)"; return false; } }
   }

   return true; // All filters passed
}

//+------------------------------------------------------------------+
//| Check Indicator Filters for Auto-Cancel (e.g. EMA 1/2/3)         |
//| Returns true if order should be kept, false if it should cancel. |
//+------------------------------------------------------------------+
bool COrderManager::CheckAutoCancelFilters(const DashboardParams &params, int direction, string &outReason)
{
   string symbol = params.symbol;
   ENUM_TIMEFRAMES tf = params.timeframe;
   outReason = "";

   if(direction == 1) // BuyStop rules
   {
      double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
      if(params.ema1On) { double v = GetEmaValue(symbol, tf, params.ema1Period); if(v > 0 && bid < v) { outReason = "Price < EMA1 (Buy)"; return false; } }
      if(params.ema2On) { double v = GetEmaValue(symbol, tf, params.ema2Period); if(v > 0 && bid < v) { outReason = "Price < EMA2 (Buy)"; return false; } }
      if(params.ema3On) { double v = GetEmaValue(symbol, tf, params.ema3Period); if(v > 0 && bid < v) { outReason = "Price < EMA3 (Buy)"; return false; } }
   }
   else if(direction == -1) // SellStop rules
   {
      double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
      if(params.ema1On) { double v = GetEmaValue(symbol, tf, params.ema1Period); if(v > 0 && ask > v) { outReason = "Price > EMA1 (Sell)"; return false; } }
      if(params.ema2On) { double v = GetEmaValue(symbol, tf, params.ema2Period); if(v > 0 && ask > v) { outReason = "Price > EMA2 (Sell)"; return false; } }
      if(params.ema3On) { double v = GetEmaValue(symbol, tf, params.ema3Period); if(v > 0 && ask > v) { outReason = "Price > EMA3 (Sell)"; return false; } }
   }

   return true;
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
         if(StringFind(comment, m_lastOrderTag) >= 0)
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
   
   // 4. Indicator-based Auto Cancel
   if(!shouldCancel)
   {
      string filterReason = "";
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(!OrderSelect(ticket)) continue;
         if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;
         if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
         
         string comment = OrderGetString(ORDER_COMMENT);
         if(StringFind(comment, m_lastOrderTag) >= 0)
         {
            ENUM_ORDER_TYPE type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            int direction = (type == ORDER_TYPE_BUY_STOP) ? 1 : -1;
            
            if(!CheckAutoCancelFilters(p, direction, filterReason))
            {
               shouldCancel = true;
               reason = filterReason;
               break;
            }
         }
      }
   }
   
   if(shouldCancel)
   {
      m_cancelReason = reason;
      PrintFormat("[OrderMgr] Auto Cancel Triggered: %s", reason);
      CancelAllPending(symbol);
      m_lastOrderTag = "";
      
      // afterMinutes is a hard stop — no continuation
      if(p.afterMinutesOn && nyOpenTimeServer > 0 && 
         TimeTradeServer() >= nyOpenTimeServer + p.afterMinutes * 60)
      {
         m_state = ORB_STOPPED;
      }
      else
      {
         bool limitHit = false;
         if(p.maxSuccessOn && g_winsToday >= p.maxSuccess) limitHit = true;
         if(p.maxLossOn && g_lossesToday >= p.maxLoss) limitHit = true;
         
         if(p.contAfter1st && !limitHit)
            m_state = ORB_WAIT_BREAK;
         else
            m_state = ORB_DONE;
      }
   }
   else if(m_lastOrderTag != "")
   {
      bool exists = false;
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
          ulong ticket = OrderGetTicket(i);
          if(OrderSelect(ticket)) {
              if(OrderGetString(ORDER_COMMENT) == m_lastOrderTag) {
                  exists = true; break;
              }
          }
      }
      if(!exists) {
          m_ordersActive = false;
          m_lastOrderTag = "";
          
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
