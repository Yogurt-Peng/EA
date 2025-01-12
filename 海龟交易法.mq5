#include "Tools.mqh"
#include "Indicators.mqh"

input group "================基本参数================";
input int InpMagicNumber = 555245;               // EA编号
input ENUM_TIMEFRAMES InpTimeFrame = PERIOD_M30; // 周期
input double InpRiskRatio = 1;                   // 风险比例%

input group "================指标参数================";
input int InpEntryLength = 20;          // 入场长度
input int InpExitLength = 10;           // 出场长度
input int InpATRValue = 20;             // 止损
input double InpStopLossMultiple = 2.0; // 止损系数

CTrade trade;
CTools tools(_Symbol, &trade);

CATR ATR(_Symbol, InpTimeFrame, InpATRValue);
CDonchian EntryDC(_Symbol, InpTimeFrame, InpEntryLength);
CDonchian ExitDC(_Symbol, InpTimeFrame, InpExitLength);

int OnInit()
{
    Print("🚀🚀🚀 海龟交易法启动...");

    ATR.Initialize();
    EntryDC.Initialize();
    ExitDC.Initialize();
    ChartIndicatorAdd(0, 1, ATR.GetHandle());
    trade.SetExpertMagicNumber(InpMagicNumber);
    return (INIT_SUCCEEDED);
}

void OnTick()
{
    if (!tools.IsNewBar(PERIOD_M1))
    {
        Sleep(100);
        return;
    }

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    int positionCount = tools.GetPositionCount(InpMagicNumber);

    bool isBuySignal = ask > EntryDC.GetValue(0) && positionCount == 0;
    bool isSellSignal = bid < EntryDC.GetValue(1) && positionCount == 0;

    bool isCloseBuySignal = bid < ExitDC.GetValue(1) && positionCount > 0;
    bool isCloseSellSignal = ask > ExitDC.GetValue(0) && positionCount > 0;

    if (isCloseBuySignal)
    {
        tools.CloseAllPositions(InpMagicNumber, POSITION_TYPE_BUY);
    }
    else if (isCloseSellSignal)
    {
        tools.CloseAllPositions(InpMagicNumber, POSITION_TYPE_SELL);
        
    }
    else

    if (isBuySignal)
    {
        double stopLoss = ask - ATR.GetValue(1) * InpStopLossMultiple;
        trade.Buy(0.1, _Symbol, ask, stopLoss, 0);
    }
    else if (isSellSignal)
    {
        double stopLoss = bid + ATR.GetValue(1) * InpStopLossMultiple;
        trade.Sell(0.1, _Symbol, bid, stopLoss, 0);
    }
}

void OnDeinit(const int reason)
{
    IndicatorRelease(ATR.GetHandle());
    IndicatorRelease(EntryDC.GetHandle());
    IndicatorRelease(ExitDC.GetHandle());
    Print("🚀🚀🚀 海龟交易法停止...");
}
