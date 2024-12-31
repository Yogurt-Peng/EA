#include "Tools.mqh"
#include "Indicators.mqh"

input group "基本参数";
input int MagicNumber = 52424;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input double MultiplierSL = 1;                    // 止损点数 0:不使用
input int AtrValue = 14;                       // ATR值
input int DonchianLongValue = 21;                  // 长期唐奇安通道值
input int DonchianShortValue = 10;                 // 短期唐奇安通道值
input int EMAValue = 144;                         // EMA值

CDonchian donchianLong(_Symbol, TimeFrame, DonchianLongValue);
CDonchian donchianShort(_Symbol, TimeFrame, DonchianShortValue);
CATR atr(_Symbol, TimeFrame, AtrValue);
CMA ma(_Symbol, TimeFrame, EMAValue, MODE_EMA);

CTrade trade;
CTools tools(_Symbol, &trade);

int OnInit()
{
    Print("🚀🚀🚀 策略初始化中...");
    donchianLong.Initialize();
    donchianShort.Initialize();
    atr.Initialize();
    ma.Initialize();

    ChartIndicatorAdd(0, 0, donchianLong.GetHandle());
    ChartIndicatorAdd(0, 0, donchianShort.GetHandle());
    ChartIndicatorAdd(0, 0, ma.GetHandle());
    ChartIndicatorAdd(0, 1, atr.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);

    return (INIT_SUCCEEDED);
}

void OnTick()
{
    if (!tools.IsNewBar(TimeFrame))
        return;

    SIGN exitSign = GetExitSign();

    if (exitSign == BUY)
    {
        tools.CloseAllPositions(MagicNumber,POSITION_TYPE_SELL);
    }
    else if (exitSign == SELL)
    {
        tools.CloseAllPositions(MagicNumber,POSITION_TYPE_BUY);
        
    }

    if (tools.GetPositionCount(MagicNumber) != 0)
        return;

    double atrValue = atr.GetValue(1);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double buySl = ask - MultiplierSL * atrValue;
    double sellSl = bid + MultiplierSL * atrValue;
    SIGN sign = GetSign();

    if (sign == BUY)
    {
        trade.Buy(LotSize, _Symbol, ask, buySl);

    }
    else if (sign == SELL)
    {
        trade.Sell(LotSize, _Symbol, bid, sellSl);
    }

}

void OnDeinit(const int reason)
{
    IndicatorRelease(atr.GetHandle());
    IndicatorRelease(donchianLong.GetHandle());
    IndicatorRelease(donchianShort.GetHandle());
    Print("🚀🚀🚀 策略停止...");
}

SIGN GetSign()
{

    double close = iClose(_Symbol, TimeFrame, 1);
    //&& ma.GetValue(1)<close
    if (close > donchianLong.GetValue(0) )
        return BUY;
    else if (close < donchianLong.GetValue(1))
        return SELL;

    return NONE;
}

SIGN GetExitSign()
{
        double close = iClose(_Symbol, TimeFrame, 1);
    if (close > donchianShort.GetValue(0))
        return BUY;
    else if (close < donchianShort.GetValue(1))
        return SELL;

    return NONE;
}