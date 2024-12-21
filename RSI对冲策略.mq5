#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

input group "基本参数";
input int MagicNumber = 524211;                // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M15; // 周期
input double LotSize = 0.01;                  // 手数
input int StopLoss = 0;                       // 止损点数 0:不使用
input int TakeProfit = 0;                     // 止盈点数 0:不使用

input group "指标参数";
input int RSIValue = 20;      // RSI指标值
input int RSIOverbought = 70; // 超买区
input int RSIOversold = 30;   // 超卖区


CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);

CRSI rsi(_Symbol, TimeFrame, RSIValue);


int OnInit()
{
    Print("🚀🚀🚀 RSI对冲策略初始化中...");
    rsi.Initialize();

    ChartIndicatorAdd(0, 1, rsi.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    return INIT_SUCCEEDED;
}




void OnTick()
{

}



void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 RSI对冲策略已关闭");
}