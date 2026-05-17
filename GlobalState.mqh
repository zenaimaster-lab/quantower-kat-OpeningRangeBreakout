//+------------------------------------------------------------------+
//|                                                  GlobalState.mqh   |
//|              Global state object (single instance via extern)      |
//+------------------------------------------------------------------+
#ifndef __GLOBALSTATE_MQH__
#define __GLOBALSTATE_MQH__

//+------------------------------------------------------------------+
//| CGlobalState — single source of truth for EA-wide mutable state    |
//+------------------------------------------------------------------+
class CGlobalState
{
private:
   int    m_magic;
   // Global aggregate W/L
   int    m_winsToday;
   int    m_lossesToday;
   // Per-timeframe W/L (0=2m, 1=5m, 2=15m)
   int    m_winsTF[3];
   int    m_lossesTF[3];

public:
   CGlobalState() : m_magic(0), m_winsToday(0), m_lossesToday(0)
   {
      for(int i=0; i<3; i++) { m_winsTF[i]=0; m_lossesTF[i]=0; }
   }

   int    Magic() const          { return m_magic; }
   void   SetMagic(int v)        { m_magic = v; }

   // Global aggregate (sum of all TFs)
   int    WinsToday() const      { return m_winsToday; }
   void   SetWinsToday(int v)    { m_winsToday = v; }
   int    LossesToday() const    { return m_lossesToday; }
   void   SetLossesToday(int v)  { m_lossesToday = v; }

   // Per-timeframe: idx 0=2m, 1=5m, 2=15m
   int    WinsTodayTF(int idx) const     { return (idx>=0 && idx<3) ? m_winsTF[idx] : 0; }
   void   SetWinsTodayTF(int idx, int v) { if(idx>=0 && idx<3) m_winsTF[idx] = v; }
   int    LossesTodayTF(int idx) const     { return (idx>=0 && idx<3) ? m_lossesTF[idx] : 0; }
   void   SetLossesTodayTF(int idx, int v) { if(idx>=0 && idx<3) m_lossesTF[idx] = v; }
};

extern CGlobalState g_gs;

#endif // __GLOBALSTATE_MQH__
