//+------------------------------------------------------------------+
//|                                                   mt5-kat-ORB.mq5  |
//|                            KAT Opening Range Breakout              |
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
input int             InpNyHour            = 9;           // NY Open Hour (NY Time)
input int             InpNyMinute          = 30;          // NY Open Minute
input int             InpNySecond          = 0;           // NY Open Second
input int             InpUtcOffset         = -4;          // Broker UTC Offset (NY Time)

input group "------------- GLOBAL SETTING -------------"
input ENUM_TIMEFRAMES InpTimeframe         = PERIOD_M2;   // Default Timeframe
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

input group "------------- TRAIL -------------"
input ENUM_TRAIL_MODE InpTrailMode         = TM_CHASE;    // Trailing Stop Mode
input int             InpTrailTrigger      = 1500;        // Trailing Trigger (Points)
input int             InpTrailDistance     = 500;         // Trailing Distance (Points)
input int             InpTrailStep         = 1;           // Trailing Step (Points)
input int             InpBeActivatePts     = 200;         // Breakeven Activation (Points)
input int             InpBeLockPts         = 50;          // Breakeven Lock Profit (Points)
input bool            InpBeEnabled         = false;       // Enable Breakeven

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
// Presets removed
CDashboard    g_dashboard;
CTimeManager  g_timeMgr;
CRiskManager  g_riskMgr;
CNewsManager  g_newsMgr;
CORBRunner    g_runners[3]; // 0=M2, 1=M5, 2=M15

bool g_initialized = false;
const string BE_LINE_NAME = "Aggregate_BE_Line";

// Day-level entry tracking (persists until next NYO)
string        g_dayEntries[9];
int           g_dayEntryCount = 0;
datetime      g_dayEntriesNYO = 0;
CTradeAttempt g_attempts[9];
string        g_lastSeenEntry[3];
string        g_lastSeenCancel[3];

// P/L stats cache (set by UpdateTradeStats, used by dashboard update)
double g_plNetToday=0, g_plNetWeek=0, g_plNetMonth=0;
int    g_plWToday=0, g_plLToday=0, g_plWWeek=0, g_plLWeek=0, g_plWMonth=0, g_plLMonth=0;

void UpdateTradeStats();
void PopulateAttemptsFromHistory();
void RegisterNewPendingOrders();
void RegisterNewActivePositions();
void UpdateAttempts();
string FormatAttemptString(const CTradeAttempt &attempt);
void RegisterAttemptInMemory(const CTradeAttempt &att);
void SortAttemptsChronologically();

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
   DashboardParams p = cfg.main;
   p.symbol    = sym;
   if(runnerIdx == 0)      p.timeframe = PERIOD_M2;
   else if(runnerIdx == 1) p.timeframe = PERIOD_M5;
   else                    p.timeframe = PERIOD_M15;
   if(runnerIdx == 0)      p.comment = "orb-2m";
   else if(runnerIdx == 1) p.comment = "orb-5m";
   else                    p.comment = "orb-15m";
   p.isActive  = true;
   p.tfIndex   = runnerIdx; // 0=2m, 1=5m, 2=15m
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

   string pn = EA_NAME + "_" + IntegerToString(ChartID());
   if(!g_dashboard.CreatePanel(0,pn,0,PANEL_X,PANEL_Y,PANEL_WIDTH,PANEL_HEIGHT))
   { Print("[Main] Dashboard creation FAILED"); return INIT_FAILED; }

   SystemConfig cfg;
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

   cfg.m2Active = true;
   cfg.m5Active = true;
   cfg.m15Active = true;

   g_dashboard.SetInitialParams(cfg);
   PopulateAttemptsFromHistory();
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

   // Force immediate trade stats refresh on every tick to avoid limit-check race conditions
   UpdateTradeStats();

   SystemConfig cfg = g_dashboard.GetParams();
   string sym = (cfg.main.symbol != "") ? cfg.main.symbol : Symbol();
   g_dashboard.UpdateSpread((int)SymbolInfoInteger(sym, SYMBOL_SPREAD));
   g_dashboard.UpdateMarketStatus(IsMarketOpen(sym));

   for(int i = 0; i < 3; i++)
   {
      if((i == 0 && cfg.m2Active) || (i == 1 && cfg.m5Active) || (i == 2 && cfg.m15Active))
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

         // MT5 replaces comment on exit deals with system text (e.g. "[sl]", "[tp]").
         // To identify the timeframe, look up the ORIGINAL entry deal via DEAL_POSITION_ID.
         string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
         bool is2m = (StringFind(comment, "2m") >= 0);
         bool is15m = (StringFind(comment, "15m") >= 0);
         bool is5m = !is15m && (StringFind(comment, "5m") >= 0);

         // If exit deal comment doesn't contain timeframe info, look up the entry deal
         if(!is2m && !is5m && !is15m)
         {
            long posId = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
            if(posId > 0)
            {
               // Search all deals in history for the matching entry deal
               for(int j = 0; j < total; j++)
               {
                  ulong entryTicket = HistoryDealGetTicket(j);
                  if(entryTicket <= 0) continue;
                  if(HistoryDealGetInteger(entryTicket, DEAL_POSITION_ID) != posId) continue;
                  if(HistoryDealGetInteger(entryTicket, DEAL_ENTRY) != DEAL_ENTRY_IN) continue;

                  string entryComment = HistoryDealGetString(entryTicket, DEAL_COMMENT);
                  is2m  = (StringFind(entryComment, "2m") >= 0);
                  is15m = (StringFind(entryComment, "15m") >= 0);
                  is5m  = !is15m && (StringFind(entryComment, "5m") >= 0);
                  break;
               }
            }
         }

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
   // Per-TF W/L counters (0=2m, 1=5m, 2=15m)
   g_gs.SetWinsTodayTF(0, w2mToday);  g_gs.SetLossesTodayTF(0, l2mToday);
   g_gs.SetWinsTodayTF(1, w5mToday);  g_gs.SetLossesTodayTF(1, l5mToday);
   g_gs.SetWinsTodayTF(2, w15mToday); g_gs.SetLossesTodayTF(2, l15mToday);

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
      for(int i = 0; i < 9; i++)
      {
         ZeroMemory(g_attempts[i]);
         g_attempts[i].placeTime = 0;
         g_dayEntries[i] = "";
      }
      g_dayEntriesNYO = nyoTime;
   }

   // Run lifecycle updates
   RegisterNewPendingOrders();
   RegisterNewActivePositions();
   UpdateAttempts();

   // Format each attempt string into the dashboard array
   for(int i = 0; i < 9; i++)
   {
      g_dayEntries[i] = FormatAttemptString(g_attempts[i]);
   }

   // Update dashboard with attempts list + cached P/L
   g_dashboard.UpdateStatsTab(g_dayEntries, g_plNetToday, g_plWToday, g_plLToday,
                              g_plNetWeek, g_plWWeek, g_plLWeek,
                              g_plNetMonth, g_plWMonth, g_plLMonth);
}

//+------------------------------------------------------------------+
//| Populate attempts from history for today                         |
//+------------------------------------------------------------------+
void PopulateAttemptsFromHistory()
{
   for(int i = 0; i < 9; i++)
   {
      ZeroMemory(g_attempts[i]);
      g_attempts[i].placeTime = 0;
      g_dayEntries[i] = "";
   }

   datetime now = TimeCurrent();
   datetime todayStart = iTime(Symbol(), PERIOD_D1, 0);
   if(todayStart == 0) todayStart = now - 86400;

   // Select history since start of today
   if(!HistorySelect(todayStart, now + 3600)) return;

   CTradeAttempt temp_history[100];
   int temp_count = 0;

   // 1. Gather all historical cancelled orders of today
   int totalOrders = HistoryOrdersTotal();
   for(int i = 0; i < totalOrders; i++)
   {
      if(temp_count >= 100) break;
      
      ulong ticket = HistoryOrderGetTicket(i);
      if(ticket <= 0) continue;
      if(HistoryOrderGetInteger(ticket, ORDER_MAGIC) != g_gs.Magic()) continue;
      if(HistoryOrderGetString(ticket, ORDER_SYMBOL) != Symbol()) continue;

      long state = HistoryOrderGetInteger(ticket, ORDER_STATE);
      if(state == ORDER_STATE_CANCELED)
      {
         CTradeAttempt att;
         ZeroMemory(att);
         att.orderTicket = ticket;
         att.positionId = 0;
         att.placeTime = (datetime)HistoryOrderGetInteger(ticket, ORDER_TIME_SETUP);
         att.symbol = Symbol();
         
         string comment = HistoryOrderGetString(ticket, ORDER_COMMENT);
         att.timeframeStr = "M2";
         if(StringFind(comment, "15m") >= 0) att.timeframeStr = "M15";
         else if(StringFind(comment, "5m") >= 0) att.timeframeStr = "M5";
         
         long type = HistoryOrderGetInteger(ticket, ORDER_TYPE);
         att.direction = (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP || type == ORDER_TYPE_BUY) ? 1 : -1;
         att.entryReason = comment;
         att.status = "Cancelled";
         att.exitReason = "cancelled";
         att.resolveTime = (datetime)HistoryOrderGetInteger(ticket, ORDER_TIME_DONE);
         
         temp_history[temp_count] = att;
         temp_count++;
      }
   }

   // 2. Gather all historical closed positions of today
   int totalDeals = HistoryDealsTotal();
   for(int i = 0; i < totalDeals; i++)
   {
      if(temp_count >= 100) break;
      
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket <= 0) continue;
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != g_gs.Magic()) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != Symbol()) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

      long posId = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
      if(posId <= 0) continue;

      // Find the entry deal for this position
      ulong entryTicket = 0;
      for(int j = 0; j < totalDeals; j++)
      {
         ulong t = HistoryDealGetTicket(j);
         if(HistoryDealGetInteger(t, DEAL_POSITION_ID) == posId && HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_IN)
         {
            entryTicket = t;
            break;
         }
      }

      if(entryTicket > 0)
      {
         CTradeAttempt att;
         ZeroMemory(att);
         att.positionId = posId;
         att.placeTime = (datetime)HistoryDealGetInteger(entryTicket, DEAL_TIME);
         att.symbol = Symbol();
         
         string comment = HistoryDealGetString(entryTicket, DEAL_COMMENT);
         att.timeframeStr = "M2";
         if(StringFind(comment, "15m") >= 0) att.timeframeStr = "M15";
         else if(StringFind(comment, "5m") >= 0) att.timeframeStr = "M5";
         
         long type = HistoryDealGetInteger(entryTicket, DEAL_TYPE);
         att.direction = (type == DEAL_TYPE_BUY) ? 1 : -1;
         att.entryReason = comment;
         att.status = "Closed";
         att.resolveTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);

         double entryPrice = HistoryDealGetDouble(entryTicket, DEAL_PRICE);
         double exitPrice = HistoryDealGetDouble(ticket, DEAL_PRICE);
         double pt = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
         double diffPoints = 0;
         if(pt > 0 && entryPrice > 0)
         {
            if(att.direction == 1)
               diffPoints = (exitPrice - entryPrice) / pt;
            else
               diffPoints = (entryPrice - exitPrice) / pt;
         }
         att.profitPoints = diffPoints;

         string dealComment = HistoryDealGetString(ticket, DEAL_COMMENT);
         if(StringFind(dealComment, "[sl]") >= 0)
         {
            if(diffPoints > 0)
               att.exitReason = "trailing";
            else
               att.exitReason = "failed";
         }
         else if(StringFind(dealComment, "[tp]") >= 0)
         {
            att.exitReason = "TP";
         }
         else
         {
            att.exitReason = "closed";
         }

         temp_history[temp_count] = att;
         temp_count++;
      }
   }

   // 3. Sort temp_history chronologically by placeTime
   for(int i = 0; i < temp_count - 1; i++)
   {
      for(int j = 0; j < temp_count - 1 - i; j++)
      {
         if(temp_history[j].placeTime > temp_history[j+1].placeTime)
         {
            CTradeAttempt temp = temp_history[j];
            temp_history[j] = temp_history[j+1];
            temp_history[j+1] = temp;
         }
      }
   }

   // 4. Register them in memory in chronological order
   for(int i = 0; i < temp_count; i++)
   {
      RegisterAttemptInMemory(temp_history[i]);
   }

   SortAttemptsChronologically();
}

//+------------------------------------------------------------------+
//| Register active pending orders                                     |
//+------------------------------------------------------------------+
void RegisterNewPendingOrders()
{
   int magic = g_gs.Magic();
   int total = OrdersTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket <= 0) continue;
      if(OrderGetInteger(ORDER_MAGIC) != magic) continue;
      if(OrderGetString(ORDER_SYMBOL) != Symbol()) continue;

      bool alreadyTracked = false;
      for(int j = 0; j < 9; j++)
      {
         if(g_attempts[j].placeTime > 0 && g_attempts[j].orderTicket == ticket)
         {
            alreadyTracked = true;
            break;
         }
      }

      if(!alreadyTracked)
      {
         CTradeAttempt att;
         ZeroMemory(att);
         att.orderTicket = ticket;
         att.positionId = 0;
         att.placeTime = (datetime)OrderGetInteger(ORDER_TIME_SETUP);
         att.symbol = Symbol();
         
         string comment = OrderGetString(ORDER_COMMENT);
         att.timeframeStr = "M2";
         if(StringFind(comment, "15m") >= 0) att.timeframeStr = "M15";
         else if(StringFind(comment, "5m") >= 0) att.timeframeStr = "M5";
         
         long type = OrderGetInteger(ORDER_TYPE);
         att.direction = (type == ORDER_TYPE_BUY_LIMIT || type == ORDER_TYPE_BUY_STOP) ? 1 : -1;
         
         int tfIdx = 0;
         if(att.timeframeStr == "M5") tfIdx = 1;
         else if(att.timeframeStr == "M15") tfIdx = 2;
         string reason = g_runners[tfIdx].order.GetEntryReason();
         if(reason == "") reason = comment;
         att.entryReason = reason;
         
         att.status = "Pending";
         
         RegisterAttemptInMemory(att);
      }
   }
}

//+------------------------------------------------------------------+
//| Register active positions                                         |
//+------------------------------------------------------------------+
void RegisterNewActivePositions()
{
   int magic = g_gs.Magic();
   int total = PositionsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

      long posId = PositionGetInteger(POSITION_IDENTIFIER);
      
      int matchIdx = -1;
      for(int j = 0; j < 9; j++)
      {
         if(g_attempts[j].placeTime > 0 && g_attempts[j].orderTicket == (ulong)posId)
         {
            matchIdx = j;
            break;
         }
      }

      if(matchIdx >= 0)
      {
         g_attempts[matchIdx].positionId = posId;
         g_attempts[matchIdx].status = "Active";
      }
      else
      {
         bool alreadyTracked = false;
         for(int j = 0; j < 9; j++)
         {
            if(g_attempts[j].placeTime > 0 && g_attempts[j].positionId == posId)
            {
               alreadyTracked = true;
               break;
            }
         }

         if(!alreadyTracked)
         {
            CTradeAttempt att;
            ZeroMemory(att);
            att.orderTicket = (ulong)posId;
            att.positionId = posId;
            att.placeTime = (datetime)PositionGetInteger(POSITION_TIME);
            att.symbol = Symbol();
            
            string comment = PositionGetString(POSITION_COMMENT);
            att.timeframeStr = "M2";
            if(StringFind(comment, "15m") >= 0) att.timeframeStr = "M15";
            else if(StringFind(comment, "5m") >= 0) att.timeframeStr = "M5";
            
            long type = PositionGetInteger(POSITION_TYPE);
            att.direction = (type == POSITION_TYPE_BUY) ? 1 : -1;
            
            int tfIdx = 0;
            if(att.timeframeStr == "M5") tfIdx = 1;
            else if(att.timeframeStr == "M15") tfIdx = 2;
            string reason = g_runners[tfIdx].order.GetEntryReason();
            if(reason == "") reason = comment;
            att.entryReason = reason;
            
            att.status = "Active";
            
            RegisterAttemptInMemory(att);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Update attempts in real time                                      |
//+------------------------------------------------------------------+
void UpdateAttempts()
{
   datetime now = TimeCurrent();
   datetime todayStart = iTime(Symbol(), PERIOD_D1, 0);
   if(todayStart == 0) todayStart = now - 86400;

   HistorySelect(todayStart, now + 3600);

   for(int i = 0; i < 9; i++)
   {
      if(g_attempts[i].placeTime == 0) continue;

      if(g_attempts[i].status == "Pending")
      {
         bool activeOrderExists = false;
         int totalOrders = OrdersTotal();
         for(int o = 0; o < totalOrders; o++)
         {
            if(OrderGetTicket(o) == g_attempts[i].orderTicket)
            {
               activeOrderExists = true;
               break;
            }
         }

         if(!activeOrderExists)
         {
            if(HistoryOrderSelect(g_attempts[i].orderTicket))
            {
               long state = HistoryOrderGetInteger(g_attempts[i].orderTicket, ORDER_STATE);
               if(state == ORDER_STATE_CANCELED)
               {
                  g_attempts[i].status = "Cancelled";
                  g_attempts[i].exitReason = "cancelled";
                  g_attempts[i].resolveTime = (datetime)HistoryOrderGetInteger(g_attempts[i].orderTicket, ORDER_TIME_DONE);
               }
            }
         }
      }

      if(g_attempts[i].status == "Active")
      {
         bool activePositionExists = false;
         int totalPos = PositionsTotal();
         for(int p = 0; p < totalPos; p++)
         {
            ulong ticket = PositionGetTicket(p);
            if(ticket > 0 && PositionGetInteger(POSITION_MAGIC) == g_gs.Magic() && PositionGetInteger(POSITION_IDENTIFIER) == g_attempts[i].positionId)
            {
               activePositionExists = true;
               break;
            }
         }

         if(!activePositionExists)
         {
            int totalDeals = HistoryDealsTotal();
            ulong exitTicket = 0;
            for(int d = 0; d < totalDeals; d++)
            {
               ulong t = HistoryDealGetTicket(d);
               if(HistoryDealGetInteger(t, DEAL_POSITION_ID) == g_attempts[i].positionId && HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_OUT)
               {
                  exitTicket = t;
                  break;
               }
            }

            if(exitTicket > 0)
            {
               g_attempts[i].status = "Closed";
               g_attempts[i].resolveTime = (datetime)HistoryDealGetInteger(exitTicket, DEAL_TIME);

               double entryPrice = 0;
               for(int d = 0; d < totalDeals; d++)
               {
                  ulong t = HistoryDealGetTicket(d);
                  if(HistoryDealGetInteger(t, DEAL_POSITION_ID) == g_attempts[i].positionId && HistoryDealGetInteger(t, DEAL_ENTRY) == DEAL_ENTRY_IN)
                  {
                     entryPrice = HistoryDealGetDouble(t, DEAL_PRICE);
                     break;
                  }
               }

               double exitPrice = HistoryDealGetDouble(exitTicket, DEAL_PRICE);
               double pt = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
               double diffPoints = 0;
               if(pt > 0 && entryPrice > 0)
               {
                  if(g_attempts[i].direction == 1)
                     diffPoints = (exitPrice - entryPrice) / pt;
                  else
                     diffPoints = (entryPrice - exitPrice) / pt;
               }
               g_attempts[i].profitPoints = diffPoints;

               string dealComment = HistoryDealGetString(exitTicket, DEAL_COMMENT);
               if(StringFind(dealComment, "[sl]") >= 0)
               {
                  if(diffPoints > 0)
                     g_attempts[i].exitReason = "trailing";
                  else
                     g_attempts[i].exitReason = "failed";
               }
               else if(StringFind(dealComment, "[tp]") >= 0)
               {
                  g_attempts[i].exitReason = "TP";
               }
               else
               {
                  g_attempts[i].exitReason = "closed";
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Format attempt data into string                                   |
//+------------------------------------------------------------------+
string FormatAttemptString(const CTradeAttempt &attempt)
{
   if(attempt.placeTime == 0) return "";
   
   string entryReason = attempt.entryReason;
   StringTrimLeft(entryReason);
   StringTrimRight(entryReason);
   
   if(attempt.status == "Pending")
   {
      return entryReason + " | pending";
   }
   if(attempt.status == "Active")
   {
      return entryReason + " | active";
   }
   if(attempt.status == "Cancelled")
   {
      return entryReason + " | cancelled";
   }
   if(attempt.status == "Closed")
   {
      int scaledPts = (int)MathRound(attempt.profitPoints / 100.0);
      string sign = (scaledPts >= 0) ? "+" : "";
      
      if(attempt.exitReason == "failed")
      {
         return entryReason + " | failed " + IntegerToString(scaledPts);
      }
      else if(attempt.exitReason == "trailing")
      {
         return entryReason + " | trailing, " + sign + IntegerToString(scaledPts);
      }
      else if(attempt.exitReason == "TP")
      {
         return entryReason + " | TP, " + sign + IntegerToString(scaledPts);
      }
      else
      {
         return entryReason + " | closed, " + sign + IntegerToString(scaledPts);
      }
   }
   return entryReason;
}

//+------------------------------------------------------------------+
//| Register or overwrite attempt in local memory array              |
//+------------------------------------------------------------------+
void RegisterAttemptInMemory(const CTradeAttempt &att)
{
   int matchIdx = -1;
   for(int i = 0; i < 9; i++)
   {
      if(g_attempts[i].placeTime > 0 && 
         g_attempts[i].timeframeStr == att.timeframeStr && 
         g_attempts[i].direction == att.direction)
      {
         // 1. If existing is Pending, we always match and overwrite it
         if(g_attempts[i].status == "Pending")
         {
            matchIdx = i;
            break;
         }
         // 2. If existing is Cancelled or Closed, we overwrite it if the time difference is less than 15 minutes (900s)
         if(g_attempts[i].status == "Cancelled" || g_attempts[i].status == "Closed")
         {
            datetime prevTime = (g_attempts[i].resolveTime > 0) ? g_attempts[i].resolveTime : g_attempts[i].placeTime;
            if(MathAbs(att.placeTime - prevTime) < 900)
            {
               matchIdx = i;
               break;
            }
         }
      }
   }

   if(matchIdx >= 0)
   {
      g_attempts[matchIdx] = att;
   }
   else
   {
      int emptyIdx = -1;
      for(int i = 0; i < 9; i++)
      {
         if(g_attempts[i].placeTime == 0)
         {
            emptyIdx = i;
            break;
         }
      }

      if(emptyIdx >= 0)
      {
         g_attempts[emptyIdx] = att;
      }
      else
      {
         for(int i = 0; i < 8; i++)
         {
            g_attempts[i] = g_attempts[i+1];
         }
         g_attempts[8] = att;
      }
   }
}

//+------------------------------------------------------------------+
//| Sort attempts chronologically                                     |
//+------------------------------------------------------------------+
void SortAttemptsChronologically()
{
   for(int i = 0; i < 8; i++)
   {
      for(int j = 0; j < 8 - i; j++)
      {
         if(g_attempts[j].placeTime > 0 && g_attempts[j+1].placeTime > 0)
         {
            if(g_attempts[j].placeTime > g_attempts[j+1].placeTime)
            {
               CTradeAttempt temp = g_attempts[j];
               g_attempts[j] = g_attempts[j+1];
               g_attempts[j+1] = temp;
            }
         }
         else if(g_attempts[j].placeTime == 0 && g_attempts[j+1].placeTime > 0)
         {
            CTradeAttempt temp = g_attempts[j];
            g_attempts[j] = g_attempts[j+1];
            g_attempts[j+1] = temp;
         }
      }
   }
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
   bool active[3] = { cfg.m2Active, cfg.m5Active, cfg.m15Active };
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

}

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
{
   if(!g_initialized) return;
   // Immediately update stats when deals are added (trade closes or opens)
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      UpdateTradeStats();
   }
}
//+------------------------------------------------------------------+
