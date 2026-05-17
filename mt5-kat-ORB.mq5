//+------------------------------------------------------------------+
//|                                                   mt5-kat-ORB.mq5  |
//|                            KAT Opening Range Breakout              |
//|                                                      Version 1.21  |
//+------------------------------------------------------------------+
#property copyright   "KAT Opening Range Breakout"
#property link        ""
#property description "KAT Opening Range Breakout"
#property description "Automated Break & Retest range strategy on 2m/5m/15m NYO candles."
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
input int             InpTpPoints          = 15000;       // Take Profit (Points)
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
input int             Inp2MTpPoints          = 15000;       // 2m: Take Profit (Points)
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
input int             Inp5MTpPoints          = 15000;       // 5m: Take Profit (Points)
input bool            Inp5MSlCandle          = false;       // 5m: Use Candle Extremes for SL
input ENUM_ORDER_MODE Inp5MOrderMode         = MODE_BOTH;   // 5m: Allowed Trade Directions
input int             Inp5MEntryBufferPoints = 5;           // 5m: Entry/SL Buffer (Points)
input bool            Inp5MCustomRetestOn    = true;        // 5m: Use Custom Retest Candle
input int             Inp5MCustomRetestMin   = 1;           // 5m: Retest Candle Timeframe (Min)
input double          Inp5MRiskPercent       = 2.0;         // 5m: Risk per Trade (%)
input double          Inp5MFixLot            = 2.0;         // 5m: Fix Lot Size
input bool            Inp5MRiskModeOn        = true;        // 5m: Risk Management (true=Risk%, false=Fix Lot)

input group "------------- 15M SETTING -------------"
input int             Inp15MSlPoints          = 1500;        // 15m: Stop Loss (Points)
input int             Inp15MTpPoints          = 15000;       // 15m: Take Profit (Points)
input bool            Inp15MSlCandle          = false;       // 15m: Use Candle Extremes for SL
input ENUM_ORDER_MODE Inp15MOrderMode         = MODE_BOTH;   // 15m: Allowed Trade Directions
input int             Inp15MEntryBufferPoints = 5;           // 15m: Entry/SL Buffer (Points)
input bool            Inp15MCustomRetestOn    = true;        // 15m: Use Custom Retest Candle
input int             Inp15MCustomRetestMin   = 1;           // 15m: Retest Candle Timeframe (Min)
input double          Inp15MRiskPercent       = 2.0;         // 15m: Risk per Trade (%)
input double          Inp15MFixLot            = 2.0;         // 15m: Fix Lot Size
input bool            Inp15MRiskModeOn        = true;        // 15m: Risk Management (true=Risk%, false=Fix Lot)

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
input int             InpmA_TP             = 15000;       // Set mA: Take Profit
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
input int             Inp2A_TP             = 15000;       // Set 2A: Take Profit
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
input int             Inp5A_TP             = 15000;       // Set 5A: Take Profit
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

sinput string         sep_preset_15A       = "---------- SET 15A ----------"; // ---------- SET 15A ----------
input int             Inp15A_SL             = 1500;        // Set 15A: Stop Loss
input int             Inp15A_TP             = 15000;       // Set 15A: Take Profit
input double          Inp15A_Risk           = 1.0;         // Set 15A: Risk %
input int             Inp15A_TrTrig         = 1500;        // Set 15A: Trail Trigger
input int             Inp15A_TrDist         = 500;         // Set 15A: Trail Distance
input int             Inp15A_TrStep         = 1;           // Set 15A: Trail Step
input ENUM_TIMEFRAMES Inp15A_TF             = PERIOD_M15;  // Set 15A: Timeframe

sinput string         sep_preset_15B       = "---------- SET 15B ----------"; // ---------- SET 15B ----------
input int             Inp15B_SL             = 300;         // Set 15B: Stop Loss
input int             Inp15B_TP             = 600;         // Set 15B: Take Profit
input double          Inp15B_Risk           = 0.5;         // Set 15B: Risk %
input int             Inp15B_TrTrig         = 20;          // Set 15B: Trail Trigger
input int             Inp15B_TrDist         = 15;          // Set 15B: Trail Distance
input int             Inp15B_TrStep         = 3;           // Set 15B: Trail Step
input ENUM_TIMEFRAMES Inp15B_TF             = PERIOD_M15;  // Set 15B: Timeframe

sinput string         sep_preset_15C       = "---------- SET 15C ----------"; // ---------- SET 15C ----------
input int             Inp15C_SL             = 800;         // Set 15C: Stop Loss
input int             Inp15C_TP             = 1600;        // Set 15C: Take Profit
input double          Inp15C_Risk           = 2.0;         // Set 15C: Risk %
input int             Inp15C_TrTrig         = 50;          // Set 15C: Trail Trigger
input int             Inp15C_TrDist         = 30;          // Set 15C: Trail Distance
input int             Inp15C_TrStep         = 10;          // Set 15C: Trail Step
input ENUM_TIMEFRAMES Inp15C_TF             = PERIOD_M15;  // Set 15C: Timeframe


#include "Dashboard.mqh"
#include "TimeManager.mqh"
#include "RiskManager.mqh"
#include "OrderManager.mqh"
#include "TrailManager.mqh"
#include "NewsManager.mqh"

//+------------------------------------------------------------------+
//| CORBRunner — bundles order + trail managers for one timeframe     |
//+------------------------------------------------------------------+
struct CORBRunner
{
   COrderManager   order;
   CTrailManager   trail;
   ENUM_TIMEFRAMES tf;
   string          comment;
};

CGlobalState  g_gs;
PresetParams g_presets[12];
CDashboard    g_dashboard;
CTimeManager  g_timeMgr;
CRiskManager  g_riskMgr;
CNewsManager  g_newsMgr;
CORBRunner    g_runners[3]; // 0=M2, 1=M5, 2=M15

bool g_initialized = false;
const string BE_LINE_NAME = "Aggregate_BE_Line";

// Day-level entry tracking (persists until next NYO)
string   g_dayEntries[6];
int      g_dayEntryCount = 0;
datetime g_dayEntriesNYO = 0;
string   g_lastSeenEntry[3];
string   g_lastSeenCancel[3];

// P/L stats cache (set by UpdateTradeStats, used by dashboard update)
double g_plNetToday=0, g_plNetWeek=0, g_plNetMonth=0;
int    g_plWToday=0, g_plLToday=0, g_plWWeek=0, g_plLWeek=0, g_plWMonth=0, g_plLMonth=0;

//+------------------------------------------------------------------+
//| Helpers                                                            |
//+------------------------------------------------------------------+
bool IsMarketOpen(string sym)
{
   long tradeMode = SymbolInfoInteger(sym, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED || tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY) return false;

   datetime now = TimeCurrent();
   if(now == 0) return false;

   datetime nowTime = now % 86400;
   MqlDateTime dtNow; TimeToStruct(now, dtNow);
   bool hasSessions = false;
   datetime from, to;
   for(uint i = 0; i < 10; i++)
   {
      if(!SymbolInfoSessionTrade(sym, (ENUM_DAY_OF_WEEK)dtNow.day_of_week, i, from, to)) break;
      hasSessions = true;
      if(to < from) { if(nowTime >= from || nowTime <= to) return true; }
      else          { if(nowTime >= from && nowTime <= to) return true; }
   }
   return !hasSessions;
}
int TimeDayOfWeek(datetime t){ MqlDateTime d; TimeToStruct(t,d); return d.day_of_week; }

//+------------------------------------------------------------------+
//| Build per-timeframe params from config                             |
//+------------------------------------------------------------------+
DashboardParams BuildRunnerParams(const SystemConfig &cfg, int runnerIdx, string sym)
{
   DashboardParams p;
   if(cfg.globalOverride)
      p = cfg.main;
   else if(runnerIdx == 0)
      p = cfg.m2;
   else if(runnerIdx == 1)
      p = cfg.m5;
   else
      p = cfg.m15;
   p.symbol    = sym;
   if(runnerIdx == 0)      p.timeframe = PERIOD_M2;
   else if(runnerIdx == 1) p.timeframe = PERIOD_M5;
   else                    p.timeframe = PERIOD_M15;
   if(runnerIdx == 0)      p.comment = "orb-2m";
   else if(runnerIdx == 1) p.comment = "orb-5m";
   else                    p.comment = "orb-15m";
   p.isActive  = true;
   return p;
}

//+------------------------------------------------------------------+
//| OnInit                                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   g_gs.SetMagic(InpMagicNumber);

   g_runners[0].tf = PERIOD_M2;  g_runners[0].comment = "orb-2m";
   g_runners[1].tf = PERIOD_M5;  g_runners[1].comment = "orb-5m";
   g_runners[2].tf = PERIOD_M15; g_runners[2].comment = "orb-15m";
   for(int i = 0; i < 3; i++) { g_runners[i].order.Init(); g_runners[i].trail.Init(); }

   g_newsMgr.SetNYO(InpNyHour, InpNyMinute, InpNySecond, InpUtcOffset);

   // Presets
   InitPreset(g_presets[0], InpmA_SL,InpmA_TP,InpmA_Risk,InpmA_TrTrig,InpmA_TrDist,InpmA_TrStep,InpmA_TF);
   InitPreset(g_presets[1], InpmB_SL,InpmB_TP,InpmB_Risk,InpmB_TrTrig,InpmB_TrDist,InpmB_TrStep,InpmB_TF);
   InitPreset(g_presets[2], InpmC_SL,InpmC_TP,InpmC_Risk,InpmC_TrTrig,InpmC_TrDist,InpmC_TrStep,InpmC_TF);
   InitPreset(g_presets[3], Inp2A_SL,Inp2A_TP,Inp2A_Risk,Inp2A_TrTrig,Inp2A_TrDist,Inp2A_TrStep,Inp2A_TF);
   InitPreset(g_presets[4], Inp2B_SL,Inp2B_TP,Inp2B_Risk,Inp2B_TrTrig,Inp2B_TrDist,Inp2B_TrStep,Inp2B_TF);
   InitPreset(g_presets[5], Inp2C_SL,Inp2C_TP,Inp2C_Risk,Inp2C_TrTrig,Inp2C_TrDist,Inp2C_TrStep,Inp2C_TF);
   InitPreset(g_presets[6], Inp5A_SL,Inp5A_TP,Inp5A_Risk,Inp5A_TrTrig,Inp5A_TrDist,Inp5A_TrStep,Inp5A_TF);
   InitPreset(g_presets[7], Inp5B_SL,Inp5B_TP,Inp5B_Risk,Inp5B_TrTrig,Inp5B_TrDist,Inp5B_TrStep,Inp5B_TF);
   InitPreset(g_presets[8], Inp5C_SL,Inp5C_TP,Inp5C_Risk,Inp5C_TrTrig,Inp5C_TrDist,Inp5C_TrStep,Inp5C_TF);
   InitPreset(g_presets[9], Inp15A_SL,Inp15A_TP,Inp15A_Risk,Inp15A_TrTrig,Inp15A_TrDist,Inp15A_TrStep,Inp15A_TF);
   InitPreset(g_presets[10], Inp15B_SL,Inp15B_TP,Inp15B_Risk,Inp15B_TrTrig,Inp15B_TrDist,Inp15B_TrStep,Inp15B_TF);
   InitPreset(g_presets[11], Inp15C_SL,Inp15C_TP,Inp15C_Risk,Inp15C_TrTrig,Inp15C_TrDist,Inp15C_TrStep,Inp15C_TF);

   string pn = EA_NAME + "_" + IntegerToString(ChartID());
   if(!g_dashboard.CreatePanel(0,pn,0,PANEL_X,PANEL_Y,PANEL_WIDTH,PANEL_HEIGHT))
   { Print("[Main] Dashboard creation FAILED"); return INIT_FAILED; }

   SystemConfig cfg;
   cfg.globalOverride = InpGlobalOverride;
   cfg.main.nyHour=InpNyHour; cfg.main.nyMinute=InpNyMinute; cfg.main.nySecond=InpNySecond;
   cfg.main.utcOffset=InpUtcOffset;
   cfg.main.timeframe=InpTimeframe;
   cfg.main.slPoints=InpSlPoints; cfg.main.tpPoints=InpTpPoints;
   cfg.main.slCandle=InpSlCandle; cfg.main.entryBufferPoints=InpEntryBufferPoints;
   cfg.main.orderMode=InpOrderMode;
   cfg.main.customRetestOn=InpCustomRetestOn; cfg.main.customRetestMin=InpCustomRetestMin;
   cfg.main.riskPercent=InpRiskPercent; cfg.main.fixLot=InpFixLot; cfg.main.riskModeOn=InpRiskModeOn;

   cfg.main.trailMode=InpTrailMode; cfg.main.trailTrigger=InpTrailTrigger;
   cfg.main.trailDistance=InpTrailDistance; cfg.main.trailStep=InpTrailStep;
   cfg.main.beActivatePoints=InpBeActivatePts; cfg.main.beLockPoints=InpBeLockPts; cfg.main.beEnabled=InpBeEnabled;

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

   cfg.m15 = cfg.main;
   cfg.m15.timeframe = PERIOD_M15; cfg.m15.comment = "orb-15m";
   cfg.m15.slPoints=Inp15MSlPoints; cfg.m15.tpPoints=Inp15MTpPoints;
   cfg.m15.slCandle=Inp15MSlCandle; cfg.m15.entryBufferPoints=Inp15MEntryBufferPoints;
   cfg.m15.orderMode=Inp15MOrderMode;
   cfg.m15.customRetestOn=Inp15MCustomRetestOn; cfg.m15.customRetestMin=Inp15MCustomRetestMin;
   cfg.m15.riskPercent=Inp15MRiskPercent; cfg.m15.fixLot=Inp15MFixLot; cfg.m15.riskModeOn=Inp15MRiskModeOn;

   g_dashboard.SetInitialParams(cfg);
   g_dashboard.Run();
   EventSetTimer(1);
   g_initialized = true;
   PrintFormat("[Main] %s v%s | %s | Magic=%d", EA_NAME, EA_VERSION, Symbol(), g_gs.Magic());
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectDelete(0, BE_LINE_NAME);
   g_dashboard.Destroy(reason);
}

//+------------------------------------------------------------------+
void OnTick()
{
   if(!g_initialized) return;
   SystemConfig cfg = g_dashboard.GetParams();
   string sym = (cfg.main.symbol != "") ? cfg.main.symbol : Symbol();
   g_dashboard.UpdateSpread((int)SymbolInfoInteger(sym, SYMBOL_SPREAD));
   g_dashboard.UpdateMarketStatus(IsMarketOpen(sym));

   for(int i = 0; i < 3; i++)
   {
      if((i == 0 && cfg.m2.isActive) || (i == 1 && cfg.m5.isActive) || (i == 2 && cfg.m15.isActive))
      {
         DashboardParams p = BuildRunnerParams(cfg, i, sym);
         g_runners[i].order.CheckAutoFlatten(p, g_timeMgr.GetTargetTime());
         g_runners[i].trail.Process(p);
      }
   }
}

//+------------------------------------------------------------------+
//| Trade stats aggregation                                            |
//+------------------------------------------------------------------+
void UpdateTradeStats()
{
   int wToday=0,lToday=0,wWeek=0,lWeek=0,wMonth=0,lMonth=0;
   double netToday=0,netWeek=0,netMonth=0;
   int w2mToday=0,l2mToday=0,w2mWeek=0,l2mWeek=0,w2mMonth=0,l2mMonth=0;
   double net2mToday=0,net2mWeek=0,net2mMonth=0;
   int w5mToday=0,l5mToday=0,w5mWeek=0,l5mWeek=0,w5mMonth=0,l5mMonth=0;
   double net5mToday=0,net5mWeek=0,net5mMonth=0;
   int w15mToday=0,l15mToday=0,w15mWeek=0,l15mWeek=0,w15mMonth=0,l15mMonth=0;
   double net15mToday=0,net15mWeek=0,net15mMonth=0;

   datetime now = TimeCurrent();
   datetime d1Start = iTime(Symbol(), PERIOD_D1, 0);
   datetime w1Start = iTime(Symbol(), PERIOD_W1, 0);
   datetime mn1Start = iTime(Symbol(), PERIOD_MN1, 0);

   if(HistorySelect(0, now))
   {
      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++)
      {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket <= 0) continue;
         if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != g_gs.Magic()) continue;
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

         double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                       + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                       + HistoryDealGetDouble(ticket, DEAL_SWAP);
         datetime time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
         bool is2m = (StringFind(comment, "2m") >= 0);
         bool is5m = (StringFind(comment, "5m") >= 0);
         bool is15m = (StringFind(comment, "15m") >= 0);

         if(time >= d1Start)
         {
            netToday += profit;
            if(profit > 0) wToday++; else lToday++;
            if(is2m) { net2mToday += profit; if(profit > 0) w2mToday++; else l2mToday++; }
            if(is5m) { net5mToday += profit; if(profit > 0) w5mToday++; else l5mToday++; }
            if(is15m) { net15mToday += profit; if(profit > 0) w15mToday++; else l15mToday++; }
         }
         if(time >= w1Start)
         {
            netWeek += profit;
            if(profit > 0) wWeek++; else lWeek++;
            if(is2m) { net2mWeek += profit; if(profit > 0) w2mWeek++; else l2mWeek++; }
            if(is5m) { net5mWeek += profit; if(profit > 0) w5mWeek++; else l5mWeek++; }
            if(is15m) { net15mWeek += profit; if(profit > 0) w15mWeek++; else l15mWeek++; }
         }
         if(time >= mn1Start)
         {
            netMonth += profit;
            if(profit > 0) wMonth++; else lMonth++;
            if(is2m) { net2mMonth += profit; if(profit > 0) w2mMonth++; else l2mMonth++; }
            if(is5m) { net5mMonth += profit; if(profit > 0) w5mMonth++; else l5mMonth++; }
            if(is15m) { net15mMonth += profit; if(profit > 0) w15mMonth++; else l15mMonth++; }
         }
      }
   }

   g_gs.SetWinsToday(wToday);
   g_gs.SetLossesToday(lToday);

   // Cache P/L stats for later dashboard update
   g_plNetToday = netToday; g_plWToday = wToday; g_plLToday = lToday;
   g_plNetWeek = netWeek;   g_plWWeek = wWeek;   g_plLWeek = lWeek;
   g_plNetMonth = netMonth;  g_plWMonth = wMonth;  g_plLMonth = lMonth;

   g_dashboard.Update2mPL(net2mToday, w2mToday, l2mToday, net2mWeek, w2mWeek, l2mWeek, net2mMonth, w2mMonth, l2mMonth);
   g_dashboard.Update5mPL(net5mToday, w5mToday, l5mToday, net5mWeek, w5mWeek, l5mWeek, net5mMonth, w5mMonth, l5mMonth);
   g_dashboard.Update15mPL(net15mToday, w15mToday, l15mToday, net15mWeek, w15mWeek, l15mWeek, net15mMonth, w15mMonth, l15mMonth);
}

//+------------------------------------------------------------------+
//| Accumulate day entries — reset only on new NYO                     |
//+------------------------------------------------------------------+
void AccumulateDayEntries(datetime nyoTime)
{
   // Reset on new trading day (new NYO detected)
   if(nyoTime > 0 && nyoTime != g_dayEntriesNYO)
   {
      // Snapshot current runner reasons as "already seen" to avoid re-capturing old data
      for(int i = 0; i < 3; i++)
      {
         g_lastSeenEntry[i]  = g_runners[i].order.GetEntryReason();
         g_lastSeenCancel[i] = g_runners[i].order.GetCancelReason();
      }
      g_dayEntryCount = 0;
      for(int i = 0; i < 6; i++) g_dayEntries[i] = "";
      g_dayEntriesNYO = nyoTime;
   }

   // Capture new entries from runners (2m→5m→15m order)
   for(int ri = 0; ri < 3; ri++)
   {
      if(g_dayEntryCount >= 6) break;

      string eR = g_runners[ri].order.GetEntryReason();
      string cR = g_runners[ri].order.GetCancelReason();

      // New entry reason detected → record it
      if(eR != "" && eR != g_lastSeenEntry[ri])
      {
         g_dayEntries[g_dayEntryCount] = eR;
         g_dayEntryCount++;
         g_lastSeenEntry[ri] = eR;
         g_lastSeenCancel[ri] = ""; // reset cancel tracking for this cycle
      }

      // New cancel reason detected → record it
      if(cR != "" && cR != g_lastSeenCancel[ri] && g_dayEntryCount < 6)
      {
         g_dayEntries[g_dayEntryCount] = cR;
         g_dayEntryCount++;
         g_lastSeenCancel[ri] = cR;
      }
   }

   // Update dashboard with accumulated entries + cached P/L
   g_dashboard.UpdateStatsTab(g_dayEntries, g_plNetToday, g_plWToday, g_plLToday,
                              g_plNetWeek, g_plWWeek, g_plLWeek,
                              g_plNetMonth, g_plWMonth, g_plLMonth);
}

//+------------------------------------------------------------------+
void DrawNYOLines(int utcOffset)
{
   datetime t930  = g_timeMgr.NYTimeToServerTime(9, 30, 0, utcOffset);
   datetime t1030 = g_timeMgr.NYTimeToServerTime(10, 30, 0, utcOffset);

   string name930 = "NY_930_" + TimeToString(t930, TIME_DATE);
   if(ObjectFind(0, name930) < 0)
   {
      ObjectCreate(0, name930, OBJ_VLINE, 0, t930, 0);
      ObjectSetInteger(0, name930, OBJPROP_COLOR, clrDarkGray);
      ObjectSetInteger(0, name930, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name930, OBJPROP_BACK, true);
      ObjectSetInteger(0, name930, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name930, OBJPROP_HIDDEN, true);
   }
   string name1030 = "NY_1030_" + TimeToString(t1030, TIME_DATE);
   if(ObjectFind(0, name1030) < 0)
   {
      ObjectCreate(0, name1030, OBJ_VLINE, 0, t1030, 0);
      ObjectSetInteger(0, name1030, OBJPROP_COLOR, clrDarkGray);
      ObjectSetInteger(0, name1030, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name1030, OBJPROP_BACK, true);
      ObjectSetInteger(0, name1030, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name1030, OBJPROP_HIDDEN, true);
   }
}

//+------------------------------------------------------------------+
//| Update dashboard risk / reward / lot section                       |
//+------------------------------------------------------------------+
double UpdateDashboardRisk(const DashboardParams &p)
{
   if(p.symbol == "") return 0;

   int displaySlPoints = p.slPoints;
   if(p.slCandle)
   {
      double ch = iHigh(p.symbol, p.timeframe, 0);
      double cl = iLow(p.symbol, p.timeframe, 0);
      double pt = SymbolInfoDouble(p.symbol, SYMBOL_POINT);
      if(pt > 0) displaySlPoints = (int)MathRound((ch - cl) / pt) + 2 * p.entryBufferPoints;
   }

   double bal=0, rAmt=0, rwAmt=0, lot=0;
   g_riskMgr.CalcRiskRewardInfo(p.symbol, p.riskModeOn, p.riskPercent, p.fixLot,
                                displaySlPoints, p.tpPoints, bal, rAmt, rwAmt, lot);
   g_dashboard.UpdateBalanceInfo(bal, rAmt, rwAmt, lot);

   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double profit = AccountInfoDouble(ACCOUNT_PROFIT);
   g_dashboard.UpdateEquityPL(equity, profit);
   return rAmt;
}

//+------------------------------------------------------------------+
//| Update aggregate exposure / RR / BE line                           |
//+------------------------------------------------------------------+
void UpdateDashboardExposure(const string &sym, double riskAmount, double riskPercent)
{
   double totalBuyLots = 0, totalSellLots = 0;
   double totalProfitAtTP = 0, totalLossAtSL = 0;
   double weightedEntry = 0, totalLots = 0;
   int magic = g_gs.Magic();

   for(int i = 0; i < PositionsTotal(); i++)
   {
      ulong t = PositionGetTicket(i);
      if(t <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic || PositionGetString(POSITION_SYMBOL) != sym) continue;

      double vol = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(type == POSITION_TYPE_BUY) totalBuyLots += vol;
      else totalSellLots += vol;
      totalLots += vol;
      weightedEntry += price * vol;

      double tp = PositionGetDouble(POSITION_TP);
      double sl = PositionGetDouble(POSITION_SL);
      ENUM_ORDER_TYPE oType = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double pftTP = 0, pftSL = 0;
      if(tp > 0 && OrderCalcProfit(oType, sym, vol, price, tp, pftTP)) totalProfitAtTP += pftTP;
      if(sl > 0 && OrderCalcProfit(oType, sym, vol, price, sl, pftSL)) totalLossAtSL += pftSL;
   }

   double netExposed = totalBuyLots - totalSellLots;
   int expType = 2;
   if(netExposed > 0.001) expType = 0;
   else if(netExposed < -0.001) expType = 1;
   g_dashboard.UpdateTotalExposed(MathAbs(netExposed), expType);

   double absLoss = MathAbs(totalLossAtSL);
   g_dashboard.UpdateRealtimeRR(totalProfitAtTP, absLoss, riskAmount);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskPc = (bal > 0) ? (absLoss / bal) * 100.0 : 0.0;
   g_dashboard.UpdateRealtimeRiskPercent(riskPc, riskPercent);

   // Aggregate BE line
   if(totalLots > 0)
   {
      double avgEntry = weightedEntry / totalLots;
      double spread = (double)SymbolInfoInteger(sym, SYMBOL_SPREAD) * SymbolInfoDouble(sym, SYMBOL_POINT);
      bool isBuyDominant = (totalBuyLots >= totalSellLots);
      double beLine = isBuyDominant ? avgEntry + spread : avgEntry - spread;
      int digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
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

//+------------------------------------------------------------------+
//| Run ORB processing for active runners                              |
//+------------------------------------------------------------------+
void RunORBRunners(const SystemConfig &cfg, const DashboardParams &p, datetime nyoTime)
{
   bool active[3] = { cfg.m2.isActive, cfg.m5.isActive, cfg.m15.isActive };
   for(int i = 0; i < 3; i++)
   {
      if(active[i])
      {
         DashboardParams pm = BuildRunnerParams(cfg, i, p.symbol);
         g_runners[i].order.ProcessORB(pm, nyoTime);
         g_runners[i].order.CheckAutoFlatten(pm, nyoTime);
      }
      else
      {
         g_runners[i].order.CleanupLines(g_runners[i].tf);
      }
   }

   // Update status lines
   g_dashboard.Update2mStatus(active[0] ? g_runners[0].order.GetStatus() : "OFF",
                              active[0] ? g_runners[0].order.GetStatusColor() : CLR_TEXT_DIM);
   g_dashboard.Update5mStatus(active[1] ? g_runners[1].order.GetStatus() : "OFF",
                              active[1] ? g_runners[1].order.GetStatusColor() : CLR_TEXT_DIM);
   g_dashboard.Update15mStatus(active[2] ? g_runners[2].order.GetStatus() : "OFF",
                               active[2] ? g_runners[2].order.GetStatusColor() : CLR_TEXT_DIM);
}

//+------------------------------------------------------------------+
void OnTimer()
{
   if(!g_initialized) return;
   SystemConfig cfg = g_dashboard.GetParams();
   DrawNYOLines(cfg.main.utcOffset);

   DashboardParams p = cfg.main;
   string sym = (p.symbol != "") ? p.symbol : Symbol();

   g_dashboard.UpdateNYClock(g_timeMgr.GetNYTimeString(p.utcOffset),
                             g_timeMgr.GetNYAmPmString(p.utcOffset),
                             g_timeMgr.GetNYDateString(p.utcOffset));
   g_newsMgr.SetNYO(p.nyHour, p.nyMinute, p.nySecond, p.utcOffset);
   g_newsMgr.Update();
   g_dashboard.UpdateNews(g_newsMgr.GetNextEventString());
   g_dashboard.UpdateTimer(g_timeMgr.GetCountdownString(p));
   UpdateTradeStats();

   double riskAmt = UpdateDashboardRisk(p);
   UpdateDashboardExposure(sym, riskAmt, p.riskPercent);

   if(sym == "") { g_dashboard.UpdateStatus("No symbol"); return; }

   g_timeMgr.CalculateTargetTime(p);
   datetime nyoTime = g_timeMgr.GetTargetTime();
   RunORBRunners(cfg, p, nyoTime);

   // Accumulate day entries AFTER RunORBRunners so runners have latest state
   AccumulateDayEntries(nyoTime);

   ChartRedraw();
}

//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   bool handled = false;

   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(StringFind(sparam, "Close") >= 0)
      {
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

   if(!handled && id != CHARTEVENT_CHART_CHANGE && id != CHARTEVENT_OBJECT_CHANGE)
      g_dashboard.ChartEvent(id, lparam, dparam, sparam);

   if(id == CHARTEVENT_OBJECT_ENDEDIT)
      g_dashboard.MarkDirtyPublic();

   SystemConfig cfg = g_dashboard.GetParams();
   DashboardParams p = cfg.main;
   string sym = (p.symbol != "") ? p.symbol : Symbol();

   while(g_dashboard.HasCommand())
   {
      ENUM_DASHBOARD_CMD cmd = g_dashboard.PopCommand();
      switch(cmd)
      {
         case CMD_PRESET:
         {
            int idx = g_dashboard.PresetIndex;
            if(idx >= 0 && idx < 12) g_dashboard.ApplyPreset(g_presets[idx]);
            g_dashboard.UpdateStatus("Preset applied ✓");
            break;
         }
         default: break;
      }
   }
}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
{
}
//+------------------------------------------------------------------+
