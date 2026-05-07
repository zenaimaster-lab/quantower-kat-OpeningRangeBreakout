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
   
   CButton m_btnGlobal, m_btnToggleM2, m_btnToggleM5;
   CEdit m_lblGlobalTag;
   CButton m_btnTabMain, m_btnTabM2, m_btnTabM5, m_btnTabStats;
   CEdit  m_edtSL, m_edtTP;
   CButton m_btnSLS, m_btnBoth, m_btnBuy, m_btnSell;
   CEdit m_lblBalTag, m_lblBalVal, m_lblRskTag, m_lblRPc;
   CEdit m_lblRATag, m_lblRAVal, m_lblRwVal, m_lblLtTag, m_lblLtVal;
   CEdit  m_edtRisk;
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
   CEdit m_lblAamTag, m_edtAam;
   CButton m_btnAam;
   
   CEdit m_lblEntrySec;
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
   CButton m_btnA1,m_btnA2,m_btnA3;
   CEdit m_lblOsTag, m_lblOsVal, m_lblStVal;
   CEdit m_lblEqTag, m_lblPlTag;
   CEdit m_lblStatEquity, m_lblStatPL;
   CEdit m_lblTotExpTag, m_lblTotExpVal;
   CEdit m_lblRtRrTag, m_lblRtRrLoss, m_lblRtRrPft, m_lblRtRrRiskPc;
   CPanel m_sep[20];




   void CtrlShow(CWnd &obj);
   void CtrlShowBtn(CWnd &obj);
   void CtrlShowEdit(CWnd &obj);
   void CtrlHide(CWnd &obj);


   SystemConfig m_config;
   ENUM_TAB m_activeTab;
   bool m_slCandle, m_beOn;
   bool m_ufmEnabled, m_tmrEnabled, m_aucEnabled, m_aamEnabled;
   bool m_ema1Enabled, m_ema2Enabled, m_ema3Enabled;
   bool m_contAfter1st, m_maxSuccessOn, m_maxLossOn, m_bigMomentum;
   int m_idxSepAfterPresets;
   int m_statusSepStart, m_statusSepEnd;
   int m_utcOff;
   ENUM_ORDER_MODE m_om;
   ENUM_TRAIL_MODE m_tm;
   int m_dayOffset;              
   bool m_customTiming;        
   bool m_dirty;
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
   void SetInitialParams(const SystemConfig &cfg);
   SystemConfig GetParams();
   void SaveTab(ENUM_TAB tab);
   void LoadTab(ENUM_TAB tab);
   void UpdateSpread(int s);

   void UpdateStatus(string s);
   void UpdateOrderStatus(string s);
   void UpdateNYClock(string t, string ap, string d);
   void UpdateBalanceInfo(double b,double r,double rw,double l);
   void ApplyPreset(const PresetParams &pr);
   void UpdateNews(string newsStr);
   void UpdateTimer(string timerStr);
   void UpdateMarketStatus(bool isOpen);
   void UpdateSymbol(string sym);
   void UpdateInternalTiming(int h, int m, int s) { m_config.main.nyHour=h; m_config.main.nyMinute=m; m_config.main.nySecond=s; }


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
private:
   bool ML(CEdit &l,string n,string t,int x,int y,int w,int h,color c=CLR_TEXT,int fs=FONT_SIZE);
   bool ME(CEdit &e,string n,string t,int x,int y,int w,int h);
   bool MB(CButton &b,string n,string t,int x,int y,int w,int h,color bg=CLR_BTN_OFF);
   void MSep(int idx,int x,int y,int w);
   void OnSLS(); void OnBoth(); void OnBuyO(); void OnSellO();
   void OnTrM(); void OnManP(); void OnCanA();
   void OnToggleGlobal(); void OnToggleM2(); void OnToggleM5();
   void OnTabMain(); void OnTabM2(); void OnTabM5();
   void OnBrkEv();
   void OnBEToggle();
   void OnUfmToggle(); void UpdUfm();
   void OnTmrToggle(); void UpdTmr();
   void OnAucToggle(); void UpdAuc();
   void OnAamToggle(); void UpdAam();
   void OnEma1Toggle(); void UpdEma1();
   void OnEma2Toggle(); void UpdEma2();
   void OnEma3Toggle(); void UpdEma3();
   
   void OnContToggle(); void UpdCont();
   void OnMaxSToggle(); void UpdMaxS();
   void OnMaxLToggle(); void UpdMaxL();
   void OnBigMToggle(); void UpdBigM();
   
   void OnTabStats();
   void OnA1(); void OnA2(); void OnA3();


   void UpdMode(); void UpdTrail(); void UpdBE();
   void UpdToggles(); void UpdTabs();

public:
   bool HandleDirectClick(const string &objName);

};

CDashboard::CDashboard() { m_slCandle=false; m_om=MODE_BOTH; m_tm=TM_OFF; m_activeTab=TAB_STATS;
   m_ufmEnabled=false; m_tmrEnabled=false; m_aucEnabled=false; m_aamEnabled=false; m_utcOff=-4; m_beOn=false;
   m_ema1Enabled=false; m_ema2Enabled=false; m_ema3Enabled=false;
   m_dirty=true; m_cmdCount=0; PresetIndex=-1;
   m_dayOffset=0; m_customTiming=false;
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

   cy+=12; // Tăng khoảng trống chỗ EA Title cho rộng ra một chút
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

   ML(m_lblNewsTag,"lNw","Next session:",-100,-100,10,10); // Hidden
   ML(m_lblNewsVal,"vNw","Loading...",-100,-100,10,10); // Hidden

   ML(m_lblTimerTag,"lTm","Countdown",cx,cy,LABEL_WIDTH,CTRL_HEIGHT,CLR_TEXT,FONT_SIZE_MED);
   ML(m_lblTimerVal,"vTm","--:--:--",rx,cy,rw,CTRL_HEIGHT,CLR_WARNING,FONT_SIZE_MED); cy+=CTRL_HEIGHT+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;
   
   // --- MAIN TOGGLES ---
   int thw=(cw-4)/2;
   MB(m_btnToggleM2,"bT2","Trade 2m: ON",cx,cy,thw,CTRL_HEIGHT+4,CLR_SUCCESS);
   MB(m_btnToggleM5,"bT5","Trade 5m: ON",cx+thw+4,cy,thw,CTRL_HEIGHT+4,CLR_SUCCESS); cy+=CTRL_HEIGHT+4+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // --- TABS ---
   int tcw=(cw-12)/4;
   MB(m_btnTabStats,"bTmSt","\xF0\x9F\x92\xB8",cx,cy,tcw,CTRL_HEIGHT+10,CLR_BTN_ON);
   MB(m_btnTabMain,"bTmMain","Global",cx+tcw+4,cy,tcw,CTRL_HEIGHT+10,CLR_BTN_OFF);
   MB(m_btnTabM2,"bTmM2","2m CONF",cx+(tcw+4)*2,cy,tcw,CTRL_HEIGHT+10,CLR_BTN_OFF);
   MB(m_btnTabM5,"bTmM5","5m CONF",cx+(tcw+4)*3,cy,tcw,CTRL_HEIGHT+10,CLR_BTN_OFF); cy+=CTRL_HEIGHT+10+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   int startCy = cy;



   // ── ORDER ──
   ML(m_lblGlobalTag,"lGbT","Global setting",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnGlobal,"bGb","ON",rx,cy,rw,CTRL_HEIGHT+2,CLR_WARNING); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblMdTag,"lMd","Order mode",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   int mb=(rw-6)/3;
   MB(m_btnBoth,"bBt","BOTH",rx,cy,mb,CTRL_HEIGHT+2,CLR_BTN_ON);
   MB(m_btnBuy,"bBy","BUY",rx+mb+3,cy,mb,CTRL_HEIGHT+2);
   MB(m_btnSell,"bSe","SELL",rx+(mb+3)*2,cy,mb,CTRL_HEIGHT+2); cy+=CTRL_HEIGHT+2+8+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── RISK ──
   ML(m_lblBalTag,"lBa","Balance",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblBalVal,"vBa","$0.00",rx,cy,rw,CTRL_HEIGHT,CLR_TEXT_BRIGHT); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblRskTag,"lRk","Risk (%)",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtRisk,"eRk","1.0",rx,cy,40,CTRL_HEIGHT);
   ML(m_lblRPc,"lPc","%",rx+43,cy,18,CTRL_HEIGHT,CLR_TEXT_DIM); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblRATag,"lRA","Risk / Reward",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblRAVal,"vRA","-$0",rx,cy,70,CTRL_HEIGHT,CLR_MONEY_RED);
   ML(m_lblRwVal,"vRw","+$0",rx+75,cy,70,CTRL_HEIGHT,CLR_MONEY_GREEN); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblLtTag,"lLt","Lot size",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblLtVal,"vLt","0.00",rx,cy,rw,CTRL_HEIGHT,CLR_TEXT_BRIGHT); cy+=CTRL_HEIGHT+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── TRAIL / BE ──
   ML(m_lblSlTag,"lSl","SL / TP",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtSL,"eSl","1500",rx,cy,55,CTRL_HEIGHT); ME(m_edtTP,"eTp","3000",rx+59,cy,55,CTRL_HEIGHT);
   MB(m_btnSLS,"bSs","SL by Candle",rx+120,cy,rw-120,CTRL_HEIGHT,CLR_BTN_ON); cy+=CTRL_HEIGHT+10;
   ML(m_lblTrTag,"lTr","Trailing mode",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnTrMode,"bTm","OFF",rx,cy,rw,CTRL_HEIGHT+2); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblTrTrig,"lTL","Trigger",cx,cy,55,CTRL_HEIGHT);
   ME(m_edtTTr,"eTTr","30",cx+55,cy,50,CTRL_HEIGHT);
   ML(m_lblTrDist,"lDi","Distance",cx+108,cy,65,CTRL_HEIGHT);
   ME(m_edtTDi,"eTDi","20",cx+173,cy,50,CTRL_HEIGHT);
   ML(m_lblTrStep,"lStp","Step",cx+226,cy,35,CTRL_HEIGHT);
   ME(m_edtTSt,"eTSt","5",cx+261,cy,50,CTRL_HEIGHT); cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblBETag,"lBeT","Breakeven",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnBE,"bBE","OFF",rx,cy,rw,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblBeLine,"lBL","BE Trigger",cx,cy,85,CTRL_HEIGHT);
   ME(m_edtBEA,"eBA","200",cx+87,cy,42,CTRL_HEIGHT);
   ML(m_lblBELock,"lPl","+",cx+131,cy,14,CTRL_HEIGHT);
   ME(m_edtBEL,"eBL","50",cx+147,cy,42,CTRL_HEIGHT); cy+=CTRL_HEIGHT+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── ENTRY ──
   int smallBtnW = rw / 3;
   int smallBtnX = rx + rw - smallBtnW;
   ML(m_lblEntrySec,"lEnT","ENTRY",cx,cy,cw,CTRL_HEIGHT); cy+=CTRL_HEIGHT+CTRL_GAP+8;
   
   ML(m_lblContTag,"lCo","Continue after 1st fired",cx,cy,180,CTRL_HEIGHT);
   MB(m_btnCont,"bCo","ON",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_ON); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblMaxSTag,"lMs","Max succesful order",cx,cy,150,CTRL_HEIGHT);
   ME(m_edtMaxS,"eMs","5",cx+155,cy,50,CTRL_HEIGHT);
   MB(m_btnMaxS,"bMs","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblMaxLTag,"lMl","Max loss order",cx,cy,150,CTRL_HEIGHT);
   ME(m_edtMaxL,"eMl","1",cx+155,cy,50,CTRL_HEIGHT);
   MB(m_btnMaxL,"bMl","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   
   ML(m_lblBigMTag,"lBm","Big momentum only",cx,cy,180,CTRL_HEIGHT);
   MB(m_btnBigM,"bBm","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── AUTO CANCEL PENDING ──
   ML(m_lblExpTag,"lExT","AUTO CANCEL PENDING ORDER",cx,cy,cw,CTRL_HEIGHT); cy+=CTRL_HEIGHT+CTRL_GAP+8; // Thêm khoảng trống dưới title
   ML(m_lblUfmTag,"lUfm","Unfavor move",cx,cy,150,CTRL_HEIGHT);
   ME(m_edtUfmPts,"eUfm","100",cx+155,cy,50,CTRL_HEIGHT);
   MB(m_btnUfm,"bUfm","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblTmrTag,"lTmr","Touch middle range",cx,cy,150,CTRL_HEIGHT);
   MB(m_btnTmr,"bTmr","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblAucTag,"lAuc","After unfilled candles",cx,cy,150,CTRL_HEIGHT);
   ME(m_edtAuc,"eAuc","2",cx+155,cy,50,CTRL_HEIGHT);
   MB(m_btnAuc,"bAuc","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblAamTag,"lAam","After minutes",cx,cy,150,CTRL_HEIGHT);
   ME(m_edtAam,"eAam","5",cx+155,cy,50,CTRL_HEIGHT);
   MB(m_btnAam,"bAam","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblEma1Tag,"lEm1","Unfavor EMA 1",cx,cy,150,CTRL_HEIGHT);
   ME(m_edtEma1,"eEm1","9",cx+155,cy,50,CTRL_HEIGHT);
   MB(m_btnEma1,"bEm1","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblEma2Tag,"lEm2","Unfavor EMA 2",cx,cy,150,CTRL_HEIGHT);
   ME(m_edtEma2,"eEm2","21",cx+155,cy,50,CTRL_HEIGHT);
   MB(m_btnEma2,"bEm2","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblEma3Tag,"lEm3","Unfavor EMA 3",cx,cy,150,CTRL_HEIGHT);
   ME(m_edtEma3,"eEm3","34",cx+155,cy,50,CTRL_HEIGHT);
   MB(m_btnEma3,"bEm3","OFF",smallBtnX,cy,smallBtnW,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // ── PRESETS ──
   int pw=(cw-10)/3;
   MB(m_btnA1,"bA1","Set A",cx,cy,pw,CTRL_HEIGHT+2,CLR_PRESET); 
   MB(m_btnA2,"bA2","Set B",cx+pw+5,cy,pw,CTRL_HEIGHT+2,CLR_PRESET);
   MB(m_btnA3,"bA3","Set C",cx+(pw+5)*2,cy,pw,CTRL_HEIGHT+2,CLR_PRESET); cy+=CTRL_HEIGHT+2+SEC_PAD;
   m_idxSepAfterPresets = si;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   m_statusSepStart = si;
   cy = startCy; // Rewind Y coordinate to render STATUS below TABS!

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
   
   m_statusSepEnd = si - 1;
   
   return true;
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
   p.timeframe = (tab == TAB_M5) ? PERIOD_M5 : PERIOD_M2;
   p.comment = (tab == TAB_M5) ? "orb-5m" : "orb-2m";
   p.slPoints = (int)StringToInteger(m_edtSL.Text());
   p.tpPoints=(int)StringToInteger(m_edtTP.Text());
   p.slCandle=m_slCandle;
   p.riskPercent=StringToDouble(m_edtRisk.Text());
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
   p.afterMinutesOn=m_aamEnabled;
   p.afterMinutes=(int)StringToInteger(m_edtAam.Text());
   p.ema1On=m_ema1Enabled;
   p.ema1Period=(int)StringToInteger(m_edtEma1.Text());
   p.ema2On=m_ema2Enabled;
   p.ema2Period=(int)StringToInteger(m_edtEma2.Text());
   p.ema3On=m_ema3Enabled;
   p.ema3Period=(int)StringToInteger(m_edtEma3.Text());
   p.contAfter1st=m_contAfter1st;
   p.maxSuccessOn=m_maxSuccessOn;
   p.maxSuccess=(int)StringToInteger(m_edtMaxS.Text());
   p.maxLossOn=m_maxLossOn;
   p.maxLoss=(int)StringToInteger(m_edtMaxL.Text());
   p.bigMomentum=m_bigMomentum;
   p.customTiming=m_customTiming;
   p.targetDayOffset=m_dayOffset;

   if (tab == TAB_MAIN) {
       p.isActive = m_config.main.isActive;
       p.nyHour = m_config.main.nyHour;
       p.nyMinute = m_config.main.nyMinute;
       p.nySecond = m_config.main.nySecond;
       m_config.main = p;
   } else if (tab == TAB_M2) {
       p.isActive = m_config.m2.isActive;
       m_config.m2 = p;
   } else if (tab == TAB_M5) {
       p.isActive = m_config.m5.isActive;
       m_config.m5 = p;
   }
}

void CDashboard::LoadTab(ENUM_TAB tab)
{
   if(tab == TAB_STATS) return;
   DashboardParams p;
   if (tab == TAB_MAIN) p = m_config.main;
   else if (tab == TAB_M2) p = m_config.m2;
   else if (tab == TAB_M5) p = m_config.m5;

   m_slCandle = p.slCandle;
   m_btnSLS.ColorBackground(m_slCandle?CLR_BTN_ON:CLR_BTN_OFF);
   m_edtSL.Text(IntegerToString(p.slPoints)); 
   m_utcOff=p.utcOffset;
   m_edtTP.Text(IntegerToString(p.tpPoints));
   m_btnSLS.Text(m_slCandle?"SL by Candle✓":"SL by Candle"); 
   m_edtRisk.Text(DoubleToString(p.riskPercent,1));
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
   m_aamEnabled=p.afterMinutesOn; UpdAam();
   m_edtAam.Text(IntegerToString(p.afterMinutes));
   m_ema1Enabled=p.ema1On; UpdEma1();
   m_edtEma1.Text(IntegerToString(p.ema1Period));
   m_ema2Enabled=p.ema2On; UpdEma2();
   m_edtEma2.Text(IntegerToString(p.ema2Period));
   m_ema3Enabled=p.ema3On; UpdEma3();
   m_edtEma3.Text(IntegerToString(p.ema3Period));
   m_contAfter1st=p.contAfter1st; UpdCont();
   m_maxSuccessOn=p.maxSuccessOn; UpdMaxS();
   m_edtMaxS.Text(IntegerToString(p.maxSuccess));
   m_maxLossOn=p.maxLossOn; UpdMaxL();
   m_edtMaxL.Text(IntegerToString(p.maxLoss));
   m_bigMomentum=p.bigMomentum; UpdBigM();
}

void CDashboard::SetInitialParams(const SystemConfig &cfg)
{
   m_config = cfg;
   m_activeTab = TAB_MAIN;
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
   if(objName == m_btnGlobal.Name())        { OnToggleGlobal(); return true; }
   if(objName == m_btnToggleM2.Name())      { OnToggleM2(); return true; }
   if(objName == m_btnToggleM5.Name())      { OnToggleM5(); return true; }
   if(objName == m_btnTabMain.Name())       { OnTabMain(); return true; }
   if(objName == m_btnTabM2.Name())         { OnTabM2(); return true; }
   if(objName == m_btnTabM5.Name())         { OnTabM5(); return true; }
   if(objName == m_btnTabStats.Name())      { OnTabStats(); return true; }

   if(objName == m_btnSLS.Name())           { OnSLS(); return true; }
   if(objName == m_btnBoth.Name())          { OnBoth(); return true; }
   if(objName == m_btnBuy.Name())           { OnBuyO(); return true; }
   if(objName == m_btnSell.Name())          { OnSellO(); return true; }
   if(objName == m_btnTrMode.Name())        { OnTrM(); return true; }
   if(objName == m_btnBE.Name())            { OnBEToggle(); return true; }
   if(objName == m_btnUfm.Name())           { OnUfmToggle(); return true; }
   if(objName == m_btnTmr.Name())           { OnTmrToggle(); return true; }
   if(objName == m_btnAuc.Name())           { OnAucToggle(); return true; }
   if(objName == m_btnAam.Name())           { OnAamToggle(); return true; }
   if(objName == m_btnEma1.Name())          { OnEma1Toggle(); return true; }
   if(objName == m_btnEma2.Name())          { OnEma2Toggle(); return true; }
   if(objName == m_btnEma3.Name())          { OnEma3Toggle(); return true; }
   if(objName == m_btnCont.Name())          { OnContToggle(); return true; }
   if(objName == m_btnMaxS.Name())          { OnMaxSToggle(); return true; }
   if(objName == m_btnMaxL.Name())          { OnMaxLToggle(); return true; }
   if(objName == m_btnBigM.Name())          { OnBigMToggle(); return true; }
   if(objName == m_btnA1.Name()) { OnA1(); return true; }
   if(objName == m_btnA2.Name()) { OnA2(); return true; }
   if(objName == m_btnA3.Name()) { OnA3(); return true; }
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

void CDashboard::ApplyPreset(const PresetParams &pr)
{ m_edtSL.Text(IntegerToString(pr.sl)); m_edtTP.Text(IntegerToString(pr.tp));
  m_edtRisk.Text(DoubleToString(pr.risk,1));
  m_edtTTr.Text(IntegerToString(pr.trailTrigger)); m_edtTDi.Text(IntegerToString(pr.trailDist));
  m_edtTSt.Text(IntegerToString(pr.trailStep)); 
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
   if(riskPc > maxRiskPc + 0.01) m_lblRtRrRiskPc.Color(CLR_MONEY_RED);
   else if(MathAbs(riskPc - maxRiskPc) <= 0.01) m_lblRtRrRiskPc.Color(CLR_WARNING);
   else m_lblRtRrRiskPc.Color(CLR_ACCENT);
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
void CDashboard::OnAamToggle() { m_btnAam.Pressed(false); m_aamEnabled=!m_aamEnabled; UpdAam(); MarkDirty(); }
void CDashboard::UpdAam() { m_btnAam.Text(m_aamEnabled?"ON":"OFF"); m_btnAam.ColorBackground(m_aamEnabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnEma1Toggle() { m_btnEma1.Pressed(false); m_ema1Enabled=!m_ema1Enabled; UpdEma1(); MarkDirty(); }
void CDashboard::UpdEma1() { m_btnEma1.Text(m_ema1Enabled?"ON":"OFF"); m_btnEma1.ColorBackground(m_ema1Enabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnEma2Toggle() { m_btnEma2.Pressed(false); m_ema2Enabled=!m_ema2Enabled; UpdEma2(); MarkDirty(); }
void CDashboard::UpdEma2() { m_btnEma2.Text(m_ema2Enabled?"ON":"OFF"); m_btnEma2.ColorBackground(m_ema2Enabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnEma3Toggle() { m_btnEma3.Pressed(false); m_ema3Enabled=!m_ema3Enabled; UpdEma3(); MarkDirty(); }
void CDashboard::UpdEma3() { m_btnEma3.Text(m_ema3Enabled?"ON":"OFF"); m_btnEma3.ColorBackground(m_ema3Enabled?CLR_WARNING:CLR_BTN_OFF); }

void CDashboard::OnContToggle() { m_btnCont.Pressed(false); m_contAfter1st=!m_contAfter1st; UpdCont(); MarkDirty(); }
void CDashboard::UpdCont() { m_btnCont.Text(m_contAfter1st?"ON":"OFF"); m_btnCont.ColorBackground(m_contAfter1st?CLR_WARNING:CLR_BTN_OFF); }

void CDashboard::OnMaxSToggle() { m_btnMaxS.Pressed(false); m_maxSuccessOn=!m_maxSuccessOn; UpdMaxS(); MarkDirty(); }
void CDashboard::UpdMaxS() { m_btnMaxS.Text(m_maxSuccessOn?"ON":"OFF"); m_btnMaxS.ColorBackground(m_maxSuccessOn?CLR_WARNING:CLR_BTN_OFF); }

void CDashboard::OnMaxLToggle() { m_btnMaxL.Pressed(false); m_maxLossOn=!m_maxLossOn; UpdMaxL(); MarkDirty(); }
void CDashboard::UpdMaxL() { m_btnMaxL.Text(m_maxLossOn?"ON":"OFF"); m_btnMaxL.ColorBackground(m_maxLossOn?CLR_WARNING:CLR_BTN_OFF); }

void CDashboard::OnBigMToggle() { m_btnBigM.Pressed(false); m_bigMomentum=!m_bigMomentum; UpdBigM(); MarkDirty(); }
void CDashboard::UpdBigM() { m_btnBigM.Text(m_bigMomentum?"ON":"OFF"); m_btnBigM.ColorBackground(m_bigMomentum?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnToggleGlobal() { m_btnGlobal.Pressed(false); m_config.globalOverride=!m_config.globalOverride; UpdToggles(); MarkDirty(); }
void CDashboard::OnToggleM2() { m_btnToggleM2.Pressed(false); m_config.m2.isActive=!m_config.m2.isActive; UpdToggles(); MarkDirty(); }
void CDashboard::OnToggleM5() { m_btnToggleM5.Pressed(false); m_config.m5.isActive=!m_config.m5.isActive; UpdToggles(); MarkDirty(); }

void CDashboard::UpdToggles() {
   m_btnGlobal.Text(m_config.globalOverride ? "ON" : "OFF");
   m_btnGlobal.ColorBackground(m_config.globalOverride ? CLR_WARNING : CLR_BTN_OFF);
   m_btnToggleM2.Text(m_config.m2.isActive ? "Trade 2m: ON" : "Trade 2m: OFF");
   m_btnToggleM2.ColorBackground(m_config.m2.isActive ? CLR_SUCCESS : CLR_BTN_OFF);
   m_btnToggleM5.Text(m_config.m5.isActive ? "Trade 5m: ON" : "Trade 5m: OFF");
   m_btnToggleM5.ColorBackground(m_config.m5.isActive ? CLR_SUCCESS : CLR_BTN_OFF);
}

void CDashboard::OnTabMain() { m_btnTabMain.Pressed(false); if(m_activeTab!=TAB_STATS) SaveTab(m_activeTab); m_activeTab=TAB_MAIN; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }
void CDashboard::OnTabM2() { m_btnTabM2.Pressed(false); if(m_activeTab!=TAB_STATS) SaveTab(m_activeTab); m_activeTab=TAB_M2; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }
void CDashboard::OnTabM5() { m_btnTabM5.Pressed(false); if(m_activeTab!=TAB_STATS) SaveTab(m_activeTab); m_activeTab=TAB_M5; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }
void CDashboard::OnTabStats() { m_btnTabStats.Pressed(false); if(m_activeTab!=TAB_STATS) SaveTab(m_activeTab); m_activeTab=TAB_STATS; UpdTabs(); MarkDirty(); }

void CDashboard::UpdTabs() {
   m_btnTabMain.ColorBackground(m_activeTab==TAB_MAIN ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnTabM2.ColorBackground(m_activeTab==TAB_M2 ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnTabM5.ColorBackground(m_activeTab==TAB_M5 ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnTabStats.ColorBackground(m_activeTab==TAB_STATS ? CLR_BTN_ON : CLR_BTN_OFF);
   
   bool isStats = (m_activeTab == TAB_STATS);
   
   if(isStats) {
      CtrlShow(m_lblOsTag); CtrlShow(m_lblOsVal); CtrlShow(m_lblStVal);
      CtrlShow(m_lblEqTag); CtrlShow(m_lblStatEquity); CtrlShow(m_lblPlTag); CtrlShow(m_lblStatPL);
      CtrlShow(m_lblTotExpTag); CtrlShow(m_lblTotExpVal);
      CtrlShow(m_lblRtRrTag); CtrlShow(m_lblRtRrLoss); CtrlShow(m_lblRtRrPft); CtrlShow(m_lblRtRrRiskPc);
      for(int i=m_statusSepStart; i<=m_statusSepEnd; i++) CtrlShow(m_sep[i]);
      
      CtrlHide(m_lblGlobalTag); CtrlHide(m_btnGlobal);
      CtrlHide(m_lblMdTag); CtrlHide(m_btnBoth); CtrlHide(m_btnBuy); CtrlHide(m_btnSell);
      CtrlHide(m_lblBalTag); CtrlHide(m_lblBalVal); CtrlHide(m_lblRskTag); CtrlHide(m_edtRisk); CtrlHide(m_lblRPc);
      CtrlHide(m_lblRATag); CtrlHide(m_lblRAVal); CtrlHide(m_lblRwVal); CtrlHide(m_lblLtTag); CtrlHide(m_lblLtVal);
      CtrlHide(m_lblSlTag); CtrlHide(m_edtSL); CtrlHide(m_edtTP); CtrlHide(m_btnSLS);
      CtrlHide(m_lblTrTag); CtrlHide(m_btnTrMode);
      CtrlHide(m_lblTrTrig); CtrlHide(m_edtTTr); CtrlHide(m_lblTrDist); CtrlHide(m_edtTDi); CtrlHide(m_lblTrStep); CtrlHide(m_edtTSt);
      CtrlHide(m_lblBETag); CtrlHide(m_btnBE);
      CtrlHide(m_lblBeLine); CtrlHide(m_edtBEA); CtrlHide(m_lblBELock); CtrlHide(m_edtBEL);
      CtrlHide(m_lblEntrySec); CtrlHide(m_lblContTag); CtrlHide(m_btnCont);
      CtrlHide(m_lblMaxSTag); CtrlHide(m_edtMaxS); CtrlHide(m_btnMaxS);
      CtrlHide(m_lblMaxLTag); CtrlHide(m_edtMaxL); CtrlHide(m_btnMaxL);
      CtrlHide(m_lblBigMTag); CtrlHide(m_btnBigM);
      CtrlHide(m_lblExpTag); CtrlHide(m_lblUfmTag); CtrlHide(m_edtUfmPts); CtrlHide(m_btnUfm);
      CtrlHide(m_lblTmrTag); CtrlHide(m_btnTmr);
      CtrlHide(m_lblAucTag); CtrlHide(m_edtAuc); CtrlHide(m_btnAuc);
      CtrlHide(m_lblAamTag); CtrlHide(m_edtAam); CtrlHide(m_btnAam);
      CtrlHide(m_lblEma1Tag); CtrlHide(m_edtEma1); CtrlHide(m_btnEma1);
      CtrlHide(m_lblEma2Tag); CtrlHide(m_edtEma2); CtrlHide(m_btnEma2);
      CtrlHide(m_lblEma3Tag); CtrlHide(m_edtEma3); CtrlHide(m_btnEma3);
      CtrlHide(m_btnA1); CtrlHide(m_btnA2); CtrlHide(m_btnA3);
      for(int i=5; i<=m_idxSepAfterPresets; i++) CtrlHide(m_sep[i]);
      
   } else {
      CtrlHide(m_lblOsTag); CtrlHide(m_lblOsVal); CtrlHide(m_lblStVal);
      CtrlHide(m_lblEqTag); CtrlHide(m_lblStatEquity); CtrlHide(m_lblPlTag); CtrlHide(m_lblStatPL);
      CtrlHide(m_lblTotExpTag); CtrlHide(m_lblTotExpVal);
      CtrlHide(m_lblRtRrTag); CtrlHide(m_lblRtRrLoss); CtrlHide(m_lblRtRrPft); CtrlHide(m_lblRtRrRiskPc);
      for(int i=m_statusSepStart; i<=m_statusSepEnd; i++) CtrlHide(m_sep[i]);
      
      CtrlShow(m_lblMdTag); CtrlShowBtn(m_btnBoth); CtrlShowBtn(m_btnBuy); CtrlShowBtn(m_btnSell);
      CtrlShow(m_lblBalTag); CtrlShow(m_lblBalVal); CtrlShow(m_lblRskTag); CtrlShowEdit(m_edtRisk); CtrlShow(m_lblRPc);
      CtrlShow(m_lblRATag); CtrlShow(m_lblRAVal); CtrlShow(m_lblRwVal); CtrlShow(m_lblLtTag); CtrlShow(m_lblLtVal);
      CtrlShow(m_lblSlTag); CtrlShowEdit(m_edtSL); CtrlShowEdit(m_edtTP); CtrlShowBtn(m_btnSLS);
      CtrlShow(m_lblTrTag); CtrlShowBtn(m_btnTrMode);
      CtrlShow(m_lblTrTrig); CtrlShowEdit(m_edtTTr); CtrlShow(m_lblTrDist); CtrlShowEdit(m_edtTDi); CtrlShow(m_lblTrStep); CtrlShowEdit(m_edtTSt);
      CtrlShow(m_lblBETag); CtrlShowBtn(m_btnBE);
      CtrlShow(m_lblBeLine); CtrlShowEdit(m_edtBEA); CtrlShow(m_lblBELock); CtrlShowEdit(m_edtBEL);
      CtrlShow(m_lblEntrySec); CtrlShow(m_lblContTag); CtrlShowBtn(m_btnCont);
      CtrlShow(m_lblMaxSTag); CtrlShowEdit(m_edtMaxS); CtrlShowBtn(m_btnMaxS);
      CtrlShow(m_lblMaxLTag); CtrlShowEdit(m_edtMaxL); CtrlShowBtn(m_btnMaxL);
      CtrlShow(m_lblBigMTag); CtrlShowBtn(m_btnBigM);
      CtrlShow(m_lblExpTag); CtrlShow(m_lblUfmTag); CtrlShowEdit(m_edtUfmPts); CtrlShowBtn(m_btnUfm);
      CtrlShow(m_lblTmrTag); CtrlShowBtn(m_btnTmr);
      CtrlShow(m_lblAucTag); CtrlShowEdit(m_edtAuc); CtrlShowBtn(m_btnAuc);
      CtrlShow(m_lblAamTag); CtrlShowEdit(m_edtAam); CtrlShowBtn(m_btnAam);
      CtrlShow(m_lblEma1Tag); CtrlShowEdit(m_edtEma1); CtrlShowBtn(m_btnEma1);
      CtrlShow(m_lblEma2Tag); CtrlShowEdit(m_edtEma2); CtrlShowBtn(m_btnEma2);
      CtrlShow(m_lblEma3Tag); CtrlShowEdit(m_edtEma3); CtrlShowBtn(m_btnEma3);
      CtrlShowBtn(m_btnA1); CtrlShowBtn(m_btnA2); CtrlShowBtn(m_btnA3);
      for(int i=5; i<=m_idxSepAfterPresets; i++) CtrlShow(m_sep[i]);
      
      if(m_activeTab==TAB_MAIN) {
         m_btnA1.Text("Set mA"); m_btnA2.Text("Set mB"); m_btnA3.Text("Set mC");
         CtrlShow(m_lblGlobalTag); CtrlShowBtn(m_btnGlobal);
      } else if(m_activeTab==TAB_M2) {
         m_btnA1.Text("Set 2A"); m_btnA2.Text("Set 2B"); m_btnA3.Text("Set 2C");
         CtrlHide(m_lblGlobalTag); CtrlHide(m_btnGlobal);
      } else {
         m_btnA1.Text("Set 5A"); m_btnA2.Text("Set 5B"); m_btnA3.Text("Set 5C");
         CtrlHide(m_lblGlobalTag); CtrlHide(m_btnGlobal);
      }
   }
}

void CDashboard::OnA1(){ m_btnA1.Pressed(false); PresetIndex=0; PushCmd(CMD_PRESET); }
void CDashboard::OnA2(){ m_btnA2.Pressed(false); PresetIndex=1; PushCmd(CMD_PRESET); }
void CDashboard::OnA3(){ m_btnA3.Pressed(false); PresetIndex=2; PushCmd(CMD_PRESET); }






#endif
