// 趋势型策略，关键是波动幅度与ema过滤
#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 1756;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input int LotType = 2;                            // 1:固定手数,2:固定百分比
input double LotSize = 0.01;                      // 手数
input double Percent = 1;                         // 百分比 1%
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用

input group "价格保护";
input bool PriceProtection = true; // 是否启用价格保护
input int TriggerPoints = 50;      // 触发点数
input int MovePoints = 20;         // 移动点数

input group "过滤参数";
input bool UseFilter = true; // 是否使用过滤
input int EMAValue = 200;    // FastEMA
input double Amplitude = 0.02; // 波动幅度

//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleTrix;
int handleEMA;
int handleATR;

double bufferATRValue[];
double bufferTrixValue[];
double bufferSignalValue[];
double bufferEMAValue[];

enum SIGN
{
    BUY,
    SELL,
    NONE
};

//+------------------------------------------------------------------+

int OnInit()
{

    handleTrix = iCustom(_Symbol, TimeFrame, "Wait_Indicators\\TRIX", 10, MODE_SMA, MODE_SMA, MODE_SMA, 5, MODE_SMA, PRICE_CLOSE);
    handleEMA = iMA(_Symbol, TimeFrame, EMAValue, 0, MODE_EMA, PRICE_CLOSE);
    handleATR = iATR(_Symbol, TimeFrame, 14);

    ArraySetAsSeries(bufferATRValue, true);
    ArraySetAsSeries(bufferTrixValue, true);
    ArraySetAsSeries(bufferSignalValue, true);
    ArraySetAsSeries(bufferEMAValue, true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");

    return INIT_SUCCEEDED;
}

void OnTick()
{

    if (PriceProtection)
        tools.ApplyBreakEven(TriggerPoints, MovePoints, MagicNumber);

    if (!tools.IsNewBar(TimeFrame))
        return;

    CopyBuffer(handleATR, 0, 1, 1, bufferATRValue);
    double Sl_Tp = bufferATRValue[0] * 3 * 100;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double buySl = (StopLoss == 0) ? 0 : ask - Sl_Tp * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : ask + Sl_Tp * _Point;

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sellSl = (StopLoss == 0) ? 0 : bid + Sl_Tp * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : bid - Sl_Tp * _Point;

    if (UseFilter)
    {
        if (TrixSign() == BUY && EMAFilter() == BUY && AmplitudeFilter() == BUY)
            trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);

        if (TrixSign() == SELL && EMAFilter() == SELL && AmplitudeFilter() == SELL)
            trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
    }
    else
    {
        if (TrixSign() == BUY && AmplitudeFilter() == BUY)
            trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);

        if (TrixSign() == SELL && AmplitudeFilter() == SELL)
            trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
    }
}

SIGN TrixSign()
{
    CopyBuffer(handleTrix, 0, 1, 2, bufferTrixValue);
    CopyBuffer(handleTrix, 1, 1, 2, bufferSignalValue);

    // 零轴下死叉
    if (bufferTrixValue[0] < 0 && bufferTrixValue[1] < 0 && bufferSignalValue[0] < 0 && bufferSignalValue[1] < 0)
    {
        // Trix上穿信号线
        if (bufferSignalValue[0] < bufferTrixValue[0] && bufferSignalValue[1] > bufferTrixValue[1])
        {
            return BUY;
        }
    }

    // 零轴上金叉
    if (bufferTrixValue[0] > 0 && bufferTrixValue[1] > 0 && bufferSignalValue[0] > 0 && bufferSignalValue[1] > 0)
    {
        // Trix下穿信号线
        if (bufferSignalValue[0] > bufferTrixValue[0] && bufferSignalValue[1] < bufferTrixValue[1])
        {
            return SELL;
        }
    }

    return NONE;
}

SIGN EMAFilter()
{

    CopyBuffer(handleEMA, 0, 1, 1, bufferEMAValue);

    double close = iClose(_Symbol, TimeFrame, 1);
    if (close > bufferEMAValue[0])
        return BUY;

    if (close < bufferEMAValue[0])
        return SELL;

    return NONE;
}

SIGN AmplitudeFilter()
{
    CopyBuffer(handleTrix, 0, 1, 2, bufferTrixValue);
    if (bufferTrixValue[1] >=Amplitude)
        return SELL;

    if (bufferTrixValue[1] <= -Amplitude)
        return BUY;

    return NONE;
}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 EA移除");
}
