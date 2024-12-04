#include "Tools.mqh"

input group "基本参数";
input int MagicNumber = 4753;                // EA编号
input int NarrowRangeCount = 7;              // NRNumber
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M5; // NRNumber周期
input int LotType = 1;                       // 1:固定手数,2:固定百分比
input double LotSize = 0.01;                 // 手数
input double Percent = 1;                    // 百分比 1%
input int StopLoss = 220;                    // 止损点数 0:不使用
input int TakeProfit = 180;                  // 止盈点数 0:不使用

input group "过滤参数";
input bool UseFilter = true;                     // 是否使用过滤
input int FastEMAValue = 8;                      // FastEMA
input ENUM_TIMEFRAMES FastEMAPeriod = PERIOD_H1; // FastEMA周期
input int SlowEMAValue = 100;                    // SlowEMA
input ENUM_TIMEFRAMES SlowEMAPeriod = PERIOD_H4; // SlowEMA周期

input group "价格保护";
input bool PriceProtection = true; // 是否启用价格保护
input int TriggerPoints = 50;      // 触发点数
input int MovePoints = 20;         // 移动点数

input bool TrailingStop = true; // 是否启追踪止损
input int TrailingStopPoints = 50; // 追踪止损点数

//+------------------------------------------------------------------+
int handleFastEMA;
int handleSlowEMA;

double FastEMAValueBuffer[];
double SlowEMAValueBuffer[];

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

//+------------------------------------------------------------------+

int OnInit()
{
    handleFastEMA = iMA(_Symbol, FastEMAPeriod, FastEMAValue, 0, MODE_EMA, PRICE_CLOSE);
    handleSlowEMA = iMA(_Symbol, SlowEMAPeriod, SlowEMAValue, 0, MODE_EMA, PRICE_CLOSE);

    trade.SetExpertMagicNumber(MagicNumber);

    ArraySetAsSeries(SlowEMAValueBuffer, true);
    ArraySetAsSeries(FastEMAValueBuffer, true);

    Print("🚀🚀🚀 初始化成功");

    return INIT_SUCCEEDED;
}

void OnTick()
{
    // 一分钟内只执行一次 提高效率
    if (!tools.IsNewBar(PERIOD_M1))
        return;

    if(TrailingStop)
        tools.ApplyTrailingStop( TrailingStopPoints,MagicNumber);

    if (PriceProtection)
        tools.ApplyBreakEven(TriggerPoints, MovePoints,MagicNumber);

    if (tools.GetPositionCount(MagicNumber) > 0)
        return;

    if (tools.GetOrderCount(MagicNumber) > 0)
        return;

    if (!IsNRSequence())
        return;

    CopyBuffer(handleFastEMA, 0, 0, 1, FastEMAValueBuffer);
    CopyBuffer(handleSlowEMA, 0, 0, 1, SlowEMAValueBuffer);

    double high = iHigh(_Symbol, TimeFrame, 1);
    double low = iLow(_Symbol, TimeFrame, 1);

    double buySl = (StopLoss == 0) ? 0 : high - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : high + TakeProfit * _Point;

    double sellSl = (StopLoss == 0) ? 0 : low + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : low - TakeProfit * _Point;

    // 过期时间是下一根K线
    datetime expiration = iTime(_Symbol, PERIOD_CURRENT, 0) + 1 * PeriodSeconds(PERIOD_CURRENT);

    if (FastEMAValueBuffer[0] < low && SlowEMAValueBuffer[0] < low)
    {
        double lots = (LotType == 1) ? LotSize : tools.CalcLots(high, buySl, Percent);

        trade.BuyStop(lots, high, _Symbol, buySl, buyTp, ORDER_TIME_SPECIFIED, expiration, "buy");
    }
    else if (FastEMAValueBuffer[0] > high && SlowEMAValueBuffer[0] > high)
    {
        double lots = (LotType == 1) ? LotSize : tools.CalcLots(low, sellSl, Percent);
        trade.SellStop(lots, low, _Symbol, sellSl, sellTp, ORDER_TIME_SPECIFIED, expiration, "sell");
    }
}

void OnDeinit(const int reason)
{

    Print("🚀🚀🚀 EA移除");
}

// 1.当前K线的振幅比前N-1根都小
// 2. 当前K的高点小于前一根的高点，最低点大于前一跟低点
bool IsNRSequence()
{
    double high_1 = iHigh(_Symbol, TimeFrame, 1);
    double low_1 = iLow(_Symbol, TimeFrame, 1);

    double high_2 = iHigh(_Symbol, TimeFrame, 2);
    double low_2 = iLow(_Symbol, TimeFrame, 2);

    // 1.当前K线的振幅比前N-1根都小 可以改成都是内包。
    for (int i = 2; i <= NarrowRangeCount; i++)
    {
        double high_i = iHigh(_Symbol, TimeFrame, i);
        double low_i = iLow(_Symbol, TimeFrame, i);

        if (MathAbs(high_i - low_i) < MathAbs(high_1 - low_1))
        {
            return false;
        }
    }

    // 2. 当前K的高点小于前一根的高点，最低点大于前一跟低点(内包)
    if (high_1 > high_2 || low_1 < low_2)
        return false;

    return true;
};

//+------------------------------------------------------------------+
