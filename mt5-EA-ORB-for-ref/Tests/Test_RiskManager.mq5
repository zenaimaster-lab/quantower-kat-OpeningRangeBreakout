//+------------------------------------------------------------------+
//|                                           Test_RiskManager.mq5 |
//|                                  Copyright 2026, AI Agent        |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, AI Agent"
#property link      ""
#property version   "1.00"

#include "MockRiskManager.mqh"

CGlobalState g_gs;

//+------------------------------------------------------------------+
//| Helper for assertions                                            |
//+------------------------------------------------------------------+
void AssertEqual(double actual, double expected, string message, double epsilon = 0.000001)
{
   if(MathAbs(actual - expected) > epsilon)
   {
      PrintFormat("[FAIL] %s | Expected: %.5f, Actual: %.5f", message, expected, actual);
   }
   else
   {
      PrintFormat("[PASS] %s", message);
   }
}

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   CMockRiskManager mock;
   string symbol = "EURUSD";

   Print("--- Starting CRiskManager::CalcLotSize Tests ---");

   // 1. Standard calculation
   // Balance = 10000, Risk = 1%, SL = 100 points
   // Point = 0.0001, TickValue = 1.0, TickSize = 0.0001
   // ValuePerPoint = 1.0 / 0.0001 * 0.0001 = 1.0
   // LossPerLot = 100 * 1.0 = 100.0
   // RiskAmount = 10000 * 0.01 = 100.0
   // LotSize = 100.0 / 100.0 = 1.0
   mock.SetBalance(10000);
   mock.SetPoint(0.0001);
   mock.SetTickValue(1.0);
   mock.SetTickSize(0.0001);
   mock.SetLotStep(0.01);
   mock.SetMinLot(0.01);
   mock.SetMaxLot(100.0);

   AssertEqual(mock.CalcLotSize(symbol, 1.0, 100, true), 1.0, "Standard 1% Risk 100pt SL");

   // 2. Different balance and risk
   // Balance = 5000, Risk = 2%, SL = 200 points
   // ValuePerPoint = 1.0
   // LossPerLot = 200 * 1.0 = 200.0
   // RiskAmount = 5000 * 0.02 = 100.0
   // LotSize = 100.0 / 200.0 = 0.5
   mock.SetBalance(5000);
   AssertEqual(mock.CalcLotSize(symbol, 2.0, 200, true), 0.5, "Standard 2% Risk 200pt SL");

   // 3. Edge case: riskPercent <= 0
   AssertEqual(mock.CalcLotSize(symbol, 0, 100, true), mock.GetMinLot(symbol), "Zero Risk returns MinLot");
   AssertEqual(mock.CalcLotSize(symbol, -1.0, 100, true), mock.GetMinLot(symbol), "Negative Risk returns MinLot");

   // 4. Edge case: slPoints <= 0
   AssertEqual(mock.CalcLotSize(symbol, 1.0, 0, true), mock.GetMinLot(symbol), "Zero SL returns MinLot");
   AssertEqual(mock.CalcLotSize(symbol, 1.0, -50, true), mock.GetMinLot(symbol), "Negative SL returns MinLot");

   // 5. Error condition: Invalid symbol properties (TickValue = 0)
   mock.SetTickValue(0);
   AssertEqual(mock.CalcLotSize(symbol, 1.0, 100, true), mock.GetMinLot(symbol), "Invalid TickValue returns MinLot");
   mock.SetTickValue(1.0);

   // 6. Lot normalization: Clamping to MinLot
   // Risk amount 1, Loss per lot 1000 => raw lot 0.001 -> MinLot 0.01
   mock.SetBalance(100);
   mock.SetMinLot(0.01);
   AssertEqual(mock.CalcLotSize(symbol, 1.0, 1000, true), 0.01, "Clamped to MinLot");

   // 7. Lot normalization: Clamping to MaxLot
   // Risk amount 1000, Loss per lot 1 => raw lot 1000 -> MaxLot 50
   mock.SetBalance(100000);
   mock.SetMaxLot(50.0);
   AssertEqual(mock.CalcLotSize(symbol, 1.0, 1, true), 50.0, "Clamped to MaxLot");

   // 8. Lot normalization: Rounding to LotStep
   // Raw lot 0.555 -> LotStep 0.1 -> 0.5
   mock.SetBalance(555);
   mock.SetLotStep(0.1);
   mock.SetTickValue(1.0);
   mock.SetTickSize(1.0);
   mock.SetPoint(1.0); // ValuePerPoint = 1.0
   AssertEqual(mock.CalcLotSize(symbol, 100.0, 1000, true), 0.5, "Rounded to LotStep (0.1)");

   // 9. JPY-style symbol (3 digits)
   // Point = 0.001, TickSize = 0.001, TickValue = 6.45 (approx for USDJPY)
   // ValuePerPoint = 6.45 / 0.001 * 0.001 = 6.45
   // Balance = 10000, Risk = 1% (100 USD)
   // SL = 500 points
   // LossPerLot = 500 * 6.45 = 3225.0
   // LotSize = 100 / 3225 = 0.0310... -> Normalized to 0.03
   mock.SetBalance(10000);
   mock.SetPoint(0.001);
   mock.SetTickSize(0.001);
   mock.SetTickValue(6.45);
   mock.SetLotStep(0.01);
   mock.SetMinLot(0.01);
   mock.SetMaxLot(100.0);
   AssertEqual(mock.CalcLotSize("USDJPY", 1.0, 500, true), 0.03, "JPY-style symbol calculation");

   Print("--- CRiskManager::CalcLotSize Tests Completed ---");
}
//+------------------------------------------------------------------+
