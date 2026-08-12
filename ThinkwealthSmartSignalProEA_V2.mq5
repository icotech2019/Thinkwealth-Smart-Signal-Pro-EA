//+------------------------------------------------------------------+
//| Thinkwealth Smart Signal Pro EA V2                              |
//| MACD + Stochastic + Parabolic SAR | Signal timeframe: M5        |
//| Test on demo first. Trading involves substantial risk.          |
//+------------------------------------------------------------------+
#property strict
#property version "2.00"
#property description "Thinkwealth Smart Signal Pro EA V2"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

CTrade trade;
CPositionInfo pos;

#define SIGNAL_TF PERIOD_M5

input group "Strategy"
input bool EnableBuyTrades=true;
input bool EnableSellTrades=true;
input bool AutoTrading=true;
input bool OnlyNewCandle=true;
input bool OneTradeAtATime=true;
input bool RequireStochZone=true;
input double OversoldLevel=20.0;
input double OverboughtLevel=80.0;

input group "MACD"
input int MACDFast=12;
input int MACDSlow=26;
input int MACDSignal=9;

input group "Stochastic"
input int StochK=14;
input int StochD=3;
input int StochSlowing=3;

input group "Parabolic SAR"
input double SARStep=0.02;
input double SARMaximum=0.20;

input group "Risk Management"
input bool UseRiskBasedLot=false;
input double FixedLotSize=0.10;
input double RiskPercent=2.0;
input int StopLossPoints=100;
input int TakeProfitPoints=200;
input double RiskRewardRatio=0.0;
input int MaxOpenTrades=1;
input int MaxTradesPerDay=0;
input double MaxDailyLoss=0.0;
input double DailyProfitTarget=0.0;
input double MaxSpreadPoints=0.0;
input ulong MagicNumber=20260812;
input int SlippagePoints=50;

input group "Trade Management"
input bool UseBreakEven=false;
input int BreakEvenTriggerPoints=50;
input bool UseTrailingStop=false;
input int TrailingStopPoints=50;

input group "Trading Hours"
input bool UseTradingHours=false;
input int TradingStartHour=8;
input int TradingEndHour=18;

input group "Alerts"
input bool AlertsEnabled=true;
input bool SoundAlertEnabled=true;
input string AlertSoundFile="alert.wav";
input bool PushNotificationEnabled=false;
input bool EmailNotificationEnabled=false;

input group "Display"
input bool ShowArrows=true;
input bool ShowDashboard=true;

int hMACD=INVALID_HANDLE;
int hStoch=INVALID_HANDLE;
int hSAR=INVALID_HANDLE;
double macdMain[],macdSignal[],stochK[],stochD[],sar[];
datetime lastBar=0;
datetime lastSignalBar=0;
int lastSignalDirection=0;
datetime lastAlert=0;

int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(SlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   hMACD=iMACD(_Symbol,SIGNAL_TF,MACDFast,MACDSlow,MACDSignal,PRICE_CLOSE);
   hStoch=iStochastic(_Symbol,SIGNAL_TF,StochK,StochD,StochSlowing,MODE_SMA,STO_LOWHIGH);
   hSAR=iSAR(_Symbol,SIGNAL_TF,SARStep,SARMaximum);
   if(hMACD==INVALID_HANDLE || hStoch==INVALID_HANDLE || hSAR==INVALID_HANDLE)
   {
      Print("Indicator initialization failed. Error=",GetLastError());
      return INIT_FAILED;
   }
   ArraySetAsSeries(macdMain,true); ArraySetAsSeries(macdSignal,true);
   ArraySetAsSeries(stochK,true); ArraySetAsSeries(stochD,true); ArraySetAsSeries(sar,true);
   Print("Thinkwealth Smart Signal Pro EA V2 initialized. Signals use M5.");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(hMACD!=INVALID_HANDLE) IndicatorRelease(hMACD);
   if(hStoch!=INVALID_HANDLE) IndicatorRelease(hStoch);
   if(hSAR!=INVALID_HANDLE) IndicatorRelease(hSAR);
   ObjectDelete(0,"TW_V2_DASH");
}

void OnTick()
{
   ManageTrades();
   if(ShowDashboard) UpdateDashboard();
   if(!AutoTrading && !EnableBuyTrades && !EnableSellTrades) return;
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)) return;
   if(OnlyNewCandle && !IsNewM5Bar()) return;
   if(!LoadIndicators()) return;
   if(!TradingTimeOK()) return;
   if(MaxSpreadPoints>0 && SpreadPoints()>MaxSpreadPoints) return;
   if(!DailyLimitsOK()) return;
   if(CountOpenTrades()>=MaxOpenTrades) return;

   bool buy=EnableBuyTrades && BuySignal();
   bool sell=EnableSellTrades && SellSignal();
   if(buy) ProcessSignal(true);
   if(sell && (!OneTradeAtATime || CountOpenTrades()==0)) ProcessSignal(false);
}

bool LoadIndicators()
{
   if(BarsCalculated(hMACD)<5 || BarsCalculated(hStoch)<5 || BarsCalculated(hSAR)<5) return false;
   if(CopyBuffer(hMACD,0,0,4,macdMain)<4) return false;
   if(CopyBuffer(hMACD,1,0,4,macdSignal)<4) return false;
   if(CopyBuffer(hStoch,0,0,4,stochK)<4) return false;
   if(CopyBuffer(hStoch,1,0,4,stochD)<4) return false;
   if(CopyBuffer(hSAR,0,0,4,sar)<4) return false;
   return true;
}

bool BuySignal()
{
   double close=iClose(_Symbol,SIGNAL_TF,1);
   bool macd=macdMain[2]<=macdSignal[2] && macdMain[1]>macdSignal[1];
   bool stoch=stochK[2]<=stochD[2] && stochK[1]>stochD[1];
   bool zone=!RequireStochZone || stochK[2]<=OversoldLevel;
   return macd && stoch && zone && sar[1]<close;
}

bool SellSignal()
{
   double close=iClose(_Symbol,SIGNAL_TF,1);
   bool macd=macdMain[2]>=macdSignal[2] && macdMain[1]<macdSignal[1];
   bool stoch=stochK[2]>=stochD[2] && stochK[1]<stochD[1];
   bool zone=!RequireStochZone || stochK[2]>=OverboughtLevel;
   return macd && stoch && zone && sar[1]>close;
}

void ProcessSignal(bool buy)
{
   datetime bar=iTime(_Symbol,SIGNAL_TF,1);
   int dir=buy?1:-1;
   if(bar==lastSignalBar && dir==lastSignalDirection) return;

   bool ok=!AutoTrading;
   if(AutoTrading) ok=buy?OpenBuy():OpenSell();
   if(!ok) return;

   lastSignalBar=bar; lastSignalDirection=dir;
   if(ShowArrows) DrawSignalArrow(buy,bar);
   SendSignalAlert(buy);
}

bool OpenBuy()
{
   double lot=CalculateLot();
   if(lot<=0) return false;
   double price=SymbolInfoDouble(_Symbol,SYMBOL_ASK),sl,tp;
   MakeStops(true,price,sl,tp);
   if(!ValidateStops(true,price,sl,tp)) return false;
   if(!trade.Buy(lot,_Symbol,0,sl,tp,"Thinkwealth V2 BUY"))
   {
      Print("BUY failed: ",trade.ResultRetcode()," ",trade.ResultRetcodeDescription());
      return false;
   }
   return true;
}

bool OpenSell()
{
   double lot=CalculateLot();
   if(lot<=0) return false;
   double price=SymbolInfoDouble(_Symbol,SYMBOL_BID),sl,tp;
   MakeStops(false,price,sl,tp);
   if(!ValidateStops(false,price,sl,tp)) return false;
   if(!trade.Sell(lot,_Symbol,0,sl,tp,"Thinkwealth V2 SELL"))
   {
      Print("SELL failed: ",trade.ResultRetcode()," ",trade.ResultRetcodeDescription());
      return false;
   }
   return true;
}

double CalculateLot()
{
   if(!UseRiskBasedLot) return NormalizeLot(FixedLotSize);
   if(StopLossPoints<=0 || RiskPercent<=0) return NormalizeLot(FixedLotSize);
   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney=balance*RiskPercent/100.0;
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tickValue<=0) tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tickSize=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(tickValue<=0 || tickSize<=0 || point<=0) return NormalizeLot(FixedLotSize);
   double lossPerLot=(StopLossPoints*point/tickSize)*tickValue;
   if(lossPerLot<=0) return NormalizeLot(FixedLotSize);
   return NormalizeLot(riskMoney/lossPerLot);
}

double NormalizeLot(double lot)
{
   double min=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double max=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(min<=0 || max<=0 || step<=0) return 0;
   lot=MathMax(min,MathMin(max,lot));
   lot=MathFloor(lot/step+1e-9)*step;
   if(lot<min) lot=min;
   int digits=0; double x=step;
   while(digits<8 && MathAbs(x-MathRound(x))>1e-8){x*=10;digits++;}
   return NormalizeDouble(lot,digits);
}

void MakeStops(bool buy,double price,double &sl,double &tp)
{
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double s=(StopLossPoints>0?StopLossPoints*point:0);
   double t=(RiskRewardRatio>0 && s>0)?s*RiskRewardRatio:(TakeProfitPoints>0?TakeProfitPoints*point:0);
   sl=0; tp=0;
   if(buy){if(s>0)sl=price-s;if(t>0)tp=price+t;}
   else{if(s>0)sl=price+s;if(t>0)tp=price-t;}
   if(sl>0)sl=NormalizeDouble(sl,_Digits);
   if(tp>0)tp=NormalizeDouble(tp,_Digits);
}

bool ValidateStops(bool buy,double price,double &sl,double &tp)
{
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double minDist=MathMax((double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*point,point);
   if(buy)
   {
      if(sl>0 && price-sl<minDist) sl=price-minDist;
      if(tp>0 && tp-price<minDist) tp=price+minDist;
      if(sl>0 && sl>=price)return false;
      if(tp>0 && tp<=price)return false;
   }
   else
   {
      if(sl>0 && sl-price<minDist) sl=price+minDist;
      if(tp>0 && price-tp<minDist) tp=price-minDist;
      if(sl>0 && sl<=price)return false;
      if(tp>0 && tp>=price)return false;
   }
   sl=sl>0?NormalizeDouble(sl,_Digits):0;
   tp=tp>0?NormalizeDouble(tp,_Digits):0;
   return true;
}

void ManageTrades()
{
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double minDist=MathMax((double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*point,point);
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i)) continue;
      if(pos.Symbol()!=_Symbol || pos.Magic()!=MagicNumber) continue;
      ulong ticket=pos.Ticket();
      ENUM_POSITION_TYPE type=pos.PositionType();
      double open=pos.PriceOpen(),oldSL=pos.StopLoss(),tp=pos.TakeProfit();
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID),ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double newSL=oldSL;

      if(UseBreakEven && BreakEvenTriggerPoints>0)
      {
         double trigger=BreakEvenTriggerPoints*point;
         if(type==POSITION_TYPE_BUY && bid-open>=trigger && (oldSL==0 || oldSL<open)) newSL=open;
         if(type==POSITION_TYPE_SELL && open-ask>=trigger && (oldSL==0 || oldSL>open)) newSL=open;
      }
      if(UseTrailingStop && TrailingStopPoints>0)
      {
         double trail=TrailingStopPoints*point;
         if(type==POSITION_TYPE_BUY){double c=bid-trail;if(c>newSL && c<bid-minDist)newSL=c;}
         else{double c=ask+trail;if((newSL==0 || c<newSL) && c>ask+minDist)newSL=c;}
      }
      if(newSL<=0) continue;
      newSL=NormalizeDouble(newSL,_Digits);
      bool improve=(type==POSITION_TYPE_BUY)?(oldSL==0 || newSL>oldSL):(oldSL==0 || newSL<oldSL);
      if(improve && !trade.PositionModify(ticket,newSL,tp))
         Print("PositionModify failed: ",trade.ResultRetcode()," ",trade.ResultRetcodeDescription());
   }
}

int CountOpenTrades()
{
   int n=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      if(!pos.SelectByIndex(i))continue;
      if(pos.Symbol()==_Symbol && pos.Magic()==MagicNumber)n++;
   }
   return n;
}

bool DailyLimitsOK()
{
   double p=DailyProfit();
   if(MaxDailyLoss>0 && p<=-MathAbs(MaxDailyLoss))return false;
   if(DailyProfitTarget>0 && p>=DailyProfitTarget)return false;
   if(MaxTradesPerDay>0 && TradesToday()>=MaxTradesPerDay)return false;
   return true;
}

double DailyProfit()
{
   datetime start=iTime(_Symbol,PERIOD_D1,0);
   if(!HistorySelect(start,TimeCurrent()))return 0;
   double p=0;
   for(int i=0;i<HistoryDealsTotal();i++)
   {
      ulong t=HistoryDealGetTicket(i); if(t==0)continue;
      if((ulong)HistoryDealGetInteger(t,DEAL_MAGIC)!=MagicNumber)continue;
      if(HistoryDealGetString(t,DEAL_SYMBOL)!=_Symbol)continue;
      p+=HistoryDealGetDouble(t,DEAL_PROFIT)+HistoryDealGetDouble(t,DEAL_SWAP)+HistoryDealGetDouble(t,DEAL_COMMISSION);
   }
   return p;
}

int TradesToday()
{
   datetime start=iTime(_Symbol,PERIOD_D1,0);
   if(!HistorySelect(start,TimeCurrent()))return 0;
   int n=0;
   for(int i=0;i<HistoryDealsTotal();i++)
   {
      ulong t=HistoryDealGetTicket(i); if(t==0)continue;
      if((ulong)HistoryDealGetInteger(t,DEAL_MAGIC)!=MagicNumber)continue;
      if(HistoryDealGetString(t,DEAL_SYMBOL)!=_Symbol)continue;
      long entry=HistoryDealGetInteger(t,DEAL_ENTRY);
      if(entry==DEAL_ENTRY_IN || entry==DEAL_ENTRY_INOUT)n++;
   }
   return n;
}

bool IsNewM5Bar()
{
   datetime t=iTime(_Symbol,SIGNAL_TF,0);
   if(t<=0)return false;
   if(t!=lastBar){lastBar=t;return true;}
   return false;
}

bool TradingTimeOK()
{
   if(!UseTradingHours)return true;
   MqlDateTime tm; TimeToStruct(TimeCurrent(),tm);
   if(TradingStartHour==TradingEndHour)return true;
   if(TradingStartHour<TradingEndHour)return tm.hour>=TradingStartHour && tm.hour<TradingEndHour;
   return tm.hour>=TradingStartHour || tm.hour<TradingEndHour;
}

double SpreadPoints()
{
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(point<=0)return 0;
   return (SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/point;
}

void DrawSignalArrow(bool buy,datetime bar)
{
   string name=StringFormat("TW_V2_%s_%I64d",buy?"BUY":"SELL",bar);
   double price=buy?iLow(_Symbol,SIGNAL_TF,1):iHigh(_Symbol,SIGNAL_TF,1);
   ObjectDelete(0,name);
   if(!ObjectCreate(0,name,OBJ_ARROW,0,bar,price))return;
   ObjectSetInteger(0,name,OBJPROP_ARROWCODE,buy?233:234);
   ObjectSetInteger(0,name,OBJPROP_COLOR,buy?clrGreen:clrRed);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,2);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}

void SendSignalAlert(bool buy)
{
   if(TimeCurrent()-lastAlert<3)return;
   lastAlert=TimeCurrent();
   string msg=StringFormat("Thinkwealth V2 %s SIGNAL - %s M5",buy?"BUY":"SELL",_Symbol);
   if(AlertsEnabled)Alert(msg);
   if(SoundAlertEnabled)PlaySound(AlertSoundFile);
   if(PushNotificationEnabled)SendNotification(msg);
   if(EmailNotificationEnabled)SendMail(buy?"Thinkwealth V2 BUY":"Thinkwealth V2 SELL",msg);
}

void UpdateDashboard()
{
   string name="TW_V2_DASH";
   if(ObjectFind(0,name)<0)ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   string txt="THINKWEALTH SMART SIGNAL PRO V2\n"+
      "Signal: M5 | "+_Symbol+"\n"+
      "MACD: "+DoubleToString(macdMain[1],6)+" / "+DoubleToString(macdSignal[1],6)+"\n"+
      "Stoch: "+DoubleToString(stochK[1],2)+" / "+DoubleToString(stochD[1],2)+"\n"+
      "SAR: "+DoubleToString(sar[1],_Digits)+"\n"+
      "Spread: "+DoubleToString(SpreadPoints(),1)+" pts\n"+
      "Open: "+IntegerToString(CountOpenTrades())+" / "+IntegerToString(MaxOpenTrades)+"\n"+
      "Today: "+IntegerToString(TradesToday())+" trades | P/L "+DoubleToString(DailyProfit(),2);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,10);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,25);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,10);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
}
