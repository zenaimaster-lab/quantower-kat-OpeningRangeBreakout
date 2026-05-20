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
   CEdit m_lblClkTag, m_lblClkVal, m_lblClkAmPm, m_lblClkDate;
   CEdit m_lblNewsTag, m_lblNewsVal;
   CEdit m_lblTimerTag, m_lblTimerVal;
   CEdit m_lblSlTag, m_lblMdTag;
   
    CButton m_btnToggleM2, m_btnToggleM5, m_btnToggleM15;
    CButton m_btnTabOrder, m_btnTabEntry, m_btnTabFlatten, m_btnTabStats;
   CEdit  m_edtSL, m_edtTP;
   CButton m_btnSLS, m_btnBoth, m_btnBuy, m_btnSell;
   CEdit m_lblBalTag, m_lblBalVal;
   CButton m_btnRiskMode, m_btnFixLot;
   CEdit m_edtRisk, m_edtFixLot;
   CEdit m_lblRATag, m_lblRAVal, m_lblRwVal, m_lblLtTag, m_lblLtVal;
   CEdit m_lblTrTag, m_lblTrLine, m_lblBeLine;
   CEdit m_lblTrTrig, m_lblTrDist, m_lblTrStep;
   CEdit m_edtTTr, m_edtTDi, m_edtTSt;
   CEdit m_lblBELock;
   CEdit m_edtBEA, m_edtBEL;
   CButton m_btnTrMode;
   CButton m_btnBE;
   CEdit m_lblBETag;
   CEdit m_lblExpTag;
   CEdit m_lblUfmTag, m_edtUfmPts;
   CButton m_btnUfm;
   CEdit m_lblTmrTag;
   CButton m_btnTmr;
   CEdit m_lblAucTag, m_edtAuc;
   CButton m_btnAuc;
   CEdit m_lblAfcTag, m_edtAfc;
   CButton m_btnAfc;
   CEdit m_lblAamTag, m_edtAam;
   CButton m_btnAam;
   
   CEdit m_lblEntrySec;
   CEdit m_lblRtcTag, m_edtRtc; CButton m_btnRtc;
   CEdit m_lblContTag; CButton m_btnCont;
   CEdit m_lblMaxSTag, m_edtMaxS; CButton m_btnMaxS;
   CEdit m_lblMaxLTag, m_edtMaxL; CButton m_btnMaxL;
   CEdit m_lblBigMTag; CButton m_btnBigM;
   
   CEdit m_lblEma1Tag, m_edtEma1;
   CButton m_btnEma1;
   CEdit m_lblEma2Tag, m_edtEma2;
   CButton m_btnEma2;
   CEdit m_lblEma3Tag, m_edtEma3;
   CButton m_btnEma3;
   CEdit m_lblMdrTag, m_edtMdr;
   CButton m_btnMdr;
   CEdit m_lblFemTag, m_edtFem1, m_edtFem2, m_edtFem3;
   CButton m_btnFem1, m_btnFem2, m_btnFem3;
   CEdit m_lblEmaPlus1, m_lblEmaPlus2, m_lblFemPlus1, m_lblFemPlus2;

   CEdit m_lblOsTag, m_lblOsVal, m_lblStVal;
   CEdit m_lblEqTag, m_lblPlTag;
   CEdit m_lblStatEquity, m_lblStatPL;
   CEdit m_lblTotExpTag, m_lblTotExpVal;
   CEdit m_lblRtRrTag, m_lblRtRrLoss, m_lblRtRrPft, m_lblRtRrRiskPc;
   
   CEdit m_lblEntryNum[9], m_lblEntryDesc[9];
   CEdit m_lblNetTodayTag, m_lblNetTodayVal, m_lblTodayWl;
   CEdit m_lblNetWeekTag, m_lblNetWeekVal, m_lblWeekWl;
   CEdit m_lblNetMonthTag, m_lblNetMonthVal, m_lblMonthWl;
   
   // Stats tab v2: new sections
   CEdit m_lblOrdersSec;
   CEdit m_lbl2mStTag, m_lbl2mStVal;
   CEdit m_lbl5mStTag, m_lbl5mStVal;
   CEdit m_lblLastEntrySec;
   CEdit m_lblTotalPlSec;
   CEdit m_lbl2mNtTag, m_lbl2mNtVal, m_lbl2mTodayWl;
   CEdit m_lbl2mNwTag, m_lbl2mNwVal, m_lbl2mWeekWl;
   CEdit m_lbl2mNmTag, m_lbl2mNmVal, m_lbl2mMonthWl;
   CEdit m_lbl5mNtTag, m_lbl5mNtVal, m_lbl5mTodayWl;
   CEdit m_lbl5mNwTag, m_lbl5mNwVal, m_lbl5mWeekWl;
   CEdit m_lbl5mNmTag, m_lbl5mNmVal, m_lbl5mMonthWl;
   CEdit m_lbl15mStTag, m_lbl15mStVal;
   CEdit m_lbl15mNtTag, m_lbl15mNtVal, m_lbl15mTodayWl;
   CEdit m_lbl15mNwTag, m_lbl15mNwVal, m_lbl15mWeekWl;
   CEdit m_lbl15mNmTag, m_lbl15mNmVal, m_lbl15mMonthWl;
   
   CPanel m_sep[25];




   void CtrlShow(CWnd &obj);
   void CtrlShowBtn(CWnd &obj);
   void CtrlShowEdit(CWnd &obj);
   void CtrlHide(CWnd &obj);


   SystemConfig m_config;
   ENUM_TAB m_activeTab;
   bool m_slCandle, m_beOn, m_rMode;
   bool m_ufmEnabled, m_tmrEnabled, m_aucEnabled, m_afcEnabled, m_aamEnabled, m_mdrEnabled;
   bool m_ema1Enabled, m_ema2Enabled, m_ema3Enabled;
   bool m_fem1Enabled, m_fem2Enabled, m_fem3Enabled;
   bool m_contAfter1st, m_maxSuccessOn, m_maxLossOn, m_bigMomentum, m_rtcOn;
   int m_statusSepStart, m_statusSepEnd;
   int m_utcOff;
   ENUM_ORDER_MODE m_om;
   ENUM_TRAIL_MODE m_tm;
   bool m_dirty;
   uint m_lastClickMs;                  // v0.75: debounce — last click timestamp
   string m_lastClickName;              // v0.75: debounce — last clicked object
   void MarkDirty() { m_dirty = true; } // v2.0: called by any UI interaction
public:
   CDashboard();
  ~CDashboard() {}
   bool CreatePanel(long chart,string name,int subwin,int x,int y,int w,int h);
   void SetInitialParams(const SystemConfig &cfg);
   SystemConfig GetParams();
   void SaveTab(ENUM_TAB tab);
   void LoadTab(ENUM_TAB tab);
   void UpdateSpread(int s);

   void UpdateStatus(string s);
   void UpdateOrderStatus(string s);
   void UpdateNYClock(string t, string ap, string d);
   void UpdateBalanceInfo(double b,double r,double rw,double l);
   void UpdateNews(string newsStr);
   void UpdateTimer(string timerStr);
   void UpdateMarketStatus(bool isOpen);
   void UpdateSymbol(string sym);
   void UpdateInternalTiming(int h, int m, int s) { m_config.main.nyHour=h; m_config.main.nyMinute=m; m_config.main.nySecond=s; }


   void UpdateEquityPL(double equity, double profit);
   void UpdateTotalExposed(double lots, int type);
   void UpdateRealtimeRR(double profit, double loss, double theoreticalRisk);
   void UpdateRealtimeRiskPercent(double riskPc, double maxRiskPc);
   void UpdateStatsTab(const string &entries[], double netToday, int wToday, int lToday, double netWeek, int wWeek, int lWeek, double netMonth, int wMonth, int lMonth);
   void Update2mStatus(string status, color clr);
   void Update5mStatus(string status, color clr);
   void Update15mStatus(string status, color clr);
   void Update2mPL(double netToday, int wToday, int lToday, double netWeek, int wWeek, int lWeek, double netMonth, int wMonth, int lMonth);
   void Update5mPL(double netToday, int wToday, int lToday, double netWeek, int wWeek, int lWeek, double netMonth, int wMonth, int lMonth);
   void Update15mPL(double netToday, int wToday, int lToday, double netWeek, int wWeek, int lWeek, double netMonth, int wMonth, int lMonth);
   string FormatMoneyRound(double value);
   // v2.0: Command queue API (replaces 13+ boolean flags)
   void MarkDirtyPublic() { MarkDirty(); }
private:
   bool ML(CEdit &l,string n,string t,int x,int y,int w,int h,color c=CLR_TEXT,int fs=FONT_SIZE);
   bool ME(CEdit &e,string n,string t,int x,int y,int w,int h);
   bool MB(CButton &b,string n,string t,int x,int y,int w,int h,color bg=CLR_BTN_OFF);
   void MSep(int idx,int x,int y,int w);
    void OnSLS(); void OnBoth(); void OnBuyO(); void OnSellO(); void OnTrM();
   void OnToggleM2(); void OnToggleM5(); void OnToggleM15();
   void OnTabOrder(); void OnTabEntry(); void OnTabFlatten();
   void OnRiskModeToggle(); void OnLotModeToggle();
   void OnBrkEv();
   void OnBEToggle();
   void OnUfmToggle(); void UpdUfm();
   void OnTmrToggle(); void UpdTmr();
   void OnAucToggle(); void UpdAuc();
   void OnAfcToggle(); void UpdAfc();
   void OnAamToggle(); void UpdAam();
   void OnEma1Toggle(); void UpdEma1();
   void OnEma2Toggle(); void UpdEma2();
   void OnEma3Toggle(); void UpdEma3();
   void OnMdrToggle(); void UpdMdr();
   void OnFem1Toggle(); void UpdFem1();
   void OnFem2Toggle(); void UpdFem2();
   void OnFem3Toggle(); void UpdFem3();
   
   void OnContToggle(); void UpdCont();
   void OnMaxSToggle(); void UpdMaxS();
   void OnMaxLToggle(); void UpdMaxL();
   void OnRtcToggle(); void UpdRtc();
   void OnBigMToggle(); void UpdBigM();
   
   void OnTabStats();


   void UpdMode(); void UpdTrail(); void UpdBE();
   void UpdToggles(); void UpdTabs();

public:
   bool HandleDirectClick(const string &objName);
   
   virtual void Minimize(void);
   virtual void Maximize(void);

};

CDashboard::CDashboard() { m_rMode=true; m_slCandle=false; m_om=MODE_BOTH; m_tm=TM_OFF; m_activeTab=TAB_STATS;
   m_ufmEnabled=true; m_tmrEnabled=true; m_aucEnabled=false; m_afcEnabled=true; m_aamEnabled=true; m_mdrEnabled=true; m_utcOff=-4; m_beOn=false;
   m_ema1Enabled=false; m_ema2Enabled=false; m_ema3Enabled=false;
   m_fem1Enabled=false; m_fem2Enabled=false; m_fem3Enabled=false;
   m_contAfter1st=true; m_maxSuccessOn=true; m_maxLossOn=true; m_bigMomentum=false; m_rtcOn=true;
   m_dirty=true;

   m_lastClickMs=0; m_lastClickName=""; }

bool CDashboard::CreatePanel(long chart,string name,int subwin,int x,int y,int w,int h)
{
   if(!CAppDialog::Create(chart,name,subwin,x,y,x+w,y+h)) return false;
   Caption(EA_NAME);
   
   // Customize caption bar: hide X button, enlarge Minimize button
   for(int i=ObjectsTotal(chart,subwin)-1;i>=0;i--)
   { string n=ObjectName(chart,i,subwin);
     // The CAppDialog creates buttons named "Close" and "Minimize" with suffix
     if(StringFind(n,"Close") >= 0) {
        ObjectSetInteger(chart, n, OBJPROP_XSIZE, 0);
        ObjectSetInteger(chart, n, OBJPROP_YSIZE, 0);
        ObjectSetInteger(chart, n, OBJPROP_XDISTANCE, -100);
        ObjectSetInteger(chart, n, OBJPROP_YDISTANCE, -100);
     }
     if(StringFind(n,"Minimize") >= 0) {
        ObjectSetString(chart, n, OBJPROP_TEXT, "Minimize");
        ObjectSetInteger(chart, n, OBJPROP_XSIZE, 70);
        ObjectSetInteger(chart, n, OBJPROP_FONTSIZE, 8);
     }
   }
   
   int colored=0;
   for(int i=ObjectsTotal(chart,subwin)-1;i>=0;i--)
   { string n=ObjectName(chart,i,subwin); ENUM_OBJECT ot=(ENUM_OBJECT)ObjectGetInteger(chart,n,OBJPROP_TYPE);
     if(ot==OBJ_RECTANGLE_LABEL){ObjectSetInteger(chart,n,OBJPROP_BGCOLOR,CLR_PANEL_BG);ObjectSetInteger(chart,n,OBJPROP_BORDER_COLOR,CLR_PANEL_BG);ObjectSetInteger(chart,n,OBJPROP_ZORDER,-100);colored++;}
     else if(ot==OBJ_EDIT){ObjectSetInteger(chart,n,OBJPROP_BGCOLOR,CLR_CAPTION_BG);ObjectSetInteger(chart,n,OBJPROP_COLOR,CLR_TEXT_BRIGHT);ObjectSetInteger(chart,n,OBJPROP_BORDER_COLOR,CLR_CAPTION_BG);ObjectSetInteger(chart,n,OBJPROP_ZORDER,-100);colored++;}}
   int cx=6,cy=4,cw=w-26,rx=cx+LABEL_WIDTH+4,rw=cw-LABEL_WIDTH-4;
   int si=0;

   cy+=12; // Increase gap for EA Title
   ML(m_lblVer,"ver","Version "+EA_VERSION+" | "+EA_BUILD_DATE,cx,cy,cw,12,CLR_TEXT_DIM,7); cy+=16;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD; // si = 0

   // ── MARKET ──
   ML(m_lblSym,"lSm",Symbol(),cx,cy,cw,CTRL_HEIGHT+6,CLR_SYMBOL,FONT_SIZE_BIG); cy+=CTRL_HEIGHT+8;
   ML(m_lblMktStatus,"lMk","Market Closed",cx,cy,100,16,CLR_MKT_CLOSED,8);
   ML(m_lblSpdVal,"vSp","Spread: —",cx+104,cy,cw-104,16,CLR_WARNING,8); cy+=24;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD; // si = 1

   // ── CLOCK ──
   ML(m_lblClkTag,"lCk","NY Time",cx,cy,LABEL_WIDTH,CTRL_HEIGHT,CLR_TEXT,FONT_SIZE_MED);
   ML(m_lblClkVal,"vCk","--:--:--",rx,cy,72,CTRL_HEIGHT,CLR_CLOCK_BLUE,FONT_SIZE_MED);
   ML(m_lblClkAmPm,"vCkAP","--",rx+74,cy,32,CTRL_HEIGHT,CLR_REVERSE,FONT_SIZE_MED);
   ML(m_lblClkDate,"vCkD","(-- ---)",rx+108,cy,rw-108,CTRL_HEIGHT,CLR_TEXT_DIM,FONT_SIZE_MED); cy+=CTRL_HEIGHT+CTRL_GAP;

   ML(m_lblNewsTag,"lNw","Next session:",-100,-100,10,10); // Hidden
   ML(m_lblNewsVal,"vNw","Loading...",-100,-100,10,10); // Hidden

   ML(m_lblTimerTag,"lTm","Countdown",cx,cy,LABEL_WIDTH,CTRL_HEIGHT,CLR_TEXT,FONT_SIZE_MED);
   ML(m_lblTimerVal,"vTm","--:--:--",rx,cy,rw,CTRL_HEIGHT,CLR_WARNING,FONT_SIZE_MED); cy+=CTRL_HEIGHT+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD; // si = 2
   
   // --- TIMEFRAME TOGGLES ---
   int thw=(cw-6)/3;
   MB(m_btnToggleM2,"bT2","2m: ON",cx,cy,thw,CTRL_HEIGHT+4,CLR_SUCCESS);
   MB(m_btnToggleM5,"bT5","5m: ON",cx+thw+3,cy,thw,CTRL_HEIGHT+4,CLR_SUCCESS);
   MB(m_btnToggleM15,"bT15","15m: ON",cx+(thw+3)*2,cy,thw,CTRL_HEIGHT+4,CLR_SUCCESS); cy+=CTRL_HEIGHT+4+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD; // si = 3

   // --- TABS (Consolidated: Stats, Order, Entry, Flatten) ---
   int tcw=(cw-12)/4;
   MB(m_btnTabStats,"bTmSt","\xF0\x9F\x92\xB8",cx,cy,tcw,CTRL_HEIGHT+10,CLR_BTN_ON);
   MB(m_btnTabOrder,"bTmOrd","ORDER",cx+tcw+4,cy,tcw,CTRL_HEIGHT+10,CLR_BTN_OFF);
   MB(m_btnTabEntry,"bTmEnt","ENTRY",cx+(tcw+4)*2,cy,tcw,CTRL_HEIGHT+10,CLR_BTN_OFF);
   MB(m_btnTabFlatten,"bTmFlt","FLATTEN",cx+(tcw+4)*3,cy,tcw,CTRL_HEIGHT+10,CLR_BTN_OFF); cy+=CTRL_HEIGHT+10+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD; // si = 4

   int startCy = cy;

   // ── TAB: ORDER ──
   int cyOrder = startCy;
   ML(m_lblMdTag,"lMd","Order mode",cx,cyOrder,LABEL_WIDTH,CTRL_HEIGHT);
   int mb=(rw-6)/3;
   MB(m_btnBoth,"bBt","BOTH",rx,cyOrder,mb,CTRL_HEIGHT+2,CLR_BTN_ON);
   MB(m_btnBuy,"bBy","BUY",rx+mb+3,cyOrder,mb,CTRL_HEIGHT+2);
   MB(m_btnSell,"bSe","SELL",rx+(mb+3)*2,cyOrder,mb,CTRL_HEIGHT+2); cyOrder+=CTRL_HEIGHT+2+8+SEC_PAD;
   cyOrder+=SEC_PAD; MSep(si++,cx,cyOrder,cw); cyOrder+=SEP_GAP+SEC_PAD; // si = 5

   // ── RISK ──
   ML(m_lblBalTag,"lBa","Balance",cx,cyOrder,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblBalVal,"vBa","$0.00",rx,cyOrder,rw,CTRL_HEIGHT,CLR_TEXT_BRIGHT); cyOrder+=CTRL_HEIGHT+CTRL_GAP;
   MB(m_btnRiskMode,"bRm","Risk %",cx,cyOrder,55,CTRL_HEIGHT+2,CLR_BTN_ON);
   ME(m_edtRisk,"eRk","1.0",cx+60,cyOrder,35,CTRL_HEIGHT);
   MB(m_btnFixLot,"bFl","Fix lot",cx+105,cyOrder,55,CTRL_HEIGHT+2,CLR_BTN_OFF);
   ME(m_edtFixLot,"eFl","0.1",cx+165,cyOrder,45,CTRL_HEIGHT); cyOrder+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblRATag,"lRA","Risk / Reward",cx,cyOrder,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblRAVal,"vRA","-$0",rx,cyOrder,70,CTRL_HEIGHT,CLR_MONEY_RED);
   ML(m_lblRwVal,"vRw","+$0",rx+75,cyOrder,70,CTRL_HEIGHT,CLR_MONEY_GREEN); cyOrder+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblLtTag,"lLt","Lot size",cx,cyOrder,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblLtVal,"vLt","0.00",rx,cyOrder,rw,CTRL_HEIGHT,CLR_TEXT_BRIGHT); cyOrder+=CTRL_HEIGHT+SEC_PAD;
   cyOrder+=SEC_PAD; MSep(si++,cx,cyOrder,cw); cyOrder+=SEP_GAP+SEC_PAD; // si = 6

   // ── SL/TP & TRAIL / BE ──
   ML(m_lblSlTag,"lSl","SL / TP",cx,cyOrder,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtSL,"eSl","1500",rx,cyOrder,55,CTRL_HEIGHT); ME(m_edtTP,"eTp","1500",rx+59,cyOrder,55,CTRL_HEIGHT);
   MB(m_btnSLS,"bSs","SL by Candle",rx+120,cyOrder,rw-120,CTRL_HEIGHT,CLR_BTN_ON); cyOrder+=CTRL_HEIGHT+10;
   ML(m_lblTrTag,"lTr","Trailing mode",cx,cyOrder,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnTrMode,"bTm","ON",rx,cyOrder,rw,CTRL_HEIGHT+2,CLR_BTN_ON); cyOrder+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblTrTrig,"lTL","Trigger",cx,cyOrder,55,CTRL_HEIGHT);
   ME(m_edtTTr,"eTTr","1500",cx+55,cyOrder,50,CTRL_HEIGHT);
   ML(m_lblTrDist,"lDi","Distance",cx+108,cyOrder,65,CTRL_HEIGHT);
   ME(m_edtTDi,"eTDi","500",cx+173,cyOrder,50,CTRL_HEIGHT);
   ML(m_lblTrStep,"lStp","Step",cx+226,cyOrder,35,CTRL_HEIGHT);
   ME(m_edtTSt,"eTSt","1",cx+261,cyOrder,50,CTRL_HEIGHT); cyOrder+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblBETag,"lBeT","Breakeven",cx,cyOrder,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnBE,"bBE","OFF",rx,cyOrder,rw,CTRL_HEIGHT+2,CLR_BTN_OFF); cyOrder+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblBeLine,"lBL","BE Trigger",cx,cyOrder,85,CTRL_HEIGHT);
   ME(m_edtBEA,"eBA","200",cx+87,cyOrder,42,CTRL_HEIGHT);
   ML(m_lblBELock,"lPl","+",cx+131,cyOrder,14,CTRL_HEIGHT);
   ME(m_edtBEL,"eBL","50",cx+147,cyOrder,42,CTRL_HEIGHT); cyOrder+=CTRL_HEIGHT+SEC_PAD;
   cyOrder+=SEC_PAD; MSep(si++,cx,cyOrder,cw); cyOrder+=SEP_GAP+SEC_PAD; // si = 7


   // ── TAB: ENTRY ──
   int cyEntry = startCy;
   int smallBtnW = rw / 3;
   int smallBtnX = rx + rw - smallBtnW;
   ML(m_lblEntrySec,"lEnT","ENTRY",cx,cyEntry,cw,CTRL_HEIGHT); cyEntry+=CTRL_HEIGHT+CTRL_GAP+8;
   
   ML(m_lblRtcTag,"lRtc","Retest candle (min)",cx,cyEntry,150,CTRL_HEIGHT);
   ME(m_edtRtc,"eRtc","1",cx+155,cyEntry,50,CTRL_HEIGHT);
   MB(m_btnRtc,"bRtc","ON",smallBtnX,cyEntry,smallBtnW,CTRL_HEIGHT+2,CLR_SUCCESS); cyEntry+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblContTag,"lCo","Continue after 1st fired",cx,cyEntry,180,CTRL_HEIGHT);
   MB(m_btnCont,"bCo","ON",smallBtnX,cyEntry,smallBtnW,CTRL_HEIGHT+2,CLR_SUCCESS); cyEntry+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblMaxSTag,"lMs","Max succesful order",cx,cyEntry,150,CTRL_HEIGHT);
   ME(m_edtMaxS,"eMs","2",cx+155,cyEntry,50,CTRL_HEIGHT);
   MB(m_btnMaxS,"bMs","ON",smallBtnX,cyEntry,smallBtnW,CTRL_HEIGHT+2,CLR_SUCCESS); cyEntry+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblMaxLTag,"lMl","Max loss order",cx,cyEntry,150,CTRL_HEIGHT);
   ME(m_edtMaxL,"eMl","1",cx+155,cyEntry,50,CTRL_HEIGHT);
   MB(m_btnMaxL,"bMl","ON",smallBtnX,cyEntry,smallBtnW,CTRL_HEIGHT+2,CLR_SUCCESS); cyEntry+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblBigMTag,"lBm","Big momentum only",cx,cyEntry,180,CTRL_HEIGHT);
   MB(m_btnBigM,"bBm","OFF",smallBtnX,cyEntry,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cyEntry+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblAamTag,"lAam","Trading window (min)",cx,cyEntry,150,CTRL_HEIGHT);
   ME(m_edtAam,"eAam","60",cx+155,cyEntry,50,CTRL_HEIGHT);
   MB(m_btnAam,"bAam","ON",smallBtnX,cyEntry,smallBtnW,CTRL_HEIGHT+2,CLR_SUCCESS); cyEntry+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblMdrTag,"lMdr","Max dist from range",cx,cyEntry,150,CTRL_HEIGHT);
   ME(m_edtMdr,"eMdr","6000",cx+155,cyEntry,50,CTRL_HEIGHT);
   MB(m_btnMdr,"bMdr","ON",smallBtnX,cyEntry,smallBtnW,CTRL_HEIGHT+2,CLR_SUCCESS); cyEntry+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblFemTag,"lFem","Favor EMA",cx,cyEntry,95,CTRL_HEIGHT);
   ME(m_edtFem1,"eFm1","9",cx+124,cyEntry,38,CTRL_HEIGHT);
   MB(m_btnFem1,"bFm1","",cx+163,cyEntry,24,CTRL_HEIGHT,CLR_BTN_OFF);
   ML(m_lblFemPlus1,"lFp1","+",cx+189,cyEntry,14,CTRL_HEIGHT);
   ME(m_edtFem2,"eFm2","21",cx+205,cyEntry,38,CTRL_HEIGHT);
   MB(m_btnFem2,"bFm2","",cx+244,cyEntry,24,CTRL_HEIGHT,CLR_BTN_OFF);
   ML(m_lblFemPlus2,"lFp2","+",cx+270,cyEntry,14,CTRL_HEIGHT);
   ME(m_edtFem3,"eFm3","34",cx+286,cyEntry,38,CTRL_HEIGHT);
   MB(m_btnFem3,"bFm3","",cx+325,cyEntry,24,CTRL_HEIGHT,CLR_BTN_OFF); cyEntry+=CTRL_HEIGHT+SEC_PAD;
   cyEntry+=SEC_PAD; MSep(si++,cx,cyEntry,cw); cyEntry+=SEP_GAP+SEC_PAD; // si = 8


   // ── TAB: FLATTEN ──
   int cyFlatten = startCy;
   ML(m_lblExpTag,"lExT","AUTO FLATTEN/CANCEL ALL ORDERS",cx,cyFlatten,cw,CTRL_HEIGHT); cyFlatten+=CTRL_HEIGHT+CTRL_GAP+8;
   ML(m_lblUfmTag,"lUfm","Unfavor move",cx,cyFlatten,150,CTRL_HEIGHT);
   ME(m_edtUfmPts,"eUfm","8000",cx+155,cyFlatten,50,CTRL_HEIGHT);
   MB(m_btnUfm,"bUfm","ON",smallBtnX,cyFlatten,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_ON); cyFlatten+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblTmrTag,"lTmr","Touch middle range",cx,cyFlatten,150,CTRL_HEIGHT);
   MB(m_btnTmr,"bTmr","ON",smallBtnX,cyFlatten,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_ON); cyFlatten+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblAucTag,"lAuc","After unfilled candles",cx,cyFlatten,150,CTRL_HEIGHT);
   ME(m_edtAuc,"eAuc","2",cx+155,cyFlatten,50,CTRL_HEIGHT);
   MB(m_btnAuc,"bAuc","OFF",smallBtnX,cyFlatten,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cyFlatten+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblAfcTag,"lAfc","After filled (min)",cx,cyFlatten,150,CTRL_HEIGHT);
   ME(m_edtAfc,"eAfc","5",cx+155,cyFlatten,50,CTRL_HEIGHT);
   MB(m_btnAfc,"bAfc","ON",smallBtnX,cyFlatten,smallBtnW,CTRL_HEIGHT+2,CLR_SUCCESS); cyFlatten+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblEma1Tag,"lEm1","Unfavor EMA",cx,cyFlatten,95,CTRL_HEIGHT);
   ML(m_lblEma2Tag,"lEm2","",-100,-100,10,10);
   ML(m_lblEma3Tag,"lEm3","",-100,-100,10,10);
   ME(m_edtEma1,"eEm1","9",cx+124,cyFlatten,38,CTRL_HEIGHT);
   MB(m_btnEma1,"bEm1","",cx+163,cyFlatten,24,CTRL_HEIGHT,CLR_BTN_OFF);
   ML(m_lblEmaPlus1,"lEp1","+",cx+189,cyFlatten,14,CTRL_HEIGHT);
   ME(m_edtEma2,"eEm2","21",cx+205,cyFlatten,38,CTRL_HEIGHT);
   MB(m_btnEma2,"bEm2","",cx+244,cyFlatten,24,CTRL_HEIGHT,CLR_BTN_OFF);
   ML(m_lblEmaPlus2,"lEp2","+",cx+270,cyFlatten,14,CTRL_HEIGHT);
   ME(m_edtEma3,"eEm3","34",cx+286,cyFlatten,38,CTRL_HEIGHT);
   MB(m_btnEma3,"bEm3","",cx+325,cyFlatten,24,CTRL_HEIGHT,CLR_BTN_OFF); cyFlatten+=CTRL_HEIGHT+SEC_PAD;
   cyFlatten+=SEC_PAD; MSep(si++,cx,cyFlatten,cw); cyFlatten+=SEP_GAP+SEC_PAD; // si = 9


   // ── TAB: STATS ──
   m_statusSepStart = si;
   int cyStatus = startCy;

   // ── ORDERS (single row: 2m | 5m | 15m — no header label) ──
   int ordColW = cw / 3;
   cyStatus -= 3; // Shift up to equalize top and bottom padding
   int rowH = CTRL_HEIGHT + 4; // Increase height to prevent vertical text clipping
   
   ML(m_lblOrdersSec,"lOrS","",cx,cyStatus,1,rowH);
   ML(m_lbl2mStTag,"l2sT","2m:",cx,cyStatus,32,rowH,CLR_TEXT);
   ML(m_lbl2mStVal,"v2sV","OFF",cx+32,cyStatus,ordColW-32,rowH,CLR_TEXT_DIM);
   ML(m_lbl5mStTag,"l5sT","5m:",cx+ordColW,cyStatus,32,rowH,CLR_TEXT);
   ML(m_lbl5mStVal,"v5sV","OFF",cx+ordColW+32,cyStatus,ordColW-32,rowH,CLR_TEXT_DIM);
   ML(m_lbl15mStTag,"l15sT","15m:",cx+ordColW*2,cyStatus,38,rowH,CLR_TEXT);
   ML(m_lbl15mStVal,"v15sV","OFF",cx+ordColW*2+38,cyStatus,ordColW-38,rowH,CLR_TEXT_DIM);
   
   cyStatus += rowH + 15; // Centered separator
   MSep(si++,cx,cyStatus,cw); cyStatus+=SEP_GAP+SEC_PAD; // si = 10

   // ── EQUITY ──
   ML(m_lblEqTag,"lEqT","Equity:",cx,cyStatus,50,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblStatEquity,"sEq","$0",cx+52,cyStatus,85,CTRL_HEIGHT,clrWhite);
   ML(m_lblPlTag,"lPlT","P/L:",cx+142,cyStatus,30,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblStatPL,"sPL","+$0",cx+175,cyStatus,75,CTRL_HEIGHT,CLR_SUCCESS);
   cyStatus+=CTRL_HEIGHT+SEC_PAD;
    
    // Removed/Off-screen legacy exposure & R:R lines
    ML(m_lblTotExpTag,"lTeT","",-100,-100,10,10);
    ML(m_lblTotExpVal,"sTeV","",-100,-100,10,10);
    ML(m_lblRtRrTag,"lRtT","",-100,-100,10,10);
    ML(m_lblRtRrLoss,"sRtL","",-100,-100,10,10);
    ML(m_lblRtRrPft,"sRtP","",-100,-100,10,10);
    ML(m_lblRtRrRiskPc,"sRtPc","",-100,-100,10,10);
   cyStatus+=SEC_PAD; MSep(si++,cx,cyStatus,cw); cyStatus+=SEP_GAP+SEC_PAD; // si = 11

   // ── LAST DAY ENTRIES ──
   ML(m_lblLastEntrySec,"lLeS","",-100,-100,10,10);
   for(int ei=0; ei<9; ei++) {
      string numId = "lEn" + IntegerToString(ei);
      string descId = "sEd" + IntegerToString(ei);
      ML(m_lblEntryNum[ei], numId, IntegerToString(ei+1)+".", cx, cyStatus, 18, CTRL_HEIGHT, CLR_TEXT_BRIGHT);
      ML(m_lblEntryDesc[ei], descId, "--", cx+20, cyStatus, cw-20, CTRL_HEIGHT, CLR_WARNING);
      cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   }
   cyStatus+=SEC_PAD;
   cyStatus+=SEC_PAD; MSep(si++,cx,cyStatus,cw); cyStatus+=SEP_GAP+SEC_PAD; // si = 12

   // ── TOTAL P/L ──
   ML(m_lblTotalPlSec,"lTpS","",-100,-100,10,10);
   ML(m_lblNetTodayTag,"lNtT","Last day:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblNetTodayVal,"sNtV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lblTodayWl,"sNtW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblNetWeekTag,"lNwT","Week:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblNetWeekVal,"sNwV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lblWeekWl,"sNwW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblNetMonthTag,"lNmT","Month:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lblNetMonthVal,"sNmV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lblMonthWl,"sNmW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+SEC_PAD;
   cyStatus+=SEC_PAD; MSep(si++,cx,cyStatus,cw); cyStatus+=SEP_GAP+SEC_PAD; // si = 13

   // ── 2m P/L ──
   ML(m_lbl2mNtTag,"l2nT","2m Last day:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl2mNtVal,"s2nV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl2mTodayWl,"s2nW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lbl2mNwTag,"l2nwT","2m Week:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl2mNwVal,"s2nwV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl2mWeekWl,"s2nwW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lbl2mNmTag,"l2nmT","2m Month:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl2mNmVal,"s2nmV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl2mMonthWl,"s2nmW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+SEC_PAD;
   cyStatus+=SEC_PAD; MSep(si++,cx,cyStatus,cw); cyStatus+=SEP_GAP+SEC_PAD; // si = 14

   // ── 5m P/L ──
   ML(m_lbl5mNtTag,"l5nT","5m Last day:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl5mNtVal,"s5nV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl5mTodayWl,"s5nW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lbl5mNwTag,"l5nwT","5m Week:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl5mNwVal,"s5nwV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl5mWeekWl,"s5nwW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lbl5mNmTag,"l5nmT","5m Month:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl5mNmVal,"s5nmV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl5mMonthWl,"s5nmW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+SEC_PAD;
   cyStatus+=SEC_PAD; MSep(si++,cx,cyStatus,cw); cyStatus+=SEP_GAP+SEC_PAD; // si = 15

   // ── 15m P/L ──
   ML(m_lbl15mNtTag,"l15nT","15m Last day:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl15mNtVal,"s15nV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl15mTodayWl,"s15nW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lbl15mNwTag,"l15nwT","15m Week:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl15mNwVal,"s15nwV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl15mWeekWl,"s15nwW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lbl15mNmTag,"l15nmT","15m Month:",cx,cyStatus,95,CTRL_HEIGHT,CLR_TEXT);
   ML(m_lbl15mNmVal,"s15nmV","$0",cx+95,cyStatus,90,CTRL_HEIGHT,CLR_TEXT_BRIGHT);
   ML(m_lbl15mMonthWl,"s15nmW","W/L: 0/0",cx+190,cyStatus,100,CTRL_HEIGHT,CLR_TEXT_DIM); cyStatus+=CTRL_HEIGHT+CTRL_GAP; // si = 16
   
   // Hidden legacy controls
   ML(m_lblOsTag,"lOs","",  -100,-100,10,10);
   ML(m_lblOsVal,"vOs","",  -100,-100,10,10);
   ML(m_lblStVal,"vSv","",  -100,-100,10,10);

   m_statusSepEnd = si - 1;
   
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
SystemConfig CDashboard::GetParams()
{
   if(m_activeTab != TAB_STATS) SaveTab(m_activeTab);
   m_config.main.symbol = m_lblSym.Text();
   m_dirty = false;
   return m_config;
}

void CDashboard::SaveTab(ENUM_TAB tab)
{
   if(tab == TAB_STATS) return;
   DashboardParams p;
   p.symbol = m_lblSym.Text();
   p.utcOffset = m_utcOff;
   p.timeframe = m_config.main.timeframe;
   p.comment = m_config.main.comment;
   p.slPoints = (int)StringToInteger(m_edtSL.Text());
   p.tpPoints=(int)StringToInteger(m_edtTP.Text());
   p.slCandle=m_slCandle;
   p.riskPercent=StringToDouble(m_edtRisk.Text());
   p.riskModeOn=m_rMode;
   p.fixLot=StringToDouble(m_edtFixLot.Text());
   p.orderMode=m_om;
   p.trailMode=m_tm;
   p.trailTrigger=(int)StringToInteger(m_edtTTr.Text());
   p.trailDistance=(int)StringToInteger(m_edtTDi.Text());
   p.trailStep=(int)StringToInteger(m_edtTSt.Text());
   p.beActivatePoints=(int)StringToInteger(m_edtBEA.Text());
   p.beLockPoints=(int)StringToInteger(m_edtBEL.Text());
   p.beEnabled=m_beOn;
   p.unfavorMoveOn=m_ufmEnabled;
   p.unfavorMovePts=(int)StringToInteger(m_edtUfmPts.Text());
   p.touchMidOn=m_tmrEnabled;
   p.unfilledCandlesOn=m_aucEnabled;
   p.unfilledCandles=(int)StringToInteger(m_edtAuc.Text());
   p.afterFilledMinutesOn=m_afcEnabled;
   p.afterFilledMinutes=(int)StringToInteger(m_edtAfc.Text());
   p.afterMinutesOn=m_aamEnabled;
   p.afterMinutes=(int)StringToInteger(m_edtAam.Text());
   p.ema1On=m_ema1Enabled;
   p.ema1Period=(int)StringToInteger(m_edtEma1.Text());
   p.ema2On=m_ema2Enabled;
   p.ema2Period=(int)StringToInteger(m_edtEma2.Text());
   p.ema3On=m_ema3Enabled;
   p.ema3Period=(int)StringToInteger(m_edtEma3.Text());
   p.customRetestOn=m_rtcOn;
   p.customRetestMin=(int)StringToInteger(m_edtRtc.Text());
   p.contAfter1st=m_contAfter1st;
   p.maxSuccessOn=m_maxSuccessOn;
   p.maxSuccess=(int)StringToInteger(m_edtMaxS.Text());
   p.maxLossOn=m_maxLossOn;
   p.maxLoss=(int)StringToInteger(m_edtMaxL.Text());
   p.bigMomentum=m_bigMomentum;
   p.maxDistRangeOn=m_mdrEnabled;
   p.maxDistRange=(int)StringToInteger(m_edtMdr.Text());
   p.favorEma1On=m_fem1Enabled;
   p.favorEma1Period=(int)StringToInteger(m_edtFem1.Text());
   p.favorEma2On=m_fem2Enabled;
   p.favorEma2Period=(int)StringToInteger(m_edtFem2.Text());
   p.favorEma3On=m_fem3Enabled;
   p.favorEma3Period=(int)StringToInteger(m_edtFem3.Text());

   p.isActive = m_config.main.isActive;
   p.nyHour = m_config.main.nyHour;
   p.nyMinute = m_config.main.nyMinute;
   p.nySecond = m_config.main.nySecond;
   p.entryBufferPoints = m_config.main.entryBufferPoints;
   p.tfIndex = m_config.main.tfIndex;
   m_config.main = p;
}

void CDashboard::LoadTab(ENUM_TAB tab)
{
   if(tab == TAB_STATS) return;
   DashboardParams p = m_config.main;

   m_slCandle = p.slCandle;
   m_btnSLS.ColorBackground(m_slCandle?CLR_BTN_ON:CLR_BTN_OFF);
   m_edtSL.Text(IntegerToString(p.slPoints)); 
   m_utcOff=p.utcOffset;
   m_edtTP.Text(IntegerToString(p.tpPoints));
   m_btnSLS.Text(m_slCandle?"SL by Candle✓":"SL by Candle"); 
   m_edtRisk.Text(DoubleToString(p.riskPercent,1));
   m_edtFixLot.Text(DoubleToString(p.fixLot,2));
   m_rMode=p.riskModeOn;
   m_btnRiskMode.ColorBackground(m_rMode ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnFixLot.ColorBackground(!m_rMode ? CLR_BTN_ON : CLR_BTN_OFF);
   m_om=p.orderMode; UpdMode();
   m_tm=p.trailMode; UpdTrail();
   m_edtTTr.Text(IntegerToString(p.trailTrigger)); m_edtTDi.Text(IntegerToString(p.trailDistance));
   m_edtTSt.Text(IntegerToString(p.trailStep));
   m_edtBEA.Text(IntegerToString(p.beActivatePoints)); m_edtBEL.Text(IntegerToString(p.beLockPoints));
   m_beOn=p.beEnabled; UpdBE();
   m_ufmEnabled=p.unfavorMoveOn; UpdUfm();
   m_edtUfmPts.Text(IntegerToString(p.unfavorMovePts));
   m_tmrEnabled=p.touchMidOn; UpdTmr();
   m_aucEnabled=p.unfilledCandlesOn; UpdAuc();
   m_edtAuc.Text(IntegerToString(p.unfilledCandles));
   m_afcEnabled=p.afterFilledMinutesOn; UpdAfc();
   m_edtAfc.Text(IntegerToString(p.afterFilledMinutes));
   m_aamEnabled=p.afterMinutesOn; UpdAam();
   m_edtAam.Text(IntegerToString(p.afterMinutes));
   m_ema1Enabled=p.ema1On; UpdEma1();
   m_edtEma1.Text(IntegerToString(p.ema1Period));
   m_ema2Enabled=p.ema2On; UpdEma2();
   m_edtEma2.Text(IntegerToString(p.ema2Period));
   m_ema3Enabled=p.ema3On; UpdEma3();
   m_edtEma3.Text(IntegerToString(p.ema3Period));
   m_rtcOn=p.customRetestOn; UpdRtc();
   m_edtRtc.Text(IntegerToString(p.customRetestMin));
   m_contAfter1st=p.contAfter1st; UpdCont();
   m_maxSuccessOn=p.maxSuccessOn; UpdMaxS();
   m_edtMaxS.Text(IntegerToString(p.maxSuccess));
   m_maxLossOn=p.maxLossOn; UpdMaxL();
   m_edtMaxL.Text(IntegerToString(p.maxLoss));
   m_bigMomentum=p.bigMomentum; UpdBigM();
   m_mdrEnabled=p.maxDistRangeOn; UpdMdr();
   m_edtMdr.Text(IntegerToString(p.maxDistRange));
   m_fem1Enabled=p.favorEma1On; UpdFem1();
   m_edtFem1.Text(IntegerToString(p.favorEma1Period));
   m_fem2Enabled=p.favorEma2On; UpdFem2();
   m_edtFem2.Text(IntegerToString(p.favorEma2Period));
   m_fem3Enabled=p.favorEma3On; UpdFem3();
   m_edtFem3.Text(IntegerToString(p.favorEma3Period));
}

void CDashboard::SetInitialParams(const SystemConfig &cfg)
{
   m_config = cfg;
   m_activeTab = TAB_STATS;
   m_lblSym.Text(cfg.main.symbol!=""?cfg.main.symbol:Symbol());
   UpdToggles();
   UpdTabs();
   LoadTab(m_activeTab);
}

// ── UPDATERS ──
void CDashboard::UpdateSpread(int s) { m_lblSpdVal.Text("Spread: "+IntegerToString(s)); }

void CDashboard::UpdateStatus(string s) { m_lblStVal.Text(s); }
void CDashboard::UpdateOrderStatus(string s) { m_lblOsVal.Text(s); }
void CDashboard::UpdateNYClock(string t, string ap, string d) { m_lblClkVal.Text(t); m_lblClkAmPm.Text(ap); m_lblClkDate.Text(d); }
void CDashboard::OnRiskModeToggle() { m_rMode=true; m_btnRiskMode.ColorBackground(CLR_BTN_ON); m_btnFixLot.ColorBackground(CLR_BTN_OFF); MarkDirty(); }
void CDashboard::OnLotModeToggle() { m_rMode=false; m_btnRiskMode.ColorBackground(CLR_BTN_OFF); m_btnFixLot.ColorBackground(CLR_BTN_ON); MarkDirty(); }

// ── DIRECT CLICK HANDLER - bypasses CAppDialog event routing ──
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
   if(objName == m_btnToggleM2.Name())      { OnToggleM2(); return true; }
   if(objName == m_btnToggleM5.Name())      { OnToggleM5(); return true; }
   if(objName == m_btnToggleM15.Name())     { OnToggleM15(); return true; }
   if(objName == m_btnTabOrder.Name())      { OnTabOrder(); return true; }
   if(objName == m_btnTabEntry.Name())      { OnTabEntry(); return true; }
   if(objName == m_btnTabFlatten.Name())    { OnTabFlatten(); return true; }
   if(objName == m_btnTabStats.Name())      { OnTabStats(); return true; }

   if(objName == m_btnRiskMode.Name())      { OnRiskModeToggle(); return true; }
   if(objName == m_btnFixLot.Name())        { OnLotModeToggle(); return true; }
   if(objName == m_btnSLS.Name())           { OnSLS(); return true; }
   if(objName == m_btnBoth.Name())          { OnBoth(); return true; }
   if(objName == m_btnBuy.Name())           { OnBuyO(); return true; }
   if(objName == m_btnSell.Name())          { OnSellO(); return true; }
   if(objName == m_btnTrMode.Name())        { OnTrM(); return true; }
   if(objName == m_btnBE.Name())            { OnBEToggle(); return true; }
   if(objName == m_btnUfm.Name())           { OnUfmToggle(); return true; }
   if(objName == m_btnTmr.Name())           { OnTmrToggle(); return true; }
   if(objName == m_btnAuc.Name())           { OnAucToggle(); return true; }
   if(objName == m_btnAfc.Name())           { OnAfcToggle(); return true; }
   if(objName == m_btnAam.Name())           { OnAamToggle(); return true; }
   if(objName == m_btnEma1.Name())          { OnEma1Toggle(); return true; }
   if(objName == m_btnEma2.Name())          { OnEma2Toggle(); return true; }
   if(objName == m_btnEma3.Name())          { OnEma3Toggle(); return true; }
   if(objName == m_btnMdr.Name())           { OnMdrToggle(); return true; }
   if(objName == m_btnFem1.Name())          { OnFem1Toggle(); return true; }
   if(objName == m_btnFem2.Name())          { OnFem2Toggle(); return true; }
   if(objName == m_btnFem3.Name())          { OnFem3Toggle(); return true; }
   if(objName == m_btnRtc.Name())           { OnRtcToggle(); return true; }
   if(objName == m_btnCont.Name())          { OnContToggle(); return true; }
   if(objName == m_btnMaxS.Name())          { OnMaxSToggle(); return true; }
   if(objName == m_btnMaxL.Name())          { OnMaxLToggle(); return true; }
   if(objName == m_btnBigM.Name())          { OnBigMToggle(); return true; }
   return false;
}


void CDashboard::UpdateBalanceInfo(double b,double r,double rw,double l)
{ m_lblBalVal.Text("$"+FormatMoneyRound(b)); m_lblRAVal.Text("-$"+FormatMoneyRound(r));
   m_lblRwVal.Text("+$"+FormatMoneyRound(rw)); m_lblLtVal.Text(DoubleToString(l,2)); }
void CDashboard::UpdateNews(string s) { m_lblNewsVal.Text(s); }
void CDashboard::UpdateTimer(string s) { m_lblTimerVal.Text(s); }
void CDashboard::UpdateSymbol(string sym) { m_lblSym.Text(sym); MarkDirty(); }
void CDashboard::UpdateMarketStatus(bool o)
{ m_lblMktStatus.Text(o?"Market Open":"Market Closed"); m_lblMktStatus.Color(o?CLR_MKT_OPEN:CLR_MKT_CLOSED); }


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
   string sign = (profit >= 0) ? "+" : "-";
   m_lblStatPL.Text(StringFormat("%s$%s", sign, FormatMoneyRound(MathAbs(profit))));
   m_lblStatPL.Color((profit > 0) ? CLR_SUCCESS : ((profit < 0) ? CLR_NEWS_RED : CLR_TEXT_DIM));
}
void CDashboard::UpdateTotalExposed(double lots, int type)
{
   m_lblTotExpVal.Text(DoubleToString(lots, 2));
   if(type == 0) m_lblTotExpVal.Color(CLR_BUY);
   else if(type == 1) m_lblTotExpVal.Color(CLR_SELL);
   else m_lblTotExpVal.Color(CLR_TEXT_DIM);
}
void CDashboard::UpdateRealtimeRR(double profit, double loss, double theoreticalRisk)
{
   m_lblRtRrLoss.Text(StringFormat("-$%s", FormatMoneyRound(loss)));
   m_lblRtRrPft.Text(StringFormat("+$%s", FormatMoneyRound(profit)));
   // Visual warning: actual risk exceeds theoretical — loss turns orange
   if(loss > 0 && theoreticalRisk > 0 && loss > theoreticalRisk * 1.2)
      m_lblRtRrLoss.Color(CLR_WARNING);
   else
      m_lblRtRrLoss.Color(CLR_MONEY_RED);
}
void CDashboard::UpdateRealtimeRiskPercent(double riskPc, double maxRiskPc)
{
   m_lblRtRrRiskPc.Text(StringFormat("{%.1f%%}", riskPc));
   if(riskPc > maxRiskPc) m_lblRtRrRiskPc.Color(CLR_MONEY_RED);
   else if(MathAbs(riskPc - maxRiskPc) <= 0.01) m_lblRtRrRiskPc.Color(CLR_WARNING);
   else m_lblRtRrRiskPc.Color(CLR_ACCENT);
}

void CDashboard::UpdateStatsTab(const string &entries[], double netToday, int wToday, int lToday, double netWeek, int wWeek, int lWeek, double netMonth, int wMonth, int lMonth)
{
   for(int ei=0; ei<9; ei++) {
      if(ei < ArraySize(entries) && entries[ei] != "")
         m_lblEntryDesc[ei].Text(entries[ei]);
      else
         m_lblEntryDesc[ei].Text("--");
   }
   
   m_lblNetTodayVal.Text((netToday>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netToday)));
   m_lblNetTodayVal.Color(netToday>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lblTodayWl.Text("W/L: " + IntegerToString(wToday) + "/" + IntegerToString(lToday));
   
   m_lblNetWeekVal.Text((netWeek>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netWeek)));
   m_lblNetWeekVal.Color(netWeek>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lblWeekWl.Text("W/L: " + IntegerToString(wWeek) + "/" + IntegerToString(lWeek));
   
   m_lblNetMonthVal.Text((netMonth>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netMonth)));
   m_lblNetMonthVal.Color(netMonth>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lblMonthWl.Text("W/L: " + IntegerToString(wMonth) + "/" + IntegerToString(lMonth));
}

void CDashboard::Update2mStatus(string status, color clr) {
   m_lbl2mStVal.Text(status);
   m_lbl2mStVal.Color(clr);
}
void CDashboard::Update5mStatus(string status, color clr) {
   m_lbl5mStVal.Text(status);
   m_lbl5mStVal.Color(clr);
}
void CDashboard::Update2mPL(double netToday, int wToday, int lToday, double netWeek, int wWeek, int lWeek, double netMonth, int wMonth, int lMonth) {
   m_lbl2mNtVal.Text((netToday>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netToday)));
   m_lbl2mNtVal.Color(netToday>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl2mTodayWl.Text("W/L: " + IntegerToString(wToday) + "/" + IntegerToString(lToday));
   
   m_lbl2mNwVal.Text((netWeek>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netWeek)));
   m_lbl2mNwVal.Color(netWeek>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl2mWeekWl.Text("W/L: " + IntegerToString(wWeek) + "/" + IntegerToString(lWeek));
   
   m_lbl2mNmVal.Text((netMonth>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netMonth)));
   m_lbl2mNmVal.Color(netMonth>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl2mMonthWl.Text("W/L: " + IntegerToString(wMonth) + "/" + IntegerToString(lMonth));
}
void CDashboard::Update5mPL(double netToday, int wToday, int lToday, double netWeek, int wWeek, int lWeek, double netMonth, int wMonth, int lMonth) {
   m_lbl5mNtVal.Text((netToday>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netToday)));
   m_lbl5mNtVal.Color(netToday>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl5mTodayWl.Text("W/L: " + IntegerToString(wToday) + "/" + IntegerToString(lToday));
   
   m_lbl5mNwVal.Text((netWeek>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netWeek)));
   m_lbl5mNwVal.Color(netWeek>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl5mWeekWl.Text("W/L: " + IntegerToString(wWeek) + "/" + IntegerToString(lWeek));
   
   m_lbl5mNmVal.Text((netMonth>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netMonth)));
   m_lbl5mNmVal.Color(netMonth>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl5mMonthWl.Text("W/L: " + IntegerToString(wMonth) + "/" + IntegerToString(lMonth));
}
void CDashboard::Update15mStatus(string status, color clr) {
   m_lbl15mStVal.Text(status);
   m_lbl15mStVal.Color(clr);
}
void CDashboard::Update15mPL(double netToday, int wToday, int lToday, double netWeek, int wWeek, int lWeek, double netMonth, int wMonth, int lMonth) {
   m_lbl15mNtVal.Text((netToday>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netToday)));
   m_lbl15mNtVal.Color(netToday>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl15mTodayWl.Text("W/L: " + IntegerToString(wToday) + "/" + IntegerToString(lToday));
   
   m_lbl15mNwVal.Text((netWeek>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netWeek)));
   m_lbl15mNwVal.Color(netWeek>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl15mWeekWl.Text("W/L: " + IntegerToString(wWeek) + "/" + IntegerToString(lWeek));
   
   m_lbl15mNmVal.Text((netMonth>=0?"+$":"-$") + FormatMoneyRound(MathAbs(netMonth)));
   m_lbl15mNmVal.Color(netMonth>=0 ? CLR_MONEY_GREEN : CLR_MONEY_RED);
   m_lbl15mMonthWl.Text("W/L: " + IntegerToString(wMonth) + "/" + IntegerToString(lMonth));
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
void CDashboard::OnTrM() {
   m_btnTrMode.Pressed(false);
   switch(m_tm){case TM_OFF:m_tm=TM_CHASE;break;default:m_tm=TM_OFF;break;} UpdTrail(); MarkDirty(); }
void CDashboard::UpdTrail() { string t="OFF"; color c=CLR_BTN_OFF;
   switch(m_tm){case TM_OFF:t="OFF";c=CLR_BTN_OFF;break;default:t="ON";c=CLR_SUCCESS;break;}
   m_btnTrMode.Text(t); m_btnTrMode.ColorBackground(c); }
void CDashboard::OnBEToggle() { m_btnBE.Pressed(false); m_beOn=!m_beOn; UpdBE(); MarkDirty(); }
void CDashboard::UpdBE() { m_btnBE.Text(m_beOn?"ON":"OFF");
   m_btnBE.ColorBackground(m_beOn?CLR_SUCCESS:CLR_BTN_OFF); }

void CDashboard::OnUfmToggle() { m_btnUfm.Pressed(false); m_ufmEnabled=!m_ufmEnabled; UpdUfm(); MarkDirty(); }
void CDashboard::UpdUfm() { m_btnUfm.Text(m_ufmEnabled?"ON":"OFF"); m_btnUfm.ColorBackground(m_ufmEnabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnTmrToggle() { m_btnTmr.Pressed(false); m_tmrEnabled=!m_tmrEnabled; UpdTmr(); MarkDirty(); }
void CDashboard::UpdTmr() { m_btnTmr.Text(m_tmrEnabled?"ON":"OFF"); m_btnTmr.ColorBackground(m_tmrEnabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnAucToggle() { m_btnAuc.Pressed(false); m_aucEnabled=!m_aucEnabled; UpdAuc(); MarkDirty(); }
void CDashboard::UpdAuc() { m_btnAuc.Text(m_aucEnabled?"ON":"OFF"); m_btnAuc.ColorBackground(m_aucEnabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnAfcToggle() { m_btnAfc.Pressed(false); m_afcEnabled=!m_afcEnabled; UpdAfc(); MarkDirty(); }
void CDashboard::UpdAfc() { m_btnAfc.Text(m_afcEnabled?"ON":"OFF"); m_btnAfc.ColorBackground(m_afcEnabled?CLR_SUCCESS:CLR_BTN_OFF); }
void CDashboard::OnAamToggle() { m_btnAam.Pressed(false); m_aamEnabled=!m_aamEnabled; UpdAam(); MarkDirty(); }
void CDashboard::UpdAam() { m_btnAam.Text(m_aamEnabled?"ON":"OFF"); m_btnAam.ColorBackground(m_aamEnabled?CLR_SUCCESS:CLR_BTN_OFF); }
void CDashboard::OnEma1Toggle() { m_btnEma1.Pressed(false); m_ema1Enabled=!m_ema1Enabled; UpdEma1(); MarkDirty(); }
void CDashboard::UpdEma1() { m_btnEma1.Text(m_ema1Enabled?ShortToString(0x2713):""); m_btnEma1.ColorBackground(m_ema1Enabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnEma2Toggle() { m_btnEma2.Pressed(false); m_ema2Enabled=!m_ema2Enabled; UpdEma2(); MarkDirty(); }
void CDashboard::UpdEma2() { m_btnEma2.Text(m_ema2Enabled?ShortToString(0x2713):""); m_btnEma2.ColorBackground(m_ema2Enabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnEma3Toggle() { m_btnEma3.Pressed(false); m_ema3Enabled=!m_ema3Enabled; UpdEma3(); MarkDirty(); }
void CDashboard::UpdEma3() { m_btnEma3.Text(m_ema3Enabled?ShortToString(0x2713):""); m_btnEma3.ColorBackground(m_ema3Enabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnMdrToggle() { m_btnMdr.Pressed(false); m_mdrEnabled=!m_mdrEnabled; UpdMdr(); MarkDirty(); }
void CDashboard::UpdMdr() { m_btnMdr.Text(m_mdrEnabled?"ON":"OFF"); m_btnMdr.ColorBackground(m_mdrEnabled?CLR_SUCCESS:CLR_BTN_OFF); }
void CDashboard::OnFem1Toggle() { m_btnFem1.Pressed(false); m_fem1Enabled=!m_fem1Enabled; UpdFem1(); MarkDirty(); }
void CDashboard::UpdFem1() { m_btnFem1.Text(m_fem1Enabled?ShortToString(0x2713):""); m_btnFem1.ColorBackground(m_fem1Enabled?CLR_SUCCESS:CLR_BTN_OFF); }
void CDashboard::OnFem2Toggle() { m_btnFem2.Pressed(false); m_fem2Enabled=!m_fem2Enabled; UpdFem2(); MarkDirty(); }
void CDashboard::UpdFem2() { m_btnFem2.Text(m_fem2Enabled?ShortToString(0x2713):""); m_btnFem2.ColorBackground(m_fem2Enabled?CLR_SUCCESS:CLR_BTN_OFF); }
void CDashboard::OnFem3Toggle() { m_btnFem3.Pressed(false); m_fem3Enabled=!m_fem3Enabled; UpdFem3(); MarkDirty(); }
void CDashboard::UpdFem3() { m_btnFem3.Text(m_fem3Enabled?ShortToString(0x2713):""); m_btnFem3.ColorBackground(m_fem3Enabled?CLR_SUCCESS:CLR_BTN_OFF); }

void CDashboard::OnRtcToggle() { m_btnRtc.Pressed(false); m_rtcOn=!m_rtcOn; UpdRtc(); MarkDirty(); }
void CDashboard::UpdRtc() { m_btnRtc.Text(m_rtcOn?"ON":"OFF"); m_btnRtc.ColorBackground(m_rtcOn?CLR_SUCCESS:CLR_BTN_OFF); }

void CDashboard::OnContToggle() { m_btnCont.Pressed(false); m_contAfter1st=!m_contAfter1st; UpdCont(); MarkDirty(); }
void CDashboard::UpdCont() { m_btnCont.Text(m_contAfter1st?"ON":"OFF"); m_btnCont.ColorBackground(m_contAfter1st?CLR_SUCCESS:CLR_BTN_OFF); }

void CDashboard::OnMaxSToggle() { m_btnMaxS.Pressed(false); m_maxSuccessOn=!m_maxSuccessOn; UpdMaxS(); MarkDirty(); }
void CDashboard::UpdMaxS() { m_btnMaxS.Text(m_maxSuccessOn?"ON":"OFF"); m_btnMaxS.ColorBackground(m_maxSuccessOn?CLR_SUCCESS:CLR_BTN_OFF); }

void CDashboard::OnMaxLToggle() { m_btnMaxL.Pressed(false); m_maxLossOn=!m_maxLossOn; UpdMaxL(); MarkDirty(); }
void CDashboard::UpdMaxL() { m_btnMaxL.Text(m_maxLossOn?"ON":"OFF"); m_btnMaxL.ColorBackground(m_maxLossOn?CLR_SUCCESS:CLR_BTN_OFF); }

void CDashboard::OnBigMToggle() { m_btnBigM.Pressed(false); m_bigMomentum=!m_bigMomentum; UpdBigM(); MarkDirty(); }
void CDashboard::UpdBigM() { m_btnBigM.Text(m_bigMomentum?"ON":"OFF"); m_btnBigM.ColorBackground(m_bigMomentum?CLR_SUCCESS:CLR_BTN_OFF); }
void CDashboard::OnToggleM2() { m_btnToggleM2.Pressed(false); m_config.m2Active=!m_config.m2Active; UpdToggles(); MarkDirty(); }
void CDashboard::OnToggleM5() { m_btnToggleM5.Pressed(false); m_config.m5Active=!m_config.m5Active; UpdToggles(); MarkDirty(); }
void CDashboard::OnToggleM15() { m_btnToggleM15.Pressed(false); m_config.m15Active=!m_config.m15Active; UpdToggles(); MarkDirty(); }

void CDashboard::UpdToggles() {
   m_btnToggleM2.Text(m_config.m2Active ? "2m: ON" : "2m: OFF");
   m_btnToggleM2.ColorBackground(m_config.m2Active ? CLR_SUCCESS : CLR_BTN_OFF);
   m_btnToggleM5.Text(m_config.m5Active ? "5m: ON" : "5m: OFF");
   m_btnToggleM5.ColorBackground(m_config.m5Active ? CLR_SUCCESS : CLR_BTN_OFF);
   m_btnToggleM15.Text(m_config.m15Active ? "15m: ON" : "15m: OFF");
   m_btnToggleM15.ColorBackground(m_config.m15Active ? CLR_SUCCESS : CLR_BTN_OFF);
   // Refresh tab UI
   UpdTabs();
}

void CDashboard::OnTabOrder() { m_btnTabOrder.Pressed(false); if(m_activeTab!=TAB_STATS) SaveTab(m_activeTab); m_activeTab=TAB_ORDER; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }
void CDashboard::OnTabEntry() { m_btnTabEntry.Pressed(false); if(m_activeTab!=TAB_STATS) SaveTab(m_activeTab); m_activeTab=TAB_ENTRY; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }
void CDashboard::OnTabFlatten() { m_btnTabFlatten.Pressed(false); if(m_activeTab!=TAB_STATS) SaveTab(m_activeTab); m_activeTab=TAB_FLATTEN; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }
void CDashboard::OnTabStats() { m_btnTabStats.Pressed(false); if(m_activeTab!=TAB_STATS) SaveTab(m_activeTab); m_activeTab=TAB_STATS; UpdTabs(); MarkDirty(); }

void CDashboard::UpdTabs() {
   m_btnTabOrder.ColorBackground(m_activeTab==TAB_ORDER ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnTabEntry.ColorBackground(m_activeTab==TAB_ENTRY ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnTabFlatten.ColorBackground(m_activeTab==TAB_FLATTEN ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnTabStats.ColorBackground(m_activeTab==TAB_STATS ? CLR_BTN_ON : CLR_BTN_OFF);

   // First, hide ALL settings & stats controls
   
   // --- ORDER TAB CONTROLS ---
   CtrlHide(m_lblMdTag); CtrlHide(m_btnBoth); CtrlHide(m_btnBuy); CtrlHide(m_btnSell);
   CtrlHide(m_lblBalTag); CtrlHide(m_lblBalVal); CtrlHide(m_btnRiskMode); CtrlHide(m_edtRisk); CtrlHide(m_btnFixLot); CtrlHide(m_edtFixLot);
   CtrlHide(m_lblRATag); CtrlHide(m_lblRAVal); CtrlHide(m_lblRwVal); CtrlHide(m_lblLtTag); CtrlHide(m_lblLtVal);
   CtrlHide(m_lblSlTag); CtrlHide(m_edtSL); CtrlHide(m_edtTP); CtrlHide(m_btnSLS);
   CtrlHide(m_lblTrTag); CtrlHide(m_btnTrMode);
   CtrlHide(m_lblTrTrig); CtrlHide(m_edtTTr); CtrlHide(m_lblTrDist); CtrlHide(m_edtTDi); CtrlHide(m_lblTrStep); CtrlHide(m_edtTSt);
   CtrlHide(m_lblBETag); CtrlHide(m_btnBE);
   CtrlHide(m_lblBeLine); CtrlHide(m_edtBEA); CtrlHide(m_lblBELock); CtrlHide(m_edtBEL);
   CtrlHide(m_sep[5]); CtrlHide(m_sep[6]); CtrlHide(m_sep[7]);
   
   // --- ENTRY TAB CONTROLS ---
   CtrlHide(m_lblEntrySec);
   CtrlHide(m_lblRtcTag); CtrlHide(m_edtRtc); CtrlHide(m_btnRtc);
   CtrlHide(m_lblContTag); CtrlHide(m_btnCont);
   CtrlHide(m_lblMaxSTag); CtrlHide(m_edtMaxS); CtrlHide(m_btnMaxS);
   CtrlHide(m_lblMaxLTag); CtrlHide(m_edtMaxL); CtrlHide(m_btnMaxL);
   CtrlHide(m_lblBigMTag); CtrlHide(m_btnBigM);
   CtrlHide(m_lblAamTag); CtrlHide(m_edtAam); CtrlHide(m_btnAam);
   CtrlHide(m_lblMdrTag); CtrlHide(m_edtMdr); CtrlHide(m_btnMdr);
   CtrlHide(m_lblFemTag); CtrlHide(m_edtFem1); CtrlHide(m_btnFem1); CtrlHide(m_edtFem2); CtrlHide(m_btnFem2); CtrlHide(m_edtFem3); CtrlHide(m_btnFem3);
   CtrlHide(m_lblFemPlus1); CtrlHide(m_lblFemPlus2);
   CtrlHide(m_sep[8]);

   // --- FLATTEN TAB CONTROLS ---
   CtrlHide(m_lblExpTag);
   CtrlHide(m_lblUfmTag); CtrlHide(m_edtUfmPts); CtrlHide(m_btnUfm);
   CtrlHide(m_lblTmrTag); CtrlHide(m_btnTmr);
   CtrlHide(m_lblAucTag); CtrlHide(m_edtAuc); CtrlHide(m_btnAuc);
   CtrlHide(m_lblAfcTag); CtrlHide(m_edtAfc); CtrlHide(m_btnAfc);
   CtrlHide(m_lblEma1Tag); CtrlHide(m_edtEma1); CtrlHide(m_btnEma1);
   CtrlHide(m_lblEmaPlus1); CtrlHide(m_lblEmaPlus2);
   CtrlHide(m_lblEma2Tag); CtrlHide(m_edtEma2); CtrlHide(m_btnEma2);
   CtrlHide(m_lblEma3Tag); CtrlHide(m_edtEma3); CtrlHide(m_btnEma3);
   CtrlHide(m_sep[9]);

   // --- STATS TAB CONTROLS ---
   CtrlHide(m_lblOrdersSec);
   CtrlHide(m_lbl2mStTag); CtrlHide(m_lbl2mStVal);
   CtrlHide(m_lbl5mStTag); CtrlHide(m_lbl5mStVal);
   CtrlHide(m_lbl15mStTag); CtrlHide(m_lbl15mStVal);
   CtrlHide(m_lblEqTag); CtrlHide(m_lblStatEquity); CtrlHide(m_lblPlTag); CtrlHide(m_lblStatPL);
   CtrlHide(m_lblTotExpTag); CtrlHide(m_lblTotExpVal);
   CtrlHide(m_lblRtRrTag); CtrlHide(m_lblRtRrLoss); CtrlHide(m_lblRtRrPft); CtrlHide(m_lblRtRrRiskPc);
   CtrlHide(m_lblLastEntrySec);
   for(int ei=0; ei<9; ei++) { CtrlHide(m_lblEntryNum[ei]); CtrlHide(m_lblEntryDesc[ei]); }
   CtrlHide(m_lblTotalPlSec);
   CtrlHide(m_lblNetTodayTag); CtrlHide(m_lblNetTodayVal); CtrlHide(m_lblTodayWl);
   CtrlHide(m_lblNetWeekTag); CtrlHide(m_lblNetWeekVal); CtrlHide(m_lblWeekWl);
   CtrlHide(m_lblNetMonthTag); CtrlHide(m_lblNetMonthVal); CtrlHide(m_lblMonthWl);
   CtrlHide(m_lbl2mNtTag); CtrlHide(m_lbl2mNtVal); CtrlHide(m_lbl2mTodayWl);
   CtrlHide(m_lbl2mNwTag); CtrlHide(m_lbl2mNwVal); CtrlHide(m_lbl2mWeekWl);
   CtrlHide(m_lbl2mNmTag); CtrlHide(m_lbl2mNmVal); CtrlHide(m_lbl2mMonthWl);
   CtrlHide(m_lbl5mNtTag); CtrlHide(m_lbl5mNtVal); CtrlHide(m_lbl5mTodayWl);
   CtrlHide(m_lbl5mNwTag); CtrlHide(m_lbl5mNwVal); CtrlHide(m_lbl5mWeekWl);
   CtrlHide(m_lbl5mNmTag); CtrlHide(m_lbl5mNmVal); CtrlHide(m_lbl5mMonthWl);
   CtrlHide(m_lbl15mNtTag); CtrlHide(m_lbl15mNtVal); CtrlHide(m_lbl15mTodayWl);
   CtrlHide(m_lbl15mNwTag); CtrlHide(m_lbl15mNwVal); CtrlHide(m_lbl15mWeekWl);
   CtrlHide(m_lbl15mNmTag); CtrlHide(m_lbl15mNmVal); CtrlHide(m_lbl15mMonthWl);
   for(int i=m_statusSepStart; i<=m_statusSepEnd; i++) CtrlHide(m_sep[i]);

   // Now, selectively SHOW the active tab
   if(m_activeTab == TAB_STATS) {
      CtrlShow(m_lblOrdersSec);
      CtrlShow(m_lbl2mStTag); CtrlShow(m_lbl2mStVal);
      CtrlShow(m_lbl5mStTag); CtrlShow(m_lbl5mStVal);
      CtrlShow(m_lbl15mStTag); CtrlShow(m_lbl15mStVal);
      CtrlShow(m_lblEqTag); CtrlShow(m_lblStatEquity); CtrlShow(m_lblPlTag); CtrlShow(m_lblStatPL);
      CtrlShow(m_lblTotExpTag); CtrlShow(m_lblTotExpVal);
      CtrlShow(m_lblRtRrTag); CtrlShow(m_lblRtRrLoss); CtrlShow(m_lblRtRrPft); CtrlShow(m_lblRtRrRiskPc);
      CtrlShow(m_lblLastEntrySec);
      for(int ei=0; ei<9; ei++) { CtrlShow(m_lblEntryNum[ei]); CtrlShow(m_lblEntryDesc[ei]); }
      CtrlShow(m_lblTotalPlSec);
      CtrlShow(m_lblNetTodayTag); CtrlShow(m_lblNetTodayVal); CtrlShow(m_lblTodayWl);
      CtrlShow(m_lblNetWeekTag); CtrlShow(m_lblNetWeekVal); CtrlShow(m_lblWeekWl);
      CtrlShow(m_lblNetMonthTag); CtrlShow(m_lblNetMonthVal); CtrlShow(m_lblMonthWl);
      CtrlShow(m_lbl2mNtTag); CtrlShow(m_lbl2mNtVal); CtrlShow(m_lbl2mTodayWl);
      CtrlShow(m_lbl2mNwTag); CtrlShow(m_lbl2mNwVal); CtrlShow(m_lbl2mWeekWl);
      CtrlShow(m_lbl2mNmTag); CtrlShow(m_lbl2mNmVal); CtrlShow(m_lbl2mMonthWl);
      CtrlShow(m_lbl5mNtTag); CtrlShow(m_lbl5mNtVal); CtrlShow(m_lbl5mTodayWl);
      CtrlShow(m_lbl5mNwTag); CtrlShow(m_lbl5mNwVal); CtrlShow(m_lbl5mWeekWl);
      CtrlShow(m_lbl5mNmTag); CtrlShow(m_lbl5mNmVal); CtrlShow(m_lbl5mMonthWl);
      CtrlShow(m_lbl15mNtTag); CtrlShow(m_lbl15mNtVal); CtrlShow(m_lbl15mTodayWl);
      CtrlShow(m_lbl15mNwTag); CtrlShow(m_lbl15mNwVal); CtrlShow(m_lbl15mWeekWl);
      CtrlShow(m_lbl15mNmTag); CtrlShow(m_lbl15mNmVal); CtrlShow(m_lbl15mMonthWl);
      for(int i=m_statusSepStart; i<=m_statusSepEnd; i++) CtrlShow(m_sep[i]);
   }
   else if(m_activeTab == TAB_ORDER) {
      CtrlShow(m_lblMdTag); CtrlShowBtn(m_btnBoth); CtrlShowBtn(m_btnBuy); CtrlShowBtn(m_btnSell);
      CtrlShow(m_lblBalTag); CtrlShow(m_lblBalVal); CtrlShowBtn(m_btnRiskMode); CtrlShowEdit(m_edtRisk); CtrlShowBtn(m_btnFixLot); CtrlShowEdit(m_edtFixLot);
      CtrlShow(m_lblRATag); CtrlShow(m_lblRAVal); CtrlShow(m_lblRwVal); CtrlShow(m_lblLtTag); CtrlShow(m_lblLtVal);
      CtrlShow(m_lblSlTag); CtrlShowEdit(m_edtSL); CtrlShowEdit(m_edtTP); CtrlShowBtn(m_btnSLS);
      CtrlShow(m_lblTrTag); CtrlShowBtn(m_btnTrMode);
      CtrlShow(m_lblTrTrig); CtrlShowEdit(m_edtTTr); CtrlShow(m_lblTrDist); CtrlShowEdit(m_edtTDi); CtrlShow(m_lblTrStep); CtrlShowEdit(m_edtTSt);
      CtrlShow(m_lblBETag); CtrlShowBtn(m_btnBE);
      CtrlShow(m_lblBeLine); CtrlShowEdit(m_edtBEA); CtrlShow(m_lblBELock); CtrlShowEdit(m_edtBEL);
      CtrlShow(m_sep[5]); CtrlShow(m_sep[6]); CtrlShow(m_sep[7]);
   }
   else if(m_activeTab == TAB_ENTRY) {
      CtrlShow(m_lblEntrySec);
      CtrlShow(m_lblRtcTag); CtrlShowEdit(m_edtRtc); CtrlShowBtn(m_btnRtc);
      CtrlShow(m_lblContTag); CtrlShowBtn(m_btnCont);
      CtrlShow(m_lblMaxSTag); CtrlShowEdit(m_edtMaxS); CtrlShowBtn(m_btnMaxS);
      CtrlShow(m_lblMaxLTag); CtrlShowEdit(m_edtMaxL); CtrlShowBtn(m_btnMaxL);
      CtrlShow(m_lblBigMTag); CtrlShowBtn(m_btnBigM);
      CtrlShow(m_lblAamTag); CtrlShowEdit(m_edtAam); CtrlShowBtn(m_btnAam);
      CtrlShow(m_lblMdrTag); CtrlShowEdit(m_edtMdr); CtrlShowBtn(m_btnMdr);
      CtrlShow(m_lblFemTag); CtrlShowEdit(m_edtFem1); CtrlShowBtn(m_btnFem1); CtrlShowEdit(m_edtFem2); CtrlShowBtn(m_btnFem2); CtrlShowEdit(m_edtFem3); CtrlShowBtn(m_btnFem3);
      CtrlShow(m_lblFemPlus1); CtrlShow(m_lblFemPlus2);
      CtrlShow(m_sep[8]);
   }
   else if(m_activeTab == TAB_FLATTEN) {
      CtrlShow(m_lblExpTag);
      CtrlShow(m_lblUfmTag); CtrlShowEdit(m_edtUfmPts); CtrlShowBtn(m_btnUfm);
      CtrlShow(m_lblTmrTag); CtrlShowBtn(m_btnTmr);
      CtrlShow(m_lblAucTag); CtrlShowEdit(m_edtAuc); CtrlShowBtn(m_btnAuc);
      CtrlShow(m_lblAfcTag); CtrlShowEdit(m_edtAfc); CtrlShowBtn(m_btnAfc);
      CtrlShow(m_lblEma1Tag); CtrlShowEdit(m_edtEma1); CtrlShowBtn(m_btnEma1);
      CtrlShow(m_lblEmaPlus1); CtrlShow(m_lblEmaPlus2);
      CtrlShow(m_lblEma2Tag); CtrlShowEdit(m_edtEma2); CtrlShowBtn(m_btnEma2);
      CtrlShow(m_lblEma3Tag); CtrlShowEdit(m_edtEma3); CtrlShowBtn(m_btnEma3);
      CtrlShow(m_sep[9]);
   }
}

void CDashboard::Minimize(void)
{
   CAppDialog::Minimize();
   CtrlHide(m_lblVer); CtrlHide(m_lblSym); CtrlHide(m_lblMktStatus); CtrlHide(m_lblSpdVal);
   CtrlHide(m_lblClkTag); CtrlHide(m_lblClkVal); CtrlHide(m_lblClkAmPm); CtrlHide(m_lblClkDate);
   CtrlHide(m_lblTimerTag); CtrlHide(m_lblTimerVal);
   CtrlHide(m_btnToggleM2); CtrlHide(m_btnToggleM5); CtrlHide(m_btnToggleM15);
   CtrlHide(m_btnTabOrder); CtrlHide(m_btnTabEntry); CtrlHide(m_btnTabFlatten); CtrlHide(m_btnTabStats);
   
   for(int i=0; i<=m_statusSepEnd; i++) CtrlHide(m_sep[i]);
   
   // --- ORDER TAB CONTROLS ---
   CtrlHide(m_lblMdTag); CtrlHide(m_btnBoth); CtrlHide(m_btnBuy); CtrlHide(m_btnSell);
   CtrlHide(m_lblBalTag); CtrlHide(m_lblBalVal); CtrlHide(m_btnRiskMode); CtrlHide(m_edtRisk); CtrlHide(m_btnFixLot); CtrlHide(m_edtFixLot);
   CtrlHide(m_lblRATag); CtrlHide(m_lblRAVal); CtrlHide(m_lblRwVal); CtrlHide(m_lblLtTag); CtrlHide(m_lblLtVal);
   CtrlHide(m_lblSlTag); CtrlHide(m_edtSL); CtrlHide(m_edtTP); CtrlHide(m_btnSLS);
   CtrlHide(m_lblTrTag); CtrlHide(m_btnTrMode);
   CtrlHide(m_lblTrTrig); CtrlHide(m_edtTTr); CtrlHide(m_lblTrDist); CtrlHide(m_edtTDi); CtrlHide(m_lblTrStep); CtrlHide(m_edtTSt);
   CtrlHide(m_lblBETag); CtrlHide(m_btnBE);
   CtrlHide(m_lblBeLine); CtrlHide(m_edtBEA); CtrlHide(m_lblBELock); CtrlHide(m_edtBEL);
   
   // --- ENTRY TAB CONTROLS ---
   CtrlHide(m_lblEntrySec);
   CtrlHide(m_lblRtcTag); CtrlHide(m_edtRtc); CtrlHide(m_btnRtc);
   CtrlHide(m_lblContTag); CtrlHide(m_btnCont);
   CtrlHide(m_lblMaxSTag); CtrlHide(m_edtMaxS); CtrlHide(m_btnMaxS);
   CtrlHide(m_lblMaxLTag); CtrlHide(m_edtMaxL); CtrlHide(m_btnMaxL);
   CtrlHide(m_lblBigMTag); CtrlHide(m_btnBigM);
   CtrlHide(m_lblAamTag); CtrlHide(m_edtAam); CtrlHide(m_btnAam);
   CtrlHide(m_lblMdrTag); CtrlHide(m_edtMdr); CtrlHide(m_btnMdr);
   CtrlHide(m_lblFemTag); CtrlHide(m_edtFem1); CtrlHide(m_btnFem1); CtrlHide(m_edtFem2); CtrlHide(m_btnFem2); CtrlHide(m_edtFem3); CtrlHide(m_btnFem3);
   CtrlHide(m_lblFemPlus1); CtrlHide(m_lblFemPlus2);

   // --- FLATTEN TAB CONTROLS ---
   CtrlHide(m_lblExpTag);
   CtrlHide(m_lblUfmTag); CtrlHide(m_edtUfmPts); CtrlHide(m_btnUfm);
   CtrlHide(m_lblTmrTag); CtrlHide(m_btnTmr);
   CtrlHide(m_lblAucTag); CtrlHide(m_edtAuc); CtrlHide(m_btnAuc);
   CtrlHide(m_lblAfcTag); CtrlHide(m_edtAfc); CtrlHide(m_btnAfc);
   CtrlHide(m_lblEma1Tag); CtrlHide(m_edtEma1); CtrlHide(m_btnEma1);
   CtrlHide(m_lblEmaPlus1); CtrlHide(m_lblEmaPlus2);
   CtrlHide(m_lblEma2Tag); CtrlHide(m_edtEma2); CtrlHide(m_btnEma2);
   CtrlHide(m_lblEma3Tag); CtrlHide(m_edtEma3); CtrlHide(m_btnEma3);

   // --- STATS TAB CONTROLS ---
   CtrlHide(m_lblOrdersSec);
   CtrlHide(m_lbl2mStTag); CtrlHide(m_lbl2mStVal);
   CtrlHide(m_lbl5mStTag); CtrlHide(m_lbl5mStVal);
   CtrlHide(m_lbl15mStTag); CtrlHide(m_lbl15mStVal);
   CtrlHide(m_lblEqTag); CtrlHide(m_lblStatEquity); CtrlHide(m_lblPlTag); CtrlHide(m_lblStatPL);
   CtrlHide(m_lblTotExpTag); CtrlHide(m_lblTotExpVal);
   CtrlHide(m_lblRtRrTag); CtrlHide(m_lblRtRrLoss); CtrlHide(m_lblRtRrPft); CtrlHide(m_lblRtRrRiskPc);
   CtrlHide(m_lblLastEntrySec);
   for(int ei=0; ei<9; ei++) { CtrlHide(m_lblEntryNum[ei]); CtrlHide(m_lblEntryDesc[ei]); }
   CtrlHide(m_lblTotalPlSec);
   CtrlHide(m_lblNetTodayTag); CtrlHide(m_lblNetTodayVal); CtrlHide(m_lblTodayWl);
   CtrlHide(m_lblNetWeekTag); CtrlHide(m_lblNetWeekVal); CtrlHide(m_lblWeekWl);
   CtrlHide(m_lblNetMonthTag); CtrlHide(m_lblNetMonthVal); CtrlHide(m_lblMonthWl);
   CtrlHide(m_lbl2mNtTag); CtrlHide(m_lbl2mNtVal); CtrlHide(m_lbl2mTodayWl);
   CtrlHide(m_lbl2mNwTag); CtrlHide(m_lbl2mNwVal); CtrlHide(m_lbl2mWeekWl);
   CtrlHide(m_lbl2mNmTag); CtrlHide(m_lbl2mNmVal); CtrlHide(m_lbl2mMonthWl);
   CtrlHide(m_lbl5mNtTag); CtrlHide(m_lbl5mNtVal); CtrlHide(m_lbl5mTodayWl);
   CtrlHide(m_lbl5mNwTag); CtrlHide(m_lbl5mNwVal); CtrlHide(m_lbl5mWeekWl);
   CtrlHide(m_lbl5mNmTag); CtrlHide(m_lbl5mNmVal); CtrlHide(m_lbl5mMonthWl);
   CtrlHide(m_lbl15mNtTag); CtrlHide(m_lbl15mNtVal); CtrlHide(m_lbl15mTodayWl);
   CtrlHide(m_lbl15mNwTag); CtrlHide(m_lbl15mNwVal); CtrlHide(m_lbl15mWeekWl);
   CtrlHide(m_lbl15mNmTag); CtrlHide(m_lbl15mNmVal); CtrlHide(m_lbl15mMonthWl);
}

void CDashboard::Maximize(void)
{
   CAppDialog::Maximize();
   CtrlShow(m_lblVer); CtrlShow(m_lblSym); CtrlShow(m_lblMktStatus); CtrlShow(m_lblSpdVal);
   CtrlShow(m_lblClkTag); CtrlShow(m_lblClkVal); CtrlShow(m_lblClkAmPm); CtrlShow(m_lblClkDate);
   CtrlShow(m_lblTimerTag); CtrlShow(m_lblTimerVal);
   CtrlShow(m_btnToggleM2); CtrlShow(m_btnToggleM5); CtrlShow(m_btnToggleM15);
   CtrlShow(m_btnTabOrder); CtrlShow(m_btnTabEntry); CtrlShow(m_btnTabFlatten); CtrlShow(m_btnTabStats);
   for(int i=0; i<5; i++) CtrlShow(m_sep[i]); 
   UpdTabs(); 
}

#endif
