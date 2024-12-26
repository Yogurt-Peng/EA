#include "Tools.mqh"

input group "基本参数";
input int MagicNumber = 4753;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // NRNumber周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 0;                           // 止损点数 0:不使用
input int TakeProfit = 0;                         // 止盈点数 0:不使用
input int Setup = 3;                              // 连续k线
input int Countdown = 1;                          // 比较k线数量

CTrade trade;
CTools tools(_Symbol, &trade);

int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);

    Print("🚀🚀🚀 初始化成功");
    return INIT_SUCCEEDED;
}

void OnTick()
{
    if (!tools.IsNewBar(TimeFrame))
        return;

    if (!tools.GetPositionCount(MagicNumber) == 0)
        return;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
    double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;

    SIGN sign = GetSign();
    if (sign == BUY)
    {
        trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);
    }
    else if (sign == SELL)
    {
        trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
    }
}

SIGN GetSign()
{
    int count = 1;
    while (iClose(_Symbol, TimeFrame, count) > iClose(_Symbol, TimeFrame, count + Countdown))
    {
        count++;
    }
    if (count > Setup)
        return BUY;

    count = 1;
    while (iClose(_Symbol, TimeFrame, count) < iClose(_Symbol, TimeFrame, count + Countdown))
    {
        count++;
    }
    if (count > Setup)
        return SELL;

    return NONE;
}
