//+------------------------------------------------------------------+
//|                                           OrigamiManager.mqh |
//|                      KAT Strike — Mathematical Origami     |
//|                                                      Version 0.65 |
//+------------------------------------------------------------------+
#ifndef __ORIGAMI_MANAGER_MQH__
#define __ORIGAMI_MANAGER_MQH__

#include "Defines.mqh"

struct OrigamiStep
{
   double triggerPrice;
   double lotSize;
   bool   isTriggered;
   double slPrice;
   
   OrigamiStep()
   {
      triggerPrice = 0.0;
      lotSize = 0.0;
      isTriggered = false;
      slPrice = 0.0;
   }
};

class COrigamiManager
{
private:
   OrigamiStep m_steps[3];
   bool           m_isActive;
   int            m_orderType;
   double         m_entryPrice;
   double         m_tpPrice;
   double         m_baseLotSize;
   string         m_symbol;
   double         m_targetGrowthPct;
   double         m_riskPct;
   double         m_maxRiskPct;
   int            m_slPoints;
   double         m_pct[3];
   bool           m_linesDrawn;
   double         m_marginSafetyPct;  // v1.51: DIAD Margin of Safety (% of T)
   double         m_diadConstC;       // v1.50: DIAD equalization constant ($)
   bool           m_diadFallback;     // v1.50: true if solver failed, using equal-split

   // v1.50: DIAD algebraic solver — computes per-step lots via linear algebra
   bool  SolveDIAD(double L0, double targetAmt, double V,
                   double P0, double P1, double P2, double P3,
                   double E1, double E2, double E3,
                   double S1, double S2, double S3,
                   double &outL1, double &outL2, double &outL3, double &outC);

public:
   COrigamiManager();
   ~COrigamiManager();

   void  Init();
   void  SetMarginSafety(double pct) { m_marginSafetyPct = pct; }
   double GetMarginSafety() const    { return m_marginSafetyPct; }
   double GetDiadConstC() const    { return m_diadConstC; }
   bool   IsDiadFallback() const   { return m_diadFallback; }
   
   void  CalculateOrigami(double balance, double targetGrowthPct, double riskPct, double maxRiskPct, 
                          double entryPrice, double tpPrice, int slPoints, 
                          int orderType, string symbol,
                          double pct1=35.0, double pct2=50.0, double pct3=65.0);
                          
   void  CalculateOrigamiFromExisting(double balance, double targetGrowthPct, double riskPct, double maxRiskPct, 
                                      double entryPrice, double tpPrice, int slPoints, 
                                      double existingVolume, int orderType, string symbol,
                                      double pct1=35.0, double pct2=50.0, double pct3=65.0);
                                      
   void  ApplyNow(const DashboardParams &p);
                          
   bool  IsActive() const { return m_isActive; }
   int   GetOrderType() const { return m_orderType; }
   double GetTP() const { return m_tpPrice; }
   double GetEntry() const { return m_entryPrice; }
   double GetBaseLot() const { return m_baseLotSize; }
   int   GetSLPoints() const { return m_slPoints; }
   double GetRiskPct() const { return m_riskPct; }
   double GetTargetGrowthPct() const { return m_targetGrowthPct; }
   string GetSymbol() const { return m_symbol; }
   void  Reset();
   
   bool  GetStepInfo(int idx, double &trigger, double &lot, bool &triggered) const;
   int   GetTriggeredCount() const;
   double CheckThresholds(double currentPrice);
   bool  RecalculateTP(double newTpPrice);
   double GetCurrentSLTarget();

   // v0.2: Chart line drawing
   void  DrawOrigamiLines();
   void  RemoveOrigamiLines();

   virtual double GetTickValue(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE); }
   virtual double GetTickSize(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE); }
   virtual double GetPoint(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_POINT); }
   virtual double GetMinLot(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN); }
   virtual double GetLotStep(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP); }
};

//+------------------------------------------------------------------+
COrigamiManager::COrigamiManager()
{
   m_isActive = false;
   m_linesDrawn = false;
   m_marginSafetyPct = 10.0;
   m_diadConstC = 0;
   m_diadFallback = false;
}

COrigamiManager::~COrigamiManager()
{
   RemoveOrigamiLines();
}

void COrigamiManager::Init()
{
   Reset();
}

void COrigamiManager::Reset()
{
   m_isActive = false;
   for(int i=0; i<3; i++) m_steps[i].isTriggered = false;
   RemoveOrigamiLines();
}

void COrigamiManager::CalculateOrigami(double balance, double targetGrowthPct, double riskPct, double maxRiskPct,
                                          double entryPrice, double tpPrice, int slPoints, 
                                          int orderType, string symbol,
                                          double pct1, double pct2, double pct3)
{
   Reset();
   if(entryPrice == 0 || tpPrice == 0 || entryPrice == tpPrice) return;
   
   m_orderType = orderType;
   m_entryPrice = entryPrice;
   m_tpPrice = tpPrice;
   m_symbol = symbol;
   m_targetGrowthPct = targetGrowthPct;
   m_riskPct = riskPct;
   m_maxRiskPct = maxRiskPct;
   m_slPoints = slPoints;
   m_pct[0] = pct1 / 100.0;
   m_pct[1] = pct2 / 100.0;
   m_pct[2] = pct3 / 100.0;
   
   double tickSize = GetTickSize(symbol);
   double tickValue = GetTickValue(symbol);
   double point = GetPoint(symbol);
   if(tickSize == 0 || tickValue == 0 || point == 0) return;
   
   // V = pip value per lot (convert tick-based to pip-based)
   double V = tickValue * (point / tickSize);
   
   double totalDistPrice = MathAbs(tpPrice - entryPrice);
   double totalDistPips = totalDistPrice / point;
   
   // Base lot (L0) — risk-limited
   double maxRiskAmt = balance * (riskPct / 100.0);
   double slDist = slPoints * point;
   double baseLot = maxRiskAmt / ((slDist / tickSize) * tickValue);
   
   double minLot = GetMinLot(symbol);
   double lotStep = GetLotStep(symbol);
   baseLot = MathFloor(baseLot / lotStep + 0.000000001) * lotStep;
   if(baseLot < minLot) baseLot = minLot;
   m_baseLotSize = baseLot;
   
   double targetProfitAmt = balance * (targetGrowthPct / 100.0);
   
   // DIAD parameters (all in points, measured from entry)
   double T = totalDistPips;
   double E1 = T * m_pct[0];
   double E2 = T * m_pct[1];
   double E3 = T * m_pct[2];
   
   // Margin of Safety: SL is placed this % of T behind each add-in entry
   double mos = T * (m_marginSafetyPct / 100.0);
   double S1 = E1 - mos;  if(S1 < 0) S1 = 0;
   double S2 = E2 - mos;  if(S2 < 0) S2 = 0;
   double S3 = E3 - mos;  if(S3 < 0) S3 = 0;
   
   // Profit distances (points remaining from each entry to TP)
   // NOTE: No spread deduction — entryPrice already includes spread (filled at ASK/BID)
   double P0 = T;
   double P1 = T - E1;
   double P2 = T - E2;
   double P3 = T - E3;
   
   // Solve DIAD system
   double L1 = 0, L2 = 0, L3 = 0, C = 0;
   bool solved = SolveDIAD(baseLot, targetProfitAmt, V, P0, P1, P2, P3, E1, E2, E3, S1, S2, S3, L1, L2, L3, C);
   
   if(!solved)
   {
      m_diadFallback = true;
      double effectiveDist = (1.0 - m_pct[0]) + (1.0 - m_pct[1]) + (1.0 - m_pct[2]);
      effectiveDist *= totalDistPrice;
      double remaining = targetProfitAmt - baseLot * (totalDistPrice / tickSize) * tickValue;
      double addInLot = (remaining > 0 && effectiveDist > 0) ? remaining / ((effectiveDist / tickSize) * tickValue) : minLot;
      addInLot = MathFloor(addInLot / lotStep + 0.000000001) * lotStep;
      if(addInLot < minLot) addInLot = minLot;
      L1 = L2 = L3 = addInLot;
      C = 0;
      PrintFormat("[Origami] DIAD solver failed — using equal-split fallback");
   }
   else
   {
      m_diadFallback = false;
   }
   
   // Normalize lots
   L1 = MathFloor(L1 / lotStep + 0.000000001) * lotStep; if(L1 < minLot) L1 = minLot;
   L2 = MathFloor(L2 / lotStep + 0.000000001) * lotStep; if(L2 < minLot) L2 = minLot;
   L3 = MathFloor(L3 / lotStep + 0.000000001) * lotStep; if(L3 < minLot) L3 = minLot;
   m_diadConstC = C;
   
   int dir = (orderType == ORDER_TYPE_BUY) ? 1 : -1;
   
   // Step 1
   m_steps[0].triggerPrice = entryPrice + (dir * totalDistPrice * m_pct[0]);
   m_steps[0].lotSize = L1;
   m_steps[0].slPrice = entryPrice + (dir * S1 * point);
   // Step 2
   m_steps[1].triggerPrice = entryPrice + (dir * totalDistPrice * m_pct[1]);
   m_steps[1].lotSize = L2;
   m_steps[1].slPrice = entryPrice + (dir * S2 * point);
   // Step 3
   m_steps[2].triggerPrice = entryPrice + (dir * totalDistPrice * m_pct[2]);
   m_steps[2].lotSize = L3;
   m_steps[2].slPrice = entryPrice + (dir * S3 * point);
   
   m_isActive = true;
   DrawOrigamiLines();
   
   PrintFormat("[Origami] DIAD v1.51 | BaseLot=%.2f | L1=%.2f L2=%.2f L3=%.2f | C=%.2f | MoS=%.1f%%",
               baseLot, L1, L2, L3, C, m_marginSafetyPct);
}

double COrigamiManager::CheckThresholds(double currentPrice)
{
   if(!m_isActive) return 0.0;
   
   for(int i=0; i<3; i++)
   {
      if(!m_steps[i].isTriggered && m_steps[i].lotSize > 0)
      {
         bool isCrossed = false;
         if(m_orderType == ORDER_TYPE_BUY && currentPrice >= m_steps[i].triggerPrice) isCrossed = true;
         if(m_orderType == ORDER_TYPE_SELL && currentPrice <= m_steps[i].triggerPrice) isCrossed = true;
         
         if(isCrossed)
         {
            m_steps[i].isTriggered = true;
            PrintFormat("[Origami] Step %d triggered at %.5f (Lot: %.2f)", i+1, currentPrice, m_steps[i].lotSize);
            DrawOrigamiLines(); // Refresh lines to show triggered state
            return m_steps[i].lotSize;
         }
      }
   }
   return 0.0;
}

// v1.50: Always use DIAD-computed SL — when step N fires, move ALL SLs to S_N
double COrigamiManager::GetCurrentSLTarget()
{
   if(!m_isActive) return 0.0;
   
   int lastTriggered = -1;
   for(int i=0; i<3; i++)
      if(m_steps[i].isTriggered) lastTriggered = i;
   
   if(lastTriggered == -1) return 0.0;
   
   return m_steps[lastTriggered].slPrice;
}

bool COrigamiManager::RecalculateTP(double newTpPrice)
{
   if(!m_isActive || m_entryPrice == 0) return false;
   
   int dir = (m_orderType == ORDER_TYPE_BUY) ? 1 : -1;
   if(dir == 1 && newTpPrice <= m_entryPrice) return false;
   if(dir == -1 && newTpPrice >= m_entryPrice) return false;
   
   double oldTP = m_tpPrice;
   m_tpPrice = newTpPrice;
   double totalDist = MathAbs(newTpPrice - m_entryPrice);
   
   double tickSize = GetTickSize(m_symbol);
   double tickValue = GetTickValue(m_symbol);
   if(tickSize == 0 || tickValue == 0) return false;
   
   double minLot = GetMinLot(m_symbol);
   double lotStep = GetLotStep(m_symbol);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double targetProfitAmt = balance * (m_targetGrowthPct / 100.0);
   
   double securedProfit = m_baseLotSize * (totalDist / tickSize) * tickValue;
   for(int i=0; i<3; i++)
   {
      if(m_steps[i].isTriggered)
      {
         double stepDist = MathAbs(newTpPrice - m_steps[i].triggerPrice);
         securedProfit += m_steps[i].lotSize * (stepDist / tickSize) * tickValue;
      }
   }
   
   double remainingProfit = targetProfitAmt - securedProfit;
   
   double totalEffectiveDist = 0;
   int untriggeredCount = 0;
   for(int i=0; i<3; i++)
   {
      if(!m_steps[i].isTriggered)
      {
         m_steps[i].triggerPrice = m_entryPrice + (dir * totalDist * m_pct[i]);
         m_steps[i].slPrice = m_steps[i].triggerPrice;
         double stepDist = MathAbs(newTpPrice - m_steps[i].triggerPrice);
         totalEffectiveDist += stepDist;
         untriggeredCount++;
      }
   }
   
   if(untriggeredCount == 3)
   {
      CalculateOrigamiFromExisting(balance, m_targetGrowthPct, m_riskPct, m_maxRiskPct, m_entryPrice, newTpPrice, m_slPoints, m_baseLotSize, m_orderType, m_symbol, m_pct[0]*100, m_pct[1]*100, m_pct[2]*100);
      return true;
   }
   
   if(untriggeredCount > 0 && totalEffectiveDist > 0 && remainingProfit > 0)
   {
      double addInLot = remainingProfit / ((totalEffectiveDist / tickSize) * tickValue);
      addInLot = MathFloor(addInLot / lotStep + 0.000000001) * lotStep;
      if(addInLot < minLot) addInLot = minLot;
      for(int i=0; i<3; i++)
         if(!m_steps[i].isTriggered) m_steps[i].lotSize = addInLot;
   }
   else
   {
      for(int i=0; i<3; i++)
         if(!m_steps[i].isTriggered) m_steps[i].lotSize = minLot;
   }
   
   DrawOrigamiLines(); // Refresh chart lines
   return true;
}

bool COrigamiManager::GetStepInfo(int idx, double &trigger, double &lot, bool &triggered) const
{
   if(idx < 0 || idx >= 3) return false;
   trigger = m_steps[idx].triggerPrice;
   lot = m_steps[idx].lotSize;
   triggered = m_steps[idx].isTriggered;
   return true;
}

int COrigamiManager::GetTriggeredCount() const
{
   int c = 0;
   for(int i=0; i<3; i++) if(m_steps[i].isTriggered) c++;
   return c;
}

//+------------------------------------------------------------------+
// v0.2: Draw origami add-in level lines on chart
//+------------------------------------------------------------------+
void COrigamiManager::DrawOrigamiLines()
{
   RemoveOrigamiLines();
   if(!m_isActive) return;
   
   long chartId = ChartID();
   
   for(int i=0; i<3; i++)
   {
      string lineName = "ORIGAMI_STEP_" + IntegerToString(i+1);
      string labelName = "ORIGAMI_LABEL_" + IntegerToString(i+1);
      
      double price = m_steps[i].triggerPrice;
      if(price <= 0) continue;
      
      // Draw horizontal line
      ObjectCreate(chartId, lineName, OBJ_HLINE, 0, 0, price);
      
      color lineClr;
      int lineStyle;
      if(m_steps[i].isTriggered)
      {
         lineClr = C'40,200,130'; // green = fired
         lineStyle = STYLE_SOLID;
      }
      else
      {
         lineClr = C'240,160,40'; // orange = pending
         lineStyle = STYLE_DOT;
      }
      
      ObjectSetInteger(chartId, lineName, OBJPROP_COLOR, lineClr);
      ObjectSetInteger(chartId, lineName, OBJPROP_STYLE, lineStyle);
      ObjectSetInteger(chartId, lineName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(chartId, lineName, OBJPROP_BACK, true);
      ObjectSetInteger(chartId, lineName, OBJPROP_SELECTABLE, false);
      ObjectSetString(chartId, lineName, OBJPROP_TOOLTIP, 
         StringFormat("Origami Step %d: %.2f lots @ %.0f%%", i+1, m_steps[i].lotSize, m_pct[i]*100));
      
      // Draw text label on chart
      string labelText = StringFormat("%.2f lots @ %.0f%%", m_steps[i].lotSize, m_pct[i]*100);
      if(m_steps[i].isTriggered) labelText = "✓ " + labelText;
      
      ObjectCreate(chartId, labelName, OBJ_TEXT, 0, TimeCurrent(), price);
      ObjectSetString(chartId, labelName, OBJPROP_TEXT, labelText);
      ObjectSetString(chartId, labelName, OBJPROP_FONT, "Segoe UI");
      ObjectSetInteger(chartId, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(chartId, labelName, OBJPROP_COLOR, lineClr);
      ObjectSetInteger(chartId, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      ObjectSetInteger(chartId, labelName, OBJPROP_SELECTABLE, false);
   }
   
   m_linesDrawn = true;
   ChartRedraw(chartId);
}

void COrigamiManager::RemoveOrigamiLines()
{
   if(!m_linesDrawn) return;
   long chartId = ChartID();
   for(int i=0; i<3; i++)
   {
      ObjectDelete(chartId, "ORIGAMI_STEP_" + IntegerToString(i+1));
      ObjectDelete(chartId, "ORIGAMI_LABEL_" + IntegerToString(i+1));
   }
   m_linesDrawn = false;
   ChartRedraw(chartId);
}

void COrigamiManager::CalculateOrigamiFromExisting(double balance, double targetGrowthPct, double riskPct, double maxRiskPct, 
                                          double entryPrice, double tpPrice, int slPoints, 
                                          double existingVolume, int orderType, string symbol,
                                          double pct1, double pct2, double pct3)
{
   Reset();
   if(entryPrice == 0 || tpPrice == 0 || entryPrice == tpPrice || existingVolume <= 0) return;
   
   m_orderType = orderType;
   m_entryPrice = entryPrice;
   m_tpPrice = tpPrice;
   m_symbol = symbol;
   m_targetGrowthPct = targetGrowthPct;
   m_riskPct = riskPct;
   m_maxRiskPct = maxRiskPct;
   m_slPoints = slPoints;
   m_baseLotSize = existingVolume;
   
   m_pct[0] = pct1 / 100.0;
   m_pct[1] = pct2 / 100.0;
   m_pct[2] = pct3 / 100.0;
   
   double tickSize = GetTickSize(symbol);
   double tickValue = GetTickValue(symbol);
   double point = GetPoint(symbol);
   if(tickSize == 0 || tickValue == 0 || point == 0) return;
   
   double V = tickValue * (point / tickSize);
   double totalDistPrice = MathAbs(tpPrice - entryPrice);
   double totalDistPips = totalDistPrice / point;
   
   double minLot = GetMinLot(symbol);
   double lotStep = GetLotStep(symbol);
   
   double targetProfitAmt = balance * (targetGrowthPct / 100.0);
   
   double T = totalDistPips;
   double E1 = T * m_pct[0], E2 = T * m_pct[1], E3 = T * m_pct[2];
   double mos = T * (m_marginSafetyPct / 100.0);
   double S1 = E1 - mos; if(S1 < 0) S1 = 0;
   double S2 = E2 - mos; if(S2 < 0) S2 = 0;
   double S3 = E3 - mos; if(S3 < 0) S3 = 0;
   // No spread deduction — entryPrice already includes spread
   double P0 = T;
   double P1 = T - E1, P2 = T - E2, P3 = T - E3;
   
   double L1 = 0, L2 = 0, L3 = 0, C = 0;
   bool solved = SolveDIAD(m_baseLotSize, targetProfitAmt, V, P0, P1, P2, P3, E1, E2, E3, S1, S2, S3, L1, L2, L3, C);
   
   if(!solved)
   {
      m_diadFallback = true;
      double effectiveDist = (1.0 - m_pct[0]) + (1.0 - m_pct[1]) + (1.0 - m_pct[2]);
      effectiveDist *= totalDistPrice;
      double remaining = targetProfitAmt - m_baseLotSize * (totalDistPrice / tickSize) * tickValue;
      double addInLot = (remaining > 0 && effectiveDist > 0) ? remaining / ((effectiveDist / tickSize) * tickValue) : minLot;
      addInLot = MathFloor(addInLot / lotStep + 0.000000001) * lotStep;
      if(addInLot < minLot) addInLot = minLot;
      L1 = L2 = L3 = addInLot;
      C = 0;
      PrintFormat("[Origami] DIAD solver failed — using equal-split fallback (ApplyNow)");
   }
   else
   {
      m_diadFallback = false;
   }
   
   L1 = MathFloor(L1 / lotStep + 0.000000001) * lotStep; if(L1 < minLot) L1 = minLot;
   L2 = MathFloor(L2 / lotStep + 0.000000001) * lotStep; if(L2 < minLot) L2 = minLot;
   L3 = MathFloor(L3 / lotStep + 0.000000001) * lotStep; if(L3 < minLot) L3 = minLot;
   m_diadConstC = C;
   
   int dir = (orderType == ORDER_TYPE_BUY) ? 1 : -1;
   
   m_steps[0].triggerPrice = entryPrice + (dir * totalDistPrice * m_pct[0]);
   m_steps[0].lotSize = L1;
   m_steps[0].slPrice = entryPrice + (dir * S1 * point);
   m_steps[1].triggerPrice = entryPrice + (dir * totalDistPrice * m_pct[1]);
   m_steps[1].lotSize = L2;
   m_steps[1].slPrice = entryPrice + (dir * S2 * point);
   m_steps[2].triggerPrice = entryPrice + (dir * totalDistPrice * m_pct[2]);
   m_steps[2].lotSize = L3;
   m_steps[2].slPrice = entryPrice + (dir * S3 * point);
   
   m_isActive = true;
   DrawOrigamiLines();
   
   PrintFormat("[Origami] DIAD ApplyNow | ExistingLot=%.2f | L1=%.2f L2=%.2f L3=%.2f | C=%.2f",
               m_baseLotSize, L1, L2, L3, C);
}

void COrigamiManager::ApplyNow(const DashboardParams &p)
{
   if(!p.origamiEnabled) return;
   
   double totalVolume = 0.0;
   double totalCost = 0.0;
   double commonTP = 0.0;
   int commonOrderType = -1;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   int totalPositions = PositionsTotal();
   for(int i=0; i<totalPositions; i++)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetInteger(POSITION_MAGIC) == g_magic && PositionGetString(POSITION_SYMBOL) == p.symbol)
         {
            string comment = PositionGetString(POSITION_COMMENT);
            if(StringFind(comment, "ORIGAMI_") < 0) // It's a base order
            {
               double vol = PositionGetDouble(POSITION_VOLUME);
               double price = PositionGetDouble(POSITION_PRICE_OPEN);
               int type = (int)PositionGetInteger(POSITION_TYPE);
               double tp = PositionGetDouble(POSITION_TP);
               
               if(commonOrderType == -1) commonOrderType = type;
               
               if(type == commonOrderType) // Only aggregate same direction
               {
                  totalVolume += vol;
                  totalCost += vol * price;
                  if(tp > 0) commonTP = tp; // Takes the last valid TP
               }
            }
         }
      }
   }
   
   if(totalVolume > 0 && commonTP > 0)
   {
      double avgEntry = totalCost / totalVolume;
      CalculateOrigamiFromExisting(balance, p.targetGrowthPercent, p.riskPercent, p.origamiMaxRiskPercent, avgEntry, commonTP, p.slPoints, totalVolume, commonOrderType, p.symbol, p.addInPct1, p.addInPct2, p.addInPct3);
      
      // Update states of existing origami steps if price already passed them
      double currentPrice = (commonOrderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(p.symbol, SYMBOL_ASK) : SymbolInfoDouble(p.symbol, SYMBOL_BID);
      int dir = (commonOrderType == ORDER_TYPE_BUY) ? 1 : -1;
      
      for(int i=0; i<3; i++)
      {
         if(m_steps[i].lotSize > 0)
         {
             if((dir == 1 && currentPrice >= m_steps[i].triggerPrice) || 
                (dir == -1 && currentPrice <= m_steps[i].triggerPrice))
             {
                 m_steps[i].isTriggered = true; // Mark as triggered so we don't duplicate
             }
         }
      }
      DrawOrigamiLines();
   }
   else
   {
      PrintFormat("[Origami] ApplyNow failed: no base positions or no TP set.");
   }
}
//+------------------------------------------------------------------+
// v1.50: DIAD Algebraic Solver — O(1) closed-form solution
// Solves: 4 equations, 4 unknowns (L1, L2, L3, X=C/V)
//
// Eq1 (profit):  L0*P0 + L1*P1 + L2*P2 + L3*P3 = Target$/V
// Eq2 (stop 1):  L0*S1 + L1*(S1-E1) = X
// Eq3 (stop 2):  L0*S2 + L1*(S2-E1) + L2*(S2-E2) = X
// Eq4 (stop 3):  L0*S3 + L1*(S3-E1) + L2*(S3-E2) + L3*(S3-E3) = X
//
// Solution: Express Ln = An*X + Bn via back-substitution,
//           then solve X from Eq1.
//+------------------------------------------------------------------+
bool COrigamiManager::SolveDIAD(double L0, double targetAmt, double V,
                                double P0, double P1, double P2, double P3,
                                double E1, double E2, double E3,
                                double S1, double S2, double S3,
                                double &outL1, double &outL2, double &outL3, double &outC)
{
   // Guard: denominators must not be zero
   double M1 = S1 - E1;
   double M2 = S2 - E2;
   double M3 = S3 - E3;
   
   if(MathAbs(M1) < 0.0001 || MathAbs(M2) < 0.0001 || MathAbs(M3) < 0.0001)
   {
      PrintFormat("[DIAD] ERROR: Zero denominator M1=%.4f M2=%.4f M3=%.4f", M1, M2, M3);
      return false;
   }
   if(V <= 0 || P1 <= 0 || P2 <= 0 || P3 <= 0)
   {
      PrintFormat("[DIAD] ERROR: Invalid distances V=%.2f P1=%.1f P2=%.1f P3=%.1f", V, P1, P2, P3);
      return false;
   }
   
   // Step 1: L1 = A1*X + B1
   double A1 = 1.0 / M1;
   double B1 = -(L0 * S1) / M1;
   
   // Step 2: L2 = A2*X + B2
   double A2 = (1.0 - A1 * (S2 - E1)) / M2;
   double B2 = -(L0 * S2 + B1 * (S2 - E1)) / M2;
   
   // Step 3: L3 = A3*X + B3
   double A3 = (1.0 - A1 * (S3 - E1) - A2 * (S3 - E2)) / M3;
   double B3 = -(L0 * S3 + B1 * (S3 - E1) + B2 * (S3 - E2)) / M3;
   
   // Step 4: Solve X from profit equation
   double denominator = A1 * P1 + A2 * P2 + A3 * P3;
   if(MathAbs(denominator) < 0.0001)
   {
      PrintFormat("[DIAD] ERROR: Profit equation denominator ≈ 0");
      return false;
   }
   
   double RHS = (targetAmt / V) - L0 * P0;
   double numerator = RHS - (B1 * P1 + B2 * P2 + B3 * P3);
   double X = numerator / denominator;
   
   // Step 5: Compute initial lot sizes
   outL1 = A1 * X + B1;
   outL2 = A2 * X + B2;
   outL3 = A3 * X + B3;
   outC  = X * V;  // Convert back to dollars
   
   // Optimization A: If Target is too SMALL (producing negative lots)
   // This means Natural Profit > Target. We force X = 0 (perfect zero-risk breakeven)
   if(outL1 <= 0 || outL2 <= 0 || outL3 <= 0)
   {
      PrintFormat("[DIAD] Target is smaller than natural DIAD profit. Forcing C=$0.00 to guarantee zero risk.");
      X = 0;
      outL1 = B1;
      outL2 = B2;
      outL3 = B3;
      outC = 0;
   }
   
   // Optimization B: If Target is too LARGE (producing unacceptable risk)
   // This means we must cap the risk at maxRisk.
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double maxRisk = -(balance * (m_maxRiskPct / 100.0)); // User's input Max Risk
   if(outC < maxRisk)
   {
      PrintFormat("[DIAD] Target is too high for this distance. Capping risk to user's Max Risk: $%.2f", maxRisk);
      X = maxRisk / V;
      outL1 = A1 * X + B1;
      outL2 = A2 * X + B2;
      outL3 = A3 * X + B3;
      outC = X * V;
   }
   
   // Final safety check just in case
   if(outL1 <= 0 || outL2 <= 0 || outL3 <= 0)
   {
      PrintFormat("[DIAD] ERROR: Mathematical edge case. Lots still negative after optimization. L1=%.2f L2=%.2f L3=%.2f", outL1, outL2, outL3);
      return false;
   }
   
   PrintFormat("[DIAD] SOLVED: X=%.4f | L1=%.4f L2=%.4f L3=%.4f | C=$%.2f",
               X, outL1, outL2, outL3, outC);
   return true;
}

#endif // __ORIGAMI_MANAGER_MQH__
