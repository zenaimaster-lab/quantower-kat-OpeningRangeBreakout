//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                          KAT Opening Range Breakout EA — Lot Size Calculator  |
//|                                                      Version 2.0 |
//+------------------------------------------------------------------+
#ifndef __RISKMANAGER_MQH__
#define __RISKMANAGER_MQH__

#include "Defines.mqh"

//+------------------------------------------------------------------+
//| CRiskManager — calculates position size from % risk               |
//+------------------------------------------------------------------+
class CRiskManager
{
public:
                     CRiskManager() {}
                    ~CRiskManager() {}
   
   //--- Calculate lot size based on balance % risk and SL distance
   double            CalcLotSize(string symbol, double riskPercent, int slPoints, bool silent=false);
   
   //--- Get account properties
   virtual double    GetBalance();

   //--- Get symbol properties
   virtual double    GetTickValue(string symbol);
   virtual double    GetTickSize(string symbol);
   virtual double    GetPoint(string symbol);
   virtual double    GetMinLot(string symbol);
   virtual double    GetMaxLot(string symbol);
   virtual double    GetLotStep(string symbol);
   virtual int       GetSpread(string symbol);
   
   //--- Normalize lot to broker constraints
   double            NormalizeLot(string symbol, double lots);
   
   //--- Calculate risk/reward info for dashboard display
   void              CalcRiskRewardInfo(string symbol, bool riskModeOn, double riskPercent, double fixLot, int slPts, int tpPts,
                                        double &outBalance, double &outRiskAmt, 
                                        double &outRewardAmt, double &outLotSize);
};

//+------------------------------------------------------------------+
//| Calculate lot size from risk parameters                           |
//+------------------------------------------------------------------+
double CRiskManager::CalcLotSize(string symbol, double riskPercent, int slPoints, bool silent)
{
   if(riskPercent <= 0 || slPoints <= 0) return GetMinLot(symbol);
   
   // Account balance risk amount
   double balance    = GetBalance();
   double riskAmount = balance * (riskPercent / 100.0);
   
   // Adjust SL for spread if needed
   int adjustedSL = slPoints;
   
   // Get symbol tick properties
   double tickValue = GetTickValue(symbol);
   double tickSize  = GetTickSize(symbol);
   double point     = GetPoint(symbol);
   
   if(tickValue <= 0 || tickSize <= 0 || point <= 0)
   {
      PrintFormat("[RiskManager] ERROR: Invalid symbol properties for %s (TV=%.5f TS=%.5f P=%.5f)", 
                  symbol, tickValue, tickSize, point);
      return GetMinLot(symbol);
   }
   
   // Value of 1 point for 1 lot
   double valuePerPoint = tickValue / tickSize * point;
   
   // Loss per lot at SL distance
   double lossPerLot = adjustedSL * valuePerPoint;
   
   if(lossPerLot <= 0)
   {
      PrintFormat("[RiskManager] ERROR: lossPerLot <= 0 for %s", symbol);
      return GetMinLot(symbol);
   }
   
   // Calculate raw lot size
   double lotSize = riskAmount / lossPerLot;
   
   // Normalize to broker constraints
   lotSize = NormalizeLot(symbol, lotSize);
   
   if(!silent)
      PrintFormat("[RiskManager] %s | Risk=%.1f%% | SL=%d pts | Lot=%.2f",
               symbol, riskPercent, adjustedSL, lotSize);
   
   return lotSize;
}

//+------------------------------------------------------------------+
double CRiskManager::GetBalance()
{
   return AccountInfoDouble(ACCOUNT_BALANCE);
}

//+------------------------------------------------------------------+
double CRiskManager::GetTickValue(string symbol)
{
   return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
}

//+------------------------------------------------------------------+
double CRiskManager::GetTickSize(string symbol)
{
   return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
}

//+------------------------------------------------------------------+
double CRiskManager::GetPoint(string symbol)
{
   return SymbolInfoDouble(symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
double CRiskManager::GetMinLot(string symbol)
{
   return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
}

//+------------------------------------------------------------------+
double CRiskManager::GetMaxLot(string symbol)
{
   return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
}

//+------------------------------------------------------------------+
double CRiskManager::GetLotStep(string symbol)
{
   return SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
}

//+------------------------------------------------------------------+
int CRiskManager::GetSpread(string symbol)
{
   return (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
}

//+------------------------------------------------------------------+
//| Normalize lot size to broker min/max/step                         |
//+------------------------------------------------------------------+
double CRiskManager::NormalizeLot(string symbol, double lots)
{
   double minLot  = GetMinLot(symbol);
   double maxLot  = GetMaxLot(symbol);
   double stepLot = GetLotStep(symbol);
   
   if(stepLot <= 0) stepLot = 0.01;
   
   // Round down to nearest step with epsilon to handle precision issues
   lots = MathFloor(lots / stepLot + 0.000000001) * stepLot;
   
   // Clamp to min/max
   lots = MathMax(minLot, MathMin(maxLot, lots));
   
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Calculate risk/reward monetary values for display                  |
//+------------------------------------------------------------------+
void CRiskManager::CalcRiskRewardInfo(string symbol, bool riskModeOn, double riskPercent, double fixLot, int slPts, int tpPts,
                                      double &outBalance, double &outRiskAmt, 
                                      double &outRewardAmt, double &outLotSize)
{
   outBalance   = GetBalance();
   outRiskAmt   = 0;
   outRewardAmt = 0;
   outLotSize   = 0;
   
   if(symbol == "" || slPts <= 0) return;
   
   if(riskModeOn)
      outLotSize = CalcLotSize(symbol, riskPercent, slPts + GetSpread(symbol), true);
   else
      outLotSize = NormalizeLot(symbol, fixLot);
   
   double tickValue = GetTickValue(symbol);
   double tickSize  = GetTickSize(symbol);
   double point     = GetPoint(symbol);
   
   if(tickValue > 0 && tickSize > 0 && point > 0)
   {
      double valuePerPoint = tickValue / tickSize * point;
      outRiskAmt = outLotSize * (slPts + GetSpread(symbol)) * valuePerPoint;
      int adjTP = tpPts + GetSpread(symbol);
      outRewardAmt = outLotSize * adjTP * valuePerPoint;
   }
}

#endif // __RISKMANAGER_MQH__
