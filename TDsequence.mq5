#include "Tools.mqh"

input group "基本参数";
input int MagicNumber = 4753;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // NRNumber周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 0;                           // 止损点数 0:不使用
input int TakeProfit = 0;                         // 止盈点数 0:不使用
input int Setup = 3;                              // 连续k线
input int Countdown = 1;                          // 比较k线数量
input bool IsExitByProfit = true;                 // 是否盈利平仓

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
    if (!tools.IsNewBar(PERIOD_M1))
        return;

    if(IsExitByProfit) ExitByProfit();



    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
    double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;

    SIGN sign = GetSign();
    if (sign == BUY && tools.GetPositionCount(MagicNumber,POSITION_TYPE_BUY) == 0)
    {
        tools.CloseAllPositions(MagicNumber,POSITION_TYPE_SELL);
        trade.Buy(LotSize, _Symbol, ask);
    }
    else if (sign == SELL && tools.GetPositionCount(MagicNumber,POSITION_TYPE_SELL) == 0)
    {
        tools.CloseAllPositions(MagicNumber,POSITION_TYPE_BUY);
        trade.Sell(LotSize, _Symbol, bid);
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

// 开盘判断，盈利时候平仓
#include <Arrays/ArrayInt.mqh>
CArrayInt closePositionArray;
void ExitByProfit(){
    if(IsNewBar(TimeFrame)){
        for(int i=PositionsTotal()-1; i>=0; i--){
            int positionTicket = (int)PositionGetTicket(i);
            PositionSelectByTicket(positionTicket);
            if(PositionGetInteger(POSITION_MAGIC)==MagicNumber){
                if(PositionGetDouble(POSITION_PROFIT)>0) {
                    trade.PositionClose(positionTicket);
                    if(trade.ResultRetcode()!=TRADE_RETCODE_DONE) {
                        closePositionArray.Add(positionTicket);
                    }
                }
            }
        }
    }

// 一分钟执行一次
if(closePositionArray.Total()==0) return;
for(int i=0;i<closePositionArray.Total();i++){
    int ticket = closePositionArray.At(i);
    trade.PositionClose(ticket);
    if(trade.ResultRetcode()==TRADE_RETCODE_DONE) {
        closePositionArray.Delete(i);
    }
}
}

bool IsNewBar(ENUM_TIMEFRAMES timeframe)
{
    static datetime m_prevBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, timeframe, 0);
    if (m_prevBarTime < currentBarTime)
    {
        m_prevBarTime = currentBarTime;
        return true;
    }
    return false;
}