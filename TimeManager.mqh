//+------------------------------------------------------------------+
//|                                                  TimeManager.mqh |
//|                         Opening Sniper EA — Timezone & Scheduling |
//|                                                      Version 2.0 |
//+------------------------------------------------------------------+
#ifndef __TIMEMANAGER_MQH__
#define __TIMEMANAGER_MQH__

#include "Defines.mqh"

//+------------------------------------------------------------------+
//| CTimeManager — handles NY timezone conversion and trigger timing |
//+------------------------------------------------------------------+
class CTimeManager
{
private:
   bool              m_firedToday;
   int               m_lastFireDay;
   int               m_firedScheduleHash; // Track which schedule was fired
   datetime          m_triggerTimeServer;
   datetime          m_targetTimeServer;
   bool              m_triggerCalculated;
   
public:
                     CTimeManager();
                    ~CTimeManager() {}
   
   //--- Core methods
   void              Reset();
   bool              CalculateTriggerTime(const DashboardParams &params);
   bool              IsTimeToTrade();
   bool              HasFiredToday() const { return m_firedToday; }
   void              MarkFired(const DashboardParams &params);
   
   //--- Info methods
   datetime          GetTriggerTime() const { return m_triggerTimeServer; }
   datetime          GetTargetTime() const { return m_targetTimeServer; }
   int               GetSecondsToTrigger();
   string            GetCountdownString();
   string            GetNYTimeString(int utcOffset);
   string            GetNYAmPmString(int utcOffset);
   string            GetNYDateString(int utcOffset);
   
   //--- Timezone helpers
   int               GetBrokerGMTOffset();
   datetime          NYTimeToServerTime(int nyHour, int nyMin, int nySec, int utcOffset);
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
   m_triggerTimeServer  = 0;
   m_targetTimeServer   = 0;
   m_triggerCalculated  = false;
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
   // Step 1: Get today's date in server time
   MqlDateTime serverDt;
   TimeToStruct(TimeTradeServer(), serverDt);
   
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
   utcDt.year  = serverDt.year;
   utcDt.mon   = serverDt.mon;
   utcDt.day   = serverDt.day + dayAdjust;
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
//| Calculate trigger time for today based on dashboard params        |
//+------------------------------------------------------------------+
bool CTimeManager::CalculateTriggerTime(const DashboardParams &params)
{
   MqlDateTime nowDt;
   TimeToStruct(TimeTradeServer(), nowDt);
   
   // Reset on new day
   if(nowDt.day != m_lastFireDay)
   {
      m_firedToday       = false;
      m_triggerCalculated = false;
   }
   
   // Reset if schedule changed (allow re-fire for new schedule)
   int newHash = params.nyHour * 10000 + params.nyMinute * 100 + params.nySecond;
   if(m_firedToday && newHash != m_firedScheduleHash)
   {
      m_firedToday = false;
      PrintFormat("[TimeMgr] Schedule changed → allowing new trigger");
   }
   
   m_targetTimeServer = NYTimeToServerTime(params.nyHour, params.nyMinute, 
                                            params.nySecond, params.utcOffset);
   m_triggerTimeServer = m_targetTimeServer - params.triggerBeforeSec;
   m_triggerCalculated = true;
   return true;
}

//+------------------------------------------------------------------+
//| Check if it's time to execute trades                              |
//+------------------------------------------------------------------+
bool CTimeManager::IsTimeToTrade()
{
   if(!m_triggerCalculated) return false;
   if(m_firedToday) return false;
   
   datetime now = TimeTradeServer();
   
   // Fire if current time >= trigger time AND within a reasonable window (60 seconds)
   if(now >= m_triggerTimeServer && now <= m_triggerTimeServer + 60)
   {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Mark as fired today to prevent duplicate execution                |
//+------------------------------------------------------------------+
void CTimeManager::MarkFired(const DashboardParams &params)
{
   m_firedToday = true;
   MqlDateTime nowDt;
   TimeToStruct(TimeTradeServer(), nowDt);
   m_lastFireDay = nowDt.day;
   // Store hash of NY schedule that was fired (must match CalculateTriggerTime's formula)
   m_firedScheduleHash = params.nyHour * 10000 + params.nyMinute * 100 + params.nySecond;
}

//+------------------------------------------------------------------+
//| Get seconds remaining until trigger                               |
//+------------------------------------------------------------------+
int CTimeManager::GetSecondsToTrigger()
{
   if(!m_triggerCalculated) return -1;
   if(m_firedToday) return 0;
   
   int diff = (int)(m_triggerTimeServer - TimeTradeServer());
   return (diff > 0) ? diff : 0;
}

//+------------------------------------------------------------------+
//| Get human-readable countdown string                               |
//+------------------------------------------------------------------+
string CTimeManager::GetCountdownString()
{
   if(!m_triggerCalculated) return "Not configured";
   if(m_firedToday) return "Fired today";
   
   int secs = GetSecondsToTrigger();
   if(secs <= 0) return "NOW";
   
   int hours   = secs / 3600;
   int minutes = (secs % 3600) / 60;
   int seconds = secs % 60;
   
   return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
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
