// 震荡型策略，威廉姆斯指标,一比一无法取得概率优势
#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 4585;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用


input group "价格保护";
input bool PriceProtection = true; // 是否启用价格保护
input int TriggerPoints = 50;      // 触发点数
input int MovePoints = 20;         // 移动点数


input group "过滤参数";
input bool UseFilter = true; // 是否使用过滤
input int EMAValue = 200;    // FastEMA

//+------------------------------------------------------------------+

int handleATR;
int handleEMA;
int handleWPR; // 威廉姆斯指标
double bufferATRValue[];
double bufferWPRValue[];
double bufferEMAValue[];

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade);


//+------------------------------------------------------------------+

int OnInit()
{

    handleATR = iATR(_Symbol, TimeFrame, 14);
    handleWPR = iWPR(_Symbol, TimeFrame, 14);
    handleEMA = iMA(_Symbol, TimeFrame, EMAValue, 0, MODE_EMA, PRICE_CLOSE);

    ArraySetAsSeries(bufferATRValue, true);
    ArraySetAsSeries(bufferWPRValue, true);
    ArraySetAsSeries(bufferEMAValue, true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功, 策略已启动");

    return INIT_SUCCEEDED;
}

void OnTick()
{

    if (PriceProtection)
        tools.ApplyBreakEven(TriggerPoints, MovePoints, MagicNumber);

    if (!tools.IsNewBar(TimeFrame))
        return;

    if (tools.GetPositionCount(MagicNumber) > 0)
        return;

    CopyBuffer(handleATR, 0, 1, 1, bufferATRValue);
    double Sl_Tp = bufferATRValue[0] * 3 * 1000;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double buySl = (StopLoss == 0) ? ask - Sl_Tp * _Point: ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ?ask + Sl_Tp * _Point: ask + TakeProfit * _Point;

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sellSl = (StopLoss == 0) ? bid + Sl_Tp * _Point: bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? bid - Sl_Tp * _Point: bid - TakeProfit * _Point;

    switch (GetSignal())
    {
    case BUY:
    {   
        // if(EMAFilter() == SELL)
            trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);
        break;
    };
    case SELL:
    {
        // if(EMAFilter() == BUY)
            trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
        break;
    };
    default:
        break;
    }

    
}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 策略已停止");
}

SIGN GetSignal()
{
    CopyBuffer(handleWPR, 0, 1, 2, bufferWPRValue);
    if (bufferWPRValue[1] < -80 && bufferWPRValue[0] > -80)
    {
        return BUY;
    }

    if (bufferWPRValue[1] > -20 && bufferWPRValue[0] < -20)
    {
        return SELL;
    }

    return NONE;
}

SIGN EMAFilter()
{

    CopyBuffer(handleEMA, 0, 1, 1, bufferEMAValue);

    double close = iClose(_Symbol, TimeFrame, 1);
    if (close > bufferEMAValue[0])
        return BUY;

    if (close < bufferEMAValue[0])
        return SELL;

    return NONE;
}