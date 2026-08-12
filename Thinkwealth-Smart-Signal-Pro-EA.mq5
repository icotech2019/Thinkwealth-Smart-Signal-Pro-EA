//+------------------------------------------------------------------+
//|                  Thinkwealth Smart Signal Pro EA                  |
//|                    Professional MetaTrader 5 Expert Advisor       |
//|                                                                    |
//| Strategy: MACD + Stochastic Oscillator + Parabolic SAR           |
//| Timeframe: M5 (5-minute)                                          |
//| Features: Signal Detection, Risk Management, Alerts, Dashboard   |
//|                                                                    |
//| DISCLAIMER: This EA is for educational and testing purposes only  |
//| Forex/CFD trading involves substantial risk. Trade at your own    |
//| risk and always backtest before live trading.                     |
//+------------------------------------------------------------------+

#property copyright "Thinkwealth Technologies"
#property link "https://thinkwealth.net"
#property version "1.00"
#property strict
#property description "Professional MACD + Stochastic + SAR EA for M5"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\DealInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Trading Strategy                              |
//+------------------------------------------------------------------+
group "=== Trading Strategy Settings ==="

input bool EnableBuyTrades = true;                    // Enable BUY trades
input bool EnableSellTrades = true;                   // Enable SELL trades
input bool AutoTrading = true;                        // Enable automatic trade execution
input int SignalConfirmationCandles = 0;             // Candles to confirm signal (0 = same candle)
input bool OnlyNewCandle = true;                     // Process only on new candle
input bool AvoidDuplicateSignals = true;             // Prevent duplicate signals on same bar

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - MACD Indicator Settings                       |
//+------------------------------------------------------------------+
group "=== MACD Settings ==="

input int MAConstituent_Fast = 12;                   // MACD Fast MA period
input int MAConstituent_Slow = 26;                   // MACD Slow MA period
input int MACDSignal = 9;                            // MACD Signal line period
input ENUM_MA_METHOD MAMethod = MODE_EMA;            // MACD MA method

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Stochastic Oscillator Settings                |
//+------------------------------------------------------------------+
group "=== Stochastic Settings ==="

input int Stoch_K_Period = 14;                       // Stochastic %K period
input int Stoch_D_Period = 3;                        // Stochastic %D period
input int Stoch_Slowing = 3;                         // Stochastic Slowing
input ENUM_MA_METHOD StochMethod = MODE_SMA;         // Stochastic MA method
input double OverboughtLevel = 80.0;                 // Overbought level
input double OversoldLevel = 20.0;                   // Oversold level

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Parabolic SAR Settings                        |
//+------------------------------------------------------------------+
group "=== Parabolic SAR Settings ==="

input double SAR_Step = 0.02;                        // SAR Step (initial AF)
input double SAR_Maximum = 0.2;                      // SAR Maximum AF

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Risk Management                               |
//+------------------------------------------------------------------+
group "=== Risk Management Settings ==="

input ENUM_POSITION_TYPE LotMode = POSITION_TYPE_BUY; // Lot Size Mode (POSITION_TYPE_BUY=Fixed, POSITION_TYPE_SELL=Percentage)
input double FixedLotSize = 0.1;                     // Fixed lot size (if Fixed mode)
input double RiskPercentage = 2.0;                   // Risk % per trade (if Percentage mode)
input int StopLossPoints = 100;                      // Stop Loss in points
input int TakeProfitPoints = 200;                    // Take Profit in points
input double RiskRewardRatio = 0.0;                  // Risk/Reward ratio (0 = disabled)
input int MaxOpenTrades = 5;                         // Maximum simultaneous open trades
input bool OneTradeAtATime = false;                  // Only one trade at a time
input double MaxSpread = 0.0;                        // Maximum spread in points (0 = no limit)
input int MaxTradesPerDay = 0;                       // Maximum trades per day (0 = unlimited)
input double MaxDailyLoss = 0.0;                     // Max daily loss (0 = unlimited)
input double DailyProfitTarget = 0.0;                // Daily profit target (0 = unlimited)
input uint MagicNumber = 20240812;                   // Magic number for EA trades
input int Slippage = 50;                             // Slippage/Deviation (points)

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Trade Protection                              |
//+------------------------------------------------------------------+
group "=== Trade Protection Settings ==="

input bool UseBreakEven = false;                     // Enable Break-Even
input int BreakEvenProfit = 50;                      // Break-Even profit (points)
input bool UseTrailingStop = false;                  // Enable Trailing Stop
input int TrailingStopPoints = 50;                   // Trailing Stop distance (points)
input bool UseSpreadProtection = true;               // Protect against wide spreads
input bool UseTradingHoursFilter = false;            // Enable trading hours filter
input int TradingStartHour = 8;                      // Trading start hour (24-hour format)
input int TradingEndHour = 18;                       // Trading end hour

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Alerts & Notifications                        |
//+------------------------------------------------------------------+
group "=== Alerts & Notifications ==="

input bool AlertsEnabled = true;                     // Enable MT5 popup alerts
input bool SoundAlertEnabled = true;                 // Enable sound alerts
input string AlertSoundFile = "alert.wav";           // Sound file name
input bool PushNotificationEnabled = false;          // Enable push notifications
input bool EmailNotificationEnabled = false;         // Enable email notifications
input string EmailAddress = "your@email.com";        // Email address

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Dashboard & Display                           |
//+------------------------------------------------------------------+
group "=== Dashboard & Display Settings ==="

input bool ShowDashboard = true;                     // Show information dashboard
input bool ShowArrows = true;                        // Show BUY/SELL arrows on chart
input ENUM_BASE_CORNER DashboardCorner = CORNER_LEFT_UPPER; // Dashboard corner
input int DashboardX = 10;                           // Dashboard X position
input int DashboardY = 30;                           // Dashboard Y position

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+

CTrade trade;                                        // Trade object
CPositionInfo positionInfo;                          // Position info object
COrderInfo orderInfo;                                // Order info object
CDealInfo dealInfo;                                  // Deal info object

// Indicator Handles
int macdHandle = INVALID_HANDLE;                     // MACD indicator handle
int stochHandle = INVALID_HANDLE;                    // Stochastic indicator handle
int sarHandle = INVALID_HANDLE;                      // Parabolic SAR handle

// Indicator Buffers
double macdLine[];                                   // MACD line
double signalLine[];                                 // Signal line
double histogram[];                                  // Histogram
double stochK[];                                     // Stochastic %K
double stochD[];                                     // Stochastic %D
double sar[];                                        // Parabolic SAR

// Signal Tracking
int lastSignalBar = -1;                              // Last bar with signal
bool lastSignalWasBuy = false;                       // Last signal was BUY
datetime lastAlertTime = 0;                          // Last alert time
int tradesOpenedToday = 0;                          // Trades opened today
double dailyProfit = 0.0;                            // Daily profit/loss

// Trading State
bool newCandle = false;                              // New candle flag
int prevBars = 0;                                    // Previous bar count

//+------------------------------------------------------------------+
//| Expert Initialization Function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set Magic Number for all trades
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(Slippage);
   
   // Initialize MACD Indicator
   macdHandle = iMACD(_Symbol, _Period, MAConstituent_Fast, MAConstituent_Slow, 
                      MACDSignal, PRICE_CLOSE);
   
   if (macdHandle == INVALID_HANDLE)
   {
      Alert("Failed to create MACD indicator handle");
      return INIT_FAILED;
   }
   
   // Initialize Stochastic Indicator
   stochHandle = iStochastic(_Symbol, _Period, Stoch_K_Period, Stoch_D_Period, 
                            Stoch_Slowing, StochMethod, STO_LOWHIGH);
   
   if (stochHandle == INVALID_HANDLE)
   {
      Alert("Failed to create Stochastic indicator handle");
      return INIT_FAILED;
   }
   
   // Initialize Parabolic SAR
   sarHandle = iSAR(_Symbol, _Period, SAR_Step, SAR_Maximum);
   
   if (sarHandle == INVALID_HANDLE)
   {
      Alert("Failed to create SAR indicator handle");
      return INIT_FAILED;
   }
   
   // Set array indices as series (descending order)
   ArraySetAsSeries(macdLine, true);
   ArraySetAsSeries(signalLine, true);
   ArraySetAsSeries(histogram, true);
   ArraySetAsSeries(stochK, true);
   ArraySetAsSeries(stochD, true);
   ArraySetAsSeries(sar, true);
   
   Print("Thinkwealth Smart Signal Pro EA initialized successfully");
   Print("Symbol: ", _Symbol, " | Timeframe: ", _Period, " | Magic: ", MagicNumber);
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert Deinitialization Function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Release indicator handles
   if (macdHandle != INVALID_HANDLE)
      IndicatorRelease(macdHandle);
   
   if (stochHandle != INVALID_HANDLE)
      IndicatorRelease(stochHandle);
   
   if (sarHandle != INVALID_HANDLE)
      IndicatorRelease(sarHandle);
   
   Print("Thinkwealth Smart Signal Pro EA deinitialized");
}

//+------------------------------------------------------------------+
//| Expert Tick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if AutoTrading is allowed
   if (!IsTradeAllowed())
   {
      if (ShowDashboard)
         DrawDashboard("EA Status: Trading NOT Allowed", "RED");
      return;
   }
   
   // Detect new candle
   newCandle = IsNewCandle();
   
   if (OnlyNewCandle && !newCandle)
      return; // Skip processing if not a new candle
   
   // Copy indicator data
   if (!CopyIndicatorData())
   {
      if (ShowDashboard)
         DrawDashboard("EA Status: Indicator Data Error", "RED");
      return;
   }
   
   // Check if trading is allowed at this time
   if (UseTradingHoursFilter && !IsTradingTimeAllowed())
   {
      if (ShowDashboard)
         DrawDashboard("EA Status: Outside Trading Hours", "ORANGE");
      return;
   }
   
   // Check spread protection
   if (UseSpreadProtection && GetCurrentSpread() > MaxSpread && MaxSpread > 0)
   {
      if (ShowDashboard)
         DrawDashboard("EA Status: Spread Too Wide", "ORANGE");
      return;
   }
   
   // Check daily limits
   if (!CheckDailyLimits())
   {
      if (ShowDashboard)
         DrawDashboard("EA Status: Daily Limit Reached", "RED");
      return;
   }
   
   // Check maximum trades
   int openTrades = CountOpenTrades();
   if (openTrades >= MaxOpenTrades)
   {
      if (ShowDashboard)
         DrawDashboard("EA Status: Max Trades Reached", "ORANGE");
      return;
   }
   
   // One trade at a time check
   if (OneTradeAtATime && openTrades > 0)
   {
      if (ShowDashboard)
         DrawDashboard("EA Status: One Trade Active", "ORANGE");
      return;
   }
   
   // Detect BUY Signal
   if (EnableBuyTrades && DetectBuySignal())
   {
      if (AvoidDuplicateSignals && lastSignalBar == (int)Bar() && lastSignalWasBuy)
      {
         // Skip duplicate signal
      }
      else
      {
         if (AutoTrading)
            ExecuteBuyTrade();
         
         lastSignalBar = (int)Bar();
         lastSignalWasBuy = true;
         
         if (ShowArrows)
            DrawBuyArrow();
         
         SendBuyAlerts();
      }
   }
   
   // Detect SELL Signal
   if (EnableSellTrades && DetectSellSignal())
   {
      if (AvoidDuplicateSignals && lastSignalBar == (int)Bar() && !lastSignalWasBuy)
      {
         // Skip duplicate signal
      }
      else
      {
         if (AutoTrading)
            ExecuteSellTrade();
         
         lastSignalBar = (int)Bar();
         lastSignalWasBuy = false;
         
         if (ShowArrows)
            DrawSellArrow();
         
         SendSellAlerts();
      }
   }
   
   // Update trade management (Break-Even, Trailing Stop, etc.)
   ManageTrades();
   
   // Draw dashboard
   if (ShowDashboard)
      UpdateDashboard();
}

//+------------------------------------------------------------------+
//| Copy Indicator Data Function                                     |
//+------------------------------------------------------------------+
bool CopyIndicatorData()
{
   // Copy MACD data
   if (CopyBuffer(macdHandle, 0, 0, 3, macdLine) < 3)
      return false;
   if (CopyBuffer(macdHandle, 1, 0, 3, signalLine) < 3)
      return false;
   if (CopyBuffer(macdHandle, 2, 0, 3, histogram) < 3)
      return false;
   
   // Copy Stochastic data
   if (CopyBuffer(stochHandle, 0, 0, 3, stochK) < 3)
      return false;
   if (CopyBuffer(stochHandle, 1, 0, 3, stochD) < 3)
      return false;
   
   // Copy SAR data
   if (CopyBuffer(sarHandle, 0, 0, 3, sar) < 3)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Detect BUY Signal Function                                       |
//+------------------------------------------------------------------+
bool DetectBuySignal()
{
   // Signal 1: MACD crosses above Signal line
   bool macdCrossover = (macdLine[1] <= signalLine[1]) && (macdLine[0] > signalLine[0]);
   if (!macdCrossover)
      return false;
   
   // Signal 2: Stochastic %K crosses above %D
   bool stochCrossover = (stochK[1] <= stochD[1]) && (stochK[0] > stochD[0]);
   if (!stochCrossover)
      return false;
   
   // Signal 3: Stochastic %K preferably from oversold area (below 20)
   // This is optional, but good practice - not blocking
   // bool fromOversold = (stochK[1] < OversoldLevel);
   
   // Signal 4: Parabolic SAR below price
   double currentPrice = Ask();
   bool sarBelow = (sar[0] < currentPrice);
   if (!sarBelow)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Detect SELL Signal Function                                      |
//+------------------------------------------------------------------+
bool DetectSellSignal()
{
   // Signal 1: MACD crosses below Signal line
   bool macdCrossover = (macdLine[1] >= signalLine[1]) && (macdLine[0] < signalLine[0]);
   if (!macdCrossover)
      return false;
   
   // Signal 2: Stochastic %K crosses below %D
   bool stochCrossover = (stochK[1] >= stochD[1]) && (stochK[0] < stochD[0]);
   if (!stochCrossover)
      return false;
   
   // Signal 3: Stochastic %K preferably from overbought area (above 80)
   // This is optional, but good practice - not blocking
   // bool fromOverbought = (stochK[1] > OverboughtLevel);
   
   // Signal 4: Parabolic SAR above price
   double currentPrice = Bid();
   bool sarAbove = (sar[0] > currentPrice);
   if (!sarAbove)
      return false;
   
   return true;
}

//+------------------------------------------------------------------+
//| Execute BUY Trade Function                                       |
//+------------------------------------------------------------------+
void ExecuteBuyTrade()
{
   // Check if symbol allows trading
   if ((SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL) &&
       (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_LONGONLY))
   {
      Print("BUY trade not allowed on this symbol");
      return;
   }
   
   // Calculate lot size
   double lot = CalculateLotSize(POSITION_TYPE_BUY);
   if (lot <= 0)
   {
      Print("Invalid lot size calculated");
      return;
   }
   
   // Normalize lot to broker requirements
   lot = NormalizeLot(lot);
   
   // Calculate Stop Loss and Take Profit
   double sl = 0.0, tp = 0.0;
   CalculateStopLevels(POSITION_TYPE_BUY, sl, tp);
   
   // Normalize prices
   double price = Ask();
   double bid = Bid();
   
   // Check minimum stop level
   double minStopLevel = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * Point();
   if ((price - sl) < minStopLevel)
   {
      sl = price - minStopLevel;
   }
   if ((tp - price) < minStopLevel)
   {
      tp = price + minStopLevel;
   }
   
   // Execute BUY order
   if (!trade.Buy(lot, _Symbol, price, sl, tp, "Thinkwealth BUY Signal"))
   {
      Print("BUY Order Failed. Error: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return;
   }
   
   Print("BUY Order Executed - Lot: ", lot, " Price: ", price, " SL: ", sl, " TP: ", tp);
   tradesOpenedToday++;
}

//+------------------------------------------------------------------+
//| Execute SELL Trade Function                                      |
//+------------------------------------------------------------------+
void ExecuteSellTrade()
{
   // Check if symbol allows trading
   if ((SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL) &&
       (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_SHORTONLY))
   {
      Print("SELL trade not allowed on this symbol");
      return;
   }
   
   // Calculate lot size
   double lot = CalculateLotSize(POSITION_TYPE_SELL);
   if (lot <= 0)
   {
      Print("Invalid lot size calculated");
      return;
   }
   
   // Normalize lot to broker requirements
   lot = NormalizeLot(lot);
   
   // Calculate Stop Loss and Take Profit
   double sl = 0.0, tp = 0.0;
   CalculateStopLevels(POSITION_TYPE_SELL, sl, tp);
   
   // Normalize prices
   double price = Bid();
   double ask = Ask();
   
   // Check minimum stop level
   double minStopLevel = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * Point();
   if ((sl - price) < minStopLevel)
   {
      sl = price + minStopLevel;
   }
   if ((price - tp) < minStopLevel)
   {
      tp = price - minStopLevel;
   }
   
   // Execute SELL order
   if (!trade.Sell(lot, _Symbol, price, sl, tp, "Thinkwealth SELL Signal"))
   {
      Print("SELL Order Failed. Error: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
      return;
   }
   
   Print("SELL Order Executed - Lot: ", lot, " Price: ", price, " SL: ", sl, " TP: ", tp);
   tradesOpenedToday++;
}

//+------------------------------------------------------------------+
//| Calculate Lot Size Function                                      |
//+------------------------------------------------------------------+
double CalculateLotSize(ENUM_POSITION_TYPE direction)
{
   double lot = 0.0;
   
   if (LotMode == POSITION_TYPE_BUY) // Fixed lot mode
   {
      lot = FixedLotSize;
   }
   else // Percentage risk mode
   {
      double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskAmount = accountBalance * (RiskPercentage / 100.0);
      
      // Calculate pips to risk
      double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double pointValue = pipValue * SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      
      // Calculate lot size based on risk
      lot = NormalizeDouble(riskAmount / (StopLossPoints * Point()), 2);
   }
   
   return lot;
}

//+------------------------------------------------------------------+
//| Normalize Lot Size Function                                      |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   // Adjust for broker's minimum and maximum
   if (lot < minLot)
      lot = minLot;
   if (lot > maxLot)
      lot = maxLot;
   
   // Normalize to lot step
   lot = MathRound(lot / lotStep) * lotStep;
   
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss and Take Profit Function                     |
//+------------------------------------------------------------------+
void CalculateStopLevels(ENUM_POSITION_TYPE direction, double &sl, double &tp)
{
   double price = (direction == POSITION_TYPE_BUY) ? Ask() : Bid();
   
   if (direction == POSITION_TYPE_BUY)
   {
      sl = price - (StopLossPoints * Point());
      
      if (RiskRewardRatio > 0)
      {
         tp = price + (StopLossPoints * Point() * RiskRewardRatio);
      }
      else
      {
         tp = price + (TakeProfitPoints * Point());
      }
   }
   else
   {
      sl = price + (StopLossPoints * Point());
      
      if (RiskRewardRatio > 0)
      {
         tp = price - (StopLossPoints * Point() * RiskRewardRatio);
      }
      else
      {
         tp = price - (TakeProfitPoints * Point());
      }
   }
}

//+------------------------------------------------------------------+
//| Manage Trades Function                                           |
//+------------------------------------------------------------------+
void ManageTrades()
{
   // Iterate through all open positions
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (!positionInfo.SelectByIndex(i))
         continue;
      
      // Check if position belongs to this EA
      if (positionInfo.Magic() != MagicNumber)
         continue;
      
      double positionProfit = positionInfo.Profit();
      double openPrice = positionInfo.PriceOpen();
      double sl = positionInfo.StopLoss();
      double tp = positionInfo.TakeProfit();
      ulong ticket = positionInfo.Ticket();
      
      // Break-Even Management
      if (UseBreakEven && positionProfit > BreakEvenProfit * Point())
      {
         if (positionInfo.PositionType() == POSITION_TYPE_BUY)
         {
            if (sl < openPrice)
            {
               trade.PositionModify(ticket, openPrice, tp);
            }
         }
         else if (positionInfo.PositionType() == POSITION_TYPE_SELL)
         {
            if (sl > openPrice)
            {
               trade.PositionModify(ticket, openPrice, tp);
            }
         }
      }
      
      // Trailing Stop Management
      if (UseTrailingStop)
      {
         if (positionInfo.PositionType() == POSITION_TYPE_BUY)
         {
            double newSL = Bid() - (TrailingStopPoints * Point());
            if (newSL > sl)
            {
               trade.PositionModify(ticket, newSL, tp);
            }
         }
         else if (positionInfo.PositionType() == POSITION_TYPE_SELL)
         {
            double newSL = Ask() + (TrailingStopPoints * Point());
            if (newSL < sl)
            {
               trade.PositionModify(ticket, newSL, tp);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Send BUY Alerts Function                                         |
//+------------------------------------------------------------------+
void SendBuyAlerts()
{
   // Prevent alert spam
   if ((TimeCurrent() - lastAlertTime) < 60) // 60 seconds minimum
      return;
   
   lastAlertTime = TimeCurrent();
   
   if (AlertsEnabled)
   {
      Alert("Thinkwealth Smart Signal Pro EA - BUY Signal Detected\n" +
            "Symbol: ", _Symbol, "\n" +
            "Time: ", TimeToString(TimeCurrent()));
   }
   
   if (SoundAlertEnabled)
   {
      PlaySound(AlertSoundFile);
   }
   
   if (PushNotificationEnabled)
   {
      SendNotification("Thinkwealth: BUY Signal - " + _Symbol);
   }
   
   if (EmailNotificationEnabled)
   {
      SendMail("Thinkwealth BUY Alert", "BUY signal detected on " + _Symbol + " at " + TimeToString(TimeCurrent()));
   }
}

//+------------------------------------------------------------------+
//| Send SELL Alerts Function                                        |
//+------------------------------------------------------------------+
void SendSellAlerts()
{
   // Prevent alert spam
   if ((TimeCurrent() - lastAlertTime) < 60) // 60 seconds minimum
      return;
   
   lastAlertTime = TimeCurrent();
   
   if (AlertsEnabled)
   {
      Alert("Thinkwealth Smart Signal Pro EA - SELL Signal Detected\n" +
            "Symbol: ", _Symbol, "\n" +
            "Time: ", TimeToString(TimeCurrent()));
   }
   
   if (SoundAlertEnabled)
   {
      PlaySound(AlertSoundFile);
   }
   
   if (PushNotificationEnabled)
   {
      SendNotification("Thinkwealth: SELL Signal - " + _Symbol);
   }
   
   if (EmailNotificationEnabled)
   {
      SendMail("Thinkwealth SELL Alert", "SELL signal detected on " + _Symbol + " at " + TimeToString(TimeCurrent()));
   }
}

//+------------------------------------------------------------------+
//| Draw BUY Arrow Function                                          |
//+------------------------------------------------------------------+
void DrawBuyArrow()
{
   static int arrowCount = 0;
   string arrowName = "BUY_Arrow_" + IntegerToString(arrowCount++);
   
   double price = Low(0);
   datetime time = Time(0);
   
   ObjectCreate(0, arrowName, OBJ_ARROW_DOWN, 0, time, price);
   ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrGreen);
   ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 251); // Green up arrow
}

//+------------------------------------------------------------------+
//| Draw SELL Arrow Function                                         |
//+------------------------------------------------------------------+
void DrawSellArrow()
{
   static int arrowCount = 0;
   string arrowName = "SELL_Arrow_" + IntegerToString(arrowCount++);
   
   double price = High(0);
   datetime time = Time(0);
   
   ObjectCreate(0, arrowName, OBJ_ARROW_UP, 0, time, price);
   ObjectSetInteger(0, arrowName, OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, 250); // Red down arrow
}

//+------------------------------------------------------------------+
//| Update Dashboard Function                                        |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   string status = "ACTIVE";
   color statusColor = clrGreen;
   
   if (!IsTradeAllowed())
   {
      status = "DISABLED";
      statusColor = clrRed;
   }
   
   DrawDashboard(status, "");
}

//+------------------------------------------------------------------+
//| Draw Dashboard Function                                          |
//+------------------------------------------------------------------+
void DrawDashboard(string status = "ACTIVE", string warning = "")
{
   // Create background rectangle
   string bgName = "Dashboard_BG";
   if (ObjectFind(0, bgName) >= 0)
      ObjectDelete(0, bgName);
   
   ObjectCreate(0, bgName, OBJ_RECTANGLE_FILLED, 0, Time(0), High(0), Time(0), Low(0));
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, DashboardX);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, DashboardY);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE, 350);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE, 280);
   ObjectSetInteger(0, bgName, OBJPROP_FILL, true);
   ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, clrGold);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_WIDTH, 2);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER, DashboardCorner);
   ObjectSetInteger(0, bgName, OBJPROP_BACK, true);
   
   // Dashboard title
   CreateDashboardText("Dashboard_Title", "=== THINKWEALTH SMART SIGNAL PRO ===", 
                       DashboardX + 10, DashboardY + 10, clrGold, 12, true);
   
   // EA Status
   color statusCol = (status == "ACTIVE") ? clrGreen : clrRed;
   CreateDashboardText("Dashboard_Status", "Status: " + status, 
                       DashboardX + 10, DashboardY + 35, statusCol, 11);
   
   // Symbol and Timeframe
   CreateDashboardText("Dashboard_Symbol", "Symbol: " + _Symbol + " | TF: " + PeriodToString(_Period), 
                       DashboardX + 10, DashboardY + 55, clrWhite, 11);
   
   // Indicator Status
   CreateDashboardText("Dashboard_MACD", "MACD: " + DoubleToString(macdLine[0], 5), 
                       DashboardX + 10, DashboardY + 75, clrLightBlue, 11);
   CreateDashboardText("Dashboard_Stoch", "Stoch K: " + DoubleToString(stochK[0], 2) + " | D: " + DoubleToString(stochD[0], 2), 
                       DashboardX + 10, DashboardY + 95, clrLightBlue, 11);
   CreateDashboardText("Dashboard_SAR", "SAR: " + DoubleToString(sar[0], _Digits), 
                       DashboardX + 10, DashboardY + 115, clrLightBlue, 11);
   
   // Price and Spread
   CreateDashboardText("Dashboard_Price", "Price: " + DoubleToString(Ask(), _Digits) + " | Spread: " + DoubleToString(GetCurrentSpread(), 1) + " pts", 
                       DashboardX + 10, DashboardY + 135, clrWhite, 11);
   
   // Lot Size and Risk
   double lot = (LotMode == POSITION_TYPE_BUY) ? FixedLotSize : CalculateLotSize(POSITION_TYPE_BUY);
   CreateDashboardText("Dashboard_LotSize", "Lot Size: " + DoubleToString(lot, 2) + " | Risk: " + DoubleToString(RiskPercentage, 2) + "%", 
                       DashboardX + 10, DashboardY + 155, clrWhite, 11);
   
   // Open Trades
   int openTrades = CountOpenTrades();
   CreateDashboardText("Dashboard_OpenTrades", "Open Trades: " + IntegerToString(openTrades) + " / " + IntegerToString(MaxOpenTrades), 
                       DashboardX + 10, DashboardY + 175, clrWhite, 11);
   
   // Daily Statistics
   CreateDashboardText("Dashboard_DailyTrades", "Trades Today: " + IntegerToString(tradesOpenedToday), 
                       DashboardX + 10, DashboardY + 195, clrWhite, 11);
   
   double dayProfit = CalculateDailyProfit();
   color profitCol = (dayProfit >= 0) ? clrGreen : clrRed;
   CreateDashboardText("Dashboard_DailyProfit", "Daily P/L: " + DoubleToString(dayProfit, 2), 
                       DashboardX + 10, DashboardY + 215, profitCol, 11);
   
   // Warning Message
   if (warning != "")
   {
      CreateDashboardText("Dashboard_Warning", "WARNING: " + warning, 
                          DashboardX + 10, DashboardY + 245, clrOrange, 10);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Create Dashboard Text Function                                   |
//+------------------------------------------------------------------+
void CreateDashboardText(string name, string text, int x, int y, color col, int size, bool bold = false)
{
   if (ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);
   
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_CORNER, DashboardCorner);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+

// Check if trading is allowed
bool IsTradeAllowed()
{
   if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      return false;
   
   if (!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE))
      return false;
   
   if (!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
      return false;
   
   return true;
}

// Check if trading time is allowed
bool IsTradingTimeAllowed()
{
   if (!UseTradingHoursFilter)
      return true;
   
   int currentHour = Hour();
   return (currentHour >= TradingStartHour && currentHour < TradingEndHour);
}

// Check daily limits
bool CheckDailyLimits()
{
   // Check daily loss limit
   if (MaxDailyLoss > 0)
   {
      double dayProfit = CalculateDailyProfit();
      if (dayProfit < -MaxDailyLoss)
         return false;
   }
   
   // Check daily profit target
   if (DailyProfitTarget > 0)
   {
      double dayProfit = CalculateDailyProfit();
      if (dayProfit >= DailyProfitTarget)
         return false;
   }
   
   // Check max trades per day
   if (MaxTradesPerDay > 0 && tradesOpenedToday >= MaxTradesPerDay)
      return false;
   
   return true;
}

// Count open trades
int CountOpenTrades()
{
   int count = 0;
   for (int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if (positionInfo.SelectByIndex(i))
      {
         if (positionInfo.Magic() == MagicNumber && positionInfo.Symbol() == _Symbol)
            count++;
      }
   }
   return count;
}

// Get current spread
double GetCurrentSpread()
{
   return (Ask() - Bid()) / Point();
}

// Calculate daily profit
double CalculateDailyProfit()
{
   double dayProfit = 0.0;
   
   for (int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      if (dealInfo.SelectByIndex(i))
      {
         // Check if deal belongs to this EA and is from today
         if (dealInfo.Magic() == MagicNumber && dealInfo.Symbol() == _Symbol)
         {
            datetime dealTime = (datetime)dealInfo.Time();
            if (dealTime >= iTime(_Symbol, PERIOD_D1, 0)) // Today's deals
            {
               dayProfit += dealInfo.Profit();
            }
         }
      }
   }
   
   return dayProfit;
}

// Detect new candle
bool IsNewCandle()
{
   int bars = Bars(_Symbol, _Period);
   if (prevBars != bars)
   {
      prevBars = bars;
      return true;
   }
   return false;
}

// Convert period to string
string PeriodToString(int period)
{
   string periodStr = "";
   switch (period)
   {
      case PERIOD_M1: periodStr = "M1"; break;
      case PERIOD_M5: periodStr = "M5"; break;
      case PERIOD_M15: periodStr = "M15"; break;
      case PERIOD_M30: periodStr = "M30"; break;
      case PERIOD_H1: periodStr = "H1"; break;
      case PERIOD_H4: periodStr = "H4"; break;
      case PERIOD_D1: periodStr = "D1"; break;
      case PERIOD_W1: periodStr = "W1"; break;
      case PERIOD_MN1: periodStr = "MN"; break;
      default: periodStr = "UNKNOWN";
   }
   return periodStr;
}

// Get current bar number
long Bar()
{
   return Bars(_Symbol, _Period) - 1;
}

// Get Ask price
double Ask()
{
   return SymbolInfoDouble(_Symbol, SYMBOL_ASK);
}

// Get Bid price
double Bid()
{
   return SymbolInfoDouble(_Symbol, SYMBOL_BID);
}

// Get bar close price
double Close(int shift = 0)
{
   double close[];
   CopyClose(_Symbol, _Period, shift, 1, close);
   return close[0];
}

// Get bar open price
double Open(int shift = 0)
{
   double open[];
   CopyOpen(_Symbol, _Period, shift, 1, open);
   return open[0];
}

// Get bar high price
double High(int shift = 0)
{
   double high[];
   CopyHigh(_Symbol, _Period, shift, 1, high);
   return high[0];
}

// Get bar low price
double Low(int shift = 0)
{
   double low[];
   CopyLow(_Symbol, _Period, shift, 1, low);
   return low[0];
}

// Get bar time
datetime Time(int shift = 0)
{
   datetime time[];
   CopyTime(_Symbol, _Period, shift, 1, time);
   return time[0];
}

// Get current hour
int Hour()
{
   return Hour(TimeCurrent());
}

//+------------------------------------------------------------------+
//| End of Expert Advisor                                            |
//+------------------------------------------------------------------+
