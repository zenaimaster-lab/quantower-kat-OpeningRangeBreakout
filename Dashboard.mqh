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
   CEdit m_lblTfTag, m_lblSlTag, m_lblMdTag, m_lblCmtTag;
   CEdit m_edtComment;
   CButton m_btnTf;
   
   CButton m_btnGlobal, m_btnToggleM2, m_btnToggleM5;
   CButton m_btnTabMain, m_btnTabM2, m_btnTabM5;
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
   CEdit m_lblExpTag;
   CButton m_btnExpire;
   CEdit m_edtExpCandles;
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
   bool m_slCandle, m_expEnabled, m_beOn;
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
   void OnExpire(); void OnBEToggle();
   void OnA1(); void OnA2(); void OnA3();


   void UpdMode(); void UpdTrail(); void UpdExpire(); void UpdBE();
   void UpdToggles(); void UpdTabs();

public:
   bool HandleDirectClick(const string &objName);

};

CDashboard::CDashboard() { m_slCandle=false; m_om=MODE_BOTH; m_tm=TM_OFF; m_activeTab=TAB_MAIN;
   m_expEnabled=false; m_utcOff=-4; m_beOn=false;
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
   ML(m_lblClkDate,"vCkD","(-- ---)",rx+108,cy,rw-108,CTRL_HEIGHT,CLR_TEXT_DIM,FONT_SIZE_MED); cy+=CTRL_HEIGHT+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   ML(m_lblNewsTag,"lNw","Next session:",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ML(m_lblNewsVal,"vNw","Loading...",rx,cy,rw,CTRL_HEIGHT,CLR_NEWS_RED); cy+=CTRL_HEIGHT+CTRL_GAP;
   
   // --- MAIN TOGGLES ---
   int thw=(cw-4)/2;
   MB(m_btnGlobal,"bGb","GLOBAL OVERRIDE: ON",cx,cy,cw,CTRL_HEIGHT+2,CLR_SUCCESS); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   MB(m_btnToggleM2,"bT2","2m: ON",cx,cy,thw,CTRL_HEIGHT+2,CLR_SUCCESS);
   MB(m_btnToggleM5,"bT5","5m: ON",cx+thw+4,cy,thw,CTRL_HEIGHT+2,CLR_SUCCESS); cy+=CTRL_HEIGHT+2+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;

   // --- TABS ---
   int tcw=(cw-8)/3;
   MB(m_btnTabMain,"bTmMain","MAIN",cx,cy,tcw,CTRL_HEIGHT+4,CLR_BTN_ON);
   MB(m_btnTabM2,"bTmM2","2m CONF",cx+tcw+4,cy,tcw,CTRL_HEIGHT+4,CLR_BTN_OFF);
   MB(m_btnTabM5,"bTmM5","5m CONF",cx+(tcw+4)*2,cy,tcw,CTRL_HEIGHT+4,CLR_BTN_OFF); cy+=CTRL_HEIGHT+4+SEC_PAD;
   cy+=SEC_PAD; MSep(si++,cx,cy,cw); cy+=SEP_GAP+SEC_PAD;



   // ── ORDER ──
   ML(m_lblTfTag,"lTf","Timeframe",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnTf,"bTf","M2",rx,cy,90,CTRL_HEIGHT,CLR_BTN_OFF);
   cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblCmtTag,"lCm","Comment",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtComment,"eCm","orb-trade",rx,cy,rw,CTRL_HEIGHT);
   cy+=CTRL_HEIGHT+CTRL_GAP;
   ML(m_lblSlTag,"lSl","SL / TP",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   ME(m_edtSL,"eSl","1500",rx,cy,55,CTRL_HEIGHT); ME(m_edtTP,"eTp","3000",rx+59,cy,55,CTRL_HEIGHT);
   MB(m_btnSLS,"bSs","SL by Candle",rx+120,cy,rw-120,CTRL_HEIGHT,CLR_BTN_ON); cy+=CTRL_HEIGHT+10;
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
   ML(m_lblTrTag,"lTr","Trailing mode",cx,cy,LABEL_WIDTH,CTRL_HEIGHT);
   MB(m_btnTrMode,"bTm","OFF",rx,cy,rw,CTRL_HEIGHT+2); cy+=CTRL_HEIGHT+2+CTRL_GAP;
   ML(m_lblTrTrig,"lTL","Trigger:",cx,cy,60,CTRL_HEIGHT);
   ME(m_edtTTr,"eTTr","30",cx+62,cy,35,CTRL_HEIGHT);
   ML(m_lblTrDist,"lDi","Distance:",cx+100,cy,70,CTRL_HEIGHT);
   ME(m_edtTDi,"eTDi","20",cx+172,cy,35,CTRL_HEIGHT);
   ML(m_lblTrStep,"lStp","Step:",cx+212,cy,40,CTRL_HEIGHT);
   ME(m_edtTSt,"eTSt","5",cx+254,cy,35,CTRL_HEIGHT); cy+=CTRL_HEIGHT+CTRL_GAP;
   MB(m_btnBE,"bBE","BE: OFF",cx,cy,cw,CTRL_HEIGHT+2,CLR_BTN_OFF); cy+=CTRL_HEIGHT+2+CTRL_GAP;
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
   SaveTab(m_activeTab);
   m_config.main.symbol = m_lblSym.Text();
   m_dirty = false;
   return m_config;
}

void CDashboard::SaveTab(ENUM_TAB tab)
{
   DashboardParams p;
   p.symbol = m_lblSym.Text();
   p.utcOffset = m_utcOff;
   string tf = m_btnTf.Text();
   if(tf=="M1") p.timeframe = PERIOD_M1;
   else if(tf=="M5") p.timeframe = PERIOD_M5;
   else if(tf=="M15") p.timeframe = PERIOD_M15;
   else p.timeframe = PERIOD_M2;
   
   p.comment = m_edtComment.Text();
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
   p.expireEnabled=m_expEnabled;
   p.expireCandles=(int)StringToInteger(m_edtExpCandles.Text());
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
   DashboardParams p;
   if (tab == TAB_MAIN) p = m_config.main;
   else if (tab == TAB_M2) p = m_config.m2;
   else if (tab == TAB_M5) p = m_config.m5;

   m_slCandle = p.slCandle;
   m_btnSLS.ColorBackground(m_slCandle?CLR_BTN_ON:CLR_BTN_OFF);
   
   if(p.timeframe == PERIOD_M1) m_btnTf.Text("M1");
   else if(p.timeframe == PERIOD_M5) m_btnTf.Text("M5");
   else if(p.timeframe == PERIOD_M15) m_btnTf.Text("M15");
   else m_btnTf.Text("M2");

   m_edtComment.Text(p.comment);
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
   m_expEnabled=p.expireEnabled; UpdExpire();
   m_edtExpCandles.Text(IntegerToString(p.expireCandles));
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

   if(objName == m_btnSLS.Name())           { OnSLS(); return true; }
   if(objName == m_btnBoth.Name())          { OnBoth(); return true; }
   if(objName == m_btnBuy.Name())           { OnBuyO(); return true; }
   if(objName == m_btnSell.Name())          { OnSellO(); return true; }
   if(objName == m_btnTrMode.Name())        { OnTrM(); return true; }
   if(objName == m_btnBE.Name())            { OnBEToggle(); return true; }
   if(objName == m_btnExpire.Name())        { OnExpire(); return true; }
   if(objName == m_btnA1.Name()) { OnA1(); return true; }
   if(objName == m_btnA2.Name()) { OnA2(); return true; }
   if(objName == m_btnA3.Name()) { OnA3(); return true; }
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

   return false;
}


void CDashboard::UpdateBalanceInfo(double b,double r,double rw,double l)
{ m_lblBalVal.Text("$"+FormatMoneyRound(b)); m_lblRAVal.Text("-$"+FormatMoneyRound(r));
  m_lblRwVal.Text("+$"+FormatMoneyRound(rw)); m_lblLtVal.Text(DoubleToString(l,2)); }
void CDashboard::UpdateNews(string s) { m_lblNewsVal.Text(s); }
void CDashboard::UpdateSymbol(string sym) { m_lblSym.Text(sym); MarkDirty(); }
void CDashboard::UpdateMarketStatus(bool o)
{ m_lblMktStatus.Text(o?"Market Open":"Market Closed"); m_lblMktStatus.Color(o?CLR_MKT_OPEN:CLR_MKT_CLOSED); }

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

void CDashboard::OnExpire() { m_btnExpire.Pressed(false); m_expEnabled=!m_expEnabled; UpdExpire(); MarkDirty(); }
void CDashboard::UpdExpire() { m_btnExpire.Text(m_expEnabled?"auto cancel all: ON":"auto cancel all: OFF");
   m_btnExpire.ColorBackground(m_expEnabled?CLR_WARNING:CLR_BTN_OFF); }
void CDashboard::OnToggleGlobal() { m_btnGlobal.Pressed(false); m_config.globalOverride=!m_config.globalOverride; UpdToggles(); MarkDirty(); }
void CDashboard::OnToggleM2() { m_btnToggleM2.Pressed(false); m_config.m2.isActive=!m_config.m2.isActive; UpdToggles(); MarkDirty(); }
void CDashboard::OnToggleM5() { m_btnToggleM5.Pressed(false); m_config.m5.isActive=!m_config.m5.isActive; UpdToggles(); MarkDirty(); }

void CDashboard::UpdToggles() {
   m_btnGlobal.Text(m_config.globalOverride ? "GLOBAL OVERRIDE: ON" : "GLOBAL OVERRIDE: OFF");
   m_btnGlobal.ColorBackground(m_config.globalOverride ? CLR_SUCCESS : CLR_BTN_OFF);
   m_btnToggleM2.Text(m_config.m2.isActive ? "2m: ON" : "2m: OFF");
   m_btnToggleM2.ColorBackground(m_config.m2.isActive ? CLR_SUCCESS : CLR_BTN_OFF);
   m_btnToggleM5.Text(m_config.m5.isActive ? "5m: ON" : "5m: OFF");
   m_btnToggleM5.ColorBackground(m_config.m5.isActive ? CLR_SUCCESS : CLR_BTN_OFF);
}

void CDashboard::OnTabMain() { m_btnTabMain.Pressed(false); SaveTab(m_activeTab); m_activeTab=TAB_MAIN; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }
void CDashboard::OnTabM2() { m_btnTabM2.Pressed(false); SaveTab(m_activeTab); m_activeTab=TAB_M2; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }
void CDashboard::OnTabM5() { m_btnTabM5.Pressed(false); SaveTab(m_activeTab); m_activeTab=TAB_M5; LoadTab(m_activeTab); UpdTabs(); MarkDirty(); }

void CDashboard::UpdTabs() {
   m_btnTabMain.ColorBackground(m_activeTab==TAB_MAIN ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnTabM2.ColorBackground(m_activeTab==TAB_M2 ? CLR_BTN_ON : CLR_BTN_OFF);
   m_btnTabM5.ColorBackground(m_activeTab==TAB_M5 ? CLR_BTN_ON : CLR_BTN_OFF);
   
   if(m_activeTab==TAB_MAIN) {
      m_btnA1.Text("Set mA"); m_btnA2.Text("Set mB"); m_btnA3.Text("Set mC");
      CtrlShow(m_lblOsTag); CtrlShow(m_lblOsVal); CtrlShow(m_lblStVal);
      CtrlShow(m_lblEqTag); CtrlShow(m_lblStatEquity); CtrlShow(m_lblPlTag); CtrlShow(m_lblStatPL);
      CtrlShow(m_lblTotExpTag); CtrlShow(m_lblTotExpVal);
      CtrlShow(m_lblRtRrTag); CtrlShow(m_lblRtRrLoss); CtrlShow(m_lblRtRrPft); CtrlShow(m_lblRtRrRiskPc);
   } else if(m_activeTab==TAB_M2) {
      m_btnA1.Text("Set 2A"); m_btnA2.Text("Set 2B"); m_btnA3.Text("Set 2C");
      CtrlHide(m_lblOsTag); CtrlHide(m_lblOsVal); CtrlHide(m_lblStVal);
      CtrlHide(m_lblEqTag); CtrlHide(m_lblStatEquity); CtrlHide(m_lblPlTag); CtrlHide(m_lblStatPL);
      CtrlHide(m_lblTotExpTag); CtrlHide(m_lblTotExpVal);
      CtrlHide(m_lblRtRrTag); CtrlHide(m_lblRtRrLoss); CtrlHide(m_lblRtRrPft); CtrlHide(m_lblRtRrRiskPc);
   } else {
      m_btnA1.Text("Set 5A"); m_btnA2.Text("Set 5B"); m_btnA3.Text("Set 5C");
      CtrlHide(m_lblOsTag); CtrlHide(m_lblOsVal); CtrlHide(m_lblStVal);
      CtrlHide(m_lblEqTag); CtrlHide(m_lblStatEquity); CtrlHide(m_lblPlTag); CtrlHide(m_lblStatPL);
      CtrlHide(m_lblTotExpTag); CtrlHide(m_lblTotExpVal);
      CtrlHide(m_lblRtRrTag); CtrlHide(m_lblRtRrLoss); CtrlHide(m_lblRtRrPft); CtrlHide(m_lblRtRrRiskPc);
   }
}

void CDashboard::OnA1(){ m_btnA1.Pressed(false); PresetIndex=0; PushCmd(CMD_PRESET); }
void CDashboard::OnA2(){ m_btnA2.Pressed(false); PresetIndex=1; PushCmd(CMD_PRESET); }
void CDashboard::OnA3(){ m_btnA3.Pressed(false); PresetIndex=2; PushCmd(CMD_PRESET); }






#endif
