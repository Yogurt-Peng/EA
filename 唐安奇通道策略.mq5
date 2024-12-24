#include "Tools.mqh"
#include "Indicators.mqh"

input group "基本参数";
input int MagicNumber = 555245;                   // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input double StopLossK = 2;                       // 止损系数
input double TakeProfitK = 1;                     // 止盈系数

input int ShortAtrValue = 40; // 短期ATR值
input int LongAtrValue = 130; // 长期ATR值
input int DonchianValue = 20; // 唐安奇通道长度

CTrade trade;
CTools tools(_Symbol, &trade);

CATR shortAtr(_Symbol, TimeFrame, ShortAtrValue);
CATR longAtr(_Symbol, TimeFrame, LongAtrValue);
CDonchian donchian(_Symbol, TimeFrame, LongAtrValue);

int OnInit()
{
    Print("🚀🚀🚀 唐安奇通道策略启动...");

    shortAtr.Initialize();
    longAtr.Initialize();
    donchian.Initialize();

    ChartIndicatorAdd(0, 0, shortAtr.GetHandle());
    ChartIndicatorAdd(0, 0, longAtr.GetHandle());
    ChartIndicatorAdd(0, 0, donchian.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    return (INIT_SUCCEEDED);
}

void OnTick()
{

    if (!tools.IsNewBar(TimeFrame))
        return;
    SIGN sign = GetSign();

    double donchianDifference = MathAbs(donchian.GetValue(0) - donchian.GetValue(1));

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double buySl = ask - donchianDifference * StopLossK;
    double buyTp = ask + donchianDifference * StopLossK * TakeProfitK;
    double sellSl = bid + donchianDifference * StopLossK;
    double sellTp = bid - donchianDifference * StopLossK * TakeProfitK;

    if (sign == BUY)
    {
        tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL);
        if (tools.GetPositionCount(MagicNumber) == 0)
            trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);
    }
    else if (sign == SELL)
    {
        tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY);
        if (tools.GetPositionCount(MagicNumber) == 0)
            trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
    }
}

void OnDeinit(const int reason)
{
    IndicatorRelease(shortAtr.GetHandle());
    IndicatorRelease(longAtr.GetHandle());
    IndicatorRelease(donchian.GetHandle());
    Print("🚀🚀🚀 唐安奇通道策略停止...");
}

SIGN GetSign()
{
    if (shortAtr.GetValue(1) <= longAtr.GetValue(1))
        return NONE;
    double close = iClose(_Symbol, TimeFrame, 1);

    if (close > donchian.GetValue(0))
        return SELL;
    else if (close < donchian.GetValue(1))
        return BUY;

    return NONE;
}