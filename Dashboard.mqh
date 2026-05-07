#ifndef __DASHBOARD_MQH__
#define __DASHBOARD_MQH__
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>
#include <Controls\ComboBox.mqh>
#include "Defines.mqh"

class CDashboard : public CAppDialog
{
private:
   CEdit m_lblVer, m_lblSym, m_lblMktLine, m_lblSpdVal, m_lblMktStatus;
   CEdit m_lblClkTag, m_lblClkVal, m_lblClkAmPm, m_lblClkDate, m_lblCdTag, m_lblCdVal;
   CEdit m_lblNewsTag, m_lblNewsVal;
   CEdit m_lblSchTag, m_lblC1, m_lblC2, m_lblBefTag, m_lblBefSec;
   CEdit  m_edtH, m_edtM, m_edtS, m_edtBef;
   CEdit m_lblTfTag, m_lblSlTag, m_lblMdTag, m_lblCsTag;
   CButton m_btnTf;
   CEdit  m_edtSL, m_edtTP;
   CButton m_btnSLS, m_btnBoth, m_btnBuy, m_btnSell, m_btnCandleSrc;
   CEdit m_lblBalTag, m_lblBalVal, m_lblRskTag, m_lblRPc;
   CEdit m_lblRATag, m_lblRAVal, m_lblRwVal, m_lblLtTag, m_lblLtVal;
   CEdit  m_edtRisk;
   CEdit m_lblTrTag, m_lblTrLine, m_lblBeLine;
   CEdit m_lblTrTrig, m_lblTrDist, m_lblTrStep;
   CEdit m_lblBELock;
   CButton m_btnTrMode;
   CEdit  m_edtTTr, m_edtTDi, m_edtTSt, m_edtBEA, m_edtBEL;
   CButton m_btnBE, m_btnApplyBE, m_btnApplyTrail;
   CEdit m_lblExpTag;
   CButton m_btnExpire;
   CEdit m_edtExpCandles;
   CButton m_btnA1,m_btnA2,m_btnA3;
   CButton m_btnAutoTrade, m_btnNyoOnly, m_btnAutoApply, m_btnApplyNext;
   CButton m_btnFlatten, m_btnPlaceStop, m_btnCancelPend;
   CButton m_btnBuyMkt, m_btnSellMkt, m_btnLock, m_btnReverse;
   CEdit m_lblOsTag, m_lblOsVal, m_lblStVal;
   CEdit m_lblEqTag, m_lblPlTag;
   CEdit m_lblStatEquity, m_lblStatPL;
   CEdit m_lblTotExpTag, m_lblTotExpVal;
   CEdit m_lblRtRrTag, m_lblRtRrLoss, m_lblRtRrPft, m_lblRtRrRiskPc;
   CPanel m_sep[20];

   // v0.66: Day picker (replaces AM/PM + TODAY)
   CButton m_btnDayPicker;

   // Tab system
   CButton m_btnTabMain, m_btnTabOrigami;
   int m_activeTab; // 0=Main, 1=Origami

   // Origami tab controls
   CEdit m_lblOrigamiTitle;
   CEdit m_lblOrigamiTarget, m_lblOrigamiSlMode, m_lblOrigamiPct, m_lblOrigamiTargetAmt;
   CEdit m_lblOrigamiAdd1, m_lblOrigamiAdd2, m_lblOrigamiAdd3;
   CEdit  m_edtOrigamiTarget;
   CEdit  m_edtOrigamiAdd1, m_edtOrigamiAdd2, m_edtOrigamiAdd3;
   CButton m_btnOrigamiSlMode, m_btnOrigamiOnOff, m_btnOrigamiApplyNow, m_btnOrigamiClear;
   CButton m_btnOrigamiOnOffMain, m_btnOrigamiApplyNowMain, m_btnOrigamiClearMain;
   CEdit m_lblOrigamiInfo1, m_lblOrigamiInfo2, m_lblOrigamiInfo3, m_lblOrigamiInfo4;
   CEdit m_lblO_OsTag, m_lblO_OsVal, m_lblO_StVal;
   CEdit m_lblO_EqTag, m_lblO_StatEquity, m_lblO_PlTag, m_lblO_StatPL;
   CEdit m_lblO_TotExpTag, m_lblO_TotExpVal;
   CEdit m_lblO_RtRrTag, m_lblO_RtRrLoss, m_lblO_RtRrPft, m_lblO_RtRrRiskPc;
   CEdit m_lblOrigamiStatus, m_lblOrigamiStatusMain;
   CEdit m_lblDiadStatus, m_lblDiadStatusMain;  // v1.51: DIAD solver status (shown below origami status)
   CEdit m_lblOrigamiMaxRiskTag, m_lblOrigamiMaxRiskPc;
   CEdit  m_edtOrigamiMaxRisk;

   void CtrlShow(CWnd &obj);
   void CtrlShowBtn(CWnd &obj);
   void CtrlShowEdit(CWnd &obj);
   void CtrlHide(CWnd &obj);


   DashboardParams m_p;
   bool m_slCandle, m_auto, m_expEnabled, m_beOn;
   int m_utcOff;
   bool m_nyoOnly, m_autoNews;
   ENUM_ORDER_MODE m_om;
   ENUM_TRAIL_MODE m_tm;
   ENUM_CANDLE_SOURCE m_cs;
   bool m_origamiEnabled;          // v0.2: origami on/off
   int m_dayOffset;              // v0.66: 0=Today, 1..6=next days
   bool m_customTiming;        // v0.2: user set custom timing
   ENUM_ORIGAMI_SL_MODE m_origamiSlMode;
   bool m_dirty;                        // v2.0: dirty flag for cached GetParams
   ENUM_DASHBOARD_CMD m_cmdQueue[16];   // v2.0: command queue
   int m_cmdCount;                      // v2.0: commands in queue
   uint m_lastClickMs;                  // v0.75: debounce — last click timestamp
   string m_lastClickName;              // v0.75: debounce — last clicked object
   void MarkDirty() { m_dirty = true; } // v2.0: called by any UI interaction
   void PushCmd(ENUM_DASHBOARD_CMD cmd) { if(m_cmdCount < 16) { m_cmdQueue[m_cmdCount] = cmd; m_cmdCount++; } }

public:
   CDashboard();
  ~CDashboard() {}
   bool CreatePanel(long chart,string name,int subwin,int x,int y,int w,int h);
   void SetInitialParams(const DashboardParams &p);
   DashboardParams GetParams();
   void UpdateSpread(int s);
   void UpdateCountdown(string s);
   void UpdateStatus(string s);
   void UpdateOrderStatus(string s);
   void UpdateNYClock(string t, string ap, string d);
   void UpdateBalanceInfo(double b,double r,double rw,double l);
   void ApplyPreset(const PresetParams &pr);
   void UpdateNews(string newsStr);
   void UpdateMarketStatus(bool isOpen);
   void UpdateSymbol(string sym);
   void ApplyTimingFromNews(int h,int m,int s);
   void UpdateOrigamiInfo(string s1,string s2,string s3,string s4);
   void UpdateOrigamiStatus(string s);
   void UpdateDiadStatus(string s);  // v1.51
   void UpdateEquityPL(double equity, double profit);
   void UpdateTotalExposed(double lots, int type);
   void UpdateRealtimeRR(double profit, double loss, double theoreticalRisk);
   void UpdateRealtimeRiskPercent(double riskPc, double maxRiskPc);
   string FormatMoneyRound(double value);
   // v2.0: Command queue API (replaces 13+ boolean flags)
   bool HasCommand() const { return m_cmdCount > 0; }
   ENUM_DASHBOARD_CMD PopCommand() { if(m_cmdCount <= 0) return CMD_NONE; m_cmdCount--; return m_cmdQueue[m_cmdCount]; }
   void MarkDirtyPublic() { MarkDirty(); }
   void PushCmdPublic(ENUM_DASHBOARD_CMD cmd) { PushCmd(cmd); }
   int  PresetIndex;
   bool NYOOnlyMode, AutoNewsEnabled;

private:
   bool ML(CEdit &l,string n,string t,int x,int y,int w,int h,color c=CLR_TEXT,int fs=FONT_SIZE);
   bool ME(CEdit &e,string n,string t,int x,int y,int w,int h);
   bool MB(CButton &b,string n,string t,int x,int y,int w,int h,color bg=CLR_BTN_OFF);
   void MSep(int idx,int x,int y,int w);
   void OnSLS(); void OnBoth(); void OnBuyO(); void OnSellO();
   void OnTrM(); void OnAutoT(); void OnManP(); void OnCanA();
   void OnFlatA(); void OnBrkEv(); void OnCandleSrc();
   void OnExpire(); void OnBEToggle(); void OnApplyBE(); void OnApplyTrail();
   void OnA1(); void OnA2(); void OnA3();
   void OnNyoOnly(); void OnAutoApply(); void OnApplyNextClick();
   void OnBuyMkt(); void OnSellMkt(); void OnLock(); void OnReverse();
   void OnTabMain(); void OnTabOrigami(); void OnOrigamiSlMode(); void OnOrigamiOnOff(); void OnOrigamiApplyNow(); void OnOrigamiClear();
   void OnOrigamiOnOffMain(); void OnOrigamiApplyNowMain(); void OnOrigamiClearMain();
   void OnDayPicker();
   void UpdMode(); void UpdTrail(); void UpdCandleSrc(); void UpdExpire(); void UpdBE();
   void ShowTab(int tab);
public:
   bool HandleDirectClick(const string &objName);

};

CDashboard::CDashboard() { m_slCandle=false; m_om=MODE_BOTH; m_tm=TM_OFF; m_auto=true;
   m_cs=CANDLE_CURRENT; m_expEnabled=false; m_autoNews=false;
   m_utcOff=-4; m_nyoOnly=false; m_beOn=false;
   m_dirty=true; m_cmdCount=0; PresetIndex=-1;
   NYOOnlyMode=false; AutoNewsEnabled=false;
   m_activeTab=0; m_origamiSlMode=ORIGAMI_SL_BE_SPREAD;
   m_origamiEnabled=false; m_dayOffset=0; m_customTiming=false;
   m_lastClickMs=0; m_lastClickName=""; }



bool CDashboard::CreatePanel(long chart,string name,int subwin,int x,int y,int w,int h)
{
   if(!CAppDialog::Create(chart,name,subwin,x,y,x+w,y+h)) return false;
   Caption(EA_NAME);
   int colored=0;
   for(int i=ObjectsTotal(chart,subwin)-1;i>=0;i--)
   { string n=ObjectName(chart,i,subwin); ENUM_OBJECT ot=(ENUM_OBJECT)ObjectGetInteger(chart,n,OBJPROP_TYPE);
     if(ot==OBJ_RECTANGLE_LABEL){ObjectSetInteger(chart,n,OBJPROP_BGCOLOR,CLR_PANEL_BG);ObjectSetInteger(chart,n,OBJPROP_BORDER_COLOR,CLR_PANEL_BG);ObjectSetInteger(chart,n,OBJPROP_ZORDER,-100);colored++;}
     else if(ot==OBJ_EDIT){ObjectSetInteger(chart,n,OBJPROP_BGCOLOR,CLR_CAPTION_BG);ObjectSetInteger(chart,n,OBJPROP_COLOR,CLR_TEXT_BRIGHT);ObjectSetInteger(chart,n,OBJPROP_BORDER_COLOR,CLR_CAPTION_BG);ObjectSetInteger(chart,n,OBJPROP_ZORDER,-100);colored++;}}
   int cx=6,cy=4,cw=w-26,rx=cx+LABEL_WIDTH+4,rw=cw-LABEL_WIDTH-4;
   int si=0;

   // ── TAB BUTTONS ──
   int tabW=(cw-4)/2;
   MB(m_btnTabMain,"tMain","MAIN",cx,cy,tabW,CTRL_HEIGHT+4,CLR_ACCENT);
   MB(m_btnTabOrigami,"tOrigami","ORIGAMI",cx+tabW+4,cy,tabW,CTRL_HEIGHT+4,CLR_BTN_OFF);
   cy+=CTRL_HEIGHT+4+4;

   cy+=2;
   ML(m_lblVer,"ver","Version "+EA_VERSION+" | "+EA_BUILD_DATE,cx,cy,cw,12,CLR_TEXT_DIM,7); cy+=16;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── MARKET ──
   ML(m_lblSym,"lSm",Symbol(),cx,cy,cw,CTRL_HEIGHT+6,CLR_SYMBOL,FONT_SIZE_BIG); cy+=CTRL_HEIGHT+8;
   ML(m_lblMktStatus,"lMk","Market Closed",cx,cy,100,16,CLR_MKT_CLOSED,8);
   ML(m_lblSpdVal,"vSp","Spread: —",cx+104,cy,cw-104,16,CLR_WARNING,8); cy+=24;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── CLOCK ──
   ML(m_lblClkTag,"lCk","NY Time",cx,cy,LABEL_WIDTH,CTRL_HEIGHT,CLR_TEXT,FONT_SIZE_MED);
   ML(m_lblClkVal,"vCk","--:--:--",rx,cy,72,CTRL_HEIGHT,CLR_CLOCK_BLUE,FONT_SIZE_MED);
   ML(m_lblClkAmPm,"vCkAP","--",rx+74,cy,32,CTRL_HEIGHT,CLR_REVERSE,FONT_SIZE_MED);
   ML(m_lblClkDate,"vCkD","(-- ---)",rx+108,cy,rw-108,CTRL_HEIGHT,CLR_TEXT_DIM,FONT_SIZE_MED); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblCdTag,"lCd","Countdown",cx,cy,LABEL_WIDTH,CTRL_HEIGHT,CLR_TEXT,FONT_SIZE_MED);
   ML(m_lblCdVal,"vCd","--:--:--",rx,cy,rw,CTRL_HEIGHT,CLR_WARNING,FONT_SIZE_MED); cy+=CTRL_HEIGHT+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── EVENTS / CONTROLS ──
   ML(m_lblNewsTag,"lNw","Next:",cx,cy,36,CTRL_HEIGHT);
   ML(m_lblNewsVal,"vNw","Loading...",cx+40,cy,cw-40,CTRL_HEIGHT,CLR_NEWS_RED); cy+=CTRL_HEIGHT+CTRL_GAP;
   int hw2=(cw-4)/2;
   MB(m_btnAutoTrade,"bAt","AUTO TRADE: ON",cx,cy,hw2,CTRL_HEIGHT+2,CLR_SUCCESS);
   MB(m_btnNyoOnly,"bNO","NYO ONLY: OFF",cx+hw2+4,cy,hw2,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   MB(m_btnAutoApply,"bAA","AUTO APPLY: OFF",cx,cy,hw2,CTRL_HEIGHT+2,CLR_BTN_OFF);
   MB(m_btnApplyNext,"bAN","APPLY NEXT",cx+hw2+4,cy,hw2,CTRL_HEIGHT+2,CLR_PRESET); cy+=CTRL_HEIGHT+2+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── TIMING ──
   int tw=44;
   ML(m_lblSchTag,"lSc","Target H:M:S",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtH,"eH","9",rx,cy,tw,CTRL_HEIGHT); ML(m_lblC1,"c1",":",rx+tw+2,cy,7,CTRL_HEIGHT);
   ME(m_edtM,"eM","30",rx+tw+12,cy,tw,CTRL_HEIGHT); ML(m_lblC2,"c2",":",rx+tw*2+14,cy,7,CTRL_HEIGHT);
   ME(m_edtS,"eS","0",rx+tw*2+24,cy,tw,CTRL_HEIGHT); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblBefTag,"lBf","Trigger before",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtBef,"eBf","10",rx,cy,40,CTRL_HEIGHT);
   ML(m_lblBefSec,"lBs","sec",rx+45,cy,30,CTRL_HEIGHT,CLR_TEXT_DIM);
   MB(m_btnDayPicker,"bDP","TODAY",cx+cw-110,cy,110,CTRL_HEIGHT,CLR_BTN_OFF); cy+=CTRL_HEIGHT+8;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── ORDER ──
   ML(m_lblTfTag,"lTf","Timeframe",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnTf,"bTf","M2",rx,cy,90,CTRL_HEIGHT,CLR_BTN_OFF);
   cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblSlTag,"lSl","SL / TP",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtSL,"eSl","1500",rx,cy,55,CTRL_HEIGHT); ME(m_edtTP,"eTp","3000",rx+59,cy,55,CTRL_HEIGHT);
   MB(m_btnSLS,"bSs","SL by Candle",rx+120,cy,rw-120,CTRL_HEIGHT,CLR_BTN_ON); cy+=CTRL_HEIGHT+10;
   ML(m_lblMdTag,"lMd","Order mode",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   int mb=(rw-6)/3;
   MB(m_btnBoth,"bBt","BOTH",rx,cy,mb,CTRL_HEIGHT+2,CLR_BTN_ON);
   MB(m_btnBuy,"bBy","BUY",rx+mb+3,cy,mb,CTRL_HEIGHT+2);
   MB(m_btnSell,"bSe","SELL",rx+(mb+3)*2,cy,mb,CTRL_HEIGHT+2); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblCsTag,"lCs","Candle",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnCandleSrc,"bCs","CURRENT",rx,cy,rw,CTRL_HEIGHT,CLR_SUCCESS); cy+=CTRL_HEIGHT+8+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── RISK ──
   ML(m_lblBalTag,"lBa","Balance",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblBalVal,"vBa","$0.00",rx,cy,rw,CTRL_HEIGHT,CLR_TEXT_BRIGHT); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblRskTag,"lRk","Risk (%)",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtRisk,"eRk","1.0",rx,cy,40,CTRL_HEIGHT);
   ML(m_lblRPc,"lPc","%",rx+43,cy,18,CTRL_HEIGHT,CLR_TEXT_DIM);
   ML(m_lblOrigamiMaxRiskTag,"pMRt","Max risk",rx+64,cy,70,CTRL_HEIGHT,CLR_TEXT);
   ME(m_edtOrigamiMaxRisk,"pMRk","5.0",rx+136,cy,40,CTRL_HEIGHT);
   ML(m_lblOrigamiMaxRiskPc,"pMRp","%",rx+180,cy,18,CTRL_HEIGHT,CLR_TEXT_DIM); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblRATag,"lRA","Risk / Reward",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblRAVal,"vRA","-$0",rx,cy,70,CTRL_HEIGHT,CLR_MONEY_RED);
   ML(m_lblRwVal,"vRw","+$0",rx+75,cy,70,CTRL_HEIGHT,CLR_MONEY_GREEN); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblLtTag,"lLt","Lot size",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblLtVal,"vLt","0.00",rx,cy,rw,CTRL_HEIGHT,CLR_TEXT_BRIGHT); cy+=CTRL_HEIGHT+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── TRAIL / BE ──
   ML(m_lblTrTag,"lTr","Trailing mode",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnTrMode,"bTm","OFF",rx,cy,rw,CTRL_HEIGHT+2); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblTrTrig,"lTL","Trigger:",cx,cy,60,CTRL_HEIGHT);
   ME(m_edtTTr,"eTTr","30",cx+62,cy,35,CTRL_HEIGHT);
   ML(m_lblTrDist,"lDi","Distance:",cx+100,cy,70,CTRL_HEIGHT);
   ME(m_edtTDi,"eTDi","20",cx+172,cy,35,CTRL_HEIGHT);
   ML(m_lblTrStep,"lStp","Step:",cx+212,cy,40,CTRL_HEIGHT);
   ME(m_edtTSt,"eTSt","5",cx+254,cy,35,CTRL_HEIGHT); cy+=CTRL_HEIGHT+CTRL_GAP;
   MB(m_btnApplyTrail,"bATr","APPLY TRAILING NOW",cx,cy,cw,CTRL_HEIGHT+2,CLR_ACCENT_DIM); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   int bew1=cw/3, bew2=cw-bew1-3;
   MB(m_btnBE,"bBE","BE: OFF",cx,cy,bew1,CTRL_HEIGHT+2,CLR_BTN_OFF);
   MB(m_btnApplyBE,"bABE","APPLY BE NOW",cx+bew1+3,cy,bew2,CTRL_HEIGHT+2,CLR_ACCENT_DIM); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblBeLine,"lBL","BE Trigger",cx,cy,85,CTRL_HEIGHT);
   ME(m_edtBEA,"eBA","200",cx+87,cy,42,CTRL_HEIGHT);
   ML(m_lblBELock,"lPl","+",cx+131,cy,14,CTRL_HEIGHT);
   ME(m_edtBEL,"eBL","50",cx+147,cy,42,CTRL_HEIGHT); cy+=CTRL_HEIGHT+CTRL_GAP;
   MB(m_btnExpire,"bEx","auto cancel all: OFF",cx,cy,cw-44,CTRL_HEIGHT+2,CLR_BTN_OFF);
   ME(m_edtExpCandles,"eEx","2",cx+cw-40,cy,40,CTRL_HEIGHT); cy+=CTRL_HEIGHT+2+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── PRESETS ──
   int pw=(cw-10)/3;
   MB(m_btnA1,"bA1","Set A",cx,cy,pw,CTRL_HEIGHT+2,CLR_PRESET); 
   MB(m_btnA2,"bA2","Set B",cx+pw+5,cy,pw,CTRL_HEIGHT+2,CLR_PRESET);
   MB(m_btnA3,"bA3","Set C",cx+(pw+5)*2,cy,pw,CTRL_HEIGHT+2,CLR_PRESET); cy+=CTRL_HEIGHT+2+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── MANAGE ──
   MB(m_btnFlatten,"bFl","FLATTEN ALL",cx,cy,cw,MANAGE_BTN_H,CLR_FLATTEN); cy+=MANAGE_BTN_H+CTRL_GAP;
   int hw=(cw-6)/2;
   MB(m_btnPlaceStop,"bPS","PLACE STOP ORDER",cx,cy,hw,MANAGE_BTN_H,CLR_ACCENT);
   MB(m_btnCancelPend,"bCP","CANCEL PENDING",cx+hw+6,cy,hw,MANAGE_BTN_H,CLR_BTN_OFF); cy+=MANAGE_BTN_H+CTRL_GAP;
   MB(m_btnBuyMkt,"bBM","BUY MARKET",cx,cy,hw,MANAGE_BTN_H,CLR_BUY);
   MB(m_btnSellMkt,"bSM","SELL MARKET",cx+hw+6,cy,hw,MANAGE_BTN_H,CLR_SELL); cy+=MANAGE_BTN_H+CTRL_GAP;
   MB(m_btnLock,"bLK","LOCK",cx,cy,hw,MANAGE_BTN_H,CLR_LOCK);
   MB(m_btnReverse,"bRV","REVERSE",cx+hw+6,cy,hw,MANAGE_BTN_H,CLR_REVERSE); cy+=MANAGE_BTN_H+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── STATUS ──
   ML(m_lblOsTag,"lOs","Orders",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblOsVal,"vOs","IDLE",rx,cy,rw,CTRL_HEIGHT,CLR_TEXT_DIM); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblStVal,"vSv","Ready",cx,cy,cw,CTRL_HEIGHT,CLR_SUCCESS); cy+=CTRL_HEIGHT+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   ML(m_lblEqTag,"lEqT","Equity:",cx,cy,50,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblStatEquity,"sEq","$0",cx+52,cy,85,CTRL_HEIGHT,clrWhite);
   ML(m_lblPlTag,"lPlT","P/L:",cx+142,cy,30,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblStatPL,"sPL","+$0",cx+175,cy,75,CTRL_HEIGHT,CLR_SUCCESS);
   cy+=CTRL_HEIGHT+CTRL_GAP;
   
   ML(m_lblTotExpTag,"lTeT","Total exposed:",cx,cy,100,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblTotExpVal,"sTeV","0.00",cx+105,cy,rw,CTRL_HEIGHT,CLR_TEXT_DIM);
   cy+=CTRL_HEIGHT+CTRL_GAP;
   
   ML(m_lblRtRrTag,"lRtT","Realtime R:R",cx,cy,LABEL_WIDTH,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblRtRrLoss,"sRtL","-$0",rx,cy,65,CTRL_HEIGHT,CLR_MONEY_RED);
   ML(m_lblRtRrPft,"sRtP","+$0",rx+68,cy,65,CTRL_HEIGHT,CLR_MONEY_GREEN);
   ML(m_lblRtRrRiskPc,"sRtPc","{0.0%}",cx+cw-45,cy,45,CTRL_HEIGHT,CLR_ACCENT);
   cy+=CTRL_HEIGHT+CTRL_GAP;
   
   MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;
   ML(m_lblOrigamiStatusMain,"pStM","Origami: OFF",cx,cy,cw-140,CTRL_HEIGHT,CLR_WARNING);
   MB(m_btnOrigamiApplyNowMain,"bPOAM","NOW",cx+cw-135,cy,40,CTRL_HEIGHT,CLR_ACCENT_DIM);
   MB(m_btnOrigamiClearMain,"bPOCM","CLR",cx+cw-90,cy,35,CTRL_HEIGHT,CLR_FLATTEN);
   MB(m_btnOrigamiOnOffMain,"bPOOM","OFF",cx+cw-50,cy,50,CTRL_HEIGHT,CLR_BTN_OFF);
   cy+=CTRL_HEIGHT+2;
   ML(m_lblDiadStatusMain,"pDsM","",cx,cy,cw,CTRL_HEIGHT,C'255,220,100',FONT_SIZE);
   cy+=CTRL_HEIGHT+SEC_PAD+15;

   // ══════════════════════════════════════════════════
   // ── ORIGAMI TAB (initially hidden) ──
   // ══════════════════════════════════════════════════
   int py = 50;
   MSep(si++,cx,py,cw); py+=SEP_GAP+SEC_PAD;
   ML(m_lblOrigamiTitle,"pTi","ORIGAMI MODE",cx,py,cw-90,CTRL_HEIGHT+4,CLR_CLOCK_BLUE,FONT_SIZE_MED);
   MB(m_btnOrigamiOnOff,"bPOO","OFF",cx+cw-80,py,80,CTRL_HEIGHT+4,CLR_BTN_OFF);
   py+=CTRL_HEIGHT+8;

   int obtnW = (cw-CTRL_GAP)/2;
   MB(m_btnOrigamiApplyNow,"bPOA","APPLY NOW",cx,py,obtnW,CTRL_HEIGHT+2,CLR_ACCENT_DIM);
   MB(m_btnOrigamiClear,"bPOC","CLEAR",cx+obtnW+CTRL_GAP,py,obtnW,CTRL_HEIGHT+2,CLR_FLATTEN);
   py+=CTRL_HEIGHT+2+CTRL_GAP+SEC_PAD+10;
   MSep(si++,cx,py,cw); py+=SEP_GAP+SEC_PAD;

   ML(m_lblOrigamiTarget,"pTg","Target Growth",cx,py,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtOrigamiTarget,"ePTg","50.0",rx,py,44,CTRL_HEIGHT);
   ML(m_lblOrigamiPct,"pPc","%",rx+46,py,20,CTRL_HEIGHT,CLR_TEXT_DIM);
   ML(m_lblOrigamiTargetAmt,"pTA","",rx+68,py,rw-68,CTRL_HEIGHT,CLR_GOLD,FONT_SIZE); py+=CTRL_HEIGHT+CTRL_GAP;

   ML(m_lblOrigamiAdd1,"pA1","Add-in 1 (%)",cx,py,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtOrigamiAdd1,"ePA1","35",rx,py,44,CTRL_HEIGHT); py+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblOrigamiAdd2,"pA2","Add-in 2 (%)",cx,py,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtOrigamiAdd2,"ePA2","50",rx,py,44,CTRL_HEIGHT); py+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblOrigamiAdd3,"pA3","Add-in 3 (%)",cx,py,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtOrigamiAdd3,"ePA3","65",rx,py,44,CTRL_HEIGHT); py+=CTRL_HEIGHT+CTRL_GAP+4;

   MSep(si++,cx,py,cw); py+=SEP_GAP+SEC_PAD;
   ML(m_lblOrigamiInfo1,"pI1","Step 1: —",cx,py,cw,CTRL_HEIGHT,CLR_TEXT_DIM); py+=CTRL_HEIGHT+2;
   ML(m_lblOrigamiInfo2,"pI2","Step 2: —",cx,py,cw,CTRL_HEIGHT,CLR_TEXT_DIM); py+=CTRL_HEIGHT+2;
   ML(m_lblOrigamiInfo3,"pI3","Step 3: —",cx,py,cw,CTRL_HEIGHT,CLR_TEXT_DIM); py+=CTRL_HEIGHT+2;
   ML(m_lblOrigamiInfo4,"pI4","Base: —",cx,py,cw,CTRL_HEIGHT,CLR_TEXT_DIM); py+=CTRL_HEIGHT+CTRL_GAP;
   MSep(si++,cx,py,cw); py+=SEP_GAP+SEC_PAD;
   ML(m_lblO_OsTag,"lO_Os","Orders",cx,py,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblO_OsVal,"vO_Os","IDLE",rx,py,rw,CTRL_HEIGHT,CLR_TEXT_DIM); py+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblO_StVal,"vO_Sv","Ready",cx,py,cw,CTRL_HEIGHT,CLR_SUCCESS); py+=CTRL_HEIGHT+SEC_PAD;
   py+=SEC_PAD; MSep(si++,cx,py,cw); py+=SEP_GAP+SEC_PAD;

   ML(m_lblO_EqTag,"lO_EqT","Equity:",cx,py,50,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblO_StatEquity,"sO_Eq","$0",cx+52,py,85,CTRL_HEIGHT,clrWhite);
   ML(m_lblO_PlTag,"lO_PlT","P/L:",cx+142,py,30,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblO_StatPL,"sO_PL","+$0",cx+175,py,75,CTRL_HEIGHT,CLR_SUCCESS);
   py+=CTRL_HEIGHT+CTRL_GAP;

   ML(m_lblO_TotExpTag,"lO_TeT","Total exposed:",cx,py,100,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblO_TotExpVal,"sO_TeV","0.00",cx+105,py,rw,CTRL_HEIGHT,CLR_TEXT_DIM);
   py+=CTRL_HEIGHT+CTRL_GAP;

   ML(m_lblO_RtRrTag,"lO_RtT","Realtime R:R",cx,py,LABEL_WIDTH,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblO_RtRrLoss,"sO_RtL","-$0",rx,py,65,CTRL_HEIGHT,CLR_MONEY_RED);
   ML(m_lblO_RtRrPft,"sO_RtP","+$0",rx+68,py,65,CTRL_HEIGHT,CLR_MONEY_GREEN);
   ML(m_lblO_RtRrRiskPc,"sO_RtPc","{0.0%}",cx+cw-45,py,45,CTRL_HEIGHT,CLR_ACCENT);
   py+=CTRL_HEIGHT+CTRL_GAP;

   MSep(si++,cx,py,cw); py+=SEP_GAP+SEC_PAD;
   ML(m_lblOrigamiStatus,"pSt","Origami: OFF",cx,py,cw,CTRL_HEIGHT,CLR_WARNING);
   py+=CTRL_HEIGHT+2;
   ML(m_lblDiadStatus,"pDs","",cx,py,cw,CTRL_HEIGHT,C'255,220,100',FONT_SIZE);

   // Start on Main tab
   ShowTab(0);
   return true;
}

// ── HELPERS ──
bool CDashboard::ML(CEdit &l,string n,string t,int x,int y,int w,int h,color c,int fs)
{ if(!l.Create(m_chart_id,n,m_subwin,x,y,x+w,y+h)) return false;
  l.Text(t);l.Color(c);l.ColorBackground(CLR_PANEL_BG);l.ColorBorder(CLR_PANEL_BG);
  l.Font(FONT_NAME);l.FontSize(fs);l.ReadOnly(true);
  ObjectSetInteger(m_chart_id,l.Name(),OBJPROP_ALIGN,ALIGN_LEFT);
  ObjectSetInteger(m_chart_id,l.Name(),OBJPROP_ZORDER,10);
  ObjectSetInteger(m_chart_id,l.Name(),OBJPROP_SELECTABLE,false);
  ObjectSetInteger(m_chart_id,l.Name(),OBJPROP_HIDDEN,true);
  return Add(l); }
bool CDashboard::ME(CEdit &e,string n,string t,int x,int y,int w,int h)
{ if(!e.Create(m_chart_id,n,m_subwin,x,y,x+w,y+h)) return false;
  e.Text(t);e.ColorBackground(CLR_EDIT_BG);e.ColorBorder(CLR_EDIT_BORDER);
  e.Color(CLR_TEXT_BRIGHT);e.Font(FONT_NAME);e.FontSize(FONT_SIZE);
  ObjectSetInteger(m_chart_id,e.Name(),OBJPROP_ZORDER,50);
  return Add(e); }
bool CDashboard::MB(CButton &b,string n,string t,int x,int y,int w,int h,color bg)
{ if(!b.Create(m_chart_id,n,m_subwin,x,y,x+w,y+h)) return false;
  b.Text(t);b.ColorBackground(bg);b.Color(clrWhite);b.ColorBorder(CLR_EDIT_BORDER);
  b.Font(FONT_NAME);b.FontSize(FONT_SIZE); 
  ObjectSetInteger(m_chart_id,b.Name(),OBJPROP_ZORDER,200);
  return Add(b); }
void CDashboard::MSep(int idx,int x,int y,int w)
{ string nm="sep"+IntegerToString(idx);
  if(!m_sep[idx].Create(m_chart_id,nm,m_subwin,x,y,x+w,y+1)) return;
  m_sep[idx].ColorBackground(CLR_TEXT_DIM);
  m_sep[idx].ColorBorder(CLR_TEXT_DIM);
  ObjectSetInteger(m_chart_id, nm, OBJPROP_ZORDER, -100);
  ObjectSetInteger(m_chart_id, nm, OBJPROP_SELECTABLE, false);
  ObjectSetInteger(m_chart_id, nm, OBJPROP_HIDDEN, true);
  Add(m_sep[idx]); }
void CDashboard::CtrlShow(CWnd &obj) {
   obj.Show();
   ObjectSetInteger(m_chart_id, obj.Name(), OBJPROP_ZORDER, 10);
}
void CDashboard::CtrlShowBtn(CWnd &obj) {
   obj.Show();
   ObjectSetInteger(m_chart_id, obj.Name(), OBJPROP_ZORDER, 200);
}
void CDashboard::CtrlShowEdit(CWnd &obj) {
   obj.Show();
   ObjectSetInteger(m_chart_id, obj.Name(), OBJPROP_ZORDER, 50);
}
void CDashboard::CtrlHide(CWnd &obj) {
   obj.Hide();
   ObjectSetInteger(m_chart_id, obj.Name(), OBJPROP_ZORDER, -100);
}

// ── DATA SYNC ──
DashboardParams CDashboard::GetParams()
{
   DashboardParams p = m_p;
   // v0.89: These were missing — symbol + timing MUST be read from UI
   p.symbol = m_lblSym.Text();
   p.nyHour = (int)StringToInteger(m_edtH.Text());
   p.nyMinute = (int)StringToInteger(m_edtM.Text());
   p.nySecond = (int)StringToInteger(m_edtS.Text());
   p.utcOffset = m_utcOff;
   p.triggerBeforeSec = (int)StringToInteger(m_edtBef.Text());
   string tf = m_btnTf.Text();
   if(tf=="M1") p.timeframe = PERIOD_M1;
   else if(tf=="M5") p.timeframe = PERIOD_M5;
   else if(tf=="M15") p.timeframe = PERIOD_M15;
   else p.timeframe = PERIOD_M2;
   
   p.slPoints = (int)StringToInteger(m_edtSL.Text());
  p.tpPoints=(int)StringToInteger(m_edtTP.Text());
  p.slCandle=m_slCandle;
  p.riskPercent=StringToDouble(m_edtRisk.Text());
  p.orderMode=m_om;
  p.eaMode=m_auto ? EA_AUTO : EA_MANUAL;
  p.trailMode=m_tm;
  p.trailTrigger=(int)StringToInteger(m_edtTTr.Text());
  p.trailDistance=(int)StringToInteger(m_edtTDi.Text());
  p.trailStep=(int)StringToInteger(m_edtTSt.Text());
  p.beActivatePoints=(int)StringToInteger(m_edtBEA.Text());
  p.beLockPoints=(int)StringToInteger(m_edtBEL.Text());
  p.beEnabled=m_beOn;
  p.candleSource=m_cs;
  p.expireEnabled=m_expEnabled;
  p.expireCandles=(int)StringToInteger(m_edtExpCandles.Text());
  p.targetGrowthPercent=StringToDouble(m_edtOrigamiTarget.Text());
  p.origamiSlMode=m_origamiSlMode;
  p.addInPct1=StringToDouble(m_edtOrigamiAdd1.Text());
  p.addInPct2=StringToDouble(m_edtOrigamiAdd2.Text());
  p.addInPct3=StringToDouble(m_edtOrigamiAdd3.Text());
  p.origamiEnabled=m_origamiEnabled;
  p.origamiMaxRiskPercent=StringToDouble(m_edtOrigamiMaxRisk.Text());
  p.customTiming=m_customTiming;
  p.targetDayOffset=m_dayOffset;
  m_dirty = false;
  return p;
}

void CDashboard::SetInitialParams(const DashboardParams &p)
{
   m_p = p;
   m_slCandle = p.slCandle;
   m_btnSLS.ColorBackground(m_slCandle?CLR_BTN_ON:CLR_BTN_OFF);
   
   if(p.timeframe == PERIOD_M1) m_btnTf.Text("M1");
   else if(p.timeframe == PERIOD_M5) m_btnTf.Text("M5");
   else if(p.timeframe == PERIOD_M15) m_btnTf.Text("M15");
   else m_btnTf.Text("M2");

   m_edtSL.Text(IntegerToString(p.slPoints)); 
   m_edtH.Text(IntegerToString(p.nyHour)); m_edtM.Text(IntegerToString(p.nyMinute));
   m_edtS.Text(IntegerToString(p.nySecond)); m_utcOff=p.utcOffset;
   m_edtBef.Text(IntegerToString(p.triggerBeforeSec));
   m_edtTP.Text(IntegerToString(p.tpPoints));
   m_slCandle=p.slCandle; m_btnSLS.Text(m_slCandle?"SL by Candle✓":"SL by Candle"); m_btnSLS.ColorBackground(m_slCandle?CLR_BTN_ON:CLR_BTN_OFF);
   m_edtRisk.Text(DoubleToString(p.riskPercent,1));
   m_om=p.orderMode; UpdMode(); m_cs=p.candleSource; UpdCandleSrc();
   m_tm=p.trailMode; UpdTrail();
   m_auto=(p.eaMode==EA_AUTO); m_btnAutoTrade.Text(m_auto?"AUTO TRADE: ON":"AUTO TRADE: OFF");
   m_btnAutoTrade.ColorBackground(m_auto?CLR_SUCCESS:CLR_BTN_OFF);
   m_edtTTr.Text(IntegerToString(p.trailTrigger)); m_edtTDi.Text(IntegerToString(p.trailDistance));
   m_edtTSt.Text(IntegerToString(p.trailStep));
   m_edtBEA.Text(IntegerToString(p.beActivatePoints)); m_edtBEL.Text(IntegerToString(p.beLockPoints));
   m_beOn=p.beEnabled; UpdBE();
   m_expEnabled=p.expireEnabled; UpdExpire();
   m_edtExpCandles.Text(IntegerToString(p.expireCandles));
   m_lblSym.Text(p.symbol!=""?p.symbol:Symbol());
   m_edtOrigamiTarget.Text(DoubleToString(p.targetGrowthPercent,1));
   m_origamiSlMode=p.origamiSlMode;
   m_btnOrigamiSlMode.Text(OrigamiSlModeToString(m_origamiSlMode));
   color slClr=CLR_BTN_OFF;
   if(m_origamiSlMode==ORIGAMI_SL_ALWAYS_ORIG) slClr=CLR_WARNING;
   else if(m_origamiSlMode==ORIGAMI_SL_BE_SPREAD) slClr=CLR_SUCCESS;
   m_btnOrigamiSlMode.ColorBackground(slClr);
   m_origamiEnabled=p.origamiEnabled;
   m_edtOrigamiMaxRisk.Text(DoubleToString(p.origamiMaxRiskPercent,1));
   m_btnOrigamiOnOff.Text(m_origamiEnabled?"ON":"OFF");
   m_btnOrigamiOnOff.ColorBackground(m_origamiEnabled?CLR_SUCCESS:CLR_BTN_OFF); }

// ── UPDATERS ──
void CDashboard::UpdateSpread(int s) { m_lblSpdVal.Text("Spread: "+IntegerToString(s)); }
void CDashboard::UpdateCountdown(string s) { m_lblCdVal.Text(s); }
void CDashboard::UpdateStatus(string s) { m_lblStVal.Text(s); m_lblO_StVal.Text(s); }
void CDashboard::UpdateOrderStatus(string s) { m_lblOsVal.Text(s); m_lblO_OsVal.Text(s); }
void CDashboard::UpdateNYClock(string t, string ap, string d) { m_lblClkVal.Text(t); m_lblClkAmPm.Text(ap); m_lblClkDate.Text(d); }

// ── DIRECT CLICK HANDLER — bypasses CAppDialog event routing ──
bool CDashboard::HandleDirectClick(const string &objName)
{
   // v0.89: HandleDirectClick is now the SINGLE source of truth via Native Object Clicks.
   // The 500ms debounce prevents phantom double-clicks (hardware bounce)
   uint now = GetTickCount();
   if(objName == m_lastClickName && (now - m_lastClickMs) < 500)
      return true;
   
   // Reset toggle state immediately
   ObjectSetInteger(m_chart_id, objName, OBJPROP_STATE, false);
   m_lastClickMs = now;
   m_lastClickName = objName;
   if(objName == m_btnAutoTrade.Name())     { OnAutoT(); return true; }
   if(objName == m_btnNyoOnly.Name())       { OnNyoOnly(); return true; }
   if(objName == m_btnAutoApply.Name())     { OnAutoApply(); return true; }
   if(objName == m_btnApplyNext.Name())     { OnApplyNextClick(); return true; }
   if(objName == m_btnDayPicker.Name())     { OnDayPicker(); return true; }
   if(objName == m_btnSLS.Name())           { OnSLS(); return true; }
   if(objName == m_btnBoth.Name())          { OnBoth(); return true; }
   if(objName == m_btnBuy.Name())           { OnBuyO(); return true; }
   if(objName == m_btnSell.Name())          { OnSellO(); return true; }
   if(objName == m_btnCandleSrc.Name())     { OnCandleSrc(); return true; }
   if(objName == m_btnTrMode.Name())        { OnTrM(); return true; }
   if(objName == m_btnApplyTrail.Name())    { OnApplyTrail(); return true; }
   if(objName == m_btnBE.Name())            { OnBEToggle(); return true; }
   if(objName == m_btnApplyBE.Name())       { OnApplyBE(); return true; }
   if(objName == m_btnExpire.Name())        { OnExpire(); return true; }
   if(objName == m_btnA1.Name()) { OnA1(); return true; }
   if(objName == m_btnA2.Name()) { OnA2(); return true; }
   if(objName == m_btnA3.Name()) { OnA3(); return true; }
   if(objName == m_btnFlatten.Name())       { OnFlatA(); return true; }
   if(objName == m_btnPlaceStop.Name())     { OnManP(); return true; }
   if(objName == m_btnCancelPend.Name())    { OnCanA(); return true; }
   if(objName == m_btnBuyMkt.Name())        { OnBuyMkt(); return true; }
   if(objName == m_btnSellMkt.Name())       { OnSellMkt(); return true; }
   if(objName == m_btnLock.Name())          { OnLock(); return true; }
   if(objName == m_btnReverse.Name())       { OnReverse(); return true; }
   if(objName == m_btnTabMain.Name())       { OnTabMain(); return true; }
   if(objName == m_btnTabOrigami.Name())    { OnTabOrigami(); return true; }
   if(objName == m_btnOrigamiSlMode.Name()) { OnOrigamiSlMode(); return true; }
   if(objName == m_btnOrigamiOnOff.Name())  { OnOrigamiOnOff(); return true; }
   if(objName == m_btnOrigamiApplyNow.Name())    { OnOrigamiApplyNow(); return true; }
   if(objName == m_btnOrigamiClear.Name())       { OnOrigamiClear(); return true; }
   if(objName == m_btnOrigamiOnOffMain.Name())   { OnOrigamiOnOffMain(); return true; }
   else if(objName == m_btnTf.Name())
   {
      string tf = m_btnTf.Text();
      if(tf == "M1") m_btnTf.Text("M2");
      else if(tf == "M2") m_btnTf.Text("M5");
      else if(tf == "M5") m_btnTf.Text("M15");
      else m_btnTf.Text("M1");
      m_dirty = true;
      m_btnTf.Pressed(false);
      return true;
   }
   else if(objName == m_btnOrigamiApplyNowMain.Name() || objName == m_btnOrigamiApplyNow.Name())
   { OnOrigamiApplyNowMain(); return true; }
   if(objName == m_btnOrigamiClearMain.Name())   { OnOrigamiClearMain(); return true; }
   return false;
}


void CDashboard::UpdateBalanceInfo(double b,double r,double rw,double l)
{ m_lblBalVal.Text("$"+FormatMoneyRound(b)); m_lblRAVal.Text("-$"+FormatMoneyRound(r));
  m_lblRwVal.Text("+$"+FormatMoneyRound(rw)); m_lblLtVal.Text(DoubleToString(l,2)); }
void CDashboard::UpdateNews(string s) { m_lblNewsVal.Text(s); }
void CDashboard::UpdateSymbol(string sym) { m_lblSym.Text(sym); MarkDirty(); }
void CDashboard::UpdateMarketStatus(bool o)
{ m_lblMktStatus.Text(o?"Market Open":"Market Closed"); m_lblMktStatus.Color(o?CLR_MKT_OPEN:CLR_MKT_CLOSED); }
void CDashboard::ApplyTimingFromNews(int h,int m,int s)
{ m_edtH.Text(IntegerToString(h)); m_edtM.Text(IntegerToString(m)); m_edtS.Text(IntegerToString(s)); MarkDirty(); }
void CDashboard::ApplyPreset(const PresetParams &pr)
{ m_edtSL.Text(IntegerToString(pr.sl)); m_edtTP.Text(IntegerToString(pr.tp));
  m_edtRisk.Text(DoubleToString(pr.risk,1));
  m_edtTTr.Text(IntegerToString(pr.trailTrigger)); m_edtTDi.Text(IntegerToString(pr.trailDist));
  m_edtTSt.Text(IntegerToString(pr.trailStep)); 
  if(pr.tf == PERIOD_M1) m_btnTf.Text("M1");
  else if(pr.tf == PERIOD_M5) m_btnTf.Text("M5");
  else if(pr.tf == PERIOD_M15) m_btnTf.Text("M15");
  else m_btnTf.Text("M2");
  MarkDirty(); }
string CDashboard::FormatMoneyRound(double value)
{
   long val = (long)MathFloor(value + 0.5);
   string s = IntegerToString(MathAbs(val));
   string out = "";
   int len = StringLen(s);
   for(int i = 0; i < len; i++)
   {
      if(i > 0 && (len - i) % 3 == 0) out += ",";
      out += StringSubstr(s, i, 1);
   }
   return out;
}

void CDashboard::UpdateEquityPL(double equity, double profit) 
{ 
   m_lblStatEquity.Text(StringFormat("$%s", FormatMoneyRound(equity)));
   m_lblO_StatEquity.Text(m_lblStatEquity.Text());
   string sign = (profit >= 0) ? "+" : "-";
   m_lblStatPL.Text(StringFormat("%s$%s", sign, FormatMoneyRound(MathAbs(profit))));
   m_lblO_StatPL.Text(m_lblStatPL.Text());
   m_lblStatPL.Color((profit > 0) ? CLR_SUCCESS : ((profit < 0) ? CLR_NEWS_RED : CLR_TEXT_DIM));
   m_lblO_StatPL.Color(m_lblStatPL.Color());
}
void CDashboard::UpdateTotalExposed(double lots, int type)
{
   m_lblTotExpVal.Text(DoubleToString(lots, 2));
   m_lblO_TotExpVal.Text(m_lblTotExpVal.Text());
   if(type == 0) m_lblTotExpVal.Color(CLR_BUY);
   else if(type == 1) m_lblTotExpVal.Color(CLR_SELL);
   else m_lblTotExpVal.Color(CLR_TEXT_DIM);
   m_lblO_TotExpVal.Color(m_lblTotExpVal.Color());
}
void CDashboard::UpdateRealtimeRR(double profit, double loss, double theoreticalRisk)
{
   m_lblRtRrLoss.Text(StringFormat("-$%s", FormatMoneyRound(loss)));
   m_lblO_RtRrLoss.Text(m_lblRtRrLoss.Text());
   m_lblRtRrPft.Text(StringFormat("+$%s", FormatMoneyRound(profit)));
   m_lblO_RtRrPft.Text(m_lblRtRrPft.Text());
   // Visual warning: actual risk exceeds theoretical — loss turns orange
   if(loss > 0 && theoreticalRisk > 0 && loss > theoreticalRisk * 1.2)
      m_lblRtRrLoss.Color(CLR_WARNING);
   else
      m_lblRtRrLoss.Color(CLR_MONEY_RED);
   m_lblO_RtRrLoss.Color(m_lblRtRrLoss.Color());
}
void CDashboard::UpdateRealtimeRiskPercent(double riskPc, double maxRiskPc)
{
   m_lblRtRrRiskPc.Text(StringFormat("{%.1f%%}", riskPc));
   m_lblO_RtRrRiskPc.Text(m_lblRtRrRiskPc.Text());
   if(riskPc > maxRiskPc + 0.01) m_lblRtRrRiskPc.Color(CLR_MONEY_RED);
   else if(MathAbs(riskPc - maxRiskPc) <= 0.01) m_lblRtRrRiskPc.Color(CLR_WARNING);
   else m_lblRtRrRiskPc.Color(CLR_ACCENT);
   m_lblO_RtRrRiskPc.Color(m_lblRtRrRiskPc.Color());
}

// ── HANDLERS ── (v2.0: all handlers call MarkDirty + PushCmd)
void CDashboard::OnSLS() { m_btnSLS.Pressed(false); m_slCandle=!m_slCandle; m_btnSLS.Text(m_slCandle?"SL by Candle✓":"SL by Candle");
   m_btnSLS.ColorBackground(m_slCandle?CLR_BTN_ON:CLR_BTN_OFF); MarkDirty(); }
void CDashboard::OnBoth() { m_btnBoth.Pressed(false); m_om=MODE_BOTH; UpdMode(); MarkDirty(); }
void CDashboard::OnBuyO() { m_btnBuy.Pressed(false); m_om=MODE_BUY_ONLY; UpdMode(); MarkDirty(); }
void CDashboard::OnSellO(){ m_btnSell.Pressed(false); m_om=MODE_SELL_ONLY; UpdMode(); MarkDirty(); }
void CDashboard::UpdMode(){ m_btnBoth.ColorBackground(m_om==MODE_BOTH?CLR_BTN_ON:CLR_BTN_OFF);
   m_btnBuy.ColorBackground(m_om==MODE_BUY_ONLY?CLR_BUY:CLR_BTN_OFF);
   m_btnSell.ColorBackground(m_om==MODE_SELL_ONLY?CLR_SELL:CLR_BTN_OFF); }
void CDashboard::OnCandleSrc() { m_btnCandleSrc.Pressed(false); m_cs=(m_cs==CANDLE_CURRENT)?CANDLE_PREVIOUS:CANDLE_CURRENT; UpdCandleSrc(); MarkDirty(); }
void CDashboard::UpdCandleSrc() { m_btnCandleSrc.Text(m_cs==CANDLE_CURRENT?"CURRENT":"PREVIOUS");
   m_btnCandleSrc.ColorBackground(m_cs==CANDLE_CURRENT?CLR_SUCCESS:CLR_ACCENT); }
void CDashboard::OnTrM() {
   m_btnTrMode.Pressed(false);
   switch(m_tm){case TM_OFF:m_tm=TM_CHASE;break;case TM_CHASE:m_tm=TM_CANDLE_1;break;
   case TM_CANDLE_1:m_tm=TM_CANDLE_2;break;case TM_CANDLE_2:m_tm=TM_CANDLE_3;break;
   case TM_CANDLE_3:m_tm=TM_OFF;break;} UpdTrail(); MarkDirty(); }
void CDashboard::UpdTrail() { string t="OFF"; color c=CLR_BTN_OFF;
   switch(m_tm){case TM_OFF:t="OFF";c=CLR_BTN_OFF;break;case TM_CHASE:t="CHASE";c=CLR_WARNING;break;
   case TM_CANDLE_1:t="TRAIL CANDLE[1]";c=CLR_ACCENT;break;case TM_CANDLE_2:t="TRAIL CANDLE[2]";c=CLR_SUCCESS;break;
   case TM_CANDLE_3:t="TRAIL CANDLE[3]";c=CLR_LOCK;break;}
   m_btnTrMode.Text(t); m_btnTrMode.ColorBackground(c); }
void CDashboard::OnBEToggle() { m_btnBE.Pressed(false); m_beOn=!m_beOn; UpdBE(); MarkDirty(); }
void CDashboard::UpdBE() { m_btnBE.Text(m_beOn?"BE: ON":"BE: OFF");
   m_btnBE.ColorBackground(m_beOn?CLR_SUCCESS:CLR_BTN_OFF); }
void CDashboard::OnApplyBE() { m_btnApplyBE.Pressed(false); PushCmd(CMD_APPLY_BE); }
void CDashboard::OnApplyTrail() { m_btnApplyTrail.Pressed(false); PushCmd(CMD_APPLY_TRAIL); }
void CDashboard::OnExpire() { m_btnExpire.Pressed(false); m_expEnabled=!m_expEnabled; UpdExpire(); MarkDirty(); }
void CDashboard::UpdExpire() { m_btnExpire.Text(m_expEnabled?"auto cancel all: ON":"auto cancel all: OFF");
   m_btnExpire.ColorBackground(m_expEnabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnAutoT() { m_btnAutoTrade.Pressed(false); m_auto=!m_auto; m_btnAutoTrade.Text(m_auto?"AUTO TRADE: ON":"AUTO TRADE: OFF");
   m_btnAutoTrade.ColorBackground(m_auto?CLR_SUCCESS:CLR_BTN_OFF); MarkDirty(); }
void CDashboard::OnManP()  { m_btnPlaceStop.Pressed(false); PushCmd(CMD_MANUAL_PLACE); }
void CDashboard::OnCanA()  { m_btnCancelPend.Pressed(false); PushCmd(CMD_CANCEL_ALL); }
void CDashboard::OnFlatA() { m_btnFlatten.Pressed(false); PushCmd(CMD_FLATTEN_ALL); }
void CDashboard::OnBrkEv() { PushCmd(CMD_BREAK_EVEN); }
void CDashboard::OnA1(){ m_btnA1.Pressed(false); PresetIndex=0; PushCmd(CMD_PRESET); }
void CDashboard::OnA2(){ m_btnA2.Pressed(false); PresetIndex=1; PushCmd(CMD_PRESET); }
void CDashboard::OnA3(){ m_btnA3.Pressed(false); PresetIndex=2; PushCmd(CMD_PRESET); }
void CDashboard::OnNyoOnly() { m_btnNyoOnly.Pressed(false); m_nyoOnly=!m_nyoOnly; NYOOnlyMode=m_nyoOnly;
   m_btnNyoOnly.Text(m_nyoOnly?"NYO ONLY: ON":"NYO ONLY: OFF");
   m_btnNyoOnly.ColorBackground(m_nyoOnly?CLR_SUCCESS:CLR_BTN_OFF); }
void CDashboard::OnAutoApply() { m_btnAutoApply.Pressed(false); m_autoNews=!m_autoNews; AutoNewsEnabled=m_autoNews;
   m_btnAutoApply.Text(m_autoNews?"AUTO APPLY: ON":"AUTO APPLY: OFF");
   m_btnAutoApply.ColorBackground(m_autoNews?CLR_SUCCESS:CLR_BTN_OFF); MarkDirty(); }
void CDashboard::OnApplyNextClick() { m_btnApplyNext.Pressed(false); PushCmd(CMD_APPLY_NEXT); }
void CDashboard::OnBuyMkt()  { m_btnBuyMkt.Pressed(false); PushCmd(CMD_BUY_MKT); }
void CDashboard::OnSellMkt() { m_btnSellMkt.Pressed(false); PushCmd(CMD_SELL_MKT); }
void CDashboard::OnLock()    { m_btnLock.Pressed(false); PushCmd(CMD_LOCK); }
void CDashboard::OnReverse() { m_btnReverse.Pressed(false); PushCmd(CMD_REVERSE); }

// ── TAB SWITCHING ──
void CDashboard::OnTabMain() { m_btnTabMain.Pressed(false); ShowTab(0); }
void CDashboard::OnTabOrigami()  { m_btnTabOrigami.Pressed(false); ShowTab(1); }

void CDashboard::ShowTab(int tab)
{
   m_activeTab = tab;
   m_btnTabMain.ColorBackground(tab==0 ? CLR_ACCENT : CLR_BTN_OFF);
   m_btnTabOrigami.ColorBackground(tab==1 ? CLR_ACCENT : CLR_BTN_OFF);
   
   if(tab == 0)
   {
      // Show Main controls
      CtrlShow(m_lblVer); CtrlShow(m_lblSym); CtrlShow(m_lblMktStatus); CtrlShow(m_lblSpdVal);
      CtrlShow(m_lblClkTag); CtrlShow(m_lblClkVal); CtrlShow(m_lblClkAmPm); CtrlShow(m_lblClkDate); CtrlShow(m_lblCdTag); CtrlShow(m_lblCdVal);
      CtrlShow(m_lblNewsTag); CtrlShow(m_lblNewsVal);
      CtrlShowBtn(m_btnAutoTrade); CtrlShowBtn(m_btnNyoOnly); CtrlShowBtn(m_btnAutoApply); CtrlShowBtn(m_btnApplyNext);
      CtrlShow(m_lblSchTag); CtrlShowEdit(m_edtH); CtrlShow(m_lblC1); CtrlShowEdit(m_edtM); CtrlShow(m_lblC2); CtrlShowEdit(m_edtS);
      CtrlShow(m_lblBefTag); CtrlShowEdit(m_edtBef); CtrlShow(m_lblBefSec);
      CtrlShow(m_lblTfTag); CtrlShowBtn(m_btnTf);
      CtrlShow(m_lblSlTag); CtrlShowEdit(m_edtSL); CtrlShowEdit(m_edtTP); CtrlShowBtn(m_btnSLS);
      CtrlShow(m_lblMdTag); CtrlShowBtn(m_btnBoth); CtrlShowBtn(m_btnBuy); CtrlShowBtn(m_btnSell);
      CtrlShow(m_lblCsTag); CtrlShowBtn(m_btnCandleSrc);
      CtrlShow(m_lblBalTag); CtrlShow(m_lblBalVal); CtrlShow(m_lblRskTag); CtrlShowEdit(m_edtRisk); CtrlShow(m_lblRPc);
      CtrlShow(m_lblRATag); CtrlShow(m_lblRAVal); CtrlShow(m_lblRwVal); CtrlShow(m_lblLtTag); CtrlShow(m_lblLtVal);
      CtrlShow(m_lblTrTag); CtrlShowBtn(m_btnTrMode);
      CtrlShow(m_lblTrTrig); CtrlShowEdit(m_edtTTr); CtrlShow(m_lblTrDist); CtrlShowEdit(m_edtTDi); CtrlShow(m_lblTrStep); CtrlShowEdit(m_edtTSt);
      CtrlShowBtn(m_btnApplyTrail); CtrlShowBtn(m_btnBE); CtrlShowBtn(m_btnApplyBE);
      CtrlShow(m_lblBeLine); CtrlShowEdit(m_edtBEA); CtrlShow(m_lblBELock); CtrlShowEdit(m_edtBEL);
      CtrlShowBtn(m_btnExpire); CtrlShowEdit(m_edtExpCandles);
      CtrlShowBtn(m_btnA1); CtrlShowBtn(m_btnA2); CtrlShowBtn(m_btnA3); 
      CtrlShowBtn(m_btnFlatten); CtrlShowBtn(m_btnPlaceStop); CtrlShowBtn(m_btnCancelPend);
      CtrlShowBtn(m_btnBuyMkt); CtrlShowBtn(m_btnSellMkt); CtrlShowBtn(m_btnLock); CtrlShowBtn(m_btnReverse);
      CtrlShow(m_lblOsTag); CtrlShow(m_lblOsVal); CtrlShow(m_lblStVal);
      CtrlShow(m_lblEqTag); CtrlShow(m_lblStatEquity); CtrlShow(m_lblPlTag); CtrlShow(m_lblStatPL);
      CtrlShow(m_lblTotExpTag); CtrlShow(m_lblTotExpVal); CtrlShow(m_lblRtRrTag); CtrlShow(m_lblRtRrLoss); CtrlShow(m_lblRtRrPft); CtrlShow(m_lblRtRrRiskPc);
      CtrlShowBtn(m_btnDayPicker);
      CtrlShow(m_lblOrigamiStatusMain); CtrlShowBtn(m_btnOrigamiApplyNowMain); CtrlShowBtn(m_btnOrigamiClearMain); CtrlShowBtn(m_btnOrigamiOnOffMain);
      CtrlShow(m_lblDiadStatusMain);
      CtrlShow(m_lblOrigamiMaxRiskTag); CtrlShowEdit(m_edtOrigamiMaxRisk); CtrlShow(m_lblOrigamiMaxRiskPc);
      // Hide Origami controls
      CtrlHide(m_lblOrigamiTitle); CtrlHide(m_lblOrigamiTarget); CtrlHide(m_edtOrigamiTarget); CtrlHide(m_lblOrigamiPct);
      CtrlHide(m_lblOrigamiSlMode); CtrlHide(m_btnOrigamiSlMode);
      CtrlHide(m_lblOrigamiAdd1); CtrlHide(m_edtOrigamiAdd1);
      CtrlHide(m_lblOrigamiAdd2); CtrlHide(m_edtOrigamiAdd2);
      CtrlHide(m_lblOrigamiAdd3); CtrlHide(m_edtOrigamiAdd3);
      CtrlHide(m_lblOrigamiInfo1); CtrlHide(m_lblOrigamiInfo2); CtrlHide(m_lblOrigamiInfo3); CtrlHide(m_lblOrigamiInfo4);
      CtrlHide(m_lblOrigamiStatus); CtrlHide(m_lblDiadStatus);
      CtrlHide(m_btnOrigamiOnOff); CtrlHide(m_lblOrigamiTargetAmt); CtrlHide(m_btnOrigamiApplyNow); CtrlHide(m_btnOrigamiClear);
      CtrlHide(m_lblO_OsTag); CtrlHide(m_lblO_OsVal); CtrlHide(m_lblO_StVal);
      CtrlHide(m_lblO_OsTag); CtrlHide(m_lblO_OsVal); CtrlHide(m_lblO_StVal);
      CtrlHide(m_lblO_EqTag); CtrlHide(m_lblO_StatEquity); CtrlHide(m_lblO_PlTag); CtrlHide(m_lblO_StatPL);
      CtrlHide(m_lblO_TotExpTag); CtrlHide(m_lblO_TotExpVal); CtrlHide(m_lblO_RtRrTag); CtrlHide(m_lblO_RtRrLoss); CtrlHide(m_lblO_RtRrPft); CtrlHide(m_lblO_RtRrRiskPc);
   }
   else
   {
      // Hide Main controls
      CtrlHide(m_lblVer); CtrlHide(m_lblSym); CtrlHide(m_lblMktStatus); CtrlHide(m_lblSpdVal);
      CtrlHide(m_lblClkTag); CtrlHide(m_lblClkVal); CtrlHide(m_lblClkAmPm); CtrlHide(m_lblClkDate); CtrlHide(m_lblCdTag); CtrlHide(m_lblCdVal);
      CtrlHide(m_lblNewsTag); CtrlHide(m_lblNewsVal);
      CtrlHide(m_btnAutoTrade); CtrlHide(m_btnNyoOnly); CtrlHide(m_btnAutoApply); CtrlHide(m_btnApplyNext);
      CtrlHide(m_lblSchTag); CtrlHide(m_edtH); CtrlHide(m_lblC1); CtrlHide(m_edtM); CtrlHide(m_lblC2); CtrlHide(m_edtS);
      CtrlHide(m_lblBefTag); CtrlHide(m_edtBef); CtrlHide(m_lblBefSec);
      CtrlHide(m_lblTfTag); CtrlHide(m_btnTf);
      CtrlHide(m_lblSlTag); CtrlHide(m_edtSL); CtrlHide(m_edtTP); CtrlHide(m_btnSLS);
      CtrlHide(m_lblMdTag); CtrlHide(m_btnBoth); CtrlHide(m_btnBuy); CtrlHide(m_btnSell);
      CtrlHide(m_lblCsTag); CtrlHide(m_btnCandleSrc);
      CtrlHide(m_lblBalTag); CtrlHide(m_lblBalVal); CtrlHide(m_lblRskTag); CtrlHide(m_edtRisk); CtrlHide(m_lblRPc);
      CtrlHide(m_lblRATag); CtrlHide(m_lblRAVal); CtrlHide(m_lblRwVal); CtrlHide(m_lblLtTag); CtrlHide(m_lblLtVal);
      CtrlHide(m_lblTrTag); CtrlHide(m_btnTrMode);
      CtrlHide(m_lblTrTrig); CtrlHide(m_edtTTr); CtrlHide(m_lblTrDist); CtrlHide(m_edtTDi); CtrlHide(m_lblTrStep); CtrlHide(m_edtTSt);
      CtrlHide(m_btnApplyTrail); CtrlHide(m_btnBE); CtrlHide(m_btnApplyBE);
      CtrlHide(m_lblBeLine); CtrlHide(m_edtBEA); CtrlHide(m_lblBELock); CtrlHide(m_edtBEL);
      CtrlHide(m_btnExpire); CtrlHide(m_edtExpCandles);
      CtrlHide(m_btnA1); CtrlHide(m_btnA2); CtrlHide(m_btnA3); 
      CtrlHide(m_btnFlatten); CtrlHide(m_btnPlaceStop); CtrlHide(m_btnCancelPend);
      CtrlHide(m_btnBuyMkt); CtrlHide(m_btnSellMkt); CtrlHide(m_btnLock); CtrlHide(m_btnReverse);
      CtrlHide(m_lblOsTag); CtrlHide(m_lblOsVal); CtrlHide(m_lblStVal);
      CtrlHide(m_lblEqTag); CtrlHide(m_lblStatEquity); CtrlHide(m_lblPlTag); CtrlHide(m_lblStatPL);
      CtrlHide(m_lblTotExpTag); CtrlHide(m_lblTotExpVal); CtrlHide(m_lblRtRrTag); CtrlHide(m_lblRtRrLoss); CtrlHide(m_lblRtRrPft); CtrlHide(m_lblRtRrRiskPc);
      CtrlHide(m_btnDayPicker);
      CtrlHide(m_lblOrigamiStatusMain); CtrlHide(m_btnOrigamiApplyNowMain); CtrlHide(m_btnOrigamiClearMain); CtrlHide(m_btnOrigamiOnOffMain);
      CtrlHide(m_lblDiadStatusMain);
      CtrlHide(m_lblOrigamiMaxRiskTag); CtrlHide(m_edtOrigamiMaxRisk); CtrlHide(m_lblOrigamiMaxRiskPc);
      // Show Origami controls
      CtrlShow(m_lblOrigamiTitle); CtrlShow(m_lblOrigamiTarget); CtrlShowEdit(m_edtOrigamiTarget); CtrlShow(m_lblOrigamiPct);
      CtrlHide(m_lblOrigamiSlMode); CtrlHide(m_btnOrigamiSlMode); // v1.51: SL mode removed
      CtrlShow(m_lblOrigamiAdd1); CtrlShowEdit(m_edtOrigamiAdd1);
      CtrlShow(m_lblOrigamiAdd2); CtrlShowEdit(m_edtOrigamiAdd2);
      CtrlShow(m_lblOrigamiAdd3); CtrlShowEdit(m_edtOrigamiAdd3);
      CtrlShow(m_lblOrigamiInfo1); CtrlShow(m_lblOrigamiInfo2); CtrlShow(m_lblOrigamiInfo3); CtrlShow(m_lblOrigamiInfo4);
      CtrlShow(m_lblOrigamiStatus); CtrlShow(m_lblDiadStatus);
      CtrlShowBtn(m_btnOrigamiOnOff); CtrlShow(m_lblOrigamiTargetAmt); CtrlShowBtn(m_btnOrigamiApplyNow); CtrlShowBtn(m_btnOrigamiClear);
      CtrlShow(m_lblO_OsTag); CtrlShow(m_lblO_OsVal); CtrlShow(m_lblO_StVal);
      CtrlShow(m_lblO_EqTag); CtrlShow(m_lblO_StatEquity); CtrlShow(m_lblO_PlTag); CtrlShow(m_lblO_StatPL);
      CtrlShow(m_lblO_TotExpTag); CtrlShow(m_lblO_TotExpVal); CtrlShow(m_lblO_RtRrTag); CtrlShow(m_lblO_RtRrLoss); CtrlShow(m_lblO_RtRrPft); CtrlShow(m_lblO_RtRrRiskPc);
   }
   // Separators: 0-11 main, 12+ origami
   for(int i=0; i<20; i++)
   {
      if(i < 12) { if(tab==0) m_sep[i].Show(); else m_sep[i].Hide(); }
      else { if(tab==1) m_sep[i].Show(); else m_sep[i].Hide(); }
   }
   ChartRedraw();
}

void CDashboard::OnOrigamiSlMode()
{
   m_btnOrigamiSlMode.Pressed(false);
   switch(m_origamiSlMode)
   {
      case ORIGAMI_SL_DONT_MOVE:   m_origamiSlMode=ORIGAMI_SL_ALWAYS_ORIG; break;
      case ORIGAMI_SL_ALWAYS_ORIG: m_origamiSlMode=ORIGAMI_SL_BE_SPREAD;   break;
      case ORIGAMI_SL_BE_SPREAD:   m_origamiSlMode=ORIGAMI_SL_DONT_MOVE;   break;
   }
   m_btnOrigamiSlMode.Text(OrigamiSlModeToString(m_origamiSlMode));
   color slClr=CLR_BTN_OFF;
   if(m_origamiSlMode==ORIGAMI_SL_ALWAYS_ORIG) slClr=CLR_WARNING;
   else if(m_origamiSlMode==ORIGAMI_SL_BE_SPREAD) slClr=CLR_SUCCESS;
   m_btnOrigamiSlMode.ColorBackground(slClr);
   MarkDirty();
}

void CDashboard::OnOrigamiOnOff()
{
   m_btnOrigamiOnOff.Pressed(false);
   m_origamiEnabled=!m_origamiEnabled;
   m_btnOrigamiOnOff.Text(m_origamiEnabled?"ON":"OFF");
   m_btnOrigamiOnOff.ColorBackground(m_origamiEnabled?CLR_SUCCESS:CLR_BTN_OFF);
   m_btnOrigamiOnOffMain.Text(m_origamiEnabled?"ON":"OFF");
   m_btnOrigamiOnOffMain.ColorBackground(m_origamiEnabled?CLR_SUCCESS:CLR_BTN_OFF);
   m_lblOrigamiStatus.Text(m_origamiEnabled?"Origami: ON":"Origami: OFF");
   m_lblOrigamiStatus.Color(m_origamiEnabled?CLR_SUCCESS:CLR_WARNING);
   m_lblOrigamiStatusMain.Text(m_origamiEnabled?"Origami: ON":"Origami: OFF");
   m_lblOrigamiStatusMain.Color(m_origamiEnabled?CLR_SUCCESS:CLR_WARNING);
   MarkDirty();
}

void CDashboard::OnOrigamiOnOffMain()
{
   m_btnOrigamiOnOffMain.Pressed(false);
   OnOrigamiOnOff();
}

void CDashboard::OnOrigamiApplyNow()
{
   m_btnOrigamiApplyNow.Pressed(false);
   if(!m_origamiEnabled) {
      OnOrigamiOnOff();
   }
   PushCmd(CMD_ORIGAMI_APPLY_NOW);
}

void CDashboard::OnOrigamiApplyNowMain()
{
   m_btnOrigamiApplyNowMain.Pressed(false);
   OnOrigamiApplyNow();
}

void CDashboard::OnOrigamiClear()
{
   m_btnOrigamiClear.Pressed(false);
   PushCmd(CMD_ORIGAMI_CLEAR);
}

void CDashboard::OnOrigamiClearMain()
{
   m_btnOrigamiClearMain.Pressed(false);
   OnOrigamiClear();
}

void CDashboard::OnDayPicker()
{
   m_btnDayPicker.Pressed(false);
   m_dayOffset = (m_dayOffset + 1) % 7;
   if(m_dayOffset == 0)
   {
      m_btnDayPicker.Text("TODAY");
      m_btnDayPicker.ColorBackground(CLR_BTN_OFF);
   }
   else
   {
      // Calculate future date's day name
      datetime gmtTime = TimeGMT();
      datetime futureTime = gmtTime + m_dayOffset * 86400;
      MqlDateTime dt;
      TimeToStruct(futureTime, dt);
      string dNames[] = {"SUN","MON","TUE","WED","THU","FRI","SAT"};
      string months[] = {"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
      string dayName = (dt.day_of_week >= 0 && dt.day_of_week <= 6) ? dNames[dt.day_of_week] : "?";
      string mon = (dt.mon >= 1 && dt.mon <= 12) ? months[dt.mon] : "?";
      m_btnDayPicker.Text(StringFormat("%s, %02d %s", dayName, dt.day, mon));
      m_btnDayPicker.ColorBackground(CLR_ACCENT);
   }
   MarkDirty();
}

void CDashboard::UpdateOrigamiInfo(string s1, string s2, string s3, string s4)
{
   m_lblOrigamiInfo1.Text(s1);
   m_lblOrigamiInfo2.Text(s2);
   m_lblOrigamiInfo3.Text(s3);
   m_lblOrigamiInfo4.Text(s4);
}

void CDashboard::UpdateOrigamiStatus(string s)
{
   m_lblOrigamiStatus.Text(s);
   m_lblOrigamiStatusMain.Text(s);
   if(StringFind(s, "ACTIVE") >= 0 || StringFind(s, "ON") >= 0) {
      m_lblOrigamiStatus.Color(CLR_SUCCESS);
      m_lblOrigamiStatusMain.Color(CLR_SUCCESS);
   } else {
      m_lblOrigamiStatus.Color(CLR_WARNING);
      m_lblOrigamiStatusMain.Color(CLR_WARNING);
   }
}

void CDashboard::UpdateDiadStatus(string s)
{
   m_lblDiadStatus.Text(s);
   m_lblDiadStatus.Color(C'255,220,100');
   m_lblDiadStatusMain.Text(s);
   m_lblDiadStatusMain.Color(C'255,220,100');
}

#endif
