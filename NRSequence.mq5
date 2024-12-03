#include "Tools.mqh"

input group "基本参数";
input int MagicNumber = 4753;   // EA编号
input int LotType = 1;          // 1:固定手数,2:固定百分比
input double LotSize = 0.1;     // 手数
input double Percent = 1;       // 百分比 1%
input int StopLoss = 100;       // 止损点数 0:不使用
input int TakeProfit = 100;     // 止盈点数 0:不使用
input int NarrowRangeCount = 8; // NRNumber 8

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

}

void OnDeinit(const int reason)
{

    Print("🚀🚀🚀 EA移除");
}
//+------------------------------------------------------------------+
