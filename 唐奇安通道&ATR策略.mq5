#include "Tools.mqh"
#include "Indicators.mqh"

input group "基本参数";
input int MagicNumber = 52424;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input double MultiplierSL = 1;                    // 止损点数 0:不使用
input double MultiplierTP = 1;                    // 止盈点数 0:不使用
input int AtrValue = 14;                       // ATR值
input int DonchianValue = 20;                  // 唐奇安通道值

CDonchian donchian(_Symbol, TimeFrame, DonchianValue);
CATR atr(_Symbol, TimeFrame, AtrValue);

CTrade trade;
CTools tools(_Symbol, &trade);

int OnInit()
{
    Print("🚀🚀🚀 策略初始化中...");
    donchian.Initialize();
    atr.Initialize();

    ChartIndicatorAdd(0, 0, donchian.GetHandle());
    ChartIndicatorAdd(0, 1, atr.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);

    return (INIT_SUCCEEDED);
}

void OnTick()
{
    if (!tools.IsNewBar(TimeFrame))
        return;

    if (tools.GetPositionCount(MagicNumber) != 0)
        return;

    double atrValue = atr.GetValue(1);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double buySl = ask - MultiplierSL * atrValue;
    double buyTp = ask + MultiplierTP * atrValue;
    double sellSl = bid + MultiplierSL * atrValue;
    double sellTp = bid - MultiplierTP * atrValue;
    SIGN sign = GetSign();

    if (sign == BUY)
    {
        trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);
    }
    else if (sign == SELL)
    {
        trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
    }
}

void OnDeinit(const int reason)
{
    IndicatorRelease(atr.GetHandle());
    IndicatorRelease(donchian.GetHandle());
    Print("🚀🚀🚀 策略停止...");
}

SIGN GetSign()
{

    double close = iClose(_Symbol, TimeFrame, 1);
    if (close > donchian.GetValue(0))
        return SELL;
    else if (close < donchian.GetValue(1))
        return BUY;

    return NONE;
}
