# Thinkwealth Smart Signal Pro EA - Configuration Guide

## Parameter Groups Overview

The EA organizes all parameters into logical groups for easy configuration:

### 1. Trading Strategy Settings

**EnableBuyTrades** (Default: true)
- Enable/disable BUY signal detection and trade execution
- Set to `false` if you only want SELL signals

**EnableSellTrades** (Default: true)
- Enable/disable SELL signal detection and trade execution
- Set to `false` if you only want BUY signals

**AutoTrading** (Default: true)
- Enable automatic trade execution when signals are detected
- Set to `false` to generate signals without placing trades (demo mode)

**SignalConfirmationCandles** (Default: 0)
- Number of candles to confirm a signal before acting
- 0 = act on signal immediately on same candle
- 1-5 = wait for confirmation on subsequent candles (reduces false signals)

**OnlyNewCandle** (Default: true)
- Process signals only when a new candle forms
- Recommended: true (prevents repeated signals from same candle)
- Set to false to process on every tick (not recommended, may cause duplicate trades)

**AvoidDuplicateSignals** (Default: true)
- Prevent the EA from opening multiple trades from the same signal bar
- Recommended: true

---

## 2. MACD Indicator Settings

**MAConstituent_Fast** (Default: 12)
- MACD Fast Exponential Moving Average period
- Lower values (8-12): faster, more signals, more false signals
- Higher values (14-20): slower, fewer signals, more reliable

**MAConstituent_Slow** (Default: 26)
- MACD Slow Exponential Moving Average period
- Standard range: 20-30
- Increase for slower markets, decrease for fast-moving markets

**MACDSignal** (Default: 9)
- MACD Signal line period
- Standard value: 9 (rarely changed)

**MAMethod** (Default: MODE_EMA)
- Moving Average method for MACD calculation
- MODE_EMA = Exponential (recommended)
- MODE_SMA = Simple
- MODE_SMMA = Smoothed

**Recommended Settings:**
- Aggressive: Fast=8, Slow=20, Signal=7
- Moderate: Fast=12, Slow=26, Signal=9 (DEFAULT)
- Conservative: Fast=15, Slow=30, Signal=11

---

## 3. Stochastic Oscillator Settings

**Stoch_K_Period** (Default: 14)
- Number of periods for %K calculation
- Lower values (7-10): more sensitive, more signals
- Higher values (14-21): less sensitive, fewer signals

**Stoch_D_Period** (Default: 3)
- Smoothing period for %D (signal line)
- Standard range: 3-5
- Higher = smoother, fewer whipsaws

**Stoch_Slowing** (Default: 3)
- Additional smoothing for %K
- 1 = no smoothing (raw Stochastic)
- 3-5 = moderate smoothing (recommended)

**StochMethod** (Default: MODE_SMA)
- Moving Average method for Stochastic
- MODE_SMA = Simple (most common)
- MODE_EMA = Exponential

**OverboughtLevel** (Default: 80.0)
- Level above which Stochastic is considered overbought
- Common range: 75-85
- Used as reference for SELL signals

**OversoldLevel** (Default: 20.0)
- Level below which Stochastic is considered oversold
- Common range: 15-25
- Used as reference for BUY signals

**Recommended Settings:**
- Aggressive: K=10, D=3, Slowing=1, Overbought=75, Oversold=25
- Moderate: K=14, D=3, Slowing=3, Overbought=80, Oversold=20 (DEFAULT)
- Conservative: K=21, D=5, Slowing=5, Overbought=85, Oversold=15

---

## 4. Parabolic SAR Settings

**SAR_Step** (Default: 0.02)
- Initial Acceleration Factor (AF)
- Lower values (0.01-0.02): SAR moves slowly, fewer reversals
- Higher values (0.03-0.05): SAR moves faster, more reversals

**SAR_Maximum** (Default: 0.2)
- Maximum Acceleration Factor
- Standard range: 0.15-0.3
- Higher = more aggressive SAR adjustments

**Recommended Settings:**
- Aggressive: Step=0.03, Maximum=0.3
- Moderate: Step=0.02, Maximum=0.2 (DEFAULT)
- Conservative: Step=0.01, Maximum=0.15

---

## 5. Risk Management Settings

### Lot Size Configuration

**LotMode** (Default: POSITION_TYPE_BUY)
- POSITION_TYPE_BUY = Use Fixed Lot Size
- POSITION_TYPE_SELL = Use Percentage Risk Mode

**FixedLotSize** (Default: 0.1)
- Used when LotMode = POSITION_TYPE_BUY
- Example: 0.1 = 0.1 lot, 1.0 = 1 lot
- Check broker requirements for minimum lot

**RiskPercentage** (Default: 2.0)
- Used when LotMode = POSITION_TYPE_SELL
- Percentage of account to risk per trade
- Example: 2.0 = risk 2% of account balance
- Safe range: 1-5% (2% is standard)

### Stop Loss and Take Profit

**StopLossPoints** (Default: 100)
- Stop Loss distance in points
- Example: 100 = 100 points (10 pips for 4-decimal symbols, 1 pip for 2-decimal)
- Range: 50-500 depending on volatility and symbol

**TakeProfitPoints** (Default: 200)
- Take Profit distance in points
- Example: 200 = 200 points
- Should be 1.5x to 3x the Stop Loss (good risk/reward)

**RiskRewardRatio** (Default: 0.0)
- Automatic Take Profit calculation based on Stop Loss
- Example: 2.0 = TP will be 2x the SL distance
- 0.0 = disabled, use TakeProfitPoints value instead
- Recommended: 2.0 or 3.0 for good risk/reward

### Trade Limits

**MaxOpenTrades** (Default: 5)
- Maximum simultaneous open positions
- Range: 1-20 depending on capital and risk tolerance
- Lower = more conservative, fewer open trades at once

**OneTradeAtATime** (Default: false)
- If true: close previous trade before opening new one
- Useful for limiting exposure
- false = allow multiple trades to be open

**MaxSpread** (Default: 0.0)
- Maximum allowable spread before trading
- 0.0 = no spread limit
- Example: 20.0 = don't trade if spread > 20 points
- Recommended: 5-20 for stable pairs, higher for exotic pairs

**MaxTradesPerDay** (Default: 0)
- Maximum trades to open in one day
- 0 = unlimited
- Useful for controlling overtrading

**MaxDailyLoss** (Default: 0.0)
- Stop trading after daily loss exceeds this amount
- 0.0 = no limit
- Example: 100.0 = stop trading if daily loss > $100

**DailyProfitTarget** (Default: 0.0)
- Stop trading after reaching daily profit target
- 0.0 = no limit
- Example: 500.0 = stop trading after $500 profit

### Execution Settings

**MagicNumber** (Default: 20240812)
- Unique identifier for EA trades
- Change if running multiple EAs on same account
- Used to identify which EA placed each trade

**Slippage** (Default: 50)
- Maximum acceptable deviation/slippage in points
- Range: 10-200 depending on broker
- Higher value = more likely to get filled, possibly at worse price

---

## 6. Trade Protection Settings

**UseBreakEven** (Default: false)
- Automatically move Stop Loss to entry price after reaching profit
- Protects against losing trades that were profitable

**BreakEvenProfit** (Default: 50)
- Profit in points required before activating Break-Even
- Example: 50 = move SL to entry after 50 points profit

**UseTrailingStop** (Default: false)
- Automatically adjust Stop Loss upward (for BUY) or downward (for SELL) as price moves favorably
- Locks in profits and protects from reversals

**TrailingStopPoints** (Default: 50)
- Distance from current price for trailing stop
- Example: 50 = keep SL 50 points below current price (for BUY)

**UseSpreadProtection** (Default: true)
- Prevent trading during very wide spreads
- Protects from poor execution prices

**UseTradingHoursFilter** (Default: false)
- Only trade during specific hours
- Useful for avoiding low-liquidity times

**TradingStartHour** (Default: 8)
- Start trading at this hour (24-hour format)
- Example: 8 = 8:00 AM

**TradingEndHour** (Default: 18)
- Stop trading at this hour
- Example: 18 = 6:00 PM

---

## 7. Alerts & Notifications Settings

**AlertsEnabled** (Default: true)
- Show MT5 popup alerts when signals are detected

**SoundAlertEnabled** (Default: true)
- Play sound alert
- Make sure your system has sound enabled

**AlertSoundFile** (Default: "alert.wav")
- Sound file to play (should be in MT5/Sounds folder)
- Built-in options: "alert.wav", "alarm.wav", "bell.wav"

**PushNotificationEnabled** (Default: false)
- Send push notifications to mobile device (requires MQL5 Cloud)

**EmailNotificationEnabled** (Default: false)
- Send email alerts
- Requires MT5 email configuration

**EmailAddress** (Default: "your@email.com")
- Email address to receive alerts

---

## 8. Dashboard & Display Settings

**ShowDashboard** (Default: true)
- Display professional information dashboard on chart

**ShowArrows** (Default: true)
- Draw BUY (green) and SELL (red) arrows on chart

**DashboardCorner** (Default: CORNER_LEFT_UPPER)
- Corner position for dashboard
- Options:
  - CORNER_LEFT_UPPER = Top-left
  - CORNER_LEFT_LOWER = Bottom-left
  - CORNER_RIGHT_UPPER = Top-right
  - CORNER_RIGHT_LOWER = Bottom-right

**DashboardX** (Default: 10)
- Horizontal offset in pixels

**DashboardY** (Default: 30)
- Vertical offset in pixels

---

## Recommended Configuration Presets

### CONSERVATIVE (Low Risk, Few Trades)
```
MAConstituent_Fast: 15
MAConstituent_Slow: 30
Stoch_K_Period: 21
RiskPercentage: 1.0
StopLossPoints: 150
TakeProfitPoints: 300
MaxOpenTrades: 2
MaxSpread: 10.0
UseTrailingStop: true
TrailingStopPoints: 75
```

### MODERATE (Balanced - RECOMMENDED)
```
MAConstituent_Fast: 12
MAConstituent_Slow: 26
Stoch_K_Period: 14
RiskPercentage: 2.0
StopLossPoints: 100
TakeProfitPoints: 200
MaxOpenTrades: 5
MaxSpread: 15.0
UseBreakEven: true
BreakEvenProfit: 50
```

### AGGRESSIVE (High Risk, More Trades)
```
MAConstituent_Fast: 8
MAConstituent_Slow: 20
Stoch_K_Period: 10
RiskPercentage: 5.0
StopLossPoints: 50
TakeProfitPoints: 150
MaxOpenTrades: 10
MaxSpread: 25.0
UseTrailingStop: true
TrailingStopPoints: 30
```

---

## Important Configuration Tips

1. **Start Conservative**: Begin with conservative settings, then optimize
2. **Backtest First**: Always backtest parameter changes before live trading
3. **Test on Demo**: Forward test on demo for at least 5-10 days
4. **Journal Review**: Track all trades and review performance
5. **Adjust Gradually**: Change one parameter at a time and monitor results
6. **Account Size**: Adjust lot size based on account balance
7. **Broker Specs**: Check your broker's min lot, max lot, and min stop level
8. **Risk Management**: Never risk more than 2-5% per trade on live accounts

---

## Optimization Tips for Strategy Tester

When optimizing in MT5 Strategy Tester:

1. **Avoid Over-Optimization**: Too many parameters = poor live results
2. **Focus Key Parameters**: Optimize MACD and Stochastic periods first
3. **Use Robust Settings**: Look for settings that work across different timeframes and symbols
4. **Profit Factor > 2.0**: Target profit factor above 2.0 (2x profit vs loss)
5. **Win Rate Target**: 50%+ win rate with proper risk/reward
6. **Drawdown Control**: Keep max drawdown below 25% of account
7. **Forward Test**: Always verify optimized settings on forward data (demo)

---

## Troubleshooting Configuration Issues

**No signals generated:**
- Check indicator parameters are reasonable
- Verify timeframe is M5
- Check that price isn't too flat/choppy

**Too many false signals:**
- Increase MA periods (more conservative)
- Increase Stochastic periods
- Use higher slowing values

**Too few signals:**
- Decrease MA periods (more aggressive)
- Decrease Stochastic periods
- Lower slowing values

**Trades closing too early:**
- Increase Take Profit points
- Increase Risk/Reward ratio

**Trades hitting stop loss too often:**
- Increase Stop Loss points
- Review indicator alignment
- Check volatility of symbol

---

For questions about specific parameters, review the **STRATEGY_DETAILS.md** file for more information about how the signals are generated.
