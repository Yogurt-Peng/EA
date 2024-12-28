#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

input group "基本参数";
input int MagicNumber = 52424;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 0;                           // 止损点数 0:不使用
input int TakeProfit = 0;                         // 止盈点数 0:不使用

input group "指标参数";
input int RSIValue = 20;      // RSI指标值
input int RSIOverbought = 70; // 超买区
input int RSIOversold = 30;   // 超卖区
input int EMAValue30;

CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);

CRSI rsi(_Symbol, TimeFrame, RSIValue);
CMA ma(_Symbol, TimeFrame, EMAValue30, MODE_EMA);

bool IsClosePosition = true; // 是否成功平仓

int OnInit()
{
    Print("🚀🚀🚀 策略初始化中...");
    rsi.Initialize();
    ma.Initialize();
    EventSetTimer(5); // 设置定时器，每30秒执行一次OnTimer函数

    ChartIndicatorAdd(0, 1, rsi.GetHandle());
    ChartIndicatorAdd(0, 0, ma.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    return INIT_SUCCEEDED;
}

void OnTick()
{
    if (!tools.IsNewBar(TimeFrame))
        return;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double close = iClose(_Symbol, TimeFrame, 1);
    double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
    double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;
    SIGN sign = GetSign();
    SIGN exitSign = GetExitSign();
    int positionCount = tools.GetPositionCount(MagicNumber);

    if (positionCount > 0 && sign == SELL)
    {

        IsClosePosition = tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY) ? true : false;
        Sleep(100);
    }
    else if (positionCount > 0 && sign == BUY)
    {

        IsClosePosition = tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL) ? true : false;
        Sleep(100);
    }

    if (IsClosePosition && tools.GetPositionCount(MagicNumber) == 0)
    {
        if (sign == BUY)
        {
            trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);
        }
        else if (sign == SELL)
            trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
    }
};



void OnTimer()
{
    if (!IsClosePosition)
    {
        Print("🚀🚀🚀 平仓失败处理...");
        if (tools.CloseAllPositions(MagicNumber))
        {
            IsClosePosition = true;
            Print("🚀🚀🚀 平仓成功");
        }
        else
            IsClosePosition = false;
    }
}
void OnDeinit(const int reason)
{
    EventKillTimer();
    IndicatorRelease(rsi.GetHandle());
    IndicatorRelease(ma.GetHandle());
    Print("🚀🚀🚀 策略已关闭");
}

SIGN GetExitSign()
{

    if (rsi.GetValue(2) > RSIOverbought && rsi.GetValue(1) < RSIOverbought)
        return SELL;

    else if (rsi.GetValue(2) < RSIOversold && rsi.GetValue(1) > RSIOversold)
        return BUY;

    return NONE;
}

SIGN GetSign()
{

    if (rsi.GetValue(2) < RSIOverbought && rsi.GetValue(1) > RSIOverbought)

        return SELL;

    else if (rsi.GetValue(2) > RSIOversold && rsi.GetValue(1) < RSIOversold)
        return BUY;

    return NONE;
}