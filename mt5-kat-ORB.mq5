//+------------------------------------------------------------------+
//|                                                   mt5-kat-ORB.mq5  |
//|                            KAT Opening Range Breakout              |
//|                                                      Version 0.73 |
//+------------------------------------------------------------------+
#property copyright   "KAT Opening Range Breakout"
#property link        ""
#property description "KAT Opening Range Breakout"
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

input int             InpSlPoints        = 1500;
input int             InpTpPoints        = 3000;
input bool            InpSlCandle        = false;
input ENUM_ORDER_MODE InpOrderMode       = MODE_BOTH;
input int             InpEntryBufferPoints= 5;

input group "=== RISK ==="
input double          InpRiskPercent     = 1.0;


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



input group "=== PRESETS ==="
input int InpA1_SL=1500;input int InpA1_TP=3000;input double InpA1_Risk=1.0;
input int InpA1_TrTrig=30;input int InpA1_TrDist=20;input int InpA1_TrStep=5;input ENUM_TIMEFRAMES InpA1_TF=PERIOD_M2;
input int InpA2_SL=300;input int InpA2_TP=600;input double InpA2_Risk=0.5;
input int InpA2_TrTrig=20;input int InpA2_TrDist=15;input int InpA2_TrStep=3;input ENUM_TIMEFRAMES InpA2_TF=PERIOD_M1;
input int InpA3_SL=800;input int InpA3_TP=1600;input double InpA3_Risk=2.0;
input int InpA3_TrTrig=50;input int InpA3_TrDist=30;input int InpA3_TrStep=10;input ENUM_TIMEFRAMES InpA3_TF=PERIOD_M5;



#include "Dashboard.mqh"
#include "TimeManager.mqh"
#include "RiskManager.mqh"
#include "OrderManager.mqh"
#include "TrailManager.mqh"
#include "NewsManager.mqh"

int g_magic;
PresetParams g_presets[3];
CDashboard    g_dashboard;
CTimeManager  g_timeMgr;
CRiskManager  g_riskMgr;   // Used for dashboard balance/risk display only
COrderManager g_orderMgr_M2;
COrderManager g_orderMgr_M5;
CTrailManager g_trailMgr_M2;
CTrailManager g_trailMgr_M5;
CNewsManager  g_newsMgr;

bool g_initialized = false;
datetime g_lastTpPollTime = 0;  // Throttle for tick-based TP polling
const string BE_LINE_NAME = "Aggregate_BE_Line";

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
   g_magic=InpMagicNumber; 
   g_orderMgr_M2.Init(); g_trailMgr_M2.Init();
   g_orderMgr_M5.Init(); g_trailMgr_M5.Init();
   g_newsMgr.SetNYO(InpNyHour,InpNyMinute,InpNySecond,InpUtcOffset);

   // Presets — v2.0: uses InitPreset helper (DRY)
   InitPreset(g_presets[0], InpA1_SL,InpA1_TP,InpA1_Risk,InpA1_TrTrig,InpA1_TrDist,InpA1_TrStep,InpA1_TF);
   InitPreset(g_presets[1], InpA2_SL,InpA2_TP,InpA2_Risk,InpA2_TrTrig,InpA2_TrDist,InpA2_TrStep,InpA2_TF);
   InitPreset(g_presets[2], InpA3_SL,InpA3_TP,InpA3_Risk,InpA3_TrTrig,InpA3_TrDist,InpA3_TrStep,InpA3_TF);

   string pn=EA_NAME+"_"+IntegerToString(ChartID());
   if(!g_dashboard.CreatePanel(0,pn,0,PANEL_X,PANEL_Y,PANEL_WIDTH,PANEL_HEIGHT))
   { Print("[Main] Dashboard creation FAILED"); return INIT_FAILED; }

   SystemConfig cfg;
   cfg.main.nyHour=InpNyHour;cfg.main.nyMinute=InpNyMinute;cfg.main.nySecond=InpNySecond;
   cfg.main.utcOffset=InpUtcOffset;cfg.main.triggerBeforeSec=InpTriggerBefore;
   cfg.main.timeframe=InpTimeframe;cfg.main.slPoints=InpSlPoints;cfg.main.tpPoints=InpTpPoints;
   cfg.main.slCandle=InpSlCandle;cfg.main.riskPercent=InpRiskPercent;cfg.main.entryBufferPoints=InpEntryBufferPoints;
   cfg.main.orderMode=InpOrderMode;cfg.main.trailMode=InpTrailMode;cfg.main.trailTrigger=InpTrailTrigger;
   cfg.main.trailDistance=InpTrailDistance;cfg.main.trailStep=InpTrailStep;
   cfg.main.beActivatePoints=InpBeActivatePts;cfg.main.beLockPoints=InpBeLockPts;cfg.main.beEnabled=InpBeEnabled;
   cfg.main.unfavorMoveOn=false; cfg.main.unfavorMovePts=100;
   cfg.main.touchMidOn=false;
   cfg.main.unfilledCandlesOn=false; cfg.main.unfilledCandles=2;
   cfg.m2 = cfg.main; cfg.m2.timeframe = PERIOD_M2; cfg.m2.comment = "orb-2m";
   cfg.m5 = cfg.main; cfg.m5.timeframe = PERIOD_M5; cfg.m5.comment = "orb-5m";

   g_dashboard.SetInitialParams(cfg);
   g_dashboard.Run(); EventSetTimer(1); g_initialized=true;
   PrintFormat("[Main] %s v%s | %s | Magic=%d", EA_NAME, EA_VERSION, Symbol(), g_magic);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason){EventKillTimer();ObjectDelete(0,BE_LINE_NAME);g_dashboard.Destroy(reason);}

void OnTick()
{
   if(!g_initialized) return;
   SystemConfig cfg=g_dashboard.GetParams();
   string sym=(cfg.main.symbol!="")?cfg.main.symbol:Symbol();
   g_dashboard.UpdateSpread((int)SymbolInfoInteger(sym,SYMBOL_SPREAD));
   g_dashboard.UpdateMarketStatus(IsMarketOpen(sym));
   
   g_orderMgr_M2.CheckAutoCancel(cfg.globalOverride ? cfg.main : cfg.m2, g_timeMgr.GetTargetTime());
   g_orderMgr_M5.CheckAutoCancel(cfg.globalOverride ? cfg.main : cfg.m5, g_timeMgr.GetTargetTime());
   
   string s2 = g_orderMgr_M2.GetStatus();
   string s5 = g_orderMgr_M5.GetStatus();
   string combined = "2m: " + s2 + " | 5m: " + s5;
   g_dashboard.UpdateOrderStatus(combined);
   
   g_trailMgr_M2.Process(cfg.globalOverride ? cfg.main : cfg.m2);
   g_trailMgr_M5.Process(cfg.globalOverride ? cfg.main : cfg.m5);
}



void OnTimer()
{
   if(!g_initialized) return;
   SystemConfig cfg=g_dashboard.GetParams();
   DashboardParams p=cfg.main; // Time/Display mostly uses MAIN params
   g_dashboard.UpdateNYClock(g_timeMgr.GetNYTimeString(p.utcOffset), g_timeMgr.GetNYAmPmString(p.utcOffset), g_timeMgr.GetNYDateString(p.utcOffset));
   g_newsMgr.SetNYO(p.nyHour,p.nyMinute,p.nySecond,p.utcOffset);
   g_newsMgr.Update();
   g_dashboard.UpdateNews(g_newsMgr.GetNextEventString());
   g_dashboard.UpdateTimer(g_timeMgr.GetCountdownString());
   if(p.symbol!="")
   { double bal=0,rAmt=0,rwAmt=0,lot=0;
     int displaySlPoints = p.slPoints;
     if (p.slCandle) {
        int cIdx = 0;
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
     g_dashboard.UpdateRealtimeRiskPercent(riskPc, p.riskPercent);

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
   
   g_timeMgr.CalculateTriggerTime(p);
   datetime nyoTime = g_timeMgr.GetTargetTime();
   
   bool tradeM2 = cfg.globalOverride ? p.isActive : cfg.m2.isActive;
   bool tradeM5 = cfg.globalOverride ? p.isActive : cfg.m5.isActive;
   
   if(tradeM2) {
      DashboardParams pm2 = cfg.globalOverride ? p : cfg.m2;
      pm2.symbol = p.symbol;
      g_orderMgr_M2.ProcessORB(pm2, nyoTime);
      g_orderMgr_M2.CheckAutoCancel(pm2, nyoTime);
   }
   
   if(tradeM5) {
      DashboardParams pm5 = cfg.globalOverride ? p : cfg.m5;
      pm5.symbol = p.symbol;
      g_orderMgr_M5.ProcessORB(pm5, nyoTime);
      g_orderMgr_M5.CheckAutoCancel(pm5, nyoTime);
   }
   
   string s2 = tradeM2 ? g_orderMgr_M2.GetStatus() : "OFF";
   string s5 = tradeM5 ? g_orderMgr_M5.GetStatus() : "OFF";
   g_dashboard.UpdateOrderStatus("2m: " + s2 + " | 5m: " + s5);
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

   SystemConfig cfg = g_dashboard.GetParams();
   DashboardParams p = cfg.main;
   string sym = (p.symbol != "") ? p.symbol : Symbol();

   // Keyboard shortcuts → push to command queue
   if(id == CHARTEVENT_KEYDOWN)
   {
      string k = ShortToString((ushort)lparam); StringToUpper(k);

   }

   // v2.0: Command queue dispatcher — process all pending commands
   while(g_dashboard.HasCommand())
   {
      ENUM_DASHBOARD_CMD cmd = g_dashboard.PopCommand();
      switch(cmd)
      {

         case CMD_PRESET:
         {
            int idx = g_dashboard.PresetIndex;
            if(idx >= 0 && idx < 6) g_dashboard.ApplyPreset(g_presets[idx]);
            g_dashboard.UpdateStatus("Preset applied ✓");
            break;
         }

         default: break;
      }
   }
}

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
{ 
}
