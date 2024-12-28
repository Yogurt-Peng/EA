#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"
input group "基本参数";
input int MagicNumber = 55244;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int openHour = 9;                           // 开盘时间
input int closeHour = 22;                         // 收盘时间

input int EMAValue = 10; // EMA周期

CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);

CMA Ma1(_Symbol, TimeFrame, EMAValue, MODE_EMA);

int OnInit()
{
    Print("🚀🚀🚀 策略初始化中...");
    Ma1.Initialize();
    ChartIndicatorAdd(0, 0, Ma1.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    return INIT_SUCCEEDED;
}

void OnTick()
{

    if (!tools.IsNewBar(TimeFrame))
        return;

    datetime currentTime = TimeCurrent();
    MqlDateTime currentTimeStruct;
    TimeToStruct(currentTime, currentTimeStruct);

    double yesterdayClose = iClose(NULL, PERIOD_D1, 1);

    if (currentTimeStruct.hour == closeHour)
        tools.CloseAllPositions(MagicNumber);

    if (tools.GetPositionCount(MagicNumber) > 0)
        return;

    if (yesterdayClose > Ma1.GetValue(1))
    {
        if (currentTimeStruct.hour == openHour)
        {
            trade.Buy(LotSize);
        }
    }

    if (yesterdayClose < Ma1.GetValue(1))
    {
        if (currentTimeStruct.hour == openHour)
        {
            trade.Sell(LotSize);
        }
    }
}
