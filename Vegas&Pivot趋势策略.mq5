#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

input group "基本参数";
input int MagicNumber = 45752;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input ENUM_TIMEFRAMES PivotTimeFrame = PERIOD_D1; // 枢轴周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用
input int StopTime = 22;                           // 全部平仓时间

CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);

CMA Ma1(_Symbol, TimeFrame, 169, MODE_EMA);
CMA Ma2(_Symbol, TimeFrame, 338, MODE_EMA);
CPivots Pivots(_Symbol, TimeFrame,PivotTimeFrame);

bool g_IsNewDay = true;

int OnInit()
{
    Print("🚀🚀🚀 Vegas&Pivot趋势策略初始化中...");
    Ma1.Initialize();
    Ma2.Initialize();
    Pivots.Initialize();

    ChartIndicatorAdd(0, 0, Ma1.GetHandle());
    ChartIndicatorAdd(0, 0, Ma2.GetHandle());
    ChartIndicatorAdd(0, 0, Pivots.GetHandle());
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


    if (currentTimeStruct.hour >= StopTime)
    {
        g_IsNewDay=true;
        tools.CloseAllPositions(MagicNumber);
        tools.DeleteAllOrders(MagicNumber);
    }


    if (g_IsNewDay && currentTimeStruct.hour == 0)
    {
        if (Ma1.GetValue(1) > Ma2.GetValue(1))
        {
            trade.BuyLimit(LotSize,Pivots.GetValue(0),_Symbol); // Pivots
            trade.BuyLimit(LotSize,Pivots.GetValue(5),_Symbol); // R1
            trade.BuyLimit(LotSize,Pivots.GetValue(6),_Symbol); // R2
            
        }
        else if (Ma1.GetValue(1) < Ma2.GetValue(1))
        {
            trade.SellLimit(LotSize,Pivots.GetValue(0),_Symbol); // Pivots
            trade.SellLimit(LotSize,Pivots.GetValue(1),_Symbol); // S1
            trade.SellLimit(LotSize,Pivots.GetValue(2),_Symbol); // S2

        }

        g_IsNewDay= false;
    }

};

void OnDeinit(const int reason)
{
    IndicatorRelease(Ma1.GetHandle());
    IndicatorRelease(Ma2.GetHandle());
    Print("🚀🚀🚀 Vegas&Pivot趋势策略已关闭...");
}