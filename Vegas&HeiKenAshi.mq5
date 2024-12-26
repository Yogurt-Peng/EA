#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"
input group "基本参数";
input int MagicNumber = 55244;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用

CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);

CMA Ma1(_Symbol, TimeFrame, 144, MODE_EMA);
CMA Ma2(_Symbol, TimeFrame, 169, MODE_EMA);
CHeiKenAshi Ashi(_Symbol, TimeFrame);

int OnInit()
{
    Print("🚀🚀🚀 Vegas&Pivot趋势策略初始化中...");
    Ma1.Initialize();
    Ma2.Initialize();
    Ashi.Initialize();
    // Ma3.Initialize();

    ChartIndicatorAdd(0, 0, Ma1.GetHandle());
    ChartIndicatorAdd(0, 0, Ma2.GetHandle());
    ChartIndicatorAdd(0, 1, Ashi.GetHandle());
    // ChartIndicatorAdd(0, 0, Ma3.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    return INIT_SUCCEEDED;
}
void OnTick()
{
    if (!tools.IsNewBar(TimeFrame))
        return;

    if (!tools.GetPositionCount(MagicNumber) == 0)
        return;

    double ma1Value = Ma1.GetValue(1);
    double ma2Value = Ma2.GetValue(1);
    // double ma3Value = Ma3.GetValue(1);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double buySl = ask - StopLoss * _Point;
    double buyTp = ask + TakeProfit * _Point;
    double sellSl = bid + StopLoss * _Point;
    double sellTp = bid - TakeProfit * _Point;
    double close =iClose(_Symbol, TimeFrame, 1);

    int highIndex=iHighest(_Symbol, TimeFrame,MODE_HIGH, 4,1);
    int lowIndex=iLowest(_Symbol, TimeFrame,MODE_LOW, 4,1);
    double high=iHigh(_Symbol, TimeFrame, highIndex);
    double low=iLow(_Symbol, TimeFrame, lowIndex);

    SIGN sign = GetSign();

    // 多头排列

    if (ma1Value > ma2Value && sign == BUY &&close>ma1Value)
    {
        trade.Buy(LotSize, _Symbol, ask, low, buyTp);
    }
        // 空头排列
    if (ma1Value < ma2Value && sign == SELL&& close<ma1Value)
    {
        trade.Sell(LotSize, _Symbol, bid, high, sellTp);
    }
   
}

SIGN GetSign()
{
    double open[4], high[4], low[4], close[4];
    Ashi.GetValues(4, open, high, low, close);

    if (open[3] > close[3] && open[0] < close[0] && close[0] > open[3])
        return BUY;

    if (open[3] < close[3] && open[0] > close[0] && close[0] < open[3])
        return SELL;

    return NONE;
}
void OnDeinit(const int reason)
{
    // IndicatorRelease(Ma1.GetHandle());
    // IndicatorRelease(Ma2.GetHandle());
    // IndicatorRelease(Ashi.GetHandle());
    Print("🚀🚀🚀 Vegas&Pivot趋势策略已关闭...");
}