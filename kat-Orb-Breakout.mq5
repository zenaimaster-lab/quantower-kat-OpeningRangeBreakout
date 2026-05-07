//+------------------------------------------------------------------+
//|                                              kat-Strike.mq5  |
//|                      KAT Strike — Mathematical Origami |
//|                                                      Version 0.73 |
//+------------------------------------------------------------------+
#property copyright   "KAT Strike"
#property link        ""
#property description "KAT Strike"
#property description "Scaling into winners to hit % growth targets."

#include "Defines.mqh"

input group "=== INSTANCE ==="
input int             InpMagicNumber     = 202605011;
input ENUM_EA_MODE    InpEaMode          = EA_AUTO;

input group "=== SCHEDULE ==="
input int             InpNyHour          = 9;
input int             InpNyMinute        = 30;
input int             InpNySecond        = 0;
input int             InpUtcOffset       = -4;
input int             InpTriggerBefore   = 10;

input group "=== ORDER ==="
input ENUM_TIMEFRAMES InpTimeframe       = PERIOD_M2;
input ENUM_CANDLE_SOURCE InpCandleSrc    = CANDLE_CURRENT;
input int             InpSlPoints        = 1500;
input int             InpTpPoints        = 3000;
input bool            InpSlCandle        = false;
input ENUM_ORDER_MODE InpOrderMode       = MODE_BOTH;
input int             InpEntryBufferPoints= 5;

input group "=== RISK ==="
input double          InpRiskPercent     = 1.0;

input group "=== ORIGAMI ==="
input double          InpTargetGrowthPercent = 50.0;
input double          InpMarginSafetyPct     = 10.0; // v1.51: DIAD Margin of Safety (% of distance)

input group "=== TRAIL ==="
input ENUM_TRAIL_MODE InpTrailMode       = TM_OFF;
input int             InpTrailTrigger    = 30;
input int             InpTrailDistance   = 20;
input int             InpTrailStep       = 5;
input int             InpBeActivatePts   = 200;
input int             InpBeLockPts       = 50;
input bool            InpBeEnabled       = false;

input group "=== AUTO CANCEL ==="
input bool            InpExpireEnabled   = false;
input int             InpExpireCandles   = 2;

input group "=== NEWS FILTER ==="
input bool InpNewsNFP=true; input bool InpNewsCPI=true; input bool InpNewsFOMC=true;
input bool InpNewsGDP=true; input bool InpNewsPPI=true; input bool InpNewsRetail=true;
input bool InpNewsUnemploy=true; input bool InpNewsISM=true; input bool InpNewsPMI=true;
input bool InpNewsFedSpeak=true; input bool InpNewsECB=true; input bool InpNewsBOE=true;

input group "=== PRESETS ==="
input int InpA1_SL=1500;input int InpA1_TP=3000;input double InpA1_Risk=1.0;
input int InpA1_TrTrig=30;input int InpA1_TrDist=20;input int InpA1_TrStep=5;input ENUM_TIMEFRAMES InpA1_TF=PERIOD_M2;
input int InpA2_SL=300;input int InpA2_TP=600;input double InpA2_Risk=0.5;
input int InpA2_TrTrig=20;input int InpA2_TrDist=15;input int InpA2_TrStep=3;input ENUM_TIMEFRAMES InpA2_TF=PERIOD_M1;
input int InpA3_SL=800;input int InpA3_TP=1600;input double InpA3_Risk=2.0;
input int InpA3_TrTrig=50;input int InpA3_TrDist=30;input int InpA3_TrStep=10;input ENUM_TIMEFRAMES InpA3_TF=PERIOD_M5;

input group "=== SHORTCUTS ==="
input string InpKeyPlaceOrder="P"; input string InpKeyFlatten="F"; input string InpKeyCollapse="H";

#include "Dashboard.mqh"
#include "TimeManager.mqh"
#include "RiskManager.mqh"
#include "OrderManager.mqh"
#include "TrailManager.mqh"
#include "NewsManager.mqh"
#include "OrigamiManager.mqh"

int g_magic;
PresetParams g_presets[3];
CDashboard    g_dashboard;
CTimeManager  g_timeMgr;
CRiskManager  g_riskMgr;   // Used for dashboard balance/risk display only
COrderManager g_orderMgr;
CTrailManager g_trailMgr;
CNewsManager  g_newsMgr;
COrigamiManager g_origamiMgr;
bool g_initialized = false;
datetime g_lastTpPollTime = 0;  // Throttle for tick-based TP polling
const string BE_LINE_NAME = "Origami_BE_Line";

bool IsMarketOpen(string sym)
{ 
   long tradeMode = SymbolInfoInteger(sym, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED || tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY) return false;
   
   datetime now = TimeCurrent();
   if(now == 0) return false; // Not connected
   
   // Time of day in seconds from midnight
   datetime nowTime = now % 86400;
   
   MqlDateTime dtNow; TimeToStruct(now, dtNow);
   bool hasSessions = false;
   datetime from, to;
   for(uint i=0; i<10; i++)
   {
      // from/to are returned as datetime representing time since midnight (00:00:00)
      if(!SymbolInfoSessionTrade(sym, (ENUM_DAY_OF_WEEK)dtNow.day_of_week, i, from, to)) break;
      hasSessions = true;

      if(to < from) // Overnight session
      {
         if(nowTime >= from || nowTime <= to) return true;
      }
      else
      {
         if(nowTime >= from && nowTime <= to) return true;
      }
   }
   
   // If no session data is returned by broker, we assume it's open if SYMBOL_TRADE_MODE is FULL/LONG/SHORT.
   if(!hasSessions) return true; 
   return false;
}
int TimeDayOfWeek(datetime t){MqlDateTime d;TimeToStruct(t,d);return d.day_of_week;}

int OnInit()
{
   g_magic=InpMagicNumber; g_orderMgr.Init(); g_trailMgr.Init();
   g_newsMgr.SetNYO(InpNyHour,InpNyMinute,InpNySecond,InpUtcOffset);
   g_newsMgr.SetFilters(InpNewsNFP,InpNewsCPI,InpNewsFOMC,InpNewsGDP,InpNewsPPI,
      InpNewsRetail,InpNewsUnemploy,InpNewsISM,InpNewsPMI,InpNewsFedSpeak,InpNewsECB,InpNewsBOE);
   // Presets — v2.0: uses InitPreset helper (DRY)
   InitPreset(g_presets[0], InpA1_SL,InpA1_TP,InpA1_Risk,InpA1_TrTrig,InpA1_TrDist,InpA1_TrStep,InpA1_TF);
   InitPreset(g_presets[1], InpA2_SL,InpA2_TP,InpA2_Risk,InpA2_TrTrig,InpA2_TrDist,InpA2_TrStep,InpA2_TF);
   InitPreset(g_presets[2], InpA3_SL,InpA3_TP,InpA3_Risk,InpA3_TrTrig,InpA3_TrDist,InpA3_TrStep,InpA3_TF);

   string pn=EA_NAME+"_"+IntegerToString(ChartID());
   if(!g_dashboard.CreatePanel(0,pn,0,PANEL_X,PANEL_Y,PANEL_WIDTH,PANEL_HEIGHT))
   { Print("[Main] Dashboard creation FAILED"); return INIT_FAILED; }

   DashboardParams p;
   p.nyHour=InpNyHour;p.nyMinute=InpNyMinute;p.nySecond=InpNySecond;
   p.utcOffset=InpUtcOffset;p.triggerBeforeSec=InpTriggerBefore;
   p.timeframe=InpTimeframe;p.slPoints=InpSlPoints;p.tpPoints=InpTpPoints;
   p.slCandle=InpSlCandle;p.riskPercent=InpRiskPercent;p.entryBufferPoints=InpEntryBufferPoints;
   p.orderMode=InpOrderMode;p.eaMode=InpEaMode;
   p.trailMode=InpTrailMode;p.trailTrigger=InpTrailTrigger;
   p.trailDistance=InpTrailDistance;p.trailStep=InpTrailStep;
   p.beActivatePoints=InpBeActivatePts;p.beLockPoints=InpBeLockPts;p.beEnabled=InpBeEnabled;
   p.candleSource=InpCandleSrc;p.expireEnabled=InpExpireEnabled;p.expireCandles=InpExpireCandles;
   p.targetGrowthPercent=InpTargetGrowthPercent;p.origamiSlMode=ORIGAMI_SL_BE_SPREAD;
   p.marginSafetyPct=InpMarginSafetyPct;
   g_dashboard.SetInitialParams(p);
   g_dashboard.Run(); EventSetTimer(1); g_initialized=true;
   PrintFormat("[Main] %s v%s | %s | Magic=%d", EA_NAME, EA_VERSION, Symbol(), g_magic);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason){EventKillTimer();ObjectDelete(0,BE_LINE_NAME);g_dashboard.Destroy(reason);}

void OnTick()
{
   if(!g_initialized) return;
   DashboardParams p=g_dashboard.GetParams();
   string sym=(p.symbol!="")?p.symbol:Symbol();
   g_dashboard.UpdateSpread((int)SymbolInfoInteger(sym,SYMBOL_SPREAD));
   g_dashboard.UpdateMarketStatus(IsMarketOpen(sym));
   g_orderMgr.CheckOCO(); g_orderMgr.ProcessMissingOrders(); g_orderMgr.CheckExpire(p);
   g_dashboard.UpdateOrderStatus(g_orderMgr.GetStatus());
   g_trailMgr.Process(p);
   
   // Tick-based TP polling fallback (throttled to 1x/sec)
   if(g_origamiMgr.IsActive() && TimeCurrent() > g_lastTpPollTime)
   {
      g_lastTpPollTime = TimeCurrent();
      int totalPositions = PositionsTotal();
      double pointSize = SymbolInfoDouble(sym, SYMBOL_POINT);
      for(int i=0; i<totalPositions; i++)
      {
         ulong t = PositionGetTicket(i);
         if(t <= 0) continue;
         if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         if(PositionGetString(POSITION_SYMBOL) != sym) continue;
         double posTP = PositionGetDouble(POSITION_TP);
         if(posTP > 0 && MathAbs(posTP - g_origamiMgr.GetTP()) > pointSize)
         {
            HandleTPChange(posTP, sym);
            break;
         }
      }
   }

   // Origami Engine Check
   if(g_origamiMgr.IsActive())
   {
      if(!p.origamiEnabled)
      {
         g_origamiMgr.Reset();
         g_dashboard.UpdateOrigamiStatus("Origami: OFF");
      }
      else
      {
         int posCount = 0;
         int totalPositions = PositionsTotal();
         for(int i=0; i<totalPositions; i++){
            if(PositionGetTicket(i)>0 && PositionGetInteger(POSITION_MAGIC)==g_magic && PositionGetString(POSITION_SYMBOL)==p.symbol) posCount++;
         }
         if(posCount == 0) {
            g_origamiMgr.Reset();
            g_dashboard.UpdateOrigamiStatus("Origami: INACTIVE");
         }
         else {
            double currentPrice = (g_origamiMgr.GetOrderType() == ORDER_TYPE_BUY) ? SymbolInfoDouble(p.symbol, SYMBOL_ASK) : SymbolInfoDouble(p.symbol, SYMBOL_BID);
            double lotToAdd = g_origamiMgr.CheckThresholds(currentPrice);
            if(lotToAdd > 0)
            {
               // Margin check before placing add-in
               double marginReq = 0;
               if(OrderCalcMargin(g_origamiMgr.GetOrderType()==ORDER_TYPE_BUY?ORDER_TYPE_BUY:ORDER_TYPE_SELL, p.symbol, lotToAdd, currentPrice, marginReq))
               {
                  if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) >= marginReq)
                  {
                     double tp = g_origamiMgr.GetTP();
                     if(g_origamiMgr.GetOrderType() == ORDER_TYPE_BUY) g_orderMgr.BuyMarketEx(lotToAdd, 0, tp, p.symbol);
                     else g_orderMgr.SellMarketEx(lotToAdd, 0, tp, p.symbol);
                  }
                  else PrintFormat("[Origami] SKIP add-in: margin insufficient");
               }
            }
            
            // v1.50: Always apply DIAD-computed SL (no mode selector)
            double targetSL = g_origamiMgr.GetCurrentSLTarget();
            if(targetSL > 0)
            {
               CTrade trade;
               for(int i=0; i<totalPositions; i++)
               {
                  ulong t = PositionGetTicket(i);
                  if(t <= 0) continue;
                  if(PositionGetInteger(POSITION_MAGIC)==g_magic && PositionGetString(POSITION_SYMBOL)==p.symbol)
                  {
                     double sl = PositionGetDouble(POSITION_SL);
                     int type = (int)PositionGetInteger(POSITION_TYPE);
                     bool modify = false;
                     if(type == POSITION_TYPE_BUY && (sl < targetSL || sl == 0)) modify = true;
                     if(type == POSITION_TYPE_SELL && (sl > targetSL || sl == 0)) modify = true;
                     if(modify) trade.PositionModify(t, targetSL, PositionGetDouble(POSITION_TP));
                  }
               }
            }
            
            // Dashboard origami status sync
            int tCount = g_origamiMgr.GetTriggeredCount();
            g_dashboard.UpdateOrigamiStatus("Origami: ACTIVE " + IntegerToString(tCount) + "/3");
            if(g_origamiMgr.IsDiadFallback())
               g_dashboard.UpdateDiadStatus("FALLBACK: mathematical edge case");
            else
               g_dashboard.UpdateDiadStatus("DIAD: OK | Calc Risk (C): -$" + DoubleToString(MathAbs(g_origamiMgr.GetDiadConstC()), 0));
            double tr1,tr2,tr3,lt1,lt2,lt3; bool fg1,fg2,fg3;
            g_origamiMgr.GetStepInfo(0,tr1,lt1,fg1); g_origamiMgr.GetStepInfo(1,tr2,lt2,fg2); g_origamiMgr.GetStepInfo(2,tr3,lt3,fg3);
            string baseLine = "Base: "+DoubleToString(g_origamiMgr.GetBaseLot(),2)+" | CalcRisk: -$" + DoubleToString(MathAbs(g_origamiMgr.GetDiadConstC()),0);
            g_dashboard.UpdateOrigamiInfo(
               "Step 1: "+(fg1?"FIRED ":"")+DoubleToString(tr1,2)+" | "+DoubleToString(lt1,2)+" lots",
               "Step 2: "+(fg2?"FIRED ":"")+DoubleToString(tr2,2)+" | "+DoubleToString(lt2,2)+" lots",
               "Step 3: "+(fg3?"FIRED ":"")+DoubleToString(tr3,2)+" | "+DoubleToString(lt3,2)+" lots",
               baseLine
            );
         }
      }
   }
}

// Centralized TP change handler — called from both OnTradeTransaction and OnTick polling
void HandleTPChange(double newTP, string symbol)
{
   double oldTP = g_origamiMgr.GetTP();
   PrintFormat("[Origami] TP DRAGGED: %.5f -> %.5f", oldTP, newTP);
   g_dashboard.UpdateStatus("TP updated -> recalculating...");
   
   if(g_origamiMgr.RecalculateTP(newTP))
   {
      // Sync new TP to ALL open positions with our magic
      CTrade syncTrade;
      int totalPositions = PositionsTotal();
      double pointSize = SymbolInfoDouble(symbol, SYMBOL_POINT);
      for(int i=0; i<totalPositions; i++)
      {
         ulong t = PositionGetTicket(i);
         if(t <= 0) continue;
         if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
         if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
         double curTP = PositionGetDouble(POSITION_TP);
         if(MathAbs(curTP - newTP) > pointSize)
         {
            syncTrade.PositionModify(t, PositionGetDouble(POSITION_SL), newTP);
         }
      }
      g_dashboard.UpdateStatus("Origami recalculated OK");
   }
   else
   {
      g_dashboard.UpdateStatus("TP recalc skipped (invalid)");
   }
}

void ApplyNewsToTiming()
{
   NewsEvent ev=g_newsMgr.GetNextEvent(); if(ev.time==0) return;
   DashboardParams p=g_dashboard.GetParams();
   datetime nyTime=ev.time+p.utcOffset*3600; MqlDateTime dt; TimeToStruct(nyTime,dt);
   g_dashboard.ApplyTimingFromNews(dt.hour,dt.min,dt.sec);
   g_dashboard.UpdateStatus("Applied: "+ev.name);
}

void OnTimer()
{
   if(!g_initialized) return;
   DashboardParams p=g_dashboard.GetParams();
   g_dashboard.UpdateNYClock(g_timeMgr.GetNYTimeString(p.utcOffset), g_timeMgr.GetNYAmPmString(p.utcOffset), g_timeMgr.GetNYDateString(p.utcOffset));
   g_newsMgr.SetNYO(p.nyHour,p.nyMinute,p.nySecond,p.utcOffset);
   g_newsMgr.SetNYOOnly(g_dashboard.NYOOnlyMode);
   g_newsMgr.Update();
   // v0.3: Detect custom timing — if user changed H:M:S from input defaults, show "Custom"
   bool isCustom = (p.nyHour!=InpNyHour || p.nyMinute!=InpNyMinute || p.nySecond!=InpNySecond);
   if(isCustom)
   {
      g_dashboard.UpdateNews(StringFormat("Custom | %02d:%02d", p.nyHour, p.nyMinute));
   }
   else g_dashboard.UpdateNews(g_newsMgr.GetNextEventString());
   if(g_dashboard.AutoNewsEnabled && g_newsMgr.HasEvent()) ApplyNewsToTiming();
   if(p.symbol!="")
   { double bal=0,rAmt=0,rwAmt=0,lot=0;
     int displaySlPoints = p.slPoints;
     if (p.slCandle) {
        int cIdx = (p.candleSource == CANDLE_CURRENT) ? 0 : 1;
        double candleHigh = iHigh(p.symbol, p.timeframe, cIdx);
        double candleLow = iLow(p.symbol, p.timeframe, cIdx);
        double point = SymbolInfoDouble(p.symbol, SYMBOL_POINT);
        if (point > 0)
           displaySlPoints = (int)MathRound((candleHigh - candleLow) / point) + 2 * p.entryBufferPoints;
     }
     g_riskMgr.CalcRiskRewardInfo(p.symbol,p.riskPercent,displaySlPoints,p.tpPoints,bal,rAmt,rwAmt,lot);
     g_dashboard.UpdateBalanceInfo(bal,rAmt,rwAmt,lot);
     // v0.2: Equity + P/L merged line
     double equity=AccountInfoDouble(ACCOUNT_EQUITY);
     double profit=AccountInfoDouble(ACCOUNT_PROFIT);
     g_dashboard.UpdateEquityPL(equity, profit);
     // Realtime Total Exposed & Risk/Reward
     double totalBuyLots = 0;
     double totalSellLots = 0;
     double totalProfitAtTP = 0;
     double totalLossAtSL = 0;
     double weightedEntry = 0;
     double totalLots = 0;
     int totalPositions = PositionsTotal();
     for(int i=0; i<totalPositions; i++) {
        ulong t = PositionGetTicket(i);
        if(t <= 0) continue;
        if(PositionGetInteger(POSITION_MAGIC) != g_magic || PositionGetString(POSITION_SYMBOL) != p.symbol) continue;
        
        double vol = PositionGetDouble(POSITION_VOLUME);
        double price = PositionGetDouble(POSITION_PRICE_OPEN);
        ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
        if(type == POSITION_TYPE_BUY) totalBuyLots += vol;
        else totalSellLots += vol;
        totalLots += vol;
        weightedEntry += price * vol;
        
        double tp = PositionGetDouble(POSITION_TP);
        double sl = PositionGetDouble(POSITION_SL);
        double pftTP = 0, pftSL = 0;
        ENUM_ORDER_TYPE orderType = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
        
        if(tp > 0) { if(OrderCalcProfit(orderType, p.symbol, vol, price, tp, pftTP)) totalProfitAtTP += pftTP; }
        if(sl > 0) { if(OrderCalcProfit(orderType, p.symbol, vol, price, sl, pftSL)) totalLossAtSL += pftSL; }
     }
     
     double netExposed = totalBuyLots - totalSellLots;
     int expType = 2; // Flat
     if(netExposed > 0.001) expType = 0; // Buy
     else if(netExposed < -0.001) expType = 1; // Sell
     g_dashboard.UpdateTotalExposed(MathAbs(netExposed), expType);
     
     double absLoss = MathAbs(totalLossAtSL);
     g_dashboard.UpdateRealtimeRR(totalProfitAtTP, absLoss, rAmt);
     double riskPc = (bal > 0) ? (absLoss / bal) * 100.0 : 0.0;
     g_dashboard.UpdateRealtimeRiskPercent(riskPc, p.origamiMaxRiskPercent);

     // ── Aggregate BE line (always visible when positions exist) ──
      if(totalLots > 0)
      {
         double avgEntry = weightedEntry / totalLots;
         double spread = (double)SymbolInfoInteger(p.symbol, SYMBOL_SPREAD) * SymbolInfoDouble(p.symbol, SYMBOL_POINT);
         bool isBuyDominant = (totalBuyLots >= totalSellLots);
         double beLine = isBuyDominant ? avgEntry + spread : avgEntry - spread;
         int digits = (int)SymbolInfoInteger(p.symbol, SYMBOL_DIGITS);
         beLine = NormalizeDouble(beLine, digits);
         
         if(ObjectFind(0, BE_LINE_NAME) < 0)
         {
            ObjectCreate(0, BE_LINE_NAME, OBJ_HLINE, 0, 0, beLine);
            ObjectSetInteger(0, BE_LINE_NAME, OBJPROP_COLOR, clrYellow);
            ObjectSetInteger(0, BE_LINE_NAME, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, BE_LINE_NAME, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, BE_LINE_NAME, OBJPROP_BACK, true);
            ObjectSetString(0, BE_LINE_NAME, OBJPROP_TEXT, "BE: " + DoubleToString(beLine, digits));
         }
         else
         {
            ObjectSetDouble(0, BE_LINE_NAME, OBJPROP_PRICE, beLine);
            ObjectSetString(0, BE_LINE_NAME, OBJPROP_TEXT, "BE: " + DoubleToString(beLine, digits));
         }
      }
      else
      {
         ObjectDelete(0, BE_LINE_NAME);
      }
   }
   if(p.symbol==""){g_dashboard.UpdateStatus("No symbol");return;}
   if(p.eaMode==EA_AUTO)
   { g_timeMgr.CalculateTriggerTime(p); g_dashboard.UpdateCountdown(g_timeMgr.GetCountdownString());
     if(g_timeMgr.IsTimeToTrade())
     { g_dashboard.UpdateStatus("TRIGGERING...");
       if(g_orderMgr.PlaceOCOOrders(p)){g_timeMgr.MarkFired(p);g_dashboard.UpdateStatus("Orders placed ✓");}
       else g_dashboard.UpdateStatus("Order FAILED");
       g_dashboard.UpdateOrderStatus(g_orderMgr.GetStatus()); }
     else if(g_timeMgr.HasFiredToday()) g_dashboard.UpdateStatus("Fired — change schedule");
     else g_dashboard.UpdateStatus("AUTO — Waiting..."); }
   else{g_dashboard.UpdateCountdown("MANUAL");g_dashboard.UpdateStatus("Manual mode");}
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   // v0.72: Direct button click handling — bypasses CAppDialog event routing
   // CRITICAL: Do NOT return early — command queue + origami engine must still run
   bool handled = false;
   



   // v0.89: Native Object Click is the ONLY reliable event for buttons.
   // EVENT_MAP was deleted because its internal hit-testing caused the "1 goc nho" bug.
   // HandleMouseClick was deleted because CHARTEVENT_CLICK doesn't fire on objects.
   // So HandleDirectClick is the single source of truth.
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(g_dashboard.HandleDirectClick(sparam))
      {
         handled = true;
         ChartRedraw();
      }
   }
   
   // ALWAYS pass to CAppDialog except CHART_CHANGE, OBJECT_CHANGE, and handled OBJECT_CLICKs
   if(!handled && id!=CHARTEVENT_CHART_CHANGE && id!=CHARTEVENT_OBJECT_CHANGE)
      g_dashboard.ChartEvent(id,lparam,dparam,sparam);

   // v2.0: Mark dirty on edit field END only (user finished typing)
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
      g_dashboard.MarkDirtyPublic();

   DashboardParams p = g_dashboard.GetParams();
   string sym = (p.symbol != "") ? p.symbol : Symbol();

   // Keyboard shortcuts → push to command queue
   if(id == CHARTEVENT_KEYDOWN)
   {
      string k = ShortToString((ushort)lparam); StringToUpper(k);
      string kP = InpKeyPlaceOrder; StringToUpper(kP);
      string kF = InpKeyFlatten;    StringToUpper(kF);
      string kC = InpKeyCollapse;   StringToUpper(kC);
      if(k == kP)      g_dashboard.PushCmdPublic(CMD_MANUAL_PLACE);
      else if(k == kF)  g_dashboard.PushCmdPublic(CMD_FLATTEN_ALL);
      else if(k == kC) { static bool h = false; if(!h){g_dashboard.Hide();h=true;}else{g_dashboard.Show();h=false;} }
   }

   // v2.0: Command queue dispatcher — process all pending commands
   while(g_dashboard.HasCommand())
   {
      ENUM_DASHBOARD_CMD cmd = g_dashboard.PopCommand();
      switch(cmd)
      {
         case CMD_APPLY_NEXT:
            ApplyNewsToTiming();
            break;
         case CMD_PRESET:
         {
            int idx = g_dashboard.PresetIndex;
            if(idx >= 0 && idx < 6) g_dashboard.ApplyPreset(g_presets[idx]);
            g_dashboard.UpdateStatus("Preset applied ✓");
            break;
         }
         case CMD_MANUAL_PLACE:
            if(g_orderMgr.PlaceOCOOrders(p)) g_dashboard.UpdateStatus("Stop orders placed ✓");
            else g_dashboard.UpdateStatus("Order FAILED");
            g_dashboard.UpdateOrderStatus(g_orderMgr.GetStatus());
            break;
         case CMD_CANCEL_ALL:
            g_orderMgr.CancelAllPending(sym);
            g_dashboard.UpdateStatus("Pending cancelled");
            g_dashboard.UpdateOrderStatus("IDLE");
            break;
         case CMD_FLATTEN_ALL:
            g_orderMgr.FlattenAll(sym);
            g_origamiMgr.Reset();
            g_dashboard.UpdateOrigamiStatus("Origami: INACTIVE");
            g_dashboard.UpdateStatus("FLAT — all closed");
            g_dashboard.UpdateOrderStatus("FLAT");
            break;
         case CMD_APPLY_TRAIL:
            g_orderMgr.ApplySettings(p);
            g_dashboard.UpdateStatus("Trailing applied ✓");
            break;
         case CMD_APPLY_BE:
            g_trailMgr.ForceBreakeven(p);
            g_dashboard.UpdateStatus("BE applied ✓");
            break;
         case CMD_BUY_MKT:
            if(g_orderMgr.BuyMarket(p)) g_dashboard.UpdateStatus("BUY filled ✓");
            else g_dashboard.UpdateStatus("BUY FAILED");
            break;
         case CMD_SELL_MKT:
            if(g_orderMgr.SellMarket(p)) g_dashboard.UpdateStatus("SELL filled ✓");
            else g_dashboard.UpdateStatus("SELL FAILED");
            break;
         case CMD_LOCK:
            if(g_orderMgr.LockAll(sym)) { g_origamiMgr.Reset(); g_dashboard.UpdateOrigamiStatus("Origami: INACTIVE"); g_dashboard.UpdateStatus("LOCKED ✓"); }
            else g_dashboard.UpdateStatus("LOCK FAILED");
            break;
         case CMD_REVERSE:
            if(g_orderMgr.ReverseAll(p)) { g_origamiMgr.Reset(); g_dashboard.UpdateOrigamiStatus("Origami: INACTIVE"); g_dashboard.UpdateStatus("REVERSED ✓"); }
            else g_dashboard.UpdateStatus("REVERSE FAILED");
            break;
         case CMD_BREAK_EVEN:
            g_trailMgr.ForceBreakeven(p);
            g_dashboard.UpdateStatus("BE applied ✓");
            break;
         case CMD_ORIGAMI_APPLY_NOW:
             if(p.origamiEnabled) {
                g_origamiMgr.SetMarginSafety(p.marginSafetyPct); // v1.51: DIAD
                g_origamiMgr.ApplyNow(p);
                g_dashboard.UpdateOrigamiStatus("Origami: APPLIED");
             }
            break;
         case CMD_ORIGAMI_CLEAR:
            g_origamiMgr.Reset();
            g_dashboard.UpdateOrigamiStatus("Origami: CLEARED");
            g_dashboard.UpdateStatus("Origami steps cleared");
            break;
         default: break;
      }
   }
}

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
{ 
   g_orderMgr.OnTransaction(trans,request,result); 
   g_dashboard.UpdateOrderStatus(g_orderMgr.GetStatus()); 
   
   // Detect TP modification from chart drag (TRADE_TRANSACTION_POSITION)
   if(trans.type == TRADE_TRANSACTION_POSITION && g_origamiMgr.IsActive())
   {
      ulong posTicket = trans.position;
      if(PositionSelectByTicket(posTicket) && PositionGetInteger(POSITION_MAGIC) == g_magic)
      {
         string posSymbol = PositionGetString(POSITION_SYMBOL);
         double newTP = PositionGetDouble(POSITION_TP);
         if(newTP > 0 && MathAbs(newTP - g_origamiMgr.GetTP()) > SymbolInfoDouble(posSymbol, SYMBOL_POINT))
         {
            HandleTPChange(newTP, posSymbol);
         }
      }
   }
   
   // Detect new position entry for origami initialization
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      ulong dealTicket = trans.deal;
      if(HistoryDealSelect(dealTicket) && HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == g_magic)
      {
         long entryType = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
         if(entryType == DEAL_ENTRY_IN)
         {
            if(!g_origamiMgr.IsActive())
            {
               DashboardParams p = g_dashboard.GetParams();
               if(!p.origamiEnabled) return;
               g_origamiMgr.SetMarginSafety(p.marginSafetyPct);
               double bal = AccountInfoDouble(ACCOUNT_BALANCE);
               double entry = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
               int orderType = (int)HistoryDealGetInteger(dealTicket, DEAL_TYPE); 
               
               long posId = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
               if(PositionSelectByTicket(posId))
               {
                  double tp = PositionGetDouble(POSITION_TP);
                  if(tp > 0)
                  {
                     g_origamiMgr.CalculateOrigami(bal, p.targetGrowthPercent, p.riskPercent, p.origamiMaxRiskPercent, entry, tp, p.slPoints, orderType, p.symbol, p.addInPct1, p.addInPct2, p.addInPct3);
                  }
               }
            }
         }
      }
   }
}
