//+------------------------------------------------------------------+
//|                                                  GlobalState.mqh   |
//|              Singleton global state (replaces extern globals)      |
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

   CGlobalState() : m_magic(0), m_winsToday(0), m_lossesToday(0) {}
   CGlobalState(const CGlobalState &); // disable copy
   void operator=(const CGlobalState &); // disable assign

public:
   static CGlobalState *Instance()
   {
      static CGlobalState instance;
      return &instance;
   }

   int    Magic() const          { return m_magic; }
   void   SetMagic(int v)        { m_magic = v; }

   int    WinsToday() const      { return m_winsToday; }
   void   SetWinsToday(int v)    { m_winsToday = v; }

   int    LossesToday() const    { return m_lossesToday; }
   void   SetLossesToday(int v)  { m_lossesToday = v; }
};

#endif // __GLOBALSTATE_MQH__
