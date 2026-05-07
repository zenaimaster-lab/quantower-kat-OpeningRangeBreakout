//+------------------------------------------------------------------+
//|                                                 OrderManager.mqh |
//|                    Opening Sniper EA — OCO Order Placement Logic  |
//|                                                      Version 2.0 |
//+------------------------------------------------------------------+
#ifndef __ORDERMANAGER_MQH__
#define __ORDERMANAGER_MQH__

#include "Defines.mqh"
#include "RiskManager.mqh"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| COrderManager — places OCO Buy Stop / Sell Stop orders            |
//+------------------------------------------------------------------+
class COrderManager
{
private:
   CTrade            m_trade;
   CRiskManager      m_riskMgr;
   string            m_lastOcoTag;     // Comment tag for current OCO pair
   bool              m_ordersActive;    // Whether we have pending OCO orders
   int               m_ocoCounter;     // Counter for unique OCO tags
   
   // Missing orders tracking
   bool              m_missingBuy;
   double            m_buyStopPrice, m_buySL, m_buyTP, m_buyLot;
   bool              m_missingSell;
   double            m_sellStopPrice, m_sellSL, m_sellTP, m_sellLot;
   string            m_missingSymbol;
   datetime          m_placedTime;
   ENUM_TIMEFRAMES   m_placedTf;
   
public:
                     COrderManager();
                    ~COrderManager() {}
   
   //--- Core methods
   void              Init() { m_trade.SetExpertMagicNumber(g_magic); }
   bool              PlaceOCOOrders(const DashboardParams &params);
   void              CheckOCO();
   void              ProcessMissingOrders();
   void              CancelAllPending(string symbol);
   void              CheckExpire(const DashboardParams &params);
   void              FlattenAll(string symbol);
   void              ApplySettings(const DashboardParams &params);
   void              ClearOrigamiPositions(string symbol);
   
   //--- OCO handler — call from OnTradeTransaction
   void              OnTransaction(const MqlTradeTransaction &trans,
                                    const MqlTradeRequest &request,
                                    const MqlTradeResult &result);
   
   //--- Status
   bool              HasActiveOrders() const { return m_ordersActive; }
   string            GetLastTag() const { return m_lastOcoTag; }
   string            GetStatus() const;
   bool              BuyMarket(const DashboardParams &params);
   bool              SellMarket(const DashboardParams &params);
   bool              BuyMarketEx(double lot, double sl, double tp, string symbol);
   bool              SellMarketEx(double lot, double sl, double tp, string symbol);
   bool              LockAll(string symbol);
   bool              ReverseAll(const DashboardParams &params);
   
   //--- Virtual properties for testing
   virtual double    GetPoint(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_POINT); }
   virtual int       GetDigits(string symbol) { return (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS); }
   virtual int       GetSpread(string symbol) { return (int)SymbolInfoInteger(symbol, SYMBOL_SPREAD); }
   virtual double    GetAsk(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_ASK); }
   virtual double    GetBid(string symbol) { return SymbolInfoDouble(symbol, SYMBOL_BID); }
   virtual int       GetStopsLevel(string symbol) { return (int)SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL); }

private:
   //--- Internal helpers
   string            GenerateOcoTag();
   bool              GetCandleRange(string symbol, ENUM_TIMEFRAMES tf, int shift, double &high, double &low);
   void              CancelPendingByTag(string tag);
   int               CountPendingByTag(string tag);
   int               CountPositionsByTag(string tag);
};

//+------------------------------------------------------------------+
COrderManager::COrderManager()
{
   m_trade.SetDeviationInPoints(30);
   m_lastOcoTag    = "";
   m_ordersActive  = false;
   m_ocoCounter    = 0;
   
   m_missingBuy    = false;
   m_missingSell   = false;
   m_missingSymbol = "";
   m_placedTime    = 0;
   m_placedTf      = PERIOD_M2;
}

//+------------------------------------------------------------------+
string COrderManager::GenerateOcoTag()
{
   m_ocoCounter++;
   return EA_COMMENT_PREFIX + IntegerToString(TimeCurrent()) + "_" + IntegerToString(m_ocoCounter);
}

//+------------------------------------------------------------------+
bool COrderManager::GetCandleRange(string symbol, ENUM_TIMEFRAMES tf, int shift, double &high, double &low)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   
   int copied = CopyRates(symbol, tf, shift, 1, rates);
   if(copied < 1)
   {
      PrintFormat("[OrderMgr] ERROR: CopyRates failed for %s %s. Err=%d", 
                  symbol, TimeframeToString(tf), GetLastError());
      return false;
   }
   
   high = rates[0].high;
   low  = rates[0].low;
   
   PrintFormat("[OrderMgr] Candle %s %s | High=%.5f Low=%.5f", 
               symbol, TimeframeToString(tf), high, low);
   
   return true;
}

//+------------------------------------------------------------------+
bool COrderManager::PlaceOCOOrders(const DashboardParams &params)
{
   string symbol = params.symbol;
   
   //--- Validate symbol
   bool isCustom = false;
   if(!SymbolExist(symbol, isCustom))
   {
      PrintFormat("[OrderMgr] ERROR: Symbol %s does not exist", symbol);
      return false;
   }
   
   //--- Ensure symbol is in Market Watch
   SymbolSelect(symbol, true);
   
   //--- Get candle range
   double candleHigh = 0, candleLow = 0;
   int shift = (params.candleSource == CANDLE_PREVIOUS) ? 1 : 0;
   if(!GetCandleRange(symbol, params.timeframe, shift, candleHigh, candleLow))
      return false;
   
   if(candleHigh <= 0 || candleLow <= 0 || candleHigh <= candleLow)
   {
      PrintFormat("[OrderMgr] ERROR: Invalid candle range H=%.5f L=%.5f", candleHigh, candleLow);
      return false;
   }
   
   //--- Symbol properties
   double point  = GetPoint(symbol);
   int    digits = GetDigits(symbol);
   int    spread = GetSpread(symbol);
   double ask    = GetAsk(symbol);
   double bid    = GetBid(symbol);
   int    stops  = GetStopsLevel(symbol);
   
   if(point <= 0) return false;
   
   //--- Calculate SL/TP adjustments
   int exactLossPoints = params.slPoints;
   if(params.slCandle) {
       exactLossPoints = (int)MathRound((candleHigh - candleLow) / point) + 2 * params.entryBufferPoints + spread;
   }
   
   //--- Calculate lot size
   double lotSize = m_riskMgr.CalcLotSize(symbol, params.riskPercent, exactLossPoints);
   if(lotSize <= 0) return false;
   
   //--- Generate OCO tag
   string ocoTag = GenerateOcoTag();
   m_lastOcoTag = ocoTag;
   
   //--- Calculate order prices
   // Buy Stop triggers at Ask. To ensure the chart (Bid) breaks the high, we add spread + buffer.
   int buyBuffer = params.entryBufferPoints + spread;
   double buyStopPrice = NormalizeDouble(candleHigh + buyBuffer * point, digits);
   
   // Sell Stop triggers at Bid. The chart (Bid) matches this directly, so only buffer is needed.
   int sellBuffer = params.entryBufferPoints;
   double sellStopPrice = NormalizeDouble(candleLow - sellBuffer * point, digits);
   
   //--- Calculate SL/TP levels
   double buySL = 0, sellSL = 0;
   if(params.slCandle) {
       buySL = NormalizeDouble(candleLow - params.entryBufferPoints * point, digits);
       sellSL = NormalizeDouble(candleHigh + (params.entryBufferPoints + spread) * point, digits);
   } else if (params.slPoints > 0) {
       buySL = NormalizeDouble(buyStopPrice - exactLossPoints * point, digits);
       sellSL = NormalizeDouble(sellStopPrice + exactLossPoints * point, digits);
   }
   
   int tpAdjust = params.tpPoints;
   double buyTP = (params.tpPoints > 0) ? NormalizeDouble(buyStopPrice + tpAdjust * point, digits) : 0;
   double sellTP = (params.tpPoints > 0) ? NormalizeDouble(sellStopPrice - tpAdjust * point, digits) : 0;
   
   //--- Check existing orders/positions to prevent duplication
   bool buyExists = false;
   bool sellExists = false;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong t = OrderGetTicket(i);
      if(OrderSelect(t) && OrderGetInteger(ORDER_MAGIC) == g_magic && OrderGetString(ORDER_SYMBOL) == symbol) {
         long type = OrderGetInteger(ORDER_TYPE);
         if(type == ORDER_TYPE_BUY_STOP) buyExists = true;
         if(type == ORDER_TYPE_SELL_STOP) sellExists = true;
      }
   }
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong t = PositionGetTicket(i);
      if(t > 0 && PositionGetInteger(POSITION_MAGIC) == g_magic && PositionGetString(POSITION_SYMBOL) == symbol) {
         long type = PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY) buyExists = true;
         if(type == POSITION_TYPE_SELL) sellExists = true;
      }
   }
   
   bool buyPlaced  = false;
   bool sellPlaced = false;
   m_missingSymbol = symbol;
   
   if(params.orderMode == MODE_BOTH || params.orderMode == MODE_BUY_ONLY)
   {
      if(!buyExists)
      {
         if(buyStopPrice <= ask + stops * point)
         {
            m_missingBuy = true;
            m_buyStopPrice = buyStopPrice; m_buySL = buySL; m_buyTP = buyTP; m_buyLot = lotSize;
            PrintFormat("[OrderMgr] BuyStop at %.5f too close to Ask %.5f, queued for later.", buyStopPrice, ask);
         }
         else
         {
            buyPlaced = m_trade.BuyStop(lotSize, buyStopPrice, symbol, buySL, buyTP, ORDER_TIME_GTC, 0, ocoTag);
            if(buyPlaced)
            {
               m_missingBuy = false;
               PrintFormat("[OrderMgr] BUY STOP placed: Price=%.5f SL=%.5f TP=%.5f Lot=%.2f Tag=%s",
                           buyStopPrice, buySL, buyTP, lotSize, ocoTag);
            }
         }
      }
      else
      {
         m_missingBuy = false;
         PrintFormat("[OrderMgr] Buy order/pos exists, skipping BuyStop.");
      }
   }
   else m_missingBuy = false;
   
   if(params.orderMode == MODE_BOTH || params.orderMode == MODE_SELL_ONLY)
   {
      if(!sellExists)
      {
         if(sellStopPrice >= bid - stops * point)
         {
            m_missingSell = true;
            m_sellStopPrice = sellStopPrice; m_sellSL = sellSL; m_sellTP = sellTP; m_sellLot = lotSize;
            PrintFormat("[OrderMgr] SellStop at %.5f too close to Bid %.5f, queued for later.", sellStopPrice, bid);
         }
         else
         {
            sellPlaced = m_trade.SellStop(lotSize, sellStopPrice, symbol, sellSL, sellTP, ORDER_TIME_GTC, 0, ocoTag);
            if(sellPlaced)
            {
               m_missingSell = false;
               PrintFormat("[OrderMgr] SELL STOP placed: Price=%.5f SL=%.5f TP=%.5f Lot=%.2f Tag=%s",
                           sellStopPrice, sellSL, sellTP, lotSize, ocoTag);
            }
         }
      }
      else
      {
         m_missingSell = false;
         PrintFormat("[OrderMgr] Sell order/pos exists, skipping SellStop.");
      }
   }
   else m_missingSell = false;
   
   m_ordersActive = (buyPlaced || sellPlaced || m_missingBuy || m_missingSell);
   if(m_ordersActive) { m_placedTime = TimeCurrent(); m_placedTf = params.timeframe; }
   return m_ordersActive;
}

//+------------------------------------------------------------------+
void COrderManager::ProcessMissingOrders()
{
   if(!m_missingBuy && !m_missingSell) return;
   
   string symbol = m_missingSymbol;
   if(symbol == "") return;
   
   double ask    = GetAsk(symbol);
   double bid    = GetBid(symbol);
   double point  = GetPoint(symbol);
   int    stops  = GetStopsLevel(symbol);
   
   if(m_missingBuy)
   {
      if(m_buyStopPrice > ask + stops * point)
      {
         if(m_trade.BuyStop(m_buyLot, m_buyStopPrice, symbol, m_buySL, m_buyTP, ORDER_TIME_GTC, 0, m_lastOcoTag))
         {
            m_missingBuy = false;
            m_ordersActive = true;
            PrintFormat("[OrderMgr] Missing BUY STOP placed automatically: Price=%.5f", m_buyStopPrice);
         }
      }
   }
   
   if(m_missingSell)
   {
      if(m_sellStopPrice < bid - stops * point)
      {
         if(m_trade.SellStop(m_sellLot, m_sellStopPrice, symbol, m_sellSL, m_sellTP, ORDER_TIME_GTC, 0, m_lastOcoTag))
         {
            m_missingSell = false;
            m_ordersActive = true;
            PrintFormat("[OrderMgr] Missing SELL STOP placed automatically: Price=%.5f", m_sellStopPrice);
         }
      }
   }
}

//+------------------------------------------------------------------+
void COrderManager::OnTransaction(const MqlTradeTransaction &trans,
                                   const MqlTradeRequest &request,
                                   const MqlTradeResult &result)
{
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD) return;
   if(!m_ordersActive) return;
   if(m_lastOcoTag == "") return;
   
   ulong dealTicket = trans.deal;
   if(dealTicket <= 0) return;
   
   HistorySelect(TimeCurrent() - 60, TimeCurrent() + 60);
   if(!HistoryDealSelect(dealTicket)) return;
   
   long dealMagic = HistoryDealGetInteger(dealTicket, DEAL_MAGIC);
   if(dealMagic != g_magic) return;
   
   string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
   
   if(StringFind(dealComment, m_lastOcoTag) >= 0 || 
      StringFind(dealComment, EA_COMMENT_PREFIX) >= 0)
   {
      PrintFormat("[OrderMgr] OCO TRIGGERED: Deal #%d filled. Cancelling remaining pending...", dealTicket);
      CancelPendingByTag(m_lastOcoTag);
      m_missingBuy = false;
      m_missingSell = false;
   }
}

//+------------------------------------------------------------------+
void COrderManager::CheckOCO()
{
   if(!m_ordersActive) return;
   if(m_lastOcoTag == "") return;
   
   int pendingCount  = CountPendingByTag(m_lastOcoTag);
   int positionCount = CountPositionsByTag(m_lastOcoTag);
   
   if(positionCount > 0 && pendingCount > 0)
   {
      PrintFormat("[OrderMgr] OCO backup check: %d positions, %d pending → cancelling pending", 
                  positionCount, pendingCount);
      CancelPendingByTag(m_lastOcoTag);
      m_missingBuy = false;
      m_missingSell = false;
   }
   
   if(pendingCount == 0 && !m_missingBuy && !m_missingSell)
   {
      m_ordersActive = false;
   }
}

//+------------------------------------------------------------------+
void COrderManager::CancelPendingByTag(string tag)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;
      
      string comment = OrderGetString(ORDER_COMMENT);
      if(StringFind(comment, tag) >= 0)
      {
         if(m_trade.OrderDelete(ticket))
            PrintFormat("[OrderMgr] Cancelled pending order #%d (OCO)", ticket);
      }
   }
}

//+------------------------------------------------------------------+
void COrderManager::CancelAllPending(string symbol)
{
   m_missingBuy = false;
   m_missingSell = false;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;
      if(OrderGetString(ORDER_SYMBOL) != symbol) continue;
      
      if(m_trade.OrderDelete(ticket))
         PrintFormat("[OrderMgr] Cancelled pending #%d for %s", ticket, symbol);
   }
   m_ordersActive = false;
}

//+------------------------------------------------------------------+
int COrderManager::CountPendingByTag(string tag)
{
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket)) continue;
      if(OrderGetInteger(ORDER_MAGIC) != g_magic) continue;
      
      string comment = OrderGetString(ORDER_COMMENT);
      if(StringFind(comment, tag) >= 0) count++;
   }
   return count;
}

//+------------------------------------------------------------------+
int COrderManager::CountPositionsByTag(string tag)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      
      string comment = PositionGetString(POSITION_COMMENT);
      if(StringFind(comment, tag) >= 0 || StringFind(comment, EA_COMMENT_PREFIX) >= 0) 
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
string COrderManager::GetStatus() const
{
   if(m_ordersActive) {
      if(m_missingBuy || m_missingSell) return "PENDING OCO (QUEUED)";
      return "PENDING OCO ACTIVE";
   }
   return "IDLE";
}

//+------------------------------------------------------------------+
void COrderManager::FlattenAll(string symbol)
{
   CancelAllPending(symbol);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      if(m_trade.PositionClose(ticket))
         PrintFormat("[OrderMgr] Flattened position #%d on %s", ticket, symbol);
   }
   m_ordersActive = false;
}

//+------------------------------------------------------------------+
void COrderManager::ClearOrigamiPositions(string symbol)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      
      string comment = PositionGetString(POSITION_COMMENT);
      if(StringFind(comment, EA_COMMENT_PREFIX + "ORIGAMI_") >= 0)
      {
         if(m_trade.PositionClose(ticket))
            PrintFormat("[OrderMgr] Cleared Origami position #%d on %s", ticket, symbol);
      }
   }
}

//+------------------------------------------------------------------+
void COrderManager::CheckExpire(const DashboardParams &params)
{
   if(!params.expireEnabled || !m_ordersActive || m_placedTime == 0) return;
   if(params.expireCandles <= 0) return;
   
   string symbol = params.symbol;
   if(symbol == "") return;
   
   int tfSec = PeriodSeconds(m_placedTf);
   if(tfSec <= 0) return;
   
   datetime expireAfter = m_placedTime + tfSec * params.expireCandles;
   if(TimeCurrent() >= expireAfter)
   {
      int pending = CountPendingByTag(m_lastOcoTag);
      if(pending > 0)
      {
         PrintFormat("[OrderMgr] EXPIRE: %d candles passed, cancelling %d pending orders", params.expireCandles, pending);
         CancelPendingByTag(m_lastOcoTag);
         m_missingBuy = false;
         m_missingSell = false;
         m_ordersActive = false;
      }
   }
}

//+------------------------------------------------------------------+
void COrderManager::ApplySettings(const DashboardParams &params)
{
   string symbol = params.symbol;
   double point  = GetPoint(symbol);
   int    digits = GetDigits(symbol);
   int    spread = GetSpread(symbol);
   
   int exactLossPoints = params.slPoints;
   int tpAdjust = params.tpPoints;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != g_magic) continue;
      if(PositionGetString(POSITION_SYMBOL) != symbol) continue;
      
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      long posType = PositionGetInteger(POSITION_TYPE);
      double newSL = 0, newTP = 0;
      
      if(params.slCandle) {
          int cIdx = (params.candleSource == CANDLE_CURRENT) ? 0 : 1;
          double candleHigh = iHigh(symbol, params.timeframe, cIdx);
          double candleLow = iLow(symbol, params.timeframe, cIdx);
          
          if(posType == POSITION_TYPE_BUY)
              newSL = NormalizeDouble(candleLow - params.entryBufferPoints * point, digits);
          else
              newSL = NormalizeDouble(candleHigh + (params.entryBufferPoints + spread) * point, digits);
      } else if(params.slPoints > 0) {
          if(posType == POSITION_TYPE_BUY)
              newSL = NormalizeDouble(openPrice - exactLossPoints * point, digits);
          else
              newSL = NormalizeDouble(openPrice + exactLossPoints * point, digits);
      }
      
      if(posType == POSITION_TYPE_BUY)
         newTP = (params.tpPoints > 0) ? NormalizeDouble(openPrice + tpAdjust * point, digits) : 0;
      else
         newTP = (params.tpPoints > 0) ? NormalizeDouble(openPrice - tpAdjust * point, digits) : 0;
      
      if(m_trade.PositionModify(ticket, newSL, newTP))
         PrintFormat("[OrderMgr] Applied SL=%.5f TP=%.5f to #%d", newSL, newTP, ticket);
   }
}

//+------------------------------------------------------------------+
bool COrderManager::BuyMarket(const DashboardParams &params)
{
   string sym=params.symbol; if(sym=="") sym=Symbol();
   double ask=GetAsk(sym); double pt=GetPoint(sym); int dg=GetDigits(sym);
   int sp=GetSpread(sym);
   int exactLossPoints = params.slPoints;
   double sl=0;
   
   if(params.slCandle) {
       int cIdx = (params.candleSource == CANDLE_CURRENT) ? 0 : 1;
       double candleHigh = iHigh(sym, params.timeframe, cIdx);
       double candleLow = iLow(sym, params.timeframe, cIdx);
       sl = NormalizeDouble(candleLow - params.entryBufferPoints * pt, dg);
       exactLossPoints = (int)MathRound((ask - sl) / pt);
   } else if (params.slPoints > 0) {
       sl = NormalizeDouble(ask - exactLossPoints * pt, dg);
   }
   
   double lot = m_riskMgr.CalcLotSize(sym, params.riskPercent, exactLossPoints);
   if(lot<=0) return false;
   
   int tpAdjust = params.tpPoints;
   double tp=(params.tpPoints>0)?NormalizeDouble(ask+tpAdjust*pt,dg):0;
   return m_trade.Buy(lot,sym,ask,sl,tp,EA_COMMENT_PREFIX+"MKT_BUY");
}

//+------------------------------------------------------------------+
bool COrderManager::SellMarket(const DashboardParams &params)
{
   string sym=params.symbol; if(sym=="") sym=Symbol();
   double bid=GetBid(sym); double pt=GetPoint(sym); int dg=GetDigits(sym);
   int sp=GetSpread(sym);
   int exactLossPoints = params.slPoints;
   double sl=0;
   
   if(params.slCandle) {
       int cIdx = (params.candleSource == CANDLE_CURRENT) ? 0 : 1;
       double candleHigh = iHigh(sym, params.timeframe, cIdx);
       double candleLow = iLow(sym, params.timeframe, cIdx);
       sl = NormalizeDouble(candleHigh + (params.entryBufferPoints + sp) * pt, dg);
       exactLossPoints = (int)MathRound((sl - bid) / pt);
   } else if (params.slPoints > 0) {
       sl = NormalizeDouble(bid + exactLossPoints * pt, dg);
   }
   
   double lot = m_riskMgr.CalcLotSize(sym, params.riskPercent, exactLossPoints);
   if(lot<=0) return false;
   
   int tpAdjust = params.tpPoints;
   double tp=(params.tpPoints>0)?NormalizeDouble(bid-tpAdjust*pt,dg):0;
   return m_trade.Sell(lot,sym,bid,sl,tp,EA_COMMENT_PREFIX+"MKT_SELL");
}

//+------------------------------------------------------------------+
bool COrderManager::BuyMarketEx(double lot, double sl, double tp, string symbol)
{
   if(lot<=0) return false;
   double ask=GetAsk(symbol);
   return m_trade.Buy(lot,symbol,ask,sl,tp,EA_COMMENT_PREFIX+"ORIGAMI_BUY");
}

//+------------------------------------------------------------------+
bool COrderManager::SellMarketEx(double lot, double sl, double tp, string symbol)
{
   if(lot<=0) return false;
   double bid=GetBid(symbol);
   return m_trade.Sell(lot,symbol,bid,sl,tp,EA_COMMENT_PREFIX+"ORIGAMI_SELL");
}

//+------------------------------------------------------------------+
bool COrderManager::LockAll(string symbol)
{
   CancelAllPending(symbol);
   double buyVol=0, sellVol=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   { ulong t=PositionGetTicket(i); if(t<=0) continue;
     if(PositionGetString(POSITION_SYMBOL)!=symbol||PositionGetInteger(POSITION_MAGIC)!=g_magic) continue;
     // Remove SL/TP
     m_trade.PositionModify(t,0,0);
     if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) buyVol+=PositionGetDouble(POSITION_VOLUME);
     else sellVol+=PositionGetDouble(POSITION_VOLUME); }
   double net=buyVol-sellVol;
   if(MathAbs(net)<0.001) return true;
   if(net>0) return m_trade.Sell(net,symbol,0,0,0,EA_COMMENT_PREFIX+"LOCK");
   else return m_trade.Buy(-net,symbol,0,0,0,EA_COMMENT_PREFIX+"LOCK");
}

//+------------------------------------------------------------------+
bool COrderManager::ReverseAll(const DashboardParams &params)
{
   string sym=params.symbol; if(sym=="") sym=Symbol();
   CancelAllPending(sym);
   double buyVol=0, sellVol=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   { ulong t=PositionGetTicket(i); if(t<=0) continue;
     if(PositionGetString(POSITION_SYMBOL)!=sym||PositionGetInteger(POSITION_MAGIC)!=g_magic) continue;
     if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) buyVol+=PositionGetDouble(POSITION_VOLUME);
     else sellVol+=PositionGetDouble(POSITION_VOLUME); }
   // Close all positions
   FlattenAll(sym);
   double pt=GetPoint(sym); int dg=GetDigits(sym);
   int sp=GetSpread(sym);
   // Reverse: if was net long → sell, if was net short → buy
   if(buyVol>sellVol)
   { double bid=GetBid(sym); double vol=buyVol;
     int exactLossPoints = params.slPoints + sp;
     double sl=0;
     if(params.slCandle) {
         int cIdx = (params.candleSource == CANDLE_CURRENT) ? 0 : 1;
         double candleHigh = iHigh(sym, params.timeframe, cIdx);
         sl = NormalizeDouble(candleHigh + (params.entryBufferPoints + sp) * pt, dg);
     } else if (params.slPoints > 0) {
         sl = NormalizeDouble(bid + exactLossPoints * pt, dg);
     }
     int tpAdjust = params.tpPoints + sp;
     double tp=(params.tpPoints>0)?NormalizeDouble(bid-tpAdjust*pt,dg):0;
     return m_trade.Sell(vol,sym,bid,sl,tp,EA_COMMENT_PREFIX+"REV"); }
   else if(sellVol>buyVol)
   { double ask=GetAsk(sym); double vol=sellVol;
     int exactLossPoints = params.slPoints + sp;
     double sl=0;
     if(params.slCandle) {
         int cIdx = (params.candleSource == CANDLE_CURRENT) ? 0 : 1;
         double candleLow = iLow(sym, params.timeframe, cIdx);
         sl = NormalizeDouble(candleLow - params.entryBufferPoints * pt, dg);
     } else if (params.slPoints > 0) {
         sl = NormalizeDouble(ask - exactLossPoints * pt, dg);
     }
     int tpAdjust = params.tpPoints + sp;
     double tp=(params.tpPoints>0)?NormalizeDouble(ask+tpAdjust*pt,dg):0;
     return m_trade.Buy(vol,sym,ask,sl,tp,EA_COMMENT_PREFIX+"REV"); }
   return true;
}

#endif // __ORDERMANAGER_MQH__
