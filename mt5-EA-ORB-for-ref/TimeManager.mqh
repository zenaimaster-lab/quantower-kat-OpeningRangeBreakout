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
   int offset = (int)(serverTime - gmtTime);
   
   // Round to nearest 15 minutes (900 seconds) to prevent tick-delay inaccuracies
   // that could cause the calculated time to be a few seconds early (e.g. 15:29:59)
   int remainder = offset % 900;
   if(remainder > 450) offset += (900 - remainder);
   else if(remainder < -450) offset -= (900 + remainder);
   else offset -= remainder;
   
   return offset;
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
   
   datetime gmtNow = TimeGMT();
   datetime nyTime = gmtNow + m_utcOffset * 3600;
   MqlDateTime nyDt; TimeToStruct(nyTime, nyDt);
   
   // Weekend in NY
   if(nyDt.day_of_week == 0 || nyDt.day_of_week == 6) {
       return "Happy Weekend! ✨";
   }
   
   // Create today's NYO time in NY timezone
   MqlDateTime nyTargetDt = nyDt;
   nyTargetDt.hour = m_nyHour;
   nyTargetDt.min = m_nyMinute;
   nyTargetDt.sec = m_nySecond;
   datetime nyTargetTime = StructToTime(nyTargetDt);
   
   int secsToNYO = (int)(nyTargetTime - nyTime);
   
   // Before NYO today
   if(secsToNYO > 0)
   {
      int hours   = secsToNYO / 3600;
      int minutes = (secsToNYO % 3600) / 60;
      int seconds = secsToNYO % 60;
      return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
   }
   
   // After NYO today
   int elapsedSecs = -secsToNYO;
   int windowSecs = params.afterMinutesOn ? (params.afterMinutes * 60) : (390 * 60);
   
   if (elapsedSecs <= windowSecs) {
       return "Trading Session Active";
   }
   
   // After Trading Window
   if (nyDt.day_of_week == 5) {
       return "Happy Weekend! ✨";
   }
   
   // Calculate countdown to NEXT business day's NYO (Tomorrow)
   datetime nextNyTargetTime = nyTargetTime + 86400; // Tomorrow's NYO
   int nextSecs = (int)(nextNyTargetTime - nyTime);
   
   if (nextSecs > 0) {
      int hours   = nextSecs / 3600;
      int minutes = (nextSecs % 3600) / 60;
      int seconds = nextSecs % 60;
      return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
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
