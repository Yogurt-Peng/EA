#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 1756;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 200;                         // 止损点数 0:不使用
input int TakeProfit = 200;                       // 止盈点数 0:不使用
input int RSIPeroid = 14;                         // RSI值
input double Overbought = 70;                     // 超买区
input double Oversold = 30;                       // 超卖区

//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleRSI;
int handleBB;
double bufferRSIValue[];
double bufferBBValue[];

//+------------------------------------------------------------------+

int OnInit()
{

    handleRSI = iRSI(_Symbol, TimeFrame, RSIPeroid, PRICE_CLOSE);
    handleBB = iBands(_Symbol, TimeFrame, 20, 0, 2, PRICE_CLOSE);
    ArraySetAsSeries(bufferRSIValue, true);
    ArraySetAsSeries(bufferBBValue, true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");

    return INIT_SUCCEEDED;
}

void OnTick()
{

    if (tools.GetPositionCount(MagicNumber) > 0)
    {
        CopyBuffer(handleBB, 0, 0, 1, bufferBBValue);
        if(SymbolInfoDouble(_Symbol, SYMBOL_ASK)>=bufferBBValue[0])
        {
            tools.CloseAllPositions(MagicNumber,POSITION_TYPE_BUY);
        }
        else if(SymbolInfoDouble(_Symbol, SYMBOL_BID)<=bufferBBValue[0])
        {
            tools.CloseAllPositions(MagicNumber,POSITION_TYPE_SELL);
        }

        return;
    }

    if (!tools.IsNewBar(TimeFrame))
        return;


    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double buySl = ask - StopLoss * _Point;
    double buyTp = ask + TakeProfit * _Point;

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sellSl = bid + StopLoss * _Point;
    double sellTp = bid - TakeProfit * _Point;

    switch (RSISign())
    {
    case BUY:
    {
        // if(EMAFilter() == SELL)
        trade.Buy(LotSize, _Symbol, ask, buySl);
        break;
    };
    case SELL:
    {
        // if(EMAFilter() == BUY)
        trade.Sell(LotSize, _Symbol, bid, sellSl);
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
