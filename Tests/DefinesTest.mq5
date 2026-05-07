//+------------------------------------------------------------------+
//|                                                  DefinesTest.mq5 |
//|                                     Unit tests for Defines.mqh    |
//+------------------------------------------------------------------+
#include "../Defines.mqh"
#include "TestBase.mqh"

class CDefinesTest : public CTestBase
{
public:
   CDefinesTest() : CTestBase("Defines") {}

   void RunTests()
   {
      TestTimeframeToString();
      TestStringToTimeframe();
      TestTimeframeToIndex();
      TestOrigamiSlModeToString();

      Summary();
   }

private:
   void TestTimeframeToString()
   {
      AssertEqualString("PERIOD_M1 -> M1", "M1", TimeframeToString(PERIOD_M1));
      AssertEqualString("PERIOD_M2 -> M2", "M2", TimeframeToString(PERIOD_M2));
      AssertEqualString("PERIOD_M5 -> M5", "M5", TimeframeToString(PERIOD_M5));
      AssertEqualString("PERIOD_M15 -> M15", "M15", TimeframeToString(PERIOD_M15));
      AssertEqualString("Default (PERIOD_H1) -> M2", "M2", TimeframeToString(PERIOD_H1));
   }

   void TestStringToTimeframe()
   {
      AssertEqual("M1 -> PERIOD_M1", (double)PERIOD_M1, (double)StringToTimeframe("M1"));
      AssertEqual("M2 -> PERIOD_M2", (double)PERIOD_M2, (double)StringToTimeframe("M2"));
      AssertEqual("M5 -> PERIOD_M5", (double)PERIOD_M5, (double)StringToTimeframe("M5"));
      AssertEqual("M15 -> PERIOD_M15", (double)PERIOD_M15, (double)StringToTimeframe("M15"));
      AssertEqual("m1 -> PERIOD_M1", (double)PERIOD_M1, (double)StringToTimeframe("m1"));
      AssertEqual("  M2  -> PERIOD_M2", (double)PERIOD_M2, (double)StringToTimeframe("  M2  "));
      AssertEqual("Invalid -> PERIOD_M2", (double)PERIOD_M2, (double)StringToTimeframe("H1"));
   }

   void TestTimeframeToIndex()
   {
      AssertEqual("PERIOD_M1 -> 0", 0, TimeframeToIndex(PERIOD_M1));
      AssertEqual("PERIOD_M2 -> 1", 1, TimeframeToIndex(PERIOD_M2));
      AssertEqual("PERIOD_M5 -> 2", 2, TimeframeToIndex(PERIOD_M5));
      AssertEqual("PERIOD_M15 -> 3", 3, TimeframeToIndex(PERIOD_M15));
      AssertEqual("Default (PERIOD_H1) -> 1", 1, TimeframeToIndex(PERIOD_H1));
   }

   void TestOrigamiSlModeToString()
   {
      AssertEqualString("ORIGAMI_SL_DONT_MOVE -> DON'T MOVE", "DON'T MOVE", OrigamiSlModeToString(ORIGAMI_SL_DONT_MOVE));
      AssertEqualString("ORIGAMI_SL_ALWAYS_ORIG -> ALWAYS ORIGINAL", "ALWAYS ORIGINAL", OrigamiSlModeToString(ORIGAMI_SL_ALWAYS_ORIG));
      AssertEqualString("ORIGAMI_SL_BE_SPREAD -> BE + SPREAD", "BE + SPREAD", OrigamiSlModeToString(ORIGAMI_SL_BE_SPREAD));
      AssertEqualString("Default -> DON'T MOVE", "DON'T MOVE", OrigamiSlModeToString((ENUM_ORIGAMI_SL_MODE)99));
   }
};

void OnStart()
{
   CDefinesTest tests;
   tests.RunTests();
}
