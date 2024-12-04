#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 8885;                // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // NRNumber周期
input int LotType = 1;                       // 1:固定手数,2:固定百分比
input double LotSize = 0.01;                 // 手数
input double Percent = 1;                    // 百分比 1%
input int StopLoss = 100;                    // 止损点数 0:不使用
input int TakeProfit = 100;                  // 止盈点数 0:不使用

input group "过滤参数";
input bool UseFilter = true;                     // 是否使用过滤
input int FastEMAValue = 9;                      // FastEMA
input ENUM_TIMEFRAMES FastEMAPeriod = PERIOD_CURRENT; // FastEMA周期
input int ATRValue = 14;                         // ATR
input ENUM_TIMEFRAMES ATRPeriod = PERIOD_CURRENT;     // ATR周期

//+------------------------------------------------------------------+

int handleFastEMA;
double FastEMAValueBuffer[];

int handleATR;
double ATRValueBuffer[];

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int OnInit()
{
    handleFastEMA = iMA(_Symbol, FastEMAPeriod, FastEMAValue, 0, MODE_EMA, PRICE_CLOSE);
    handleATR = iATR(_Symbol, ATRPeriod, ATRValue);

    trade.SetExpertMagicNumber(MagicNumber);
    ArraySetAsSeries(FastEMAValueBuffer, true);
    Print("🚀🚀🚀 初始化成功");

    return INIT_SUCCEEDED;
}

void OnTick()
{

    if (!tools.IsNewBar(PERIOD_CURRENT))
        return;


    if (tools.GetPositionCount(MagicNumber) > 0)
    {
        tools.CloseAllPositions(MagicNumber);
    }

    SIGN sign = IsClassification();

    if (sign == BUY)
    {
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
        double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
        trade.Buy(LotSize, _Symbol, ask);

        // double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        // double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
        // double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;
        // trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);

    }
    else if (sign == SELL)
    {
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

        double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
        double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;
        trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
    }
}
void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 EA移除");
}

enum SIGN
{
    BUY,
    SELL,
    NONE
};

SIGN IsClassification()
{
    MqlRates rates[];
    CopyRates(_Symbol, TimeFrame, 1, 3, rates);
    ArraySetAsSeries(rates, true);

    CopyBuffer(handleATR, 0, 1, 1, ATRValueBuffer);
    CopyBuffer(handleFastEMA, 0, 1, 1, FastEMAValueBuffer);


    // 第一根线为阴线的实体要占振幅的1/2 振幅大于ATR
    if (rates[2].open < rates[2].close)
        return NONE;
    if ((rates[2].open - rates[2].close) / (rates[2].high - rates[2].low) < 0.5)
        return NONE;
    if (rates[2].high - rates[2].low <= ATRValueBuffer[0])
        return NONE;

    // 最低价要低于第一根线的最低价 ，最高价小于第一  下
    if (rates[1].low >= rates[2].low)
        return NONE;

    if (rates[1].high >= rates[2].high)
        return NONE;

    // 第三根线为阳线，实体要占振幅的1/2，振幅大于ATR
    if (rates[0].open > rates[0].close)
        return NONE;
    if ((rates[0].close - rates[0].open) / (rates[0].high - rates[0].low) < 0.5)
        return NONE;
    if (rates[0].high - rates[0].low <= ATRValueBuffer[0])
        return NONE;

    // 均线下方  1:收盘价小于均线 2:最高价小于均线 3:收盘价小于均线  || rates[0].close >= FastEMAValueBuffer[0]
    if(rates[2].close >= FastEMAValueBuffer[0] || rates[1].high>= FastEMAValueBuffer[0] )
        return NONE;

    return BUY;
};