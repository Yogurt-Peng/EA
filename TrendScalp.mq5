#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 7456;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input int LotType = 1;                            // 1:固定手数,2:固定百分比
input double LotSize = 0.01;                      // 手数
input double Percent = 1;                         // 百分比 1%
input int StopLoss = 120;                         // 止损点数 0:不使用

input group "过滤参数";
input int ATRValue = 14;                          // ATR
input ENUM_TIMEFRAMES ATRPeriod = PERIOD_CURRENT; // ATR周期
input double AmplitudeRatio = 0.2;                // 幅度比例
input bool IsTrailing = false;                     // 是否追踪止损
input int TrailingStopPoints = 10;                // 追踪止损点数

input int FastEMAValue = 8;                      // FastEMA
input ENUM_TIMEFRAMES FastEMAPeriod = PERIOD_H1; // FastEMA周期

//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleATR;
double ATRValueBuffer[];


int handleFastEMA;

double FastEMAValueBuffer[];
//+------------------------------------------------------------------+

int OnInit()
{

    handleATR = iATR(_Symbol, ATRPeriod, ATRValue);
    ArraySetAsSeries(ATRValueBuffer, true);

    handleFastEMA = iMA(_Symbol, FastEMAPeriod, FastEMAValue, 0, MODE_EMA, PRICE_CLOSE);
    ArraySetAsSeries(FastEMAValueBuffer, true);


    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");
    return INIT_SUCCEEDED;
}

datetime orderTime;

void OnTick()
{
    if(IsTrailing)
        tools.ApplyTrailingStop(TrailingStopPoints, MagicNumber);


    if (!tools.IsNewBar(PERIOD_CURRENT))
        return;


    if (tools.GetPositionCount(MagicNumber) > 0 &&iTime(_Symbol, TimeFrame,3)==orderTime)
    {
        tools.CloseAllPositions(MagicNumber);
        orderTime=0;
    }



    if (tools.GetPositionCount(MagicNumber) > 0)
        return;

    if (IsLong())
    {
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double open=iOpen(_Symbol, TimeFrame, 1);
        double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
        double lots = (LotType == 1) ? LotSize : tools.CalcLots(ask, buySl, Percent);
        trade.Buy(lots, _Symbol, ask, open);
        orderTime = iTime(_Symbol, TimeFrame, 1);
    }
    else if (IsShort())
    {
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double open=iOpen(_Symbol, TimeFrame, 1);
        double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
        double lots = (LotType == 1) ? LotSize : tools.CalcLots(bid, sellSl, Percent);
        trade.Sell(lots, _Symbol, bid, open);
        orderTime = iTime(_Symbol, TimeFrame, 1);
    }
}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 EA移除");
}

bool IsShort()
{
    MqlRates rates[];
    CopyRates(_Symbol, TimeFrame, 1, 1, rates);
    CopyBuffer(handleATR, 0, 1, 1, ATRValueBuffer);
    CopyBuffer(handleFastEMA, 0, 0, 1, FastEMAValueBuffer);

    // if(rates[0].high > FastEMAValueBuffer[0])
    //     return false;


    // 阴线
    if (rates[0].close < rates[0].open)
    {
        // 影线占振幅的10%
        double amplitude = rates[0].high - rates[0].low;    // 振幅
        double upperShadow = rates[0].high - rates[0].open; // 上影线
        double lowerShadow = rates[0].close - rates[0].low; // 下影线
        double shadowSum = upperShadow + lowerShadow;       // 上下影线总和
        // 检查上下影线总和占振幅的比例是否小于等于 10%
        if (shadowSum / amplitude <= AmplitudeRatio && amplitude > ATRValueBuffer[0])
        {
            return true;
        }
    }

    return false;
}

bool IsLong()
{
    MqlRates rates[];
    CopyRates(_Symbol, TimeFrame, 1, 1, rates);
    CopyBuffer(handleATR, 0, 1, 1, ATRValueBuffer);
    CopyBuffer(handleFastEMA, 0, 1, 1, FastEMAValueBuffer);


    // if(rates[0].high < FastEMAValueBuffer[0])
    //     return false;

    // 阳线
    if (rates[0].close > rates[0].open)
    {
        // 影线占振幅的10%
        double amplitude = rates[0].high - rates[0].low;     // 振幅
        double upperShadow = rates[0].high - rates[0].close; // 上影线
        double lowerShadow = rates[0].open - rates[0].low;   // 下影线
        double shadowSum = upperShadow + lowerShadow;        // 上下影线总和

        // 检查上下影线总和占振幅的比例是否小于等于 10%
        if (shadowSum / amplitude <= AmplitudeRatio && amplitude > ATRValueBuffer[0])
        {
            return true;
        }
    }

    return false;
}