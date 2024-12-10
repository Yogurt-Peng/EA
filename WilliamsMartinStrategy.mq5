#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 8845;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用
input double Multiplier = 2.0;                    // 加仓倍数
input int MaxTrades = 4;                          // 最大加仓次数
input int PeriodWPR = 14;                         // 威廉姆斯指标周期
input double Overbought = -20;                    // 超买区
input double Oversold = -80;                      // 超卖区
input double AccountRisk = 0.02;                  // 最大账户风险（如5%）
input double StopLossPoints = 200;                // 每次开仓的固定止损点数

//+------------------------------------------------------------------+
CTrade trade;

CTools tools(_Symbol, &trade);

int handleWPR; // 威廉姆斯指标
double bufferWPRValue[];

double openPrice[10];                   // 记录开仓价格
double totalLots = 0;                   // 总手数
int tradeCount = 0;                     // 当前开仓次数

//+------------------------------------------------------------------+
int OnInit()
{
    handleWPR = iWPR(_Symbol, TimeFrame, PeriodWPR);  // 初始时获取周期的WPR
    ArraySetAsSeries(bufferWPRValue, true);
    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功, WilliamsMartinStrategy已启动");

    // 预先进行一次开仓测试，如果需要
    // trade.Buy(LotSize);
    // trade.Buy(LotSize);

    return INIT_SUCCEEDED;
}

void OnTick()
{
    // 获取账户当前权益和风险限额
    double accountEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    double maxLoss = AccountInfoDouble(ACCOUNT_BALANCE) * AccountRisk;
    Print("✔️[WilliamsMartinStrategy.mq5:49]: maxLoss: ", maxLoss);
    // 检测浮动亏损是否超过最大允许亏损
    double totalFloatingLoss = tools.GetTotalProfit(MagicNumber);
    Print("✔️[WilliamsMartinStrategy.mq5:52]: totalFloatingLoss: ", totalFloatingLoss);

    // if (MathAbs(totalFloatingLoss) >= StopLoss)
    // {
    //     tools.CloseAllPositions(MagicNumber);
    //     Print("风险敞口超限，强制平仓退出策略");
    //     tradeCount = 0;
    //     return;
    // }

    if (MathAbs(totalFloatingLoss) >= maxLoss)
    {
        tools.CloseAllPositions(MagicNumber);
        Print("风险敞口超限，平仓");
        tradeCount = 0;
        return;
    }

    // 如果盈利n点，强制平仓退出策略
    if (totalFloatingLoss >= TakeProfit)
    {
        tools.CloseAllPositions(MagicNumber);
        Print("达到止盈，平仓");
        tradeCount = 0;
        return;
    }

    // 每个周期开仓时检查
    if (!tools.IsNewBar(PERIOD_CURRENT))
        return;

    // 检查信号和是否已达到最大开仓次数
    if (tradeCount < MaxTrades)
    {
        switch (GetSignal())
        {
        case BUY:
            {
                double lotSize = LotSize * MathPow(Multiplier, tradeCount);
                trade.Buy(lotSize);
                tradeCount++;  // 增加开仓次数
                Print("开仓多头, 当前开仓次数: ", tradeCount);
                break;
            }
        default:
            break;
        }
    }
    else
    {
        Print("达到最大开仓次数，当前不再开仓。");
    }
}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 策略已停止");
}

// 获取信号
SIGN GetSignal()
{
    ENUM_TIMEFRAMES signalTimeFrame;
    
    // 根据 tradeCount 设置不同的周期
    switch (tradeCount)
    {
        case 0: signalTimeFrame = PERIOD_M5;   // 第一次开仓使用5分钟周期
            break;
        case 1: signalTimeFrame = PERIOD_M15;  // 第二次开仓使用15分钟周期
            break;
        case 2: signalTimeFrame = PERIOD_M30;   // 第三次开仓使用1小时周期
            break;
        case 3: signalTimeFrame = PERIOD_H1;   // 第四次开仓使用4小时周期
            break;
        default: signalTimeFrame = PERIOD_D1;  // 其他情况默认使用1日周期
            break;
    }

    // 获取对应周期的威廉姆斯%R指标
    handleWPR = iWPR(_Symbol, signalTimeFrame, PeriodWPR); 
    CopyBuffer(handleWPR, 0, 1, 2, bufferWPRValue);
    
    // 判断信号是否满足开仓条件
    if (bufferWPRValue[1] < Oversold && bufferWPRValue[0] > Oversold)
    {
        return BUY;  // 超卖信号，做多
    }

    if (bufferWPRValue[1] > Overbought && bufferWPRValue[0] < Overbought)
    {
        return SELL;  // 超买信号，做空
    }

    return NONE;  // 没有信号
}
