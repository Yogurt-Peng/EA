#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 56712;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 0;                         // 止损点数 0:不使用
input int TakeProfit = 0;                       // 止盈点数 0:不使用

input group "指标参数";
input int RSIValue = 14;      // RSI指标值
input int RSIOverbought = 70; // 超买区
input int RSIOversold = 30;   // 超卖区
input int BBValue = 20;       // Bollinger Bands指标值
input int BBDeviation = 2;    // Bollinger Bands指标值

input group "过滤参数";
input bool MAFilter = true;                     // 是否使用MA过滤
input bool IsReverse = true;                   // 是否反向过滤条件
input ENUM_TIMEFRAMES MAFilterTF = PERIOD_M15;   // 过滤MA带周期
input int MAFilterValue = 80;                   // MA指标值
input ENUM_MA_METHOD MAFilterMethod = MODE_SMA; // 过滤MA指标类型

//+------------------------------------------------------------------+


CTrade trade;
CTools tools(_Symbol, &trade);


int handleRSI;
int handleBB;
int handleMA;

double bufferRSIValue[];
double bufferBBValue[];
double bufferMAValue[];

//+------------------------------------------------------------------+

int OnInit()
{
    Print("🚀🚀🚀 SuperRSITrade初始化中...");

    handleRSI = iRSI(_Symbol, TimeFrame, RSIValue, PRICE_CLOSE);
    handleBB = iBands(_Symbol, TimeFrame, BBValue, 0, BBDeviation, PRICE_CLOSE);
    handleMA = iMA(_Symbol, MAFilterTF, MAFilterValue, 0, MAFilterMethod, PRICE_CLOSE);
    ChartIndicatorAdd(0,1,handleRSI);
    ChartIndicatorAdd(0,0,handleBB);
    ChartIndicatorAdd(0,0,handleMA);

    if (handleRSI == INVALID_HANDLE || handleBB == INVALID_HANDLE || handleMA == INVALID_HANDLE)
    {
        Print("🚀🚀🚀 SuperRSITrade指标初始化失败");
        return INIT_FAILED;
    }

    ArraySetAsSeries(bufferRSIValue, true);
    ArraySetAsSeries(bufferBBValue, true);
    ArraySetAsSeries(bufferMAValue, true);
    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 SuperRSITrade初始化成功");
    return INIT_SUCCEEDED;
}

void OnTick()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double yesterdayClose = iClose(_Symbol, MAFilterTF, 1);

    double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
    double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;




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

    bool buyCondition = false;
    bool sellCondition = false;

    if (MAFilter)
    {
        CopyBuffer(handleMA, 0, 1, 1, bufferMAValue);
        if (IsReverse)
        {
            buyCondition = yesterdayClose < bufferMAValue[0] && GetSign() == BUY;
            sellCondition = yesterdayClose > bufferMAValue[0] && GetSign() == SELL;
        }
        else
        {
            buyCondition = yesterdayClose > bufferMAValue[0] && GetSign() == BUY;
            sellCondition = yesterdayClose < bufferMAValue[0] && GetSign() == SELL;
        }
    }
    else
    {
        buyCondition = GetSign() == BUY;
        sellCondition = GetSign() == SELL;
    }

    if (buyCondition)
    {
        trade.Buy(LotSize, _Symbol, ask, buySl, buyTp, "SuperRSITrend");
    }
    else if (sellCondition)
    {
        trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp, "SuperRSITrend");
    }
}

void OnDeinit(const int reason)
{
    IndicatorRelease(handleRSI);
    IndicatorRelease(handleBB);
    IndicatorRelease(handleMA);
    Print("🚀🚀🚀 SuperRSITrade移除");
}

SIGN GetSign()
{
    CopyBuffer(handleRSI, 0, 1, 2, bufferRSIValue);

    if (bufferRSIValue[1] > RSIOverbought && bufferRSIValue[0] < RSIOverbought)
        return SELL;

    else if (bufferRSIValue[1] < RSIOversold && bufferRSIValue[0] > RSIOversold)
        return BUY;

    return NONE;
}
