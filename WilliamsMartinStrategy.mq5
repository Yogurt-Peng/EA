#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 8845;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用
input double Multiplier = 2.0;                    // 加仓倍数
input int MaxTrades = 5;                          // 最大加仓次数
input int Period_WPR = 14;                        // 威廉姆斯指标周期
input double Overbought = -20;                    // 超买区
input double Oversold = -80;                      // 超卖区
input double AccountRisk = 0.05;                  // 最大账户风险（如5%）
input double StopLossPoints = 200;                // 每次开仓的固定止损点数

//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleWPR; // 威廉姆斯指标
double bufferWPRValue[];

//+------------------------------------------------------------------+
int OnInit()
{

    handleWPR = iWPR(_Symbol, TimeFrame, 14);
    ArraySetAsSeries(bufferWPRValue, true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功, WilliamsMartinStrategy已启动");
    return INIT_SUCCEEDED;
}
void OnTick()
{



}
void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 策略已停止");
};

SIGN GetSignal()
{
    CopyBuffer(handleWPR, 0, 1, 2, bufferWPRValue);
    if (bufferWPRValue[1] < -80 && bufferWPRValue[0] > -80)
    {
        return BUY;
    }

    if (bufferWPRValue[1] > -20 && bufferWPRValue[0] < -20)
    {
        return SELL;
    }

    return NONE;
}