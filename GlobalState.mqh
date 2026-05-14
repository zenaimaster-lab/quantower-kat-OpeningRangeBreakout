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
   int    m_winsToday;
   int    m_lossesToday;

public:
   CGlobalState() : m_magic(0), m_winsToday(0), m_lossesToday(0) {}

   int    Magic() const          { return m_magic; }
   void   SetMagic(int v)        { m_magic = v; }

   int    WinsToday() const      { return m_winsToday; }
   void   SetWinsToday(int v)    { m_winsToday = v; }

   int    LossesToday() const    { return m_lossesToday; }
   void   SetLossesToday(int v)  { m_lossesToday = v; }
};

extern CGlobalState g_gs;

#endif // __GLOBALSTATE_MQH__
