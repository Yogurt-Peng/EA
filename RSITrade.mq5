#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 52422;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 0;                           // 止损点数 0:不使用
input int TakeProfit = 0;                         // 止盈点数 0:不使用

input group "过滤参数";
input bool MAFilter = true;                     // 是否使用MA过滤
input bool IsReverse = true;                    // 是否反向过滤条件
input ENUM_TIMEFRAMES MAFilterTF = PERIOD_M15;  // 过滤MA带周期
input int MAFilterValue = 80;                   // MA指标值
input ENUM_MA_METHOD MAFilterMethod = MODE_SMA; // 过滤MA指标类型

CTrade trade;
CTools tools(_Symbol, &trade);

CRSI rsi(_Symbol, TimeFrame, 14);
CBollingerBands bollinger(_Symbol, TimeFrame, 20, 2);
CMA ma(_Symbol, MAFilterTF, MAFilterValue, MAFilterMethod);


int OnInit()
{
    Print("🚀🚀🚀 RSITrade初始化中...");
    rsi.Initialize();
    bollinger.Initialize();
    ma.Initialize();

    ChartIndicatorAdd(0,1,rsi.GetHandle());
    ChartIndicatorAdd(0,0,bollinger.GetHandle());
    ChartIndicatorAdd(0,0,ma.GetHandle());

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 RSITrade初始化成功");
    return INIT_SUCCEEDED;
}


void OnTick()
{
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double Close = iClose(_Symbol, MAFilterTF, 1);

    double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
    double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;

    if (tools.GetPositionCount(MagicNumber) > 0)
    {

        if (ask >= bollinger.GetValue(1,1))
        {
            tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY);
        }
        if (bid <= bollinger.GetValue(2,1))
        {
            tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL);
        }
        return;
    }


    if (!tools.IsNewBar(TimeFrame))
        return;


}