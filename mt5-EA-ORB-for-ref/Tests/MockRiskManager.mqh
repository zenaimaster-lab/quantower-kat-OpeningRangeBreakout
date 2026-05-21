//+------------------------------------------------------------------+
//|                                             MockRiskManager.mqh |
//|                                  Copyright 2026, AI Agent        |
//+------------------------------------------------------------------+
#ifndef __MOCKRISKMANAGER_MQH__
#define __MOCKRISKMANAGER_MQH__

#include "../RiskManager.mqh"

//+------------------------------------------------------------------+
//| CMockRiskManager — Mock class for testing CRiskManager           |
//+------------------------------------------------------------------+
class CMockRiskManager : public CRiskManager
{
private:
   double            m_balance;
   double            m_tickValue;
   double            m_tickSize;
   double            m_point;
   double            m_minLot;
   double            m_maxLot;
   double            m_lotStep;
   int               m_spread;

public:
                     CMockRiskManager() : m_balance(10000),
                                          m_tickValue(1.0),
                                          m_tickSize(0.0001),
                                          m_point(0.0001),
                                          m_minLot(0.01),
                                          m_maxLot(100.0),
                                          m_lotStep(0.01),
                                          m_spread(0) {}

   void              SetBalance(double val)   { m_balance = val; }
   void              SetTickValue(double val) { m_tickValue = val; }
   void              SetTickSize(double val)  { m_tickSize = val; }
   void              SetPoint(double val)     { m_point = val; }
   void              SetMinLot(double val)    { m_minLot = val; }
   void              SetMaxLot(double val)    { m_maxLot = val; }
   void              SetLotStep(double val)   { m_lotStep = val; }
   void              SetSpread(int val)       { m_spread = val; }

   virtual double    GetBalance()             { return m_balance; }
   virtual double    GetTickValue(string s)   { return m_tickValue; }
   virtual double    GetTickSize(string s)    { return m_tickSize; }
   virtual double    GetPoint(string s)       { return m_point; }
   virtual double    GetMinLot(string s)      { return m_minLot; }
   virtual double    GetMaxLot(string s)      { return m_maxLot; }
   virtual double    GetLotStep(string s)     { return m_lotStep; }
   virtual int       GetSpread(string s)      { return m_spread; }
};

#endif // __MOCKRISKMANAGER_MQH__
