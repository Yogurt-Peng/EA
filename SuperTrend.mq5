#include "Tools.mqh"
#include "Indicators.mqh"
input group "基本参数";
input int MagicNumber = 1756;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 200;                         // 止损点数 0:不使用
input int TakeProfit = 200;                       // 止盈点数 0:不使用
input int SuperTrendPeriod = 10;                  // 超趋势周期
input int SuperTrendMultiplier = 3;               // 超趋势倍数
input int TPFactor = 1;                           // 止盈倍数

input bool Long = true;  // 多单
input bool Short = true; // 空单

input bool UseMAFilter = true;                         // 是否使用均线过滤
input ENUM_TIMEFRAMES EMAPeriod = PERIOD_CURRENT; // 均线过滤周期
input int EMAValueA = 144;                           // 均线过滤偏移
input int EMAValueB = 169;                           // 均线过滤偏移


CTrade trade;
CTools tools(_Symbol, &trade);

int handleSuperTrend;

CMA Ma1(_Symbol, EMAPeriod, EMAValueA, MODE_EMA);
CMA Ma2(_Symbol, EMAPeriod, EMAValueB, MODE_EMA);

double bufferSuperTrendValue[];

int OnInit()
{
    handleSuperTrend = iCustom(_Symbol, TimeFrame, "Wait_Indicators\\SuperTrend", SuperTrendPeriod, SuperTrendMultiplier);
    Ma1.Initialize();
    Ma2.Initialize();
    ArraySetAsSeries(bufferSuperTrendValue, true);

    ChartIndicatorAdd(0, 0, Ma1.GetHandle());
    ChartIndicatorAdd(0, 0, Ma2.GetHandle());

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");
    return INIT_SUCCEEDED;
}

SIGN Status=NONE;
void OnTick()
{

    if (!tools.IsNewBar(TimeFrame))
        return;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double close = iClose(_Symbol, TimeFrame, 1);

    double buySl = ask - StopLoss * _Point;
    double buyTp = ask + TakeProfit * _Point;
    double sellSl = bid + StopLoss * _Point;
    double sellTp = bid - TakeProfit * _Point;

    CopyBuffer(handleSuperTrend, 0, 1, 1, bufferSuperTrendValue);

    SIGN sign= GetTradeSignal();

    if(sign != Status && sign != NONE && Status!=NONE)
    {
        tools.CloseAllPositions(MagicNumber);
    }

    switch (sign)
    {
    case BUY:
    {
        tools.CloseAllPositions(MagicNumber);
        if(Long)
        {
        if (UseMAFilter && close > Ma1.GetValue(1)&& Ma1.GetValue(1) > Ma2.GetValue(1))
        {
            Status= BUY;
            trade.Buy(LotSize, _Symbol, ask, bufferSuperTrendValue[0], 0, "SuperTrend");

        }
        else if (!UseMAFilter)
        {
            trade.Buy(LotSize, _Symbol, ask, bufferSuperTrendValue[0], 0, "SuperTrend");
            Status= BUY;

        }

        break;
        }
    };
    case SELL:
    {
        tools.CloseAllPositions(MagicNumber);
        if(Short)
        {
        if (UseMAFilter && close < Ma1.GetValue(1)&& Ma1.GetValue(1) < Ma2.GetValue(1))
        {
            trade.Sell(LotSize, _Symbol, bid, bufferSuperTrendValue[0], 0, "RSITrend");
            Status= SELL;

        }
        else if (!UseMAFilter)
        {
            trade.Sell(LotSize, _Symbol, bid,bufferSuperTrendValue[0], 0, "RSITrend");
            Status= SELL;
        }
        break;
        }

    };
    default:
        break;
    }
}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 EA移除");
}

SIGN GetTradeSignal()
{
    MqlRates rates[];
    CopyRates(_Symbol, TimeFrame, 1, 3, rates);
    CopyBuffer(handleSuperTrend, 0, 1, 3, bufferSuperTrendValue);
    ArraySetAsSeries(rates, true);

    if (rates[1].close < bufferSuperTrendValue[1] && rates[0].close > bufferSuperTrendValue[0])
        return BUY;
    else if (rates[1].close > bufferSuperTrendValue[1] && rates[0].close < bufferSuperTrendValue[0])
        return SELL;

    return NONE;
}
