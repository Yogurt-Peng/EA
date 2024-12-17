#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

input group "基本参数";
input int MagicNumber = 45752;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用
input int StopTime = 9; // 全部平仓时间


CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);

CMA Ma1(_Symbol, TimeFrame, 169, MODE_EMA);
CMA Ma2(_Symbol, TimeFrame, 338, MODE_EMA);



int OnInit()
{
    Print("🚀🚀🚀 Vegas&Pivot趋势策略初始化中...");
    Ma1.Initialize();
    Ma2.Initialize();

    ChartIndicatorAdd(0, 0, Ma1.GetHandle());
    ChartIndicatorAdd(0, 0, Ma2.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    return INIT_SUCCEEDED;
}

void OnTick()
{
    if (!tools.IsNewBar(TimeFrame))
        return;


    


};


void OnDeinit(const int reason)
{
    IndicatorRelease(Ma1.GetHandle());
    IndicatorRelease(Ma2.GetHandle());
    Print("🚀🚀🚀 Vegas&Pivot趋势策略已关闭...");
}