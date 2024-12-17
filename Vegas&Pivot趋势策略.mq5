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
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);


    if (currentTimeStruct.hour >= StopTime)
    {
        g_IsNewDay=true;
        tools.DeleteAllOrders(MagicNumber);
        tools.CloseAllPositions(MagicNumber);
    }


    if (g_IsNewDay && currentTimeStruct.hour == 0&&currentTimeStruct.min >= 20)
    {


        double Pivot = Pivots.GetValue(0);
        double R1 = Pivots.GetValue(5);
        double R2 = Pivots.GetValue(6);
        double S1 = Pivots.GetValue(1);
        double S2 = Pivots.GetValue(2);
        if (Ma1.GetValue(1) > Ma2.GetValue(1))
        {
            Print("🚀🚀🚀 Vega&Pivot趋势策略挂多单...");
            
            if( Pivot>ask)
                trade.BuyStop(LotSize,Pivot,_Symbol,0,R1); // Pivots
            else
                trade.BuyLimit(LotSize,Pivot,_Symbol,0,R1); // R1

            if( S1>ask)
                trade.BuyStop(LotSize,S1,_Symbol,0,R2); // Pivots
            else
                trade.BuyLimit(LotSize,S1,_Symbol,0,R2); // R1

            // if( R2>ask)
            //     trade.BuyStop(LotSize,R2,_Symbol); // Pivots
            // else
            //     trade.BuyLimit(LotSize,R2,_Symbol); // R1

            
        }
        else if (Ma1.GetValue(1) < Ma2.GetValue(1))
        {
            Print("🚀🚀🚀 Vega&Pivot趋势策略挂空单...");


            if( Pivot<bid)
                trade.SellStop(LotSize,Pivot,_Symbol,0,S1); // Pivots
            else
                trade.SellLimit(LotSize,Pivot,_Symbol,0,S1); // S1

            if( R1<bid)
                trade.SellStop(LotSize,R1,_Symbol,0,S2); // Pivots
            else    
                trade.SellLimit(LotSize,R1,_Symbol,0,S2); // S1

            // if( S2<bid)
            //     trade.SellStop(LotSize,S2,_Symbol); // Pivots
            // else    
            //     trade.SellLimit(LotSize,S2,_Symbol); // S1

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