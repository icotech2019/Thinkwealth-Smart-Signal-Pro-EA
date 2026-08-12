# Thinkwealth Smart Signal Pro EA - Installation Guide

## Overview

Thinkwealth Smart Signal Pro EA is a professional MetaTrader 5 Expert Advisor that combines MACD, Stochastic Oscillator, and Parabolic SAR indicators to generate automated BUY and SELL signals on the M5 (5-minute) timeframe.

## System Requirements

- **MetaTrader 5** (Build 3000+)
- **Windows OS** or **Linux/Mac with Wine/similar virtualization**
- **Minimum 256MB RAM**
- **Internet connection for live trading or demo accounts**

## Installation Steps

### Step 1: Download the EA File

The main file is:
```
Thinkwealth-Smart-Signal-Pro-EA.mq5
```

### Step 2: Copy to MetaTrader 5 Experts Folder

1. Open MetaTrader 5
2. Go to **File → Open Data Folder**
3. Navigate to: `MQL5/Experts/`
4. Copy `Thinkwealth-Smart-Signal-Pro-EA.mq5` to this folder

### Step 3: Compile the EA

1. Open **MetaEditor** (Tools → MetaEditor or F12 in MT5)
2. Open `Thinkwealth-Smart-Signal-Pro-EA.mq5`
3. Press **F5** or click **Compile**
4. Check for compilation errors in the Toolbox window
5. If successful, you should see: `0 error(s), 0 warning(s)`

### Step 4: Load the EA on a Chart

1. Open MetaTrader 5
2. Select a chart (e.g., EURUSD, M5)
3. Click **Insert → Expert Advisors → Thinkwealth Smart Signal Pro**
4. Or drag and drop the EA from the Navigator onto the chart
5. The EA Properties window will open

### Step 5: Configure EA Parameters

See the **CONFIGURATION_GUIDE.md** for detailed parameter settings.

### Step 6: Test Before Live Trading

1. **Always backtest first** using the Strategy Tester
2. **Forward test on a demo account** for at least 5-10 days
3. Only consider live trading after successful backtesting and forward testing

## Troubleshooting

### Compilation Errors

**Error: "undeclared identifier"**
- Make sure all `#include` paths are correct
- Check that Trade.mqh exists in `MQL5/Include/Trade/`

**Error: "function not found"**
- Verify MT5 build is up to date (Tools → Options → Update)

### EA Not Starting

1. Check the **Experts** journal for errors
2. Ensure **AutoTrading** is enabled in MT5 (top right button)
3. Verify the symbol supports trading
4. Check that sufficient margin is available

### No Signals Generated

1. Verify indicator parameters are correctly set
2. Check timeframe is M5
3. Make sure sufficient candles exist (at least 50 bars minimum)
4. Check indicator values in the dashboard

## File Structure

```
Thinkwealth-Smart-Signal-Pro-EA/
├── Thinkwealth-Smart-Signal-Pro-EA.mq5 (Main EA File)
├── README.md (Project Overview)
├── INSTALLATION_GUIDE.md (This File)
├── CONFIGURATION_GUIDE.md (Parameter Settings)
├── USAGE_GUIDE.md (How to Use)
├── STRATEGY_DETAILS.md (Strategy Explanation)
└── DISCLAIMER_AND_RISKS.md (Important Legal Notice)
```

## Next Steps

1. Read **CONFIGURATION_GUIDE.md** for parameter settings
2. Read **USAGE_GUIDE.md** for operational details
3. Backtest using the Strategy Tester
4. Forward test on a demo account
5. Consider live trading only after successful testing

## Support

For issues or questions:
1. Check the **Experts** journal (View → Toolbox → Experts)
2. Review error messages in the journal
3. Ensure all parameters are configured correctly
4. Verify broker and symbol compatibility

## Important Reminder

**ALWAYS test the EA thoroughly before risking real money.**

- Forex/CFD trading involves substantial risk
- Past performance does not guarantee future results
- The EA is a trading tool, not a guaranteed profit machine
- Use proper risk management and position sizing
- Never risk more than you can afford to lose
