#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

// 基本参数
input group "基本参数";
input int MagicNumber = 555245;                   // EA编号 (专家交易系统编号)
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 交易周期
input double LotSize = 0.01;                      // 交易手数
input int GridNumber = 4;                         // 网格数量
input int GridDistance = 100;                     // 网格间距（以点数为单位）

input group "指标参数";
input int RSIValue = 14;      // RSI指标值
input int MFIValue = 14;      // MFI指标值
input int RSIOverbought = 70; // 超买区
input int RSIOversold = 30;   // 超卖区
input bool IsTimeFilter = true; // 是否启用时间过滤
input int StopTime = 12;     // 止损休息时间

// 声明交易和工具对象
CTrade trade;
CTools tools(_Symbol, &trade);
CDraw draw;
// CRSI rsi(_Symbol, TimeFrame, RSIValue);
CMFI mfi(_Symbol, TimeFrame, MFIValue);

// 跟踪基础价格和当前网格层级的变量
int currentGridLevel = 0; // 当前网格层级
SIGN currentMode = NONE;  // 当前模式（0：等待买入，1：等待卖出）
double basePrice = 0;     // 基础价格

// 初始化策略的函数
int OnInit()
{
    // rsi.Initialize();
    mfi.Initialize();
    trade.SetExpertMagicNumber(MagicNumber); // 设置交易的MagicNumber
    // 将初始基准价格设为当前买价

    // ChartIndicatorAdd(0, 1, rsi.GetHandle());
    ChartIndicatorAdd(0, 1, mfi.GetHandle());
    return (INIT_SUCCEEDED);
}

int loopBars = 0;

// 每个行情更新时调用的函数


datetime timeStop = 0;

void OnTick()
{

    if(timeStop > TimeCurrent() &&IsTimeFilter)
        return;

    // 检查是否在指定时间周期内生成了新K线
    if (!tools.IsNewBar(PERIOD_M1))
        return;

    datetime currentTime = TimeCurrent();
    MqlDateTime currentTimeStruct;
    TimeToStruct(currentTime, currentTimeStruct);

    if (currentTimeStruct.day == 5 && currentTimeStruct.hour >= 22)
    {
        if (tools.CloseAllPositions(MagicNumber) && tools.DeleteAllOrders(MagicNumber))
        {
            basePrice = 0;
            currentMode = NONE;
        }
        return;
    }

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    switch (tools.GetPositionCount(MagicNumber))
    {
    case 1:
    {
        if (tools.GetTotalProfit(MagicNumber) * 100.0 > GridDistance)
        {
            if (tools.CloseAllPositions(MagicNumber) && tools.DeleteAllOrders(MagicNumber))
            {
                basePrice = 0;
                currentMode = NONE;
            }
        }
        break;
    }
    case 2:
    {
        if (tools.GetTotalProfit(MagicNumber) * 100.0 > GridDistance)
        {
            if (tools.CloseAllPositions(MagicNumber) && tools.DeleteAllOrders(MagicNumber))
            {
                basePrice = 0;
                currentMode = NONE;
            }
        }
        break;
    }
    case 3:
    {
        if (currentMode == SELL)
        {
            if (bid > basePrice + (GridNumber)*GridDistance * _Point)
            {
                if (tools.CloseAllPositions(MagicNumber) && tools.DeleteAllOrders(MagicNumber))
                {
                    basePrice = 0;
                    currentMode = NONE;
                    timeStop = TimeCurrent() + StopTime * 3600; // 设置新的止损休息时间
                }
            }
        }
        else if (currentMode == BUY)
        {
            if (ask < basePrice - (GridNumber)*GridDistance * _Point)
            {
                if (tools.CloseAllPositions(MagicNumber) && tools.DeleteAllOrders(MagicNumber))
                {
                    basePrice = 0;
                    currentMode = NONE;
                    timeStop = TimeCurrent() + StopTime * 3600; // 设置新的止损休息时间
                }
            }
        }

        if (tools.GetTotalProfit(MagicNumber) * 100.0 > 0)
        {
            tools.CloseAllPositions(MagicNumber);
            tools.DeleteAllOrders(MagicNumber);

            basePrice = 0;
            currentMode = NONE;
        }
        break;
    }
    default:
        break;
    }

    SIGN rsiSign = GetSign();
    if (rsiSign == BUY && currentMode == NONE &&tools.GetPositionCount(MagicNumber) ==0)
    {
        trade.Buy(LotSize,_Symbol,0,0,0,"初始买单");

        basePrice = ask;
    }
    else if (rsiSign == SELL && currentMode == NONE&&tools.GetPositionCount(MagicNumber) ==0)
    {
        trade.Sell(LotSize,_Symbol,0,0,0,"初始卖单");

        basePrice = bid;
    }

    if (tools.GetPositionCount(MagicNumber) == 1 && currentMode == NONE && basePrice != 0)
    {
        for (int i = 0; i < GridNumber - 1; i++)
        {
            if (rsiSign == BUY)
                trade.BuyLimit(LotSize, basePrice - (i + 1) * GridDistance * _Point, _Symbol);

            else if (rsiSign == SELL)
                trade.SellLimit(LotSize, basePrice + (i + 1) * GridDistance * _Point, _Symbol);
        }
        currentMode = rsiSign;
    }
}
// SIGN GetSign()
// {

//     if (rsi.GetValue(2) > RSIOverbought && rsi.GetValue(1) < RSIOverbought)
//         return SELL;

//     else if (rsi.GetValue(2) < RSIOversold && rsi.GetValue(1) > RSIOversold)
//         return BUY;

//     return NONE;
// }

SIGN GetSign()
{

    if (mfi.GetValue(2) > 80 && mfi.GetValue(1) < 80)
        return SELL;

    else if (mfi.GetValue(2) < 20 && mfi.GetValue(1) > 20)
        return BUY;

    return NONE;
}
