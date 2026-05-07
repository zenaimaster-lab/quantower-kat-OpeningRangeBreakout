//+------------------------------------------------------------------+
//|                                                 NewsManager.mqh  |
//|               Opening Sniper EA — Economic Calendar & News Feed   |
//|                                                      Version 2.0 |
#ifndef __NEWSMANAGER_MQH__
#define __NEWSMANAGER_MQH__

#include "Defines.mqh"

class CNewsManager
{
private:
   NewsEvent         m_nextEvent;
   NewsEvent         m_events[50];
   int               m_eventCount;
   datetime          m_lastUpdate;
   int               m_nyoHour, m_nyoMinute, m_nyoSecond, m_utcOffset;
   
   // News filter flags
   bool m_enNFP, m_enCPI, m_enFOMC, m_enGDP, m_enPPI, m_enRetail;
   bool m_enUnemploy, m_enISM, m_enPMI, m_enFedSpeak, m_enECB, m_enBOE;
   bool m_nyoOnly;
   
public:
   CNewsManager();
   ~CNewsManager() {}
   
   void SetFilters(bool nfp, bool cpi, bool fomc, bool gdp, bool ppi, bool retail,
                   bool unemploy, bool ism, bool pmi, bool fedSpeak, bool ecb, bool boe);
   void SetNYO(int h, int m, int s, int utc) { m_nyoHour=h; m_nyoMinute=m; m_nyoSecond=s; m_utcOffset=utc; }
   void SetNYOOnly(bool on) { m_nyoOnly=on; }
   void Update();
   void ForceUpdate() { m_lastUpdate=0; Update(); }
   NewsEvent GetNextEvent() const { return m_nextEvent; }
   string GetNextEventString();
   bool HasEvent() const { return m_nextEvent.time > 0; }
   
private:
   void FetchCalendarEvents();
   void InsertNYOEvent();
   void SortAndPickNext();
   bool MatchesFilter(string eventName);
   datetime NYOToUTC(int h, int mi, int s, int utc);
};

//+------------------------------------------------------------------+
CNewsManager::CNewsManager()
{
   m_eventCount = 0;
   m_lastUpdate = 0;
   m_nyoHour = 9; m_nyoMinute = 30; m_nyoSecond = 0; m_utcOffset = -4;
   m_enNFP=true; m_enCPI=true; m_enFOMC=true; m_enGDP=true; m_enPPI=true;
   m_enRetail=true; m_enUnemploy=true; m_enISM=true; m_enPMI=true;
   m_enFedSpeak=true; m_enECB=true; m_enBOE=true;
   m_nyoOnly=false;
}

//+------------------------------------------------------------------+
void CNewsManager::SetFilters(bool nfp, bool cpi, bool fomc, bool gdp, bool ppi, bool retail,
                              bool unemploy, bool ism, bool pmi, bool fedSpeak, bool ecb, bool boe)
{
   m_enNFP=nfp; m_enCPI=cpi; m_enFOMC=fomc; m_enGDP=gdp; m_enPPI=ppi;
   m_enRetail=retail; m_enUnemploy=unemploy; m_enISM=ism; m_enPMI=pmi;
   m_enFedSpeak=fedSpeak; m_enECB=ecb; m_enBOE=boe;
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
bool CNewsManager::MatchesFilter(string eventName)
{
   StringToUpper(eventName);
   if(m_enNFP && (StringFind(eventName,"NONFARM")>=0 || StringFind(eventName,"NFP")>=0)) return true;
   if(m_enCPI && StringFind(eventName,"CPI")>=0) return true;
   if(m_enFOMC && (StringFind(eventName,"FOMC")>=0 || StringFind(eventName,"FED FUNDS")>=0 || StringFind(eventName,"INTEREST RATE")>=0)) return true;
   if(m_enGDP && StringFind(eventName,"GDP")>=0) return true;
   if(m_enPPI && StringFind(eventName,"PPI")>=0) return true;
   if(m_enRetail && StringFind(eventName,"RETAIL")>=0) return true;
   if(m_enUnemploy && (StringFind(eventName,"UNEMPLOY")>=0 || StringFind(eventName,"JOBLESS")>=0 || StringFind(eventName,"EMPLOYMENT")>=0)) return true;
   if(m_enISM && StringFind(eventName,"ISM")>=0) return true;
   if(m_enPMI && StringFind(eventName,"PMI")>=0) return true;
   if(m_enFedSpeak && (StringFind(eventName,"FED CHAIR")>=0 || StringFind(eventName,"POWELL")>=0)) return true;
   if(m_enECB && (StringFind(eventName,"ECB")>=0 || StringFind(eventName,"LAGARDE")>=0)) return true;
   if(m_enBOE && (StringFind(eventName,"BOE")>=0 || StringFind(eventName,"BANK OF ENGLAND")>=0)) return true;
   return false;
}

//+------------------------------------------------------------------+
void CNewsManager::FetchCalendarEvents()
{
   m_eventCount = 0;
   
   datetime from = TimeGMT();
   datetime to   = from + 7 * 24 * 3600; // next 7 days
   
   MqlCalendarValue values[];
   int total = CalendarValueHistory(values, from, to);
   
   if(total <= 0) return;
   
   for(int i = 0; i < total && m_eventCount < 49; i++)
   {
      MqlCalendarEvent calEvent;
      if(!CalendarEventById(values[i].event_id, calEvent)) continue;
      
      // Only high impact (red)
      if(calEvent.importance != CALENDAR_IMPORTANCE_HIGH) continue;
      
      // Check filter
      if(!MatchesFilter(calEvent.name)) continue;
      
      // Only future events
      if(values[i].time <= TimeGMT()) continue;
      
      m_events[m_eventCount].name = calEvent.name;
      m_events[m_eventCount].time = values[i].time;
      m_events[m_eventCount].isNYO = false;
      m_eventCount++;
   }
}

//+------------------------------------------------------------------+
void CNewsManager::InsertNYOEvent()
{
   if(m_eventCount >= 49) return;
   
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
   
   m_events[m_eventCount].name = "NY Open";
   m_events[m_eventCount].time = nyoGMT;
   m_events[m_eventCount].isNYO = true;
   m_eventCount++;
}

//+------------------------------------------------------------------+
void CNewsManager::SortAndPickNext()
{
   // Simple bubble sort by time
   for(int i = 0; i < m_eventCount - 1; i++)
      for(int j = i + 1; j < m_eventCount; j++)
         if(m_events[j].time < m_events[i].time)
         {
            NewsEvent tmp = m_events[i];
            m_events[i] = m_events[j];
            m_events[j] = tmp;
         }
   
   // Pick first future event
   m_nextEvent.name = "";
   m_nextEvent.time = 0;
   m_nextEvent.isNYO = false;
   
   for(int i = 0; i < m_eventCount; i++)
   {
      if(m_events[i].time > TimeGMT())
      {
         m_nextEvent = m_events[i];
         break;
      }
   }
}

//+------------------------------------------------------------------+
void CNewsManager::Update()
{
   // Refresh every 60 seconds
   if(TimeCurrent() - m_lastUpdate < 60 && m_lastUpdate > 0) return;
   m_lastUpdate = TimeCurrent();
   
   if(!m_nyoOnly) FetchCalendarEvents();
   InsertNYOEvent();
   SortAndPickNext();
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
   
   // Truncate name
   string name = m_nextEvent.name;
   if(StringLen(name) > 24) name = StringSubstr(name, 0, 24) + "..";
   
   string timeStr = StringFormat("%02d:%02d, %02d %s", dt.hour, dt.min, dt.day, mon);
   
   return name + " | " + timeStr;
}

#endif // __NEWSMANAGER_MQH__
