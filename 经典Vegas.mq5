#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"
input group "基本参数";
input int MagicNumber = 55244;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用


CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);


CMA Ma1(_Symbol, TimeFrame, 12, MODE_EMA);
CMA Ma2(_Symbol, TimeFrame, 156, MODE_EMA);
CMA Ma3(_Symbol, TimeFrame, 313, MODE_EMA);


int OnInit()
{
    Print("🚀🚀🚀 Vegas&Pivot趋势策略初始化中...");
    Ma1.Initialize();
    Ma2.Initialize();
    Ma3.Initialize();

    ChartIndicatorAdd(0, 0, Ma1.GetHandle());
    ChartIndicatorAdd(0, 0, Ma2.GetHandle());
    ChartIndicatorAdd(0, 0, Ma3.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    return INIT_SUCCEEDED;
}
void OnTick()
{
    if (!tools.IsNewBar(TimeFrame))
        return;

    double ma1ValueA = Ma1.GetValue(1);
    double ma1ValueB = Ma1.GetValue(2);
    
    double ma2Value = Ma2.GetValue(1);
    double ma3Value = Ma3.GetValue(1);

    // 空头排列
    if (ma2Value < ma3Value)
    {
        //过滤线向下穿越ma2Value
        if (ma1ValueA < ma2Value && ma1ValueB > ma2Value)
        {
            trade.Sell(LotSize);
        }
    }
    else if( ma2Value > ma3Value)
    {
        //过滤线向上穿越ma2Value
        if (ma1ValueA > ma2Value && ma1ValueB < ma2Value)
        {
            trade.Buy(LotSize);
        }
    }


        //过滤线向上穿越ma2Value
    if (ma1ValueA > ma2Value && ma1ValueB < ma2Value)
    {
        tools.CloseAllPositions(MagicNumber,POSITION_TYPE_SELL);
    }

        //过滤线向下穿越ma2Value
    if (ma1ValueA < ma2Value && ma1ValueB > ma2Value)
    {
        tools.CloseAllPositions(MagicNumber,POSITION_TYPE_BUY);
    }


}

void OnDeinit(const int reason)
{
    IndicatorRelease(Ma1.GetHandle());
    IndicatorRelease(Ma2.GetHandle());
    Print("🚀🚀🚀 Vegas&Pivot趋势策略已关闭...");
}