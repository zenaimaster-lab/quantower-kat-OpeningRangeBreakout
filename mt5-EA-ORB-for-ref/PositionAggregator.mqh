//+------------------------------------------------------------------+
//|                                             PositionAggregator.mqh |
//|         Reusable position aggregation for BE / trail / exposure    |
//+------------------------------------------------------------------+
#ifndef __POSITIONAGGREGATOR_MQH__
#define __POSITIONAGGREGATOR_MQH__

#include "Defines.mqh"

//+------------------------------------------------------------------+
//| Aggregate position data for a symbol + magic                       |
//+------------------------------------------------------------------+
struct SPositionAggregate
{
   double   totalLots;
   double   weightedEntry;
   double   buyLots;
   double   sellLots;
   int      ticketCount;
   ulong    tickets[];
   int      dominantType; // POSITION_TYPE_BUY or POSITION_TYPE_SELL, -1 if empty

   SPositionAggregate()
   {
      totalLots = 0;
      weightedEntry = 0;
      buyLots = 0;
      sellLots = 0;
      ticketCount = 0;
      dominantType = -1;
      ArrayResize(tickets, 0);
   }
};

//+------------------------------------------------------------------+
//| CPositionAggregator — collects positions matching symbol/magic     |
//+------------------------------------------------------------------+
class CPositionAggregator
{
public:
   static void Collect(string symbol, int magic, SPositionAggregate &out);
};

//+------------------------------------------------------------------+
void CPositionAggregator::Collect(string symbol, int magic, SPositionAggregate &out)
{
   out.totalLots = 0;
   out.weightedEntry = 0;
   out.buyLots = 0;
   out.sellLots = 0;
   out.ticketCount = 0;
   out.dominantType = -1;
   ArrayResize(out.tickets, 0);
   int total = PositionsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != magic) continue;

      double vol   = PositionGetDouble(POSITION_VOLUME);
      double price = PositionGetDouble(POSITION_PRICE_OPEN);
      long   type  = PositionGetInteger(POSITION_TYPE);

      if(type == POSITION_TYPE_BUY) out.buyLots += vol;
      else                          out.sellLots += vol;

      out.totalLots      += vol;
      out.weightedEntry  += price * vol;

      int n = out.ticketCount;
      ArrayResize(out.tickets, n + 1);
      out.tickets[n] = ticket;
      out.ticketCount++;
   }

   if(out.totalLots > 0)
   {
      out.weightedEntry /= out.totalLots;
      out.dominantType = (out.buyLots >= out.sellLots) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   }
}

#endif // __POSITIONAGGREGATOR_MQH__
