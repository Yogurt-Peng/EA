#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 1756;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 600;                         // 止损点数 0:不使用
input int TakeProfit = 200;                       // 止盈点数 0:不使用
input int RSIPeroid = 14;                         // RSI值
input double Overbought = 70;                     // 超买区
input double Oversold = 30;                       // 超卖区

input bool IsFilter = true;                        // 是否使用布林带过滤
input ENUM_TIMEFRAMES TimeFrameFilter = PERIOD_H4; // 过滤布林带周期
input bool IsRevers = true;                        // 反转过滤条件

input bool Long = true;  // 多单
input bool Short = true; // 空单

//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleRSI;
int handleBB;
int handleBBFilter;
int handleATR;
double bufferRSIValue[];
double bufferBBValue[];
double bufferATRValue[];
double bufferBBFilterValue[];

//+------------------------------------------------------------------+

int OnInit()
{

    handleRSI = iRSI(_Symbol, TimeFrame, RSIPeroid, PRICE_CLOSE);
    handleBB = iBands(_Symbol, TimeFrame, 20, 0, 2, PRICE_CLOSE);
    handleBBFilter = iBands(_Symbol, TimeFrameFilter, 20, 0, 2, PRICE_CLOSE);
    // handleEMA = iMA(_Symbol, EMAPeriod, EMAValue, 0, MODE_EMA, PRICE_CLOSE);
    handleATR = iATR(_Symbol, PERIOD_H1, 14);
    ArraySetAsSeries(bufferRSIValue, true);
    ArraySetAsSeries(bufferBBValue, true);
    ArraySetAsSeries(bufferATRValue, true);
    ArraySetAsSeries(bufferBBFilterValue, true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");

    return INIT_SUCCEEDED;
}

void OnTick()
{

    if (tools.GetPositionCount(MagicNumber) > 0)
    {
        CopyBuffer(handleBB, 1, 0, 1, bufferBBValue);
        if (SymbolInfoDouble(_Symbol, SYMBOL_ASK) >= bufferBBValue[0])
        {
            tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY);
        }
        CopyBuffer(handleBB, 2, 0, 1, bufferBBValue);
        if (SymbolInfoDouble(_Symbol, SYMBOL_BID) <= bufferBBValue[0])
        {
            tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL);
        }

        return;
    }

    if (!tools.IsNewBar(TimeFrame))
        return;

    CopyBuffer(handleATR, 0, 0, 1, bufferATRValue);

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double diancha = (ask - bid) * _Point;


    double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
    double buyTp = ask + TakeProfit * _Point;
    // buySl=iLow(_Symbol, TimeFrame, iLowest(_Symbol, TimeFrame, MODE_LOW,5));

    double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
    double sellTp = bid - TakeProfit * _Point;
    // sellSl= iHigh(_Symbol, TimeFrame, iHighest(_Symbol, TimeFrame,  MODE_HIGH,5));

    double high = iHigh(_Symbol, TimeFrame, 1);
    double low = iLow(_Symbol, TimeFrame, 1);
    double Amplitude = high - low;

    double yesterdayClose = iClose(_Symbol, PERIOD_D1, 1);

    CopyBuffer(handleBBFilter, 0, 1, 1, bufferBBFilterValue);
    bool buySign = false;
    bool sellSign = false;

    if (IsFilter)
    {
        if (IsRevers)
        {
            buySign = Long && (yesterdayClose < bufferBBFilterValue[0]);
            sellSign = Short && (yesterdayClose > bufferBBFilterValue[0]);
        }
        else
        {
            buySign = Long && (yesterdayClose > bufferBBFilterValue[0]);
            sellSign = Short && (yesterdayClose < bufferBBFilterValue[0]);
        }
    }
    else
    {
        buySign = Long;
        sellSign = Short;
    }

    switch (RSISign())
    {
    case BUY:
    {

        if (buySign)
            trade.Buy(LotSize, _Symbol, ask, buySl, 0, "RSITrend");
        break;
    };
    case SELL:
    {
        if (sellSign)
            trade.Sell(LotSize, _Symbol, bid, sellSl, 0, "RSITrend");
        break;
    };
    default:
        break;
    }
}

SIGN RSISign()
{
    CopyBuffer(handleRSI, 0, 1, 2, bufferRSIValue);

    if (bufferRSIValue[1] > Overbought && bufferRSIValue[0] < Overbought)
        return SELL;

    else if (bufferRSIValue[1] < Oversold && bufferRSIValue[0] > Oversold)
        return BUY;

    return NONE;
}
void OnDeinit(const int reason)
{
    IndicatorRelease(handleRSI);
    IndicatorRelease(handleBB);
    IndicatorRelease(handleBBFilter);
    Print("🚀🚀🚀 SuperRSITrade移除");
}
