//+------------------------------------------------------------------+
//|                                                     TestBase.mqh |
//|                                     Simple MQL5 Testing Framework |
//+------------------------------------------------------------------+
#ifndef __TESTBASE_MQH__
#define __TESTBASE_MQH__

class CTestBase
{
protected:
   int               m_totalTests;
   int               m_passedTests;
   string            m_testSuiteName;

public:
                     CTestBase(string suiteName) : m_totalTests(0), m_passedTests(0), m_testSuiteName(suiteName) {}

   void              AssertEqual(string message, double expected, double actual, double epsilon = 0.00001)
   {
      m_totalTests++;
      if(MathAbs(expected - actual) <= epsilon)
      {
         m_passedTests++;
      }
      else
      {
         PrintFormat("[FAIL] %s: %s (Expected: %G, Actual: %G)", m_testSuiteName, message, expected, actual);
      }
   }

   void              AssertEqualString(string message, string expected, string actual)
   {
      m_totalTests++;
      if(expected == actual)
      {
         m_passedTests++;
      }
      else
      {
         PrintFormat("[FAIL] %s: %s (Expected: %s, Actual: %s)", m_testSuiteName, message, expected, actual);
      }
   }

   void              AssertTrue(string message, bool condition)
   {
      m_totalTests++;
      if(condition)
      {
         m_passedTests++;
      }
      else
      {
         PrintFormat("[FAIL] %s: %s (Expected True)", m_testSuiteName, message);
      }
   }

   void              Summary()
   {
      PrintFormat("[%s SUMMARY] Total: %d | Passed: %d | Failed: %d",
                  m_testSuiteName, m_totalTests, m_passedTests, m_totalTests - m_passedTests);
   }
};

#endif // __TESTBASE_MQH__
