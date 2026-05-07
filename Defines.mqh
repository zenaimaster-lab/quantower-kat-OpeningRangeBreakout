//+------------------------------------------------------------------+
//|                                                      Defines.mqh |
//|                     KAT Opening Range Breakout EA — Shared Defs   |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef __DEFINES_MQH__
#define __DEFINES_MQH__

#define EA_NAME           "KAT Opening Range Breakout"
#define EA_VERSION        "0.13"
#define EA_BUILD_DATE     "08 May 2026"
extern int g_magic;
#define EA_COMMENT_PREFIX "KAT_ORB_"

//--- Panel dimensions
#define PANEL_WIDTH       370
#define PANEL_HEIGHT      1350
#define PANEL_X           20
#define PANEL_Y           20

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
#define CLR_PRESET        C'70,50,120'
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
enum ENUM_TAB { TAB_MAIN=0, TAB_M2=1, TAB_M5=2, TAB_STATS=3 };


// Consolidated trail mode
enum ENUM_TRAIL_MODE
{
   TM_OFF       = 0,
   TM_CHASE     = 1,   // Uses trigger/distance/step inputs
   TM_CANDLE_1  = 2,   // Trail SL to candle[1] low/high
   TM_CANDLE_2  = 3,   // Trail SL to candle[2]
   TM_CANDLE_3  = 4    // Trail SL to candle[3]
};


// Command queue enum
enum ENUM_DASHBOARD_CMD
{
   CMD_NONE = 0,
   CMD_CANCEL_ALL,
   CMD_PRESET
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
   int    afterMinutes;
   bool   afterMinutesOn;
   bool   ema1On;
   int    ema1Period;
   bool   ema2On;
   int    ema2Period;
   bool   ema3On;
   int    ema3Period;
   
   bool   contAfter1st;
   bool   maxSuccessOn;
   int    maxSuccess;
   bool   maxLossOn;
   int    maxLoss;
   bool   bigMomentum;
   
   string comment;
   bool   isActive;


   DashboardParams()
   {
      symbol            = "";
      nyHour            = 9;
      nyMinute          = 30;
      nySecond          = 0;
      utcOffset         = -4;
      timeframe         = PERIOD_M2;
      slPoints          = 1500;
      tpPoints          = 3000;
      slCandle          = false;
      entryBufferPoints = 5;
      riskPercent       = 1.0;
      orderMode         = MODE_BOTH;
      eaMode            = EA_AUTO;
      trailMode         = TM_OFF;
      trailTrigger      = 30;
      trailDistance      = 20;
      trailStep         = 5;
      beActivatePoints  = 200;
      beLockPoints      = 50;
      beEnabled         = false;
      unfavorMovePts=100;
      unfavorMoveOn=false;
      touchMidOn=false;
      unfilledCandles=2;
      unfilledCandlesOn=false;
      afterMinutes=5;
      afterMinutesOn=false;
      ema1On=false;
      ema1Period=9;
      ema2On=false;
      ema2Period=21;
      ema3On=false;
      ema3Period=34;
      contAfter1st=true;
      maxSuccessOn=false;
      maxSuccess=5;
      maxLossOn=false;
      maxLoss=1;
      bigMomentum=false;
      comment           = "orb-trade";
      isActive          = true;
   }
};

struct SystemConfig {
   bool globalOverride;
   DashboardParams main;
   DashboardParams m2;
   DashboardParams m5;
   
   SystemConfig() {
      globalOverride = true;
      m2.timeframe = PERIOD_M2;
      m2.comment = "orb-2m";
      m5.timeframe = PERIOD_M5;
      m5.comment = "orb-5m";
   }
};

struct PresetParams
{
   int    sl;
   int    tp;
   double risk;
   int    trailTrigger;
   int    trailDist;
   int    trailStep;
   ENUM_TIMEFRAMES tf;
};

struct NewsEvent
{
   string   name;
   datetime time;
   bool     isNYO;
   NewsEvent() { name = ""; time = 0; isNYO = false; }
};

//--- Helper: Initialize a preset (eliminates copy-paste in OnInit)
void InitPreset(PresetParams &pr, int sl, int tp, double risk,
                int trig, int dist, int step, ENUM_TIMEFRAMES tf)
{
   pr.sl          = sl;
   pr.tp          = tp;
   pr.risk        = risk;
   pr.trailTrigger = trig;
   pr.trailDist   = dist;
   pr.trailStep   = step;
   pr.tf          = tf;
}

//--- Timeframe utilities
string TimeframeToString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
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
      default:         return 1;
   }
}


#endif // __DEFINES_MQH__
