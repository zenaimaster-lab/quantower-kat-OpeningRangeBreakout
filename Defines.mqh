//+------------------------------------------------------------------+
//|                                                      Defines.mqh |
//|                     KAT Opening Range Breakout EA — Shared Defs   |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef __DEFINES_MQH__
#define __DEFINES_MQH__

#define EA_NAME           "KAT Opening Range Breakout"
#define EA_VERSION        "1.67"
#define EA_BUILD_DATE     "21 May 2026"
#define EA_COMMENT_PREFIX "KAT_ORB_"

#include "GlobalState.mqh"

//--- Panel dimensions
#define PANEL_WIDTH       370
#define PANEL_HEIGHT      1270
#define PANEL_X           20
#define PANEL_Y           20
#define PANEL_GRID_PAD    10

//--- Control sizing
#define CTRL_HEIGHT       22
#define CTRL_GAP          5
#define LABEL_WIDTH       106
#define BTN_HEIGHT        28
#define SECTION_GAP       8
#define SECTION_HDR_H     12
#define SEP_GAP           12
#define SEC_PAD           6
#define MANAGE_BTN_H      34

//--- Typography
#define FONT_NAME         "Segoe UI"
#define FONT_SIZE         9
#define FONT_SIZE_MED     11
#define FONT_SIZE_TITLE   11
#define FONT_SIZE_BIG     14

//--- Color palette
#define CLR_BG            C'14,14,22'
#define CLR_PANEL_BG      C'18,18,28'
#define CLR_CAPTION_BG    C'16,16,26'
#define CLR_ACCENT        C'55,120,210'
#define CLR_ACCENT_DIM    C'45,90,160'
#define CLR_BUY           C'0,145,85'
#define CLR_SELL          C'230,60,60'
#define CLR_TEXT          C'190,190,200'
#define CLR_TEXT_DIM      C'100,100,120'
#define CLR_TEXT_BRIGHT   C'235,235,245'
#define CLR_EDIT_BG       C'30,30,44'
#define CLR_EDIT_BORDER   C'45,45,65'
#define CLR_BTN_ON        C'30,90,160'
#define CLR_BTN_OFF       C'45,45,62'
#define CLR_WARNING       C'220,150,20'
#define CLR_SUCCESS       C'15,105,60'
#define CLR_GOLD          C'255,210,80'
#define CLR_MONEY_GREEN   C'100,220,140'
#define CLR_MONEY_RED     C'240,90,90'
#define CLR_FLATTEN       C'200,50,50'
#define CLR_PURPLE        C'110,40,160'
#define CLR_NEWS_RED      C'255,70,70'
#define CLR_MKT_OPEN      C'40,220,120'
#define CLR_MKT_CLOSED    C'200,60,60'
#define CLR_LOCK          C'180,130,40'
#define CLR_REVERSE       C'150,60,200'
#define CLR_CLOCK_BLUE    C'90,170,255'
#define CLR_SEP           C'50,50,70'
#define CLR_SYMBOL        C'255,220,80'
#define CLR_ORANGE        C'240,160,40'

//--- Enums
enum ENUM_ORDER_MODE    { MODE_BOTH=0, MODE_BUY_ONLY=1, MODE_SELL_ONLY=2 };
enum ENUM_EA_MODE       { EA_AUTO=0, EA_MANUAL=1 };
enum ENUM_TAB { TAB_STATS=0, TAB_ORDER=1, TAB_ENTRY=2, TAB_FLATTEN=3 };


// Consolidated trail mode
enum ENUM_TRAIL_MODE
{
   TM_OFF       = 0,
   TM_CHASE     = 1,   // Uses trigger/distance/step inputs
   TM_CANDLE_1  = 2,   // Trail SL to candle[1] low/high
   TM_CANDLE_2  = 3,   // Trail SL to candle[2]
   TM_CANDLE_3  = 4    // Trail SL to candle[3]
};


//--- Data structs
struct DashboardParams
{
   string symbol;
   int    nyHour;
   int    nyMinute;
   int    nySecond;
   int    utcOffset;
   ENUM_TIMEFRAMES   timeframe;
   int    slPoints;
   int    tpPoints;
   bool   slCandle;
   int    entryBufferPoints;
   double riskPercent;
   bool   riskModeOn;
   double fixLot;
   ENUM_ORDER_MODE   orderMode;
   ENUM_EA_MODE      eaMode;
   ENUM_TRAIL_MODE   trailMode;
   int    trailTrigger;
   int    trailDistance;
   int    trailStep;
   int    beActivatePoints;
   int    beLockPoints;
   bool   beEnabled;
   int    unfavorMovePts;
   bool   unfavorMoveOn;
   bool   touchMidOn;
   int    unfilledCandles;
   bool   unfilledCandlesOn;
   int    afterFilledMinutes;
   bool   afterFilledMinutesOn;
   int    afterMinutes;
   bool   afterMinutesOn;
   bool   ema1On;
   int    ema1Period;
   bool   ema2On;
   int    ema2Period;
   bool   ema3On;
   int    ema3Period;
   bool   customRetestOn;
   int    customRetestMin;
   
   bool   contAfter1st;
   bool   maxSuccessOn;
   int    maxSuccess;
   bool   maxLossOn;
   int    maxLoss;
   bool   bigMomentum;
   
   bool   maxDistRangeOn;
   int    maxDistRange;
   
   bool   favorEma1On;
   int    favorEma1Period;
   bool   favorEma2On;
   int    favorEma2Period;
   bool   favorEma3On;
   int    favorEma3Period;

   bool   obsRange5mOn;
   bool   obsRange15mOn;
   bool   obsRange30mOn;
   bool   obsPrevDayHLOn;
   bool   obsEma1On;
   int    obsEma1Period;
   bool   obsEma2On;
   int    obsEma2Period;
   bool   obsEma3On;
   int    obsEma3Period;
   bool   obsDayVwapOn;
   bool   obsWeekVwapOn;
   int    obsMaxDist;
   
   string comment;
   bool   isActive;
   int    tfIndex;  // 0=2m, 1=5m, 2=15m, 3=30m — for per-TF W/L tracking


   DashboardParams()
   {
      symbol            = "";
      nyHour            = 9;
      nyMinute          = 30;
      nySecond          = 0;
      utcOffset         = -4;
      timeframe         = PERIOD_M2;
      slPoints          = 1500;
      tpPoints          = 15000;
      slCandle          = false;
      entryBufferPoints = 5;
      riskPercent       = 1.0;
      riskModeOn        = true;
      fixLot            = 0.1;
      orderMode         = MODE_BOTH;
      eaMode            = EA_AUTO;
      trailMode         = TM_CHASE;
      trailTrigger      = 1500;
      trailDistance     = 500;
      trailStep         = 1;
      beActivatePoints  = 200;
      beLockPoints      = 50;
      beEnabled         = false;
      unfavorMovePts    = 8000;
      unfavorMoveOn     = true;
      touchMidOn        = true;
      unfilledCandles   = 2;
      unfilledCandlesOn = false;
      afterFilledMinutes = 5;
      afterFilledMinutesOn = true;
      afterMinutes      = 60;
      afterMinutesOn    = true;
      ema1On            = false;
      ema1Period        = 9;
      ema2On            = false;
      ema2Period        = 21;
      ema3On            = false;
      ema3Period        = 34;
      customRetestOn    = true;
      customRetestMin   = 1;
      contAfter1st      = true;
      maxSuccessOn      = true;
      maxSuccess        = 2;
      maxLossOn         = true;
      maxLoss           = 1;
      bigMomentum       = false;
      maxDistRangeOn    = true;
      maxDistRange      = 6000;
      favorEma1On       = false;
      favorEma1Period   = 9;
      favorEma2On       = false;
      favorEma2Period   = 21;
      favorEma3On       = false;
      favorEma3Period   = 34;
      obsRange5mOn      = true;
      obsRange15mOn     = true;
      obsRange30mOn     = true;
      obsPrevDayHLOn    = true;
      obsEma1On         = true;
      obsEma1Period     = 250;
      obsEma2On         = true;
      obsEma2Period     = 255;
      obsEma3On         = true;
      obsEma3Period     = 34;
      obsDayVwapOn      = true;
      obsWeekVwapOn     = true;
      obsMaxDist        = 1600;
      comment           = "orb-trade";
      isActive          = true;
      tfIndex           = 0;
   }
};

struct SystemConfig {
   DashboardParams main;
   bool m2Active;
   bool m5Active;
   bool m15Active;
   bool m30Active;
   
   SystemConfig() {
      m2Active = true;
      m5Active = true;
      m15Active = true;
      m30Active = true;
   }
};

struct NewsEvent
{
   string   name;
   datetime time;
   bool     isNYO;
   NewsEvent() { name = ""; time = 0; isNYO = false; }
};

//--- Timeframe utilities
string TimeframeToString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      default:         return "M2";
   }
}

ENUM_TIMEFRAMES StringToTimeframe(string s)
{
   StringToUpper(s);
   StringTrimLeft(s);
   StringTrimRight(s);
   if(s == "M1")  return PERIOD_M1;
   if(s == "M2")  return PERIOD_M2;
   if(s == "M5")  return PERIOD_M5;
   if(s == "M15") return PERIOD_M15;
   if(s == "M30") return PERIOD_M30;
   return PERIOD_M2;
}

int TimeframeToIndex(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return 0;
      case PERIOD_M2:  return 1;
      case PERIOD_M5:  return 2;
      case PERIOD_M15: return 3;
      case PERIOD_M30: return 4;
      default:         return 1;
   }
}


//--- Trade Attempt structure for dashboard stats tracking
struct CTradeAttempt
{
   ulong    orderTicket;
   long     positionId;
   datetime placeTime;
   string   symbol;
   string   timeframeStr;
   int      direction;
   string   entryReason;
   string   status;
   double   profitPoints;
   string   exitReason;
   datetime resolveTime;
};

#endif // __DEFINES_MQH__
