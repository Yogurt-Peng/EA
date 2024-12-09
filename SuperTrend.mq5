#include "Tools.mqh"
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
input ENUM_TIMEFRAMES MAFilterPeriod = PERIOD_CURRENT; // 均线过滤周期
input int MAFilterValue = 100;                           // 均线过滤偏移

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleSuperTrend;
int handleMAFilter;

double bufferSuperTrendValue[];
double bufferMAFilterValue[];

int OnInit()
{
    handleSuperTrend = iCustom(_Symbol, TimeFrame, "Wait_Indicators\\SuperTrend", SuperTrendPeriod, SuperTrendMultiplier);
    handleMAFilter = iMA(_Symbol, MAFilterPeriod, MAFilterValue, 0, MODE_EMA, PRICE_CLOSE);

    ArraySetAsSeries(bufferSuperTrendValue, true);
    ArraySetAsSeries(bufferMAFilterValue, true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");
    return INIT_SUCCEEDED;
}

void OnTick()
{


    if (tools.GetPositionCount(MagicNumber) > 0)
    {
        // CopyBuffer(handleSuperTrend, 0, 0, 3, bufferSuperTrendValue);

        // if (SymbolInfoDouble(_Symbol, SYMBOL_ASK) <= bufferSuperTrendValue[0])
        // {
        //     tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY);
        // }
        // else if (SymbolInfoDouble(_Symbol, SYMBOL_BID) >= bufferSuperTrendValue[0])
        // {
        //     tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL);
        // }

        return;
    }

    if (!tools.IsNewBar(TimeFrame))
        return;

    CopyBuffer(handleMAFilter, 0, 0, 3, bufferMAFilterValue);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double close = iClose(_Symbol, TimeFrame, 1);

    double buySl = ask - StopLoss * _Point;
    double buyTp = ask + TakeProfit * _Point;
    double sellSl = bid + StopLoss * _Point;
    double sellTp = bid - TakeProfit * _Point;

    switch (GetTradeSignal())
    {
    case BUY:
    {
        if(Long)
        {
        if (UseMAFilter && close > bufferMAFilterValue[1])
            trade.Buy(LotSize, _Symbol, ask, buySl, buyTp, "SuperTrend");
        else if (!UseMAFilter)
            trade.Buy(LotSize, _Symbol, ask, buySl, buyTp, "SuperTrend");

        break;
        }
    };
    case SELL:
    {
        if(Short)
        {
        if (UseMAFilter && close < bufferMAFilterValue[1])
            trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp, "RSITrend");
        else if (!UseMAFilter)
            trade.Sell(LotSize, _Symbol, bid,sellSl, sellTp, "RSITrend");
        break;
        }

    };
    default:
        break;
    }
}

void OnDeinit(const int reason)
{
    IndicatorRelease(handleSuperTrend);
    IndicatorRelease(handleMAFilter);
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
