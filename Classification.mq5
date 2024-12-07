// 过滤条件多了交易笔数很少，无法取得概率优势

#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 8885;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 100;                       // 止盈点数 0:不使用

input group "过滤参数";
input bool UseFilter = true;                          // 是否使用过滤
input int FastEMAValue = 9;                           // FastEMA
input ENUM_TIMEFRAMES FastEMAPeriod = PERIOD_CURRENT; // FastEMA周期
input int ATRValue = 14;                              // ATR
input ENUM_TIMEFRAMES ATRPeriod = PERIOD_CURRENT;     // ATR周期
input int RSIValue = 14;                              // RSI
input ENUM_TIMEFRAMES RSIPeriod = PERIOD_CURRENT; // RSI周期

//+------------------------------------------------------------------+



int handleFastEMA;
double FastEMAValueBuffer[];

int handleATR;
double bufferATRValue[];

int handleRSI;
double RSIValueBuffer[];

int handleWPR; // 威廉姆斯指标
double bufferWPRValue[];


CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int OnInit()
{
    handleFastEMA = iMA(_Symbol, FastEMAPeriod, FastEMAValue, 0, MODE_EMA, PRICE_CLOSE);
    handleATR = iATR(_Symbol, ATRPeriod, ATRValue);
    // handleRSI = iRSI(_Symbol, RSIPeriod, RSIValue, PRICE_CLOSE);
    handleWPR = iWPR(_Symbol, TimeFrame, 14);

    trade.SetExpertMagicNumber(MagicNumber);
    ArraySetAsSeries(FastEMAValueBuffer, true);
    ArraySetAsSeries(bufferWPRValue, true);
    ArraySetAsSeries(bufferATRValue, true);
    ArraySetAsSeries(RSIValueBuffer, true);
    Print("🚀🚀🚀 初始化成功");

    return INIT_SUCCEEDED;
}


datetime orderTime;

void OnTick()
{
    
    if (!tools.IsNewBar(PERIOD_CURRENT))
        return;


    if (tools.GetPositionCount(MagicNumber) > 0)return;

    // if (tools.GetPositionCount(MagicNumber) > 0 &&iTime(_Symbol, TimeFrame,3)==orderTime)
    // {
    //     tools.CloseAllPositions(MagicNumber,POSITION_TYPE_BUY);
    //     tools.CloseAllPositions(MagicNumber,POSITION_TYPE_SELL);
    //     orderTime=0;
    // }

    SIGN sign = IsClassification();

    CopyBuffer(handleATR, 0, 1, 1, bufferATRValue);
    double Sl_Tp = bufferATRValue[0] * 3 * 1000;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double buySl = (StopLoss == 0) ? ask - Sl_Tp * _Point: ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ?ask + Sl_Tp * _Point: ask + TakeProfit * _Point;

    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double sellSl = (StopLoss == 0) ? bid + Sl_Tp * _Point: bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? bid - Sl_Tp * _Point: bid - TakeProfit * _Point;

    if (sign == BUY)
    {
        trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);
        orderTime=iTime(_Symbol, TimeFrame,1);

    }
    else if (sign == SELL)
    {
        trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
        orderTime=iTime(_Symbol, TimeFrame,1);

    }
}
void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 EA移除");
}


SIGN IsClassification()
{

    CopyBuffer(handleWPR, 0, 1, 3, bufferWPRValue);

    if(IsTopClassification()&&(bufferWPRValue[2]>-20|| bufferWPRValue[1]>-20))
    {
        return SELL;

    }else if(IsBottomClassification()&&(bufferWPRValue[2]<-80|| bufferWPRValue[1]<-80))
    {
        return BUY;
    }

    return NONE;
};

bool IsTopClassification()
{
    MqlRates rates[];
    CopyRates(_Symbol, TimeFrame, 1, 3, rates);
    CopyBuffer(handleATR, 0, 1, 3, bufferATRValue);

    ArraySetAsSeries(rates, true);

    // 振幅都要大于ATR
    if(rates[0].high-rates[0].low<bufferATRValue[0])return false;
    if(rates[2].high-rates[2].low<bufferATRValue[2])return false;

    // 左阳右阴
    if(tools.IsUpBar(rates[0]))return false;
    if(!tools.IsUpBar(rates[2]))return false;

    // 实体要占振幅的1/2以上。
    if ((rates[0].open - rates[0].close) / (rates[0].high - rates[0].low) < 0.5)return false;
    if ((rates[2].close - rates[2].open) / (rates[2].high - rates[2].low) < 0.5)return false;

    // 中间k线高点最高，低点最高
    if(rates[1].high>rates[2].high && rates[1].high>rates[0].high && rates[1].low>rates[2].low && rates[1].low>rates[0].low)
    {
        return true;
    }

    return false;
}

bool IsBottomClassification()
{
    MqlRates rates[];
    CopyRates(_Symbol, TimeFrame, 1, 3, rates);
    CopyBuffer(handleATR, 0, 1, 3, bufferATRValue);
    ArraySetAsSeries(rates, true);

    // 振幅都要大于ATR
    if(rates[0].high-rates[0].low<bufferATRValue[0])return false;
    if(rates[2].high-rates[2].low<bufferATRValue[2])return false;

    // 左阳右阴
    if(!tools.IsUpBar(rates[0]))return false;
    if(tools.IsUpBar(rates[2]))return false;

    // 实体要占振幅的1/2以上。
    if ((rates[0].close - rates[0].open) / (rates[0].high - rates[0].low) < 0.5)return false;
    if ((rates[2].open - rates[2].close) / (rates[2].high - rates[2].low) < 0.5)return false;

    // 中间k线高点最低，低点最低
    if(rates[1].high<rates[2].high && rates[1].high<rates[0].high && rates[1].low<rates[2].low && rates[1].low<rates[0].low)
    {
        return true;
    }

    return false;
}