//+------------------------------------------------------------------+
//|                                                   mt5-kat-ORB.mq5  |
//|                            KAT Opening Range Breakout              |
//|                                                      Version 0.73 |
//+------------------------------------------------------------------+
#property copyright   "KAT Opening Range Breakout"
#property link        ""
#property description "KAT Opening Range Breakout"
#property description "Automated Break & Retest range strategy on 2m/5m NYO candles."
#property description "Features: Auto-cancel pending, Global Trailing, Breakeven, Advanced Risk Management."

#include "Defines.mqh"

input group "------------- INSTANCE -------------"
input int             InpMagicNumber       = 202605011;   // Magic Number
input ENUM_EA_MODE    InpEaMode            = EA_AUTO;     // EA Operating Mode

input group "------------- SCHEDULE -------------"
input int             InpNyHour            = 9;           // NY Open Hour (Broker Time)
input int             InpNyMinute          = 30;          // NY Open Minute
input int             InpNySecond          = 0;           // NY Open Second
input int             InpUtcOffset         = -4;          // Broker UTC Offset (NY Time)

input group "------------- GLOBAL SETTING -------------"
input bool            InpGlobalOverride    = true;        // Override 2m & 5m with Global (Global Mode)
input ENUM_TIMEFRAMES InpTimeframe         = PERIOD_M2;   // Default Global Timeframe
input int             InpSlPoints          = 1500;        // Stop Loss (Points)
input int             InpTpPoints          = 1500;        // Take Profit (Points)
input bool            InpSlCandle          = false;       // Use Candle Extremes for SL
input ENUM_ORDER_MODE InpOrderMode         = MODE_BOTH;   // Allowed Trade Directions
input int             InpEntryBufferPoints = 5;           // Entry/SL Buffer (Points)
input bool            InpCustomRetestOn    = true;        // Use Custom Retest Candle
input int             InpCustomRetestMin   = 1;           // Retest Candle Timeframe (Min)
input double          InpRiskPercent       = 2.0;         // Risk per Trade (%)
input double          InpFixLot            = 2.0;         // Fix Lot Size
input bool            InpRiskModeOn        = true;        // Risk Management (true=Risk%, false=Fix Lot)

input group "------------- 2M SETTING -------------"
input int             Inp2MSlPoints          = 1500;        // 2m: Stop Loss (Points)
input int             Inp2MTpPoints          = 1500;        // 2m: Take Profit (Points)
input bool            Inp2MSlCandle          = false;       // 2m: Use Candle Extremes for SL
input ENUM_ORDER_MODE Inp2MOrderMode         = MODE_BOTH;   // 2m: Allowed Trade Directions
input int             Inp2MEntryBufferPoints = 5;           // 2m: Entry/SL Buffer (Points)
input bool            Inp2MCustomRetestOn    = true;        // 2m: Use Custom Retest Candle
input int             Inp2MCustomRetestMin   = 1;           // 2m: Retest Candle Timeframe (Min)
input double          Inp2MRiskPercent       = 2.0;         // 2m: Risk per Trade (%)
input double          Inp2MFixLot            = 2.0;         // 2m: Fix Lot Size
input bool            Inp2MRiskModeOn        = true;        // 2m: Risk Management (true=Risk%, false=Fix Lot)

input group "------------- 5M SETTING -------------"
input int             Inp5MSlPoints          = 1500;        // 5m: Stop Loss (Points)
input int             Inp5MTpPoints          = 1500;        // 5m: Take Profit (Points)
input bool            Inp5MSlCandle          = false;       // 5m: Use Candle Extremes for SL
input ENUM_ORDER_MODE Inp5MOrderMode         = MODE_BOTH;   // 5m: Allowed Trade Directions
input int             Inp5MEntryBufferPoints = 5;           // 5m: Entry/SL Buffer (Points)
input bool            Inp5MCustomRetestOn    = true;        // 5m: Use Custom Retest Candle
input int             Inp5MCustomRetestMin   = 1;           // 5m: Retest Candle Timeframe (Min)
input double          Inp5MRiskPercent       = 2.0;         // 5m: Risk per Trade (%)
input double          Inp5MFixLot            = 2.0;         // 5m: Fix Lot Size
input bool            Inp5MRiskModeOn        = true;        // 5m: Risk Management (true=Risk%, false=Fix Lot)

input group "------------- TRAIL -------------"
input ENUM_TRAIL_MODE InpTrailMode         = TM_CHASE;    // Trailing Stop Mode
input int             InpTrailTrigger      = 1500;        // Trailing Trigger (Points)
input int             InpTrailDistance     = 500;         // Trailing Distance (Points)
input int             InpTrailStep         = 1;           // Trailing Step (Points)
input int             InpBeActivatePts     = 200;         // Breakeven Activation (Points)
input int             InpBeLockPts         = 50;          // Breakeven Lock Profit (Points)
input bool            InpBeEnabled         = false;       // Enable Breakeven

input group "------------- AUTO CANCEL -------------"
input bool            InpExpireEnabled     = false;       // Enable Expiration by Candles
input int             InpExpireCandles     = 2;           // Cancel after N Unfilled Candles

input group "------------- BIG MOMENTUM -------------"
sinput string         sep_big_m            = "--------------------------------"; // --------------------------------

input group "------------- PRESETS -------------"
sinput string         sep_preset_mA        = "---------- SET mA ----------"; // ---------- SET mA ----------
input int             InpmA_SL             = 1500;        // Set mA: Stop Loss
input int             InpmA_TP             = 1500;        // Set mA: Take Profit
input double          InpmA_Risk           = 1.0;         // Set mA: Risk %
input int             InpmA_TrTrig         = 1500;        // Set mA: Trail Trigger
input int             InpmA_TrDist         = 500;         // Set mA: Trail Distance
input int             InpmA_TrStep         = 1;           // Set mA: Trail Step
input ENUM_TIMEFRAMES InpmA_TF             = PERIOD_M2;   // Set mA: Timeframe

sinput string         sep_preset_mB        = "---------- SET mB ----------"; // ---------- SET mB ----------
input int             InpmB_SL             = 300;         // Set mB: Stop Loss
input int             InpmB_TP             = 600;         // Set mB: Take Profit
input double          InpmB_Risk           = 0.5;         // Set mB: Risk %
input int             InpmB_TrTrig         = 20;          // Set mB: Trail Trigger
input int             InpmB_TrDist         = 15;          // Set mB: Trail Distance
input int             InpmB_TrStep         = 3;           // Set mB: Trail Step
input ENUM_TIMEFRAMES InpmB_TF             = PERIOD_M1;   // Set mB: Timeframe

sinput string         sep_preset_mC        = "---------- SET mC ----------"; // ---------- SET mC ----------
input int             InpmC_SL             = 800;         // Set mC: Stop Loss
input int             InpmC_TP             = 1600;        // Set mC: Take Profit
input double          InpmC_Risk           = 2.0;         // Set mC: Risk %
input int             InpmC_TrTrig         = 50;          // Set mC: Trail Trigger
input int             InpmC_TrDist         = 30;          // Set mC: Trail Distance
input int             InpmC_TrStep         = 10;          // Set mC: Trail Step
input ENUM_TIMEFRAMES InpmC_TF             = PERIOD_M5;   // Set mC: Timeframe

sinput string         sep_preset_2A        = "---------- SET 2A ----------"; // ---------- SET 2A ----------
input int             Inp2A_SL             = 1500;        // Set 2A: Stop Loss
input int             Inp2A_TP             = 1500;        // Set 2A: Take Profit
input double          Inp2A_Risk           = 1.0;         // Set 2A: Risk %
input int             Inp2A_TrTrig         = 1500;        // Set 2A: Trail Trigger
input int             Inp2A_TrDist         = 500;         // Set 2A: Trail Distance
input int             Inp2A_TrStep         = 1;           // Set 2A: Trail Step
input ENUM_TIMEFRAMES Inp2A_TF             = PERIOD_M2;   // Set 2A: Timeframe

sinput string         sep_preset_2B        = "---------- SET 2B ----------"; // ---------- SET 2B ----------
input int             Inp2B_SL             = 300;         // Set 2B: Stop Loss
input int             Inp2B_TP             = 600;         // Set 2B: Take Profit
input double          Inp2B_Risk           = 0.5;         // Set 2B: Risk %
input int             Inp2B_TrTrig         = 20;          // Set 2B: Trail Trigger
input int             Inp2B_TrDist         = 15;          // Set 2B: Trail Distance
input int             Inp2B_TrStep         = 3;           // Set 2B: Trail Step
input ENUM_TIMEFRAMES Inp2B_TF             = PERIOD_M2;   // Set 2B: Timeframe

sinput string         sep_preset_2C        = "---------- SET 2C ----------"; // ---------- SET 2C ----------
input int             Inp2C_SL             = 800;         // Set 2C: Stop Loss
input int             Inp2C_TP             = 1600;        // Set 2C: Take Profit
input double          Inp2C_Risk           = 2.0;         // Set 2C: Risk %
input int             Inp2C_TrTrig         = 50;          // Set 2C: Trail Trigger
input int             Inp2C_TrDist         = 30;          // Set 2C: Trail Distance
input int             Inp2C_TrStep         = 10;          // Set 2C: Trail Step
input ENUM_TIMEFRAMES Inp2C_TF             = PERIOD_M2;   // Set 2C: Timeframe

sinput string         sep_preset_5A        = "---------- SET 5A ----------"; // ---------- SET 5A ----------
input int             Inp5A_SL             = 1500;        // Set 5A: Stop Loss
input int             Inp5A_TP             = 1500;        // Set 5A: Take Profit
input double          Inp5A_Risk           = 1.0;         // Set 5A: Risk %
input int             Inp5A_TrTrig         = 1500;        // Set 5A: Trail Trigger
input int             Inp5A_TrDist         = 500;         // Set 5A: Trail Distance
input int             Inp5A_TrStep         = 1;           // Set 5A: Trail Step
input ENUM_TIMEFRAMES Inp5A_TF             = PERIOD_M5;   // Set 5A: Timeframe

sinput string         sep_preset_5B        = "---------- SET 5B ----------"; // ---------- SET 5B ----------
input int             Inp5B_SL             = 300;         // Set 5B: Stop Loss
input int             Inp5B_TP             = 600;         // Set 5B: Take Profit
input double          Inp5B_Risk           = 0.5;         // Set 5B: Risk %
input int             Inp5B_TrTrig         = 20;          // Set 5B: Trail Trigger
input int             Inp5B_TrDist         = 15;          // Set 5B: Trail Distance
input int             Inp5B_TrStep         = 3;           // Set 5B: Trail Step
input ENUM_TIMEFRAMES Inp5B_TF             = PERIOD_M5;   // Set 5B: Timeframe

sinput string         sep_preset_5C        = "---------- SET 5C ----------"; // ---------- SET 5C ----------
input int             Inp5C_SL             = 800;         // Set 5C: Stop Loss
input int             Inp5C_TP             = 1600;        // Set 5C: Take Profit
input double          Inp5C_Risk           = 2.0;         // Set 5C: Risk %
input int             Inp5C_TrTrig         = 50;          // Set 5C: Trail Trigger
input int             Inp5C_TrDist         = 30;          // Set 5C: Trail Distance
input int             Inp5C_TrStep         = 10;          // Set 5C: Trail Step
input ENUM_TIMEFRAMES Inp5C_TF             = PERIOD_M5;   // Set 5C: Timeframe


#include "Dashboard.mqh"
#include "TimeManager.mqh"
#include "RiskManager.mqh"
#include "OrderManager.mqh"
#include "TrailManager.mqh"
#include "NewsManager.mqh"

int g_magic;
PresetParams g_presets[9];
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
   InitPreset(g_presets[0], InpmA_SL,InpmA_TP,InpmA_Risk,InpmA_TrTrig,InpmA_TrDist,InpmA_TrStep,InpmA_TF);
   InitPreset(g_presets[1], InpmB_SL,InpmB_TP,InpmB_Risk,InpmB_TrTrig,InpmB_TrDist,InpmB_TrStep,InpmB_TF);
   InitPreset(g_presets[2], InpmC_SL,InpmC_TP,InpmC_Risk,InpmC_TrTrig,InpmC_TrDist,InpmC_TrStep,InpmC_TF);
   InitPreset(g_presets[3], Inp2A_SL,Inp2A_TP,Inp2A_Risk,Inp2A_TrTrig,Inp2A_TrDist,Inp2A_TrStep,Inp2A_TF);
   InitPreset(g_presets[4], Inp2B_SL,Inp2B_TP,Inp2B_Risk,Inp2B_TrTrig,Inp2B_TrDist,Inp2B_TrStep,Inp2B_TF);
   InitPreset(g_presets[5], Inp2C_SL,Inp2C_TP,Inp2C_Risk,Inp2C_TrTrig,Inp2C_TrDist,Inp2C_TrStep,Inp2C_TF);
   InitPreset(g_presets[6], Inp5A_SL,Inp5A_TP,Inp5A_Risk,Inp5A_TrTrig,Inp5A_TrDist,Inp5A_TrStep,Inp5A_TF);
   InitPreset(g_presets[7], Inp5B_SL,Inp5B_TP,Inp5B_Risk,Inp5B_TrTrig,Inp5B_TrDist,Inp5B_TrStep,Inp5B_TF);
   InitPreset(g_presets[8], Inp5C_SL,Inp5C_TP,Inp5C_Risk,Inp5C_TrTrig,Inp5C_TrDist,Inp5C_TrStep,Inp5C_TF);

   string pn=EA_NAME+"_"+IntegerToString(ChartID());
   if(!g_dashboard.CreatePanel(0,pn,0,PANEL_X,PANEL_Y,PANEL_WIDTH,PANEL_HEIGHT))
   { Print("[Main] Dashboard creation FAILED"); return INIT_FAILED; }

   SystemConfig cfg;
   cfg.globalOverride = InpGlobalOverride;
   cfg.main.nyHour=InpNyHour;cfg.main.nyMinute=InpNyMinute;cfg.main.nySecond=InpNySecond;
   cfg.main.utcOffset=InpUtcOffset;
   cfg.main.timeframe=InpTimeframe;
   cfg.main.slPoints=InpSlPoints;cfg.main.tpPoints=InpTpPoints;
   cfg.main.slCandle=InpSlCandle;cfg.main.entryBufferPoints=InpEntryBufferPoints;
   cfg.main.orderMode=InpOrderMode;
   cfg.main.customRetestOn=InpCustomRetestOn; cfg.main.customRetestMin=InpCustomRetestMin;
   cfg.main.riskPercent=InpRiskPercent; cfg.main.fixLot=InpFixLot; cfg.main.riskModeOn=InpRiskModeOn;

   cfg.main.trailMode=InpTrailMode;cfg.main.trailTrigger=InpTrailTrigger;
   cfg.main.trailDistance=InpTrailDistance;cfg.main.trailStep=InpTrailStep;
   cfg.main.beActivatePoints=InpBeActivatePts;cfg.main.beLockPoints=InpBeLockPts;cfg.main.beEnabled=InpBeEnabled;
   
   cfg.m2 = cfg.main; 
   cfg.m2.timeframe = PERIOD_M2; cfg.m2.comment = "orb-2m";
   cfg.m2.slPoints=Inp2MSlPoints; cfg.m2.tpPoints=Inp2MTpPoints;
   cfg.m2.slCandle=Inp2MSlCandle; cfg.m2.entryBufferPoints=Inp2MEntryBufferPoints;
   cfg.m2.orderMode=Inp2MOrderMode;
   cfg.m2.customRetestOn=Inp2MCustomRetestOn; cfg.m2.customRetestMin=Inp2MCustomRetestMin;
   cfg.m2.riskPercent=Inp2MRiskPercent; cfg.m2.fixLot=Inp2MFixLot; cfg.m2.riskModeOn=Inp2MRiskModeOn;

   cfg.m5 = cfg.main; 
   cfg.m5.timeframe = PERIOD_M5; cfg.m5.comment = "orb-5m";
   cfg.m5.slPoints=Inp5MSlPoints; cfg.m5.tpPoints=Inp5MTpPoints;
   cfg.m5.slCandle=Inp5MSlCandle; cfg.m5.entryBufferPoints=Inp5MEntryBufferPoints;
   cfg.m5.orderMode=Inp5MOrderMode;
   cfg.m5.customRetestOn=Inp5MCustomRetestOn; cfg.m5.customRetestMin=Inp5MCustomRetestMin;
   cfg.m5.riskPercent=Inp5MRiskPercent; cfg.m5.fixLot=Inp5MFixLot; cfg.m5.riskModeOn=Inp5MRiskModeOn;

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
   
   // Build per-timeframe params with forced correct TF (same as OnTimer)
   DashboardParams pm2 = cfg.globalOverride ? cfg.main : cfg.m2;
   pm2.symbol = sym; pm2.timeframe = PERIOD_M2; pm2.comment = "orb-2m";
   
   DashboardParams pm5 = cfg.globalOverride ? cfg.main : cfg.m5;
   pm5.symbol = sym; pm5.timeframe = PERIOD_M5; pm5.comment = "orb-5m";
   
   if(cfg.m2.isActive) g_orderMgr_M2.CheckAutoCancel(pm2, g_timeMgr.GetTargetTime());
   if(cfg.m5.isActive) g_orderMgr_M5.CheckAutoCancel(pm5, g_timeMgr.GetTargetTime());
   
   if(cfg.m2.isActive) g_trailMgr_M2.Process(pm2);
   if(cfg.m5.isActive) g_trailMgr_M5.Process(pm5);
}



int g_winsToday = 0;
int g_lossesToday = 0;

void UpdateTradeStats()
{
   int wToday = 0, lToday = 0, wWeek = 0, lWeek = 0, wMonth = 0, lMonth = 0;
   double netToday = 0, netWeek = 0, netMonth = 0;
   int w2mToday = 0, l2mToday = 0, w2mWeek = 0, l2mWeek = 0, w2mMonth = 0, l2mMonth = 0;
   double net2mToday = 0, net2mWeek = 0, net2mMonth = 0;
   int w5mToday = 0, l5mToday = 0, w5mWeek = 0, l5mWeek = 0, w5mMonth = 0, l5mMonth = 0;
   double net5mToday = 0, net5mWeek = 0, net5mMonth = 0;
   
   datetime now = TimeCurrent();
   datetime d1Start = iTime(Symbol(), PERIOD_D1, 0);
   datetime w1Start = iTime(Symbol(), PERIOD_W1, 0);
   datetime mn1Start = iTime(Symbol(), PERIOD_MN1, 0);
   
   if(HistorySelect(0, now)) {
      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++) {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket <= 0) continue;
         if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != g_magic) continue;
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
         
         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_COMMISSION) + HistoryDealGetDouble(ticket, DEAL_SWAP);
         datetime time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
         bool is2m = (StringFind(comment, "2m") >= 0);
         bool is5m = (StringFind(comment, "5m") >= 0);
         
         if(time >= d1Start) {
            netToday += profit;
            if(profit > 0) wToday++; else lToday++;
            if(is2m) { net2mToday += profit; if(profit > 0) w2mToday++; else l2mToday++; }
            if(is5m) { net5mToday += profit; if(profit > 0) w5mToday++; else l5mToday++; }
         }
         if(time >= w1Start) {
            netWeek += profit;
            if(profit > 0) wWeek++; else lWeek++;
            if(is2m) { net2mWeek += profit; if(profit > 0) w2mWeek++; else l2mWeek++; }
            if(is5m) { net5mWeek += profit; if(profit > 0) w5mWeek++; else l5mWeek++; }
         }
         if(time >= mn1Start) {
            netMonth += profit;
            if(profit > 0) wMonth++; else lMonth++;
            if(is2m) { net2mMonth += profit; if(profit > 0) w2mMonth++; else l2mMonth++; }
            if(is5m) { net5mMonth += profit; if(profit > 0) w5mMonth++; else l5mMonth++; }
         }
      }
   }
   
   g_winsToday = wToday;
   g_lossesToday = lToday;
   
   string eR2 = g_orderMgr_M2.GetEntryReason();
   string cR2 = g_orderMgr_M2.GetCancelReason();
   string eR5 = g_orderMgr_M5.GetEntryReason();
   string cR5 = g_orderMgr_M5.GetCancelReason();
   
   // Combine entry/cancel reasons from both timeframes
   string entryR = "";
   if(eR2 != "") entryR += eR2;
   if(eR5 != "") entryR += (entryR != "" ? " | " : "") + eR5;
   string cancelR = "";
   if(cR2 != "") cancelR += cR2;
   if(cR5 != "") cancelR += (cancelR != "" ? " | " : "") + cR5;
   
   g_dashboard.UpdateStatsTab(entryR, cancelR, netToday, wToday, lToday, netWeek, wWeek, lWeek, netMonth, wMonth, lMonth);
   g_dashboard.Update2mPL(net2mToday, w2mToday, l2mToday, net2mWeek, w2mWeek, l2mWeek, net2mMonth, w2mMonth, l2mMonth);
   g_dashboard.Update5mPL(net5mToday, w5mToday, l5mToday, net5mWeek, w5mWeek, l5mWeek, net5mMonth, w5mMonth, l5mMonth);
}

void DrawNYOLines(int utcOffset)
{
   datetime t930 = g_timeMgr.NYTimeToServerTime(9, 30, 0, utcOffset);
   datetime t1030 = g_timeMgr.NYTimeToServerTime(10, 30, 0, utcOffset);
   
   string name930 = "NY_930_" + TimeToString(t930, TIME_DATE);
   if(ObjectFind(0, name930) < 0) {
      ObjectCreate(0, name930, OBJ_VLINE, 0, t930, 0);
      ObjectSetInteger(0, name930, OBJPROP_COLOR, clrDarkGray);
      ObjectSetInteger(0, name930, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name930, OBJPROP_BACK, true);
      ObjectSetInteger(0, name930, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name930, OBJPROP_HIDDEN, true);
   }
   
   string name1030 = "NY_1030_" + TimeToString(t1030, TIME_DATE);
   if(ObjectFind(0, name1030) < 0) {
      ObjectCreate(0, name1030, OBJ_VLINE, 0, t1030, 0);
      ObjectSetInteger(0, name1030, OBJPROP_COLOR, clrDarkGray);
      ObjectSetInteger(0, name1030, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name1030, OBJPROP_BACK, true);
      ObjectSetInteger(0, name1030, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name1030, OBJPROP_HIDDEN, true);
   }
}

void OnTimer()
{
   if(!g_initialized) return;
   SystemConfig cfg=g_dashboard.GetParams();
   DrawNYOLines(cfg.main.utcOffset);
   DashboardParams p=cfg.main; // Time/Display mostly uses MAIN params
   g_dashboard.UpdateNYClock(g_timeMgr.GetNYTimeString(p.utcOffset), g_timeMgr.GetNYAmPmString(p.utcOffset), g_timeMgr.GetNYDateString(p.utcOffset));
   g_newsMgr.SetNYO(p.nyHour,p.nyMinute,p.nySecond,p.utcOffset);
   g_newsMgr.Update();
   g_dashboard.UpdateNews(g_newsMgr.GetNextEventString());
   g_dashboard.UpdateTimer(g_timeMgr.GetCountdownString(p));
   UpdateTradeStats();
   
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
     g_riskMgr.CalcRiskRewardInfo(p.symbol,p.riskModeOn,p.riskPercent,p.fixLot,displaySlPoints,p.tpPoints,bal,rAmt,rwAmt,lot);
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
        
        if(tp > 0) {
           if(OrderCalcProfit(orderType, p.symbol, vol, price, tp, pftTP)) totalProfitAtTP += pftTP;
        }
        if(sl > 0) {
           if(OrderCalcProfit(orderType, p.symbol, vol, price, sl, pftSL)) totalLossAtSL += pftSL;
        }
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
   
   g_timeMgr.CalculateTargetTime(p);
   datetime nyoTime = g_timeMgr.GetTargetTime();
   
   bool tradeM2 = cfg.m2.isActive;
   bool tradeM5 = cfg.m5.isActive;
   
   if(tradeM2) {
      DashboardParams pm2 = cfg.globalOverride ? p : cfg.m2;
      pm2.symbol = p.symbol;
      pm2.timeframe = PERIOD_M2;  // Always M2 regardless of global
      pm2.comment = "orb-2m";
      pm2.isActive = true;
      g_orderMgr_M2.ProcessORB(pm2, nyoTime);
      g_orderMgr_M2.CheckAutoCancel(pm2, nyoTime);
   } else {
      g_orderMgr_M2.CleanupLines(PERIOD_M2);
   }
   
   if(tradeM5) {
      DashboardParams pm5 = cfg.globalOverride ? p : cfg.m5;
      pm5.symbol = p.symbol;
      pm5.timeframe = PERIOD_M5;  // Always M5 regardless of global
      pm5.comment = "orb-5m";
      pm5.isActive = true;
      g_orderMgr_M5.ProcessORB(pm5, nyoTime);
      g_orderMgr_M5.CheckAutoCancel(pm5, nyoTime);
   } else {
      g_orderMgr_M5.CleanupLines(PERIOD_M5);
   }
   
   // Update status for each timeframe separately
   if(tradeM2) {
      g_dashboard.Update2mStatus(g_orderMgr_M2.GetStatus(), g_orderMgr_M2.GetStatusColor());
   } else {
      g_dashboard.Update2mStatus("OFF", CLR_TEXT_DIM);
   }
   if(tradeM5) {
      g_dashboard.Update5mStatus(g_orderMgr_M5.GetStatus(), g_orderMgr_M5.GetStatusColor());
   } else {
      g_dashboard.Update5mStatus("OFF", CLR_TEXT_DIM);
   }
   
   // Force chart repaint so clock/countdown updates visually every second
   // Without this, chart objects only refresh on tick (price movement)
   ChartRedraw();
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   // v0.72: Direct button click handling — bypasses CAppDialog event routing
   // CRITICAL: Do NOT return early — command queue must still run
   bool handled = false;
   



   // v0.89: Native Object Click is the ONLY reliable event for buttons.
   // EVENT_MAP was deleted because its internal hit-testing caused the "1 goc nho" bug.
   // HandleMouseClick was deleted because CHARTEVENT_CLICK doesn't fire on objects.
   // So HandleDirectClick is the single source of truth.
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // v0.11: Intercept Close button — always minimize, never close
      if(StringFind(sparam, "Close") >= 0) {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
         g_dashboard.Minimize();
         ChartRedraw();
         return;
      }
      
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
            if(idx >= 0 && idx < 9) g_dashboard.ApplyPreset(g_presets[idx]);
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
