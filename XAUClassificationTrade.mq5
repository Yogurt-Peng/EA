#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 7456;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 100;                       // 止盈点数 0:不使用



//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);




//+------------------------------------------------------------------+

int OnInit()
{



    trade.SetExpertMagicNumber(MagicNumber);
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

bool IsTopClassification()
{
    MqlRates rates[];
    CopyRates(_Symbol, TimeFrame, 1, 6, rates);
    ArraySetAsSeries(rates, true);




    return true;
}

bool IsBottomClassification()
{

    return true;
}


void MergeBars(MqlRates &rates, int count)
{
    for( int i = 0; i < count; i++)
    {

    }

}