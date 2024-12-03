#include "Tools.mqh"

input group "基本参数";
input int MagicNumber = 4753;                // EA编号
input int NarrowRangeCount = 8;              // NRNumber 8
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M5; // NRNumber周期
input int LotType = 1;                       // 1:固定手数,2:固定百分比
input double LotSize = 0.1;                  // 手数
input double Percent = 1;                    // 百分比 1%
input int StopLoss = 100;                    // 止损点数 0:不使用
input int TakeProfit = 100;                  // 止盈点数 0:不使用

input group "过滤参数";
input bool UseFilter = true;                     // 是否使用过滤
input int FastEMAValue = 5;                      // FastEMA
input int SlowEMAValue = 10;                     // SlowEMA
input ENUM_TIMEFRAMES FastEMAPeriod = PERIOD_H1; // FastEMA周期
input ENUM_TIMEFRAMES SlowEMAPeriod = PERIOD_H4; // SlowEMA周期

input group "价格保护";
input bool PriceProtection = true; // 是否启用价格保护
input int TriggerPoints = 60;      // 触发点数
input int MovePoints = 10;         // 移动点数

//+------------------------------------------------------------------+

int handleSlowEMA;
int handleFastEMA;

double SlowEMAValueBuffer[];
double FastEMAValueBuffer[];

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
