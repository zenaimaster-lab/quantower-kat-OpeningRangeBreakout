//+------------------------------------------------------------------+
//|                                                  TimeManager.mqh |
//|                KAT Opening Range Breakout EA — Timezone & Sched.  |
//|                                                                  |
//+------------------------------------------------------------------+
#ifndef __TIMEMANAGER_MQH__
#define __TIMEMANAGER_MQH__

#include "Defines.mqh"

//+------------------------------------------------------------------+
//| CTimeManager — handles NY timezone conversion and NYO countdown  |
//+------------------------------------------------------------------+
class CTimeManager
{
private:
   bool              m_firedToday;
   int               m_lastFireDay;
   int               m_firedScheduleHash;
   datetime          m_targetTimeServer;
   bool              m_calculated;
   
   //--- Cached schedule params for next-day countdown calculation
   int               m_nyHour;
   int               m_nyMinute;
   int               m_nySecond;
   int               m_utcOffset;
   
public:
                     CTimeManager();
                    ~CTimeManager() {}
   
   //--- Core methods
   void              Reset();
   bool              CalculateTargetTime(const DashboardParams &params);
   bool              HasFiredToday() const { return m_firedToday; }
   void              MarkFired(const DashboardParams &params);
   
   //--- Info methods
   datetime          GetTargetTime() const { return m_targetTimeServer; }
   string            GetCountdownString(const DashboardParams &params);
   string            GetNYTimeString(int utcOffset);
   string            GetNYAmPmString(int utcOffset);
   string            GetNYDateString(int utcOffset);
   
   //--- Timezone helpers
   int               GetBrokerGMTOffset();
   datetime          NYTimeToServerTime(int nyHour, int nyMin, int nySec, int utcOffset);
   datetime          NYTimeToServerTimeForDate(int nyHour, int nyMin, int nySec, int utcOffset, datetime gmtDate);
};

//+------------------------------------------------------------------+
CTimeManager::CTimeManager()
{
   Reset();
}

//+------------------------------------------------------------------+
void CTimeManager::Reset()
{
   m_firedToday        = false;
   m_lastFireDay       = -1;
   m_firedScheduleHash = -1;
   m_targetTimeServer   = 0;
   m_calculated         = false;
   m_nyHour             = 9;
   m_nyMinute           = 30;
   m_nySecond           = 0;
   m_utcOffset          = -4;
}

//+------------------------------------------------------------------+
//| Calculate broker's GMT offset dynamically                         |
//+------------------------------------------------------------------+
int CTimeManager::GetBrokerGMTOffset()
{
   // Difference between server time and GMT
   // Positive = server ahead of GMT (e.g., GMT+2 returns 7200)
   datetime serverTime = TimeTradeServer();
   datetime gmtTime    = TimeGMT();
   return (int)(serverTime - gmtTime);
}

//+------------------------------------------------------------------+
//| Convert NY time to broker server time                             |
//+------------------------------------------------------------------+
datetime CTimeManager::NYTimeToServerTime(int nyHour, int nyMin, int nySec, int utcOffset)
{
   // Step 1: Get today's date using real-time GMT (not stale TimeTradeServer)
   MqlDateTime gmtDt;
   TimeToStruct(TimeGMT(), gmtDt);
   
   // Step 2: Build target time in UTC
   // NY time = UTC + utcOffset → UTC = NY time - utcOffset
   // utcOffset is negative for NY (e.g., -4 or -5), so subtracting negative = adding
   int utcHour   = nyHour - utcOffset;  // e.g., 9 - (-4) = 13 UTC
   int utcMin    = nyMin;
   int utcSec    = nySec;
   
   // Handle hour overflow (e.g., 23 - (-4) = 27 → next day)
   int dayAdjust = 0;
   if(utcHour >= 24) { utcHour -= 24; dayAdjust = 1; }
   if(utcHour < 0)   { utcHour += 24; dayAdjust = -1; }
   
   // Step 3: Build UTC datetime
   MqlDateTime utcDt;
   utcDt.year  = gmtDt.year;
   utcDt.mon   = gmtDt.mon;
   utcDt.day   = gmtDt.day + dayAdjust;
   utcDt.hour  = utcHour;
   utcDt.min   = utcMin;
   utcDt.sec   = utcSec;
   utcDt.day_of_week = 0;
   utcDt.day_of_year = 0;
   
   datetime utcTarget = StructToTime(utcDt);
   
   // Step 4: Convert UTC to server time
   int brokerOffset = GetBrokerGMTOffset(); // in seconds
   datetime serverTarget = utcTarget + brokerOffset;
   
   return serverTarget;
}

//+------------------------------------------------------------------+
//| Calculate NYO target time for today based on dashboard params      |
//+------------------------------------------------------------------+
bool CTimeManager::CalculateTargetTime(const DashboardParams &params)
{
   // Use real-time GMT + broker offset instead of stale TimeTradeServer()
   datetime realServerTime = TimeGMT() + GetBrokerGMTOffset();
   MqlDateTime nowDt;
   TimeToStruct(realServerTime, nowDt);
   
   if(nowDt.day != m_lastFireDay)
   {
      m_firedToday = false;
      m_calculated = false;
   }
   
   int newHash = params.nyHour * 10000 + params.nyMinute * 100 + params.nySecond;
   if(m_firedToday && newHash != m_firedScheduleHash)
   {
      m_firedToday = false;
      PrintFormat("[TimeMgr] Schedule changed, allowing new cycle");
   }
   
   // Cache schedule params for next-day countdown calculation
   m_nyHour    = params.nyHour;
   m_nyMinute  = params.nyMinute;
   m_nySecond  = params.nySecond;
   m_utcOffset = params.utcOffset;
   
   m_targetTimeServer = NYTimeToServerTime(params.nyHour, params.nyMinute, 
                                            params.nySecond, params.utcOffset);
   m_calculated = true;
   return true;
}

void CTimeManager::MarkFired(const DashboardParams &params)
{
   m_firedToday = true;
   MqlDateTime nowDt;
   TimeToStruct(TimeGMT() + GetBrokerGMTOffset(), nowDt);
   m_lastFireDay = nowDt.day;
   m_firedScheduleHash = params.nyHour * 10000 + params.nyMinute * 100 + params.nySecond;
}

//+------------------------------------------------------------------+
//| Convert NY time to server time for a specific GMT date            |
//+------------------------------------------------------------------+
datetime CTimeManager::NYTimeToServerTimeForDate(int nyHour, int nyMin, int nySec, int utcOffset, datetime gmtDate)
{
   MqlDateTime gmtDt;
   TimeToStruct(gmtDate, gmtDt);
   
   int utcHour   = nyHour - utcOffset;
   int utcMin    = nyMin;
   int utcSec    = nySec;
   
   int dayAdjust = 0;
   if(utcHour >= 24) { utcHour -= 24; dayAdjust = 1; }
   if(utcHour < 0)   { utcHour += 24; dayAdjust = -1; }
   
   MqlDateTime utcDt;
   utcDt.year  = gmtDt.year;
   utcDt.mon   = gmtDt.mon;
   utcDt.day   = gmtDt.day + dayAdjust;
   utcDt.hour  = utcHour;
   utcDt.min   = utcMin;
   utcDt.sec   = utcSec;
   utcDt.day_of_week = 0;
   utcDt.day_of_year = 0;
   
   datetime utcTarget = StructToTime(utcDt);
   int brokerOffset = GetBrokerGMTOffset();
   return utcTarget + brokerOffset;
}

//+------------------------------------------------------------------+
string CTimeManager::GetCountdownString(const DashboardParams &params)
{
   if(!m_calculated) return "Not configured";
   
   // Use real-time GMT for smooth countdown (not stale TimeTradeServer)
   datetime gmtNow = TimeGMT();
   int brokerOffset = GetBrokerGMTOffset();
   datetime realServerTime = gmtNow + brokerOffset;
   
   // Check weekend in NY time
   datetime nyTime = gmtNow + m_utcOffset * 3600;
   MqlDateTime nyDt; TimeToStruct(nyTime, nyDt);
   if(nyDt.day_of_week == 0 || nyDt.day_of_week == 6) {
       return "HAPPY WEEKEND!";
   }
   
   int secs = (int)(m_targetTimeServer - realServerTime);
   
   // Today's NYO hasn't arrived yet → countdown to it
   if(secs > 0)
   {
      int hours   = secs / 3600;
      int minutes = (secs % 3600) / 60;
      int seconds = secs % 60;
      return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
   }
   else
   {
      // After NYO
      int elapsedSecs = -secs;
      int windowSecs = params.afterMinutesOn ? (params.afterMinutes * 60) : (390 * 60);
      
      if (elapsedSecs <= windowSecs) {
          return "TRADING WINDOW";
      }
      
      if (nyDt.day_of_week == 5) {
          return "HAPPY WEEKEND!";
      }
      
      // Today's NYO and trading window have passed → calculate countdown to NEXT business day's NYO
      for(int d = 1; d <= 7; d++)
      {
         datetime futureGmt = gmtNow + d * 86400;  // +d days in GMT
         MqlDateTime futureDt;
         TimeToStruct(futureGmt, futureDt);
         
         // Skip Saturday (6) and Sunday (0)
         if(futureDt.day_of_week == 0 || futureDt.day_of_week == 6)
            continue;
         
         datetime nextTarget = NYTimeToServerTimeForDate(m_nyHour, m_nyMinute, 
                                                          m_nySecond, m_utcOffset, futureGmt);
         int nextSecs = (int)(nextTarget - realServerTime);
         if(nextSecs > 0)
         {
            int hours   = nextSecs / 3600;
            int minutes = (nextSecs % 3600) / 60;
            int seconds = nextSecs % 60;
            return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
         }
      }
   }
   
   return "---";
}

//+------------------------------------------------------------------+
//| Get current NY time as string for real-time clock display         |
//+------------------------------------------------------------------+
string CTimeManager::GetNYTimeString(int utcOffset)
{
   datetime gmtTime = TimeGMT();
   datetime nyTime  = gmtTime + utcOffset * 3600;
   
   MqlDateTime nyDt;
   TimeToStruct(nyTime, nyDt);
   
   string ampm = (nyDt.hour >= 12) ? "PM" : "AM";
   int dispHour = nyDt.hour % 12;
   if(dispHour == 0) dispHour = 12;
   
   return StringFormat("%d:%02d:%02d", dispHour, nyDt.min, nyDt.sec);
}

//+------------------------------------------------------------------+
//| Get AM/PM string for separate display                            |
//+------------------------------------------------------------------+
string CTimeManager::GetNYAmPmString(int utcOffset)
{
   datetime gmtTime = TimeGMT();
   datetime nyTime  = gmtTime + utcOffset * 3600;
   
   MqlDateTime nyDt;
   TimeToStruct(nyTime, nyDt);
   
   return (nyDt.hour >= 12) ? "PM" : "AM";
}

//+------------------------------------------------------------------+
//| Get current NY date as string for real-time clock display         |
//+------------------------------------------------------------------+
string CTimeManager::GetNYDateString(int utcOffset)
{
   datetime gmtTime = TimeGMT();
   datetime nyTime  = gmtTime + utcOffset * 3600;
   
   MqlDateTime nyDt;
   TimeToStruct(nyTime, nyDt);
   
   string months[] = {"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
   string days[]   = {"Sun","Mon","Tue","Wed","Thu","Fri","Sat"};
   string mon = (nyDt.mon >= 1 && nyDt.mon <= 12) ? months[nyDt.mon] : "?";
   string dow = (nyDt.day_of_week >= 0 && nyDt.day_of_week <= 6) ? days[nyDt.day_of_week] : "?";
   
   return StringFormat("(%s, %02d %s)", dow, nyDt.day, mon);
}

#endif // __TIMEMANAGER_MQH__
