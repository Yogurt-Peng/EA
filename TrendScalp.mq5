#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 7456;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input int LotType = 2;                            // 1:固定手数,2:固定百分比
input double LotSize = 0.01;                      // 手数
input double Percent = 1;                         // 百分比 1%
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用

input group "过滤参数";
input int ATRValue = 14;                          // ATR
input ENUM_TIMEFRAMES ATRPeriod = PERIOD_CURRENT; // ATR周期
input double AmplitudeRatio = 0.4;                // 幅度比例

input group "追踪止损";
input bool IsTrailing = true;      // 是否追踪止损
input int TrailingStopPoints = 10; // 追踪止损点数

input group "价格保护";
input bool PriceProtection = true; // 是否启用价格保护
input int TriggerPoints = 50;      // 触发点数
input int MovePoints = 20;         // 移动点数

//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleATR;
double ATRValueBuffer[];

//+------------------------------------------------------------------+

int OnInit()
{

    handleATR = iATR(_Symbol, ATRPeriod, ATRValue);
    ArraySetAsSeries(ATRValueBuffer, true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");
    return INIT_SUCCEEDED;
}

datetime orderTime;

void OnTick()
{
    if (IsTrailing)
        tools.ApplyTrailingStop(TrailingStopPoints, MagicNumber);

    if (PriceProtection)
        tools.ApplyBreakEven(TriggerPoints, MovePoints, MagicNumber);

    if (!tools.IsNewBar(PERIOD_CURRENT))
        return;

    // if (tools.GetPositionCount(MagicNumber) > 0 &&iTime(_Symbol, TimeFrame,3)==orderTime)
    // {
    //     tools.CloseAllPositions(MagicNumber);
    //     orderTime=0;
    // }

    if (tools.GetPositionCount(MagicNumber) > 0)
        return;

    CopyBuffer(handleATR, 0, 1, 1, ATRValueBuffer);
    double sl_tp = ATRValueBuffer[0] * 2 * 100;

    switch (GetTradeSignal())
    {
    case 1:
    {

        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        // double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
        // double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
        double buySl = (StopLoss == 0) ? 0 : ask - sl_tp * _Point;
        double buyTp = (TakeProfit == 0) ? 0 : ask + sl_tp * _Point;

        double lots = (LotType == 1) ? LotSize : tools.CalcLots(ask, buySl, Percent);
        trade.Buy(lots, _Symbol, ask, buySl, buyTp);
        orderTime = iTime(_Symbol, TimeFrame, 1);
        break;
    }
    case -1:
    {

        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        // double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
        // double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;
        double sellSl = (StopLoss == 0) ? 0 : bid + sl_tp * _Point;
        double sellTp = (TakeProfit == 0) ? 0 : bid - sl_tp * _Point;

        double lots = (LotType == 1) ? LotSize : tools.CalcLots(bid, sellSl, Percent);

        trade.Sell(lots, _Symbol, bid, sellSl, sellTp);
        orderTime = iTime(_Symbol, TimeFrame, 1);
        break;
    }
    default:
        break;
    }
}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 EA移除");
}

int GetTradeSignal()
{
    MqlRates rates[];
    CopyRates(_Symbol, TimeFrame, 1, 4, rates);
    CopyBuffer(handleATR, 0, 1, 1, ATRValueBuffer);

    double amplitude = rates[0].high - rates[0].low; // 振幅
    double upperShadow;
    double lowerShadow;
    double shadowSum;

    if (rates[0].close > rates[0].open && rates[1].close > rates[1].open && rates[2].close > rates[2].open) // 阳线
    {
        upperShadow = rates[0].high - rates[0].close; // 上影线
        lowerShadow = rates[0].open - rates[0].low;   // 下影线
    }
    else if (rates[0].close < rates[0].open && rates[1].close < rates[1].open && rates[2].close < rates[2].open) // 阴线
    {
        upperShadow = rates[0].high - rates[0].open; // 上影线
        lowerShadow = rates[0].close - rates[0].low; // 下影线
    }
    else
    {
        return 0; // 无交易信号（十字线或其他情况）
    }

    shadowSum = upperShadow + lowerShadow; // 上下影线总和

    // 检查上下影线总和占振幅的比例是否小于等于 AmplitudeRatio 且振幅大于 ATR
    if (shadowSum / amplitude <= AmplitudeRatio && amplitude > ATRValueBuffer[0])
    {
        if (rates[0].close > rates[0].open)
        {
            return 1; // 多头信号
        }
        else
        {
            return -1; // 空头信号
        }
    }

    return 0; // 无交易信号
}
