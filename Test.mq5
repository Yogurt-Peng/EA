#include "Indicators.mqh"
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期


int OnInit()
{
    Print("🚀🚀🚀 Vegas&Pivot趋势策略初始化中...");
    Pivots.Initialize();

    ChartIndicatorAdd(0, 0, Pivots.GetHandle());
    return INIT_SUCCEEDED;
}

CPivots Pivots(_Symbol, PERIOD_D1);

void OnTick()
{
    
    double sis=Pivots.GetValue(0);
    Print("✔️[Test.mq5:20]: sis: ", sis);


}


void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 Vegas&Pivot趋势策略已关闭...");
}