# Thinkwealth Smart Signal Pro EA - Usage Guide

## Getting Started

### Step 1: Initial Setup

After installation and compilation, load the EA onto your chart:

1. Open MetaTrader 5
2. Open a chart (e.g., EURUSD, M5 timeframe)
3. Insert → Expert Advisors → Thinkwealth Smart Signal Pro
4. Set your desired parameters (see CONFIGURATION_GUIDE.md)
5. Click **OK** to start the EA

### Step 2: Enable AutoTrading

In MetaTrader 5:
- Click the **AutoTrading** button in the top toolbar (should appear pressed/highlighted)
- Verify the light turns green
- Without this, the EA will generate signals but NOT execute trades

### Step 3: Monitor the Dashboard

The professional dashboard displays:
- **EA Status**: ACTIVE/DISABLED
- **Current Symbol & Timeframe**: e.g., EURUSD M5
- **Indicator Values**: MACD, Stochastic, SAR
- **Price & Spread**: Current bid/ask and spread
- **Lot Size & Risk**: Position size and risk percentage
- **Open Trades**: Current open positions
- **Daily Statistics**: Trades today and P/L

---

## Understanding the Signals

### BUY Signal Confirmation Requires:

1. **MACD Crossover**: MACD line crosses ABOVE Signal line (from below)
2. **Stochastic Crossover**: %K crosses ABOVE %D (from below)
3. **SAR Below Price**: Parabolic SAR is positioned below current price
4. **ALL conditions must occur on the same candle (or within confirmation window)**

When a BUY signal is detected:
- **Green BUY arrow** is drawn below the candle
- **Alert sound** plays (if enabled)
- **MT5 popup alert** appears (if enabled)
- **BUY trade is executed** (if AutoTrading is enabled)

### SELL Signal Confirmation Requires:

1. **MACD Crossover**: MACD line crosses BELOW Signal line (from above)
2. **Stochastic Crossover**: %K crosses BELOW %D (from above)
3. **SAR Above Price**: Parabolic SAR is positioned above current price
4. **ALL conditions must occur on the same candle (or within confirmation window)**

When a SELL signal is detected:
- **Red SELL arrow** is drawn above the candle
- **Alert sound** plays (if enabled)
- **MT5 popup alert** appears (if enabled)
- **SELL trade is executed** (if AutoTrading is enabled)

---

## Trade Execution

### Automatic Trade Execution (When AutoTrading = true)

When a signal is confirmed and conditions are met:

1. **Lot size is calculated** based on:
   - Fixed lot size (if using Fixed mode)
   - Risk percentage calculation (if using Percentage mode)

2. **Stop Loss is placed** at:
   - BUY: Entry Price - StopLossPoints
   - SELL: Entry Price + StopLossPoints

3. **Take Profit is placed** at:
   - BUY: Entry Price + TakeProfitPoints (or RiskRewardRatio × SL distance)
   - SELL: Entry Price - TakeProfitPoints (or RiskRewardRatio × SL distance)

4. **Order is sent** with:
   - Magic number (EA identifier)
   - Slippage tolerance
   - BUY or SELL direction

### Manual Signal Mode (When AutoTrading = false)

Use this to:
- Test signal generation without real trades
- Manually execute trades when you see signals
- Practice using the EA before live trading
- Verify signal quality during backtesting

---

## Risk Management in Action

### Fixed Lot Mode

- **Lot size remains constant** regardless of account balance
- Use for fixed contract trading
- Set LotMode = POSITION_TYPE_BUY
- Set FixedLotSize = desired lot size

**Example:**
```
FixedLotSize: 0.1 lot
Risk per trade: Fixed at 0.1 lot regardless of outcome
```

### Percentage Risk Mode

- **Lot size adjusts** based on account balance and risk percentage
- More appropriate for most traders
- Set LotMode = POSITION_TYPE_SELL
- Set RiskPercentage = 2.0 (or preferred percentage)

**Example:**
```
Account Balance: $10,000
RiskPercentage: 2.0% = $200 risk per trade
StopLossPoints: 100
Calculated Lot: Adjusted to risk exactly $200
```

### Break-Even Protection

When enabled:
- After profit reaches BreakEvenProfit (default: 50 points)
- Stop Loss is automatically moved to entry price
- Protects profitable trades from becoming losses
- No further profit beyond entry is gained, but prevents loss

### Trailing Stop Protection

When enabled:
- Stop Loss moves upward (for BUY) or downward (for SELL) as price moves favorably
- Locks in profits dynamically
- Default: TrailingStopPoints = 50 points
- Protects from reversals while allowing profit growth

---

## Daily Limits and Filters

### Maximum Daily Loss Limit

Example: MaxDailyLoss = $500
- EA tracks cumulative daily loss (closed trades only)
- Once daily loss reaches -$500, no new trades are opened
- Resets at start of next day (00:00 server time)

### Daily Profit Target

Example: DailyProfitTarget = $1,000
- EA tracks cumulative daily profit
- Once profit reaches +$1,000, no new trades are opened
- Protects from overtrading on profitable days

### Maximum Trades Per Day

Example: MaxTradesPerDay = 10
- EA counts trades opened during the day
- After 10 trades, no more trades open until next day
- Prevents overtrading and excessive risk

### Spread Protection

Example: MaxSpread = 15.0
- EA checks current spread before opening trades
- If spread > 15 points, no trades are opened
- Protects from poor execution during wide spreads
- Essential during news events and illiquid hours

### Trading Hours Filter

Example:
- TradingStartHour: 8 (8:00 AM)
- TradingEndHour: 18 (6:00 PM)

Only opens trades within this time window:
- Avoids low-liquidity sessions
- Avoids trading during your sleep
- Useful for specific trading sessions

---

## Monitoring Your Trades

### In MetaTrader 5:

**View → Toolbox → Trades Tab:**
- Shows all open positions
- Displays Entry Price, SL, TP, Current Profit

**View → Toolbox → History Tab:**
- Shows closed trades
- Right-click → Deal Info for detailed trade info

### The Dashboard Shows:

- **Open Trades**: Current positions count
- **Daily P/L**: Profit/Loss from closed trades today
- **Trades Today**: Number of trades opened today
- **Current Spread**: Real-time spread in points

---

## Backtesting the EA

### Using MT5 Strategy Tester:

1. **Open Strategy Tester**: View → Strategy Tester (Ctrl+R)
2. **Configure:**
   - Expert: Thinkwealth Smart Signal Pro
   - Symbol: Your chosen symbol (e.g., EURUSD)
   - Timeframe: M5
   - From: Start date
   - To: End date
   - Model: Every tick (most accurate)
3. **Click Start** to begin backtesting

### Interpreting Results:

**Key Metrics to Review:**
- **Total Profit**: Should be positive
- **Profit Factor**: 2.0+ is good (2x profit vs loss)
- **Win Rate**: 50%+ is acceptable with good risk/reward
- **Max Drawdown**: Should be < 25% of account
- **Consecutive Losses**: Check for excessive losing streaks
- **Recovery Factor**: Should be > 3.0

### Optimization:

1. Open Strategy Tester
2. Set "Optimization" mode (instead of Visual/Forward)
3. Select parameters to optimize
4. Set ranges for each parameter
5. Run optimization (may take hours)
6. Review results by profit, profit factor, and drawdown

---

## Forward Testing (Demo Account Testing)

**CRITICAL: Always forward test before live trading**

### Forward Testing Process:

1. **Load EA on Demo Account** at least 5-10 days
2. **Monitor** signals and trade execution
3. **Track** every trade in a spreadsheet
4. **Review** daily results and drawdown
5. **Verify** the EA performs as expected in live market conditions

### What to Look For:

- ✅ Do signals match your backtest results?
- ✅ Are trades executed at expected prices?
- ✅ Do Stop Loss and Take Profit work correctly?
- ✅ Are dashboard values accurate?
- ✅ Is daily profit/loss tracking correct?
- ❌ Are there unexpected errors or unusual behavior?

### Red Flags:

- 🚩 Significantly different results than backtest
- 🚩 Very large drawdowns
- 🚩 Spread issues preventing trade execution
- 🚩 Unusual slippage
- 🚩 Signals that don't match indicators

---

## Tips for Best Results

### 1. Choose the Right Symbol

- **Liquid pairs**: EURUSD, GBPUSD, USDJPY (tight spreads, reliable signals)
- **Avoid**: Exotic pairs, crypto during off-hours (wide spreads, slippage)
- **Test first**: Backtest on your chosen symbol before trading

### 2. Use Appropriate Risk Settings

```
Conservative: 1-2% risk per trade
Moderate: 2-3% risk per trade
Aggressive: 3-5% risk per trade

NEVER exceed 5% risk per trade on live accounts
```

### 3. Monitor Market Conditions

- **Trending Markets**: EA performs best (strong signals)
- **Ranging/Choppy Markets**: More false signals (consider increasing confirmation periods)
- **News Events**: Wide spreads, gaps (use spread protection)
- **Off-Hours**: Low liquidity (use trading hours filter)

### 4. Regular Monitoring

Even with automation, check:
- Dashboard every few hours
- Journal for any errors
- Account balance and daily P/L
- Unexpected market conditions

### 5. Review and Adjust

- **Weekly**: Review trading journal
- **Monthly**: Analyze performance and adjust parameters
- **Quarterly**: Decide if strategy still works in current market

---

## Common Issues and Solutions

### No Signals Are Generated

**Possible Causes:**
1. TimeFrame is not M5
2. Insufficient price data (< 50 bars)
3. Indicator values don't align
4. Indicators not calculating properly

**Solutions:**
- Switch to M5 timeframe
- Wait for more candles to load
- Check indicator values in dashboard
- Review indicator parameters

### Signals Generated But No Trades Execute

**Possible Causes:**
1. AutoTrading is disabled
2. Account doesn't have sufficient margin
3. Symbol trading is not allowed
4. Spread is too wide (if spread protection enabled)

**Solutions:**
- Enable AutoTrading button in MT5
- Check Account Balance and Free Margin
- Switch to another symbol
- Disable spread protection or increase limit

### Trades Execute But SL/TP Not Set

**Possible Causes:**
1. SL/TP violate broker's minimum stop level
2. Broker doesn't allow certain SL/TP distances

**Solutions:**
- Increase StopLossPoints value
- Check broker's minimum stop level requirement
- Review broker's restrictions

### Too Many False Signals (Whipsaws)

**Possible Causes:**
1. Market is ranging/choppy
2. Indicators are too sensitive

**Solutions:**
- Increase MACD periods (12/26 → 15/30)
- Increase Stochastic K period (14 → 21)
- Increase Stochastic slowing (3 → 5)
- Use SignalConfirmationCandles = 1-2

### Very Few Signals

**Possible Causes:**
1. Indicators are too conservative
2. Market conditions don't fit the strategy
3. Symbol is not trending

**Solutions:**
- Decrease MACD periods (12/26 → 8/20)
- Decrease Stochastic K period (14 → 10)
- Test on different symbols
- Review market conditions

---

## Emergency Procedures

### Stop EA Immediately

1. Click the **AutoTrading button** to disable it (red X appearance)
2. Or remove EA from chart: Right-click chart → Expert Advisors → Remove

### Close All Positions

1. Open "Trades" tab in Toolbox
2. Right-click each position
3. Click "Close Position"

### Check for Errors

1. View → Toolbox → Experts
2. Review all messages in the journal
3. Note any error codes or descriptions

---

## Disclaimer Reminder

- This EA is a **trading automation tool**, not a guaranteed profit machine
- **Past performance does not guarantee future results**
- Forex/CFD trading involves **substantial risk**
- You may lose **entire invested capital**
- **Never trade live without thorough backtesting and forward testing**
- **Risk only money you can afford to lose**
- Use proper **position sizing and risk management**
- The EA is provided **as-is without any warranty**

---

For configuration help, see **CONFIGURATION_GUIDE.md**

For strategy details, see **STRATEGY_DETAILS.md**
