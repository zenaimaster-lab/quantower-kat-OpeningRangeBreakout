//+------------------------------------------------------------------+
//|                                                 NewsManager.mqh  |
//|               Opening Sniper EA — Session Manager                |
//|                                                      Version 2.0 |
#ifndef __NEWSMANAGER_MQH__
#define __NEWSMANAGER_MQH__

#include "Defines.mqh"

class CNewsManager
{
private:
   NewsEvent         m_nextEvent;
   datetime          m_lastUpdate;
   int               m_nyoHour, m_nyoMinute, m_nyoSecond, m_utcOffset;
   
public:
   CNewsManager();
   ~CNewsManager() {}
   
   void SetNYO(int h, int m, int s, int utc) { m_nyoHour=h; m_nyoMinute=m; m_nyoSecond=s; m_utcOffset=utc; }
   void Update();
   void ForceUpdate() { m_lastUpdate=0; Update(); }
   NewsEvent GetNextEvent() const { return m_nextEvent; }
   string GetNextEventString();
   bool HasEvent() const { return m_nextEvent.time > 0; }
   
private:
   void CalcNextNYOEvent();
   datetime NYOToUTC(int h, int mi, int s, int utc);
};

//+------------------------------------------------------------------+
CNewsManager::CNewsManager()
{
   m_lastUpdate = 0;
   m_nyoHour = 9; m_nyoMinute = 30; m_nyoSecond = 0; m_utcOffset = -4;
}

//+------------------------------------------------------------------+
datetime CNewsManager::NYOToUTC(int h, int mi, int s, int utc)
{
   MqlDateTime dt;
   TimeToStruct(TimeGMT(), dt);
   int utcH = h - utc;
   int dayAdj = 0;
   if(utcH >= 24) { utcH -= 24; dayAdj = 1; }
   if(utcH < 0)   { utcH += 24; dayAdj = -1; }
   dt.hour = utcH; dt.min = mi; dt.sec = s; dt.day += dayAdj;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
void CNewsManager::CalcNextNYOEvent()
{
   // Calculate today's NYO in GMT
   datetime nyoGMT = NYOToUTC(m_nyoHour, m_nyoMinute, m_nyoSecond, m_utcOffset);
   
   // If already passed today, use tomorrow
   if(nyoGMT <= TimeGMT())
   {
      nyoGMT += 86400;
      // Skip weekends
      MqlDateTime dt;
      TimeToStruct(nyoGMT, dt);
      if(dt.day_of_week == 6) nyoGMT += 2 * 86400;
      else if(dt.day_of_week == 0) nyoGMT += 86400;
   }
   
   m_nextEvent.name = "NY Open";
   m_nextEvent.time = nyoGMT;
   m_nextEvent.isNYO = true;
}

//+------------------------------------------------------------------+
void CNewsManager::Update()
{
   // Refresh every 60 seconds
   if(TimeCurrent() - m_lastUpdate < 60 && m_lastUpdate > 0) return;
   m_lastUpdate = TimeCurrent();
   
   CalcNextNYOEvent();
}

//+------------------------------------------------------------------+
string CNewsManager::GetNextEventString()
{
   if(m_nextEvent.time == 0) return "No upcoming events";
   
   // Convert GMT event time to NY time for display
   datetime nyTime = m_nextEvent.time + m_utcOffset * 3600;
   MqlDateTime dt;
   TimeToStruct(nyTime, dt);
   
   string ampm = (dt.hour >= 12) ? "PM" : "AM";
   int dispH = dt.hour % 12;
   if(dispH == 0) dispH = 12;
   
   // Month names
   string months[] = {"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"};
   string mon = (dt.mon >= 1 && dt.mon <= 12) ? months[dt.mon] : "?";
   
   string timeStr = StringFormat("%02d:%02d, %02d %s", dt.hour, dt.min, dt.day, mon);
   
   return m_nextEvent.name + " | " + timeStr;
}

#endif // __NEWSMANAGER_MQH__
