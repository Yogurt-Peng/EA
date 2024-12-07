#include <Trade/Trade.mqh>


// 美日 趋势型策略
CTrade trade;
CPositionInfo positionInfo;

input group "基础设置" input int MagicNumber = 8888; // EA唯一编号
input ENUM_TIMEFRAMES TradeTF = PERIOD_CURRENT;      // 信号时间周期
input double Lots = 0.01;                            // 仓位手数
input bool Long = true;         // 多单
input bool Short = true;        // 空单


input group "进场信号" input int CandleSetup = 0; // 进场K线数

input group "止盈止损" input int TakeProfitPoints = 100; // 止盈点数(0=没有止盈)
input int StoplossPoints = 100;                          // 止损点数(0=没有止损)
input int TimeExitHour = 0;                              // 出场时间(-1=没有出场)

input group "价格保护";
input bool PriceProtection = true; // 价格保护
input double BE_Trigger_Points= 100; // 触发点数
input double BE_Move_Points = 0; // 移动点数

int OnInit()
{
    if (TimeExitHour < -1 || TimeExitHour > 23)
    {
        Alert("出场时间错误: TimeExitHour<-1 或者 TimeExitHour>23");
        return INIT_PARAMETERS_INCORRECT;
    }

    trade.SetExpertMagicNumber(MagicNumber);

    return (INIT_SUCCEEDED);
}

void OnTick()
{

    if (!IsNewBar(_Symbol, PERIOD_CURRENT))
        return;

    int cntBuy, cntSell;
    if (!CountOpenPositions(MagicNumber, cntBuy, cntSell))
        return;

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    int signal = Signal();
    if (signal == 2 && cntBuy == 0 && Long) 
    {
        double sl = StoplossPoints == 0 ? 0 : ask - StoplossPoints * _Point;
        double tp = TakeProfitPoints == 0 ? 0 : ask + TakeProfitPoints * _Point;
        trade.Buy(Lots, _Symbol, ask, sl, tp, "BUY");
    }
    else if (signal == 1 && cntSell == 0 && Short)
    {
        double sl = StoplossPoints == 0 ? 0 : bid + StoplossPoints * _Point;
        double tp = TakeProfitPoints == 0 ? 0 : bid - TakeProfitPoints * _Point;
        trade.Sell(Lots, _Symbol, ask, sl, tp, "SELL");
    }

    if (TimeExitHour == -1 || (cntBuy == 0 && cntSell == 0))
        return;

    MqlDateTime currentTime;
    TimeCurrent(currentTime);

    if (currentTime.hour == TimeExitHour && currentTime.min < 5)
    {
        ClosePosition(MagicNumber, POSITION_TYPE_BUY);
        ClosePosition(MagicNumber, POSITION_TYPE_SELL);
    }
}

void OnDeinit(const int reason)
{
    // EA被删除时执行
}

int Signal()
{
    int count = 1;
    while (iClose(_Symbol, TradeTF, count) > iOpen(_Symbol, TradeTF, count) && iClose(_Symbol, TradeTF, count) > iClose(_Symbol, TradeTF, count + 1))
    {
        count++;
    }
    if (count > CandleSetup)
        return 1;

    count = 1;
    while (iClose(_Symbol, TradeTF, count) < iOpen(_Symbol, TradeTF, count) && iClose(_Symbol, TradeTF, count) < iClose(_Symbol, TradeTF, count + 1))
    {
        count++;
    }
    if (count > CandleSetup)
        return 2;

    return 0;
}

bool IsNewBar(string symbol, ENUM_TIMEFRAMES timeframe)
{
    datetime currentBarTime = iTime(symbol, timeframe, 0);
    static datetime prevBarTime = currentBarTime;
    if (prevBarTime < currentBarTime)
    {
        prevBarTime = currentBarTime;
        return true;
    }

    return false;
}

bool CountOpenPositions(long magicNum, int &countBuy, int &countSell)
{
    countBuy = 0;
    countSell = 0;
    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--)
    {
        ulong positionTicket = PositionGetTicket(i);
        if (positionTicket == 0)
            return false;
        if (!PositionSelectByTicket(positionTicket))
            return false;
        long magic;
        if (!PositionGetInteger(POSITION_MAGIC, magic))
            return false;
        if (magic == magicNum)
        {
            long type;
            if (!PositionGetInteger(POSITION_TYPE, type))
                return false;
            if (type == POSITION_TYPE_BUY)
                countBuy++;
            if (type == POSITION_TYPE_SELL)
                countSell++;
        }
    }
    return true;
}

// 平仓所有符合条件的仓位
bool ClosePosition(long magicNum, ENUM_POSITION_TYPE positionType)
{
    int total = PositionsTotal();
    for (int i = total - 1; i >= 0; i--)
    {
        ulong positionTicket = PositionGetTicket(i);
        if (positionTicket == 0)
            return false;
        if (!PositionSelectByTicket(positionTicket))
            return false;
        long magic;
        if (!PositionGetInteger(POSITION_MAGIC, magic))
            return false;
        if (magic == magicNum)
        {
            long type;
            if (!PositionGetInteger(POSITION_TYPE, type))
                return false;
            if (type == POSITION_TYPE_BUY && positionType == POSITION_TYPE_SELL)
                continue;
            if (type == POSITION_TYPE_SELL && positionType == POSITION_TYPE_BUY)
                continue;

            trade.PositionClose(positionTicket);
            if (trade.ResultRetcode() != TRADE_RETCODE_DONE)
            {
                Print(trade.ResultRetcode());
                return false;
            }
        }
    }
    return true;
}

void BEFUN(){

    for(int i=0; i<PositionsTotal(); i++){
        int tick = (int)PositionGetTicket(i);
        int type = (int)PositionGetInteger(POSITION_TYPE);
        int magic = (int)PositionGetInteger(POSITION_MAGIC);

        double Pos_Open = PositionGetDouble(POSITION_PRICE_OPEN), Pos_Curr = PositionGetDouble(POSITION_PRICE_CURRENT);
        double Pos_TP = PositionGetDouble(POSITION_TP), Pos_SL = PositionGetDouble(POSITION_SL);

        double distance = 0;
        if(type == POSITION_TYPE_BUY){
            distance = (Pos_Curr - Pos_Open) / _Point;
            if(distance >= BE_Trigger_Points && Pos_SL < Pos_Open) {
                trade.PositionModify(tick, Pos_Open + BE_Move_Points * Point(), Pos_TP);
            }
        }
        else if(type == POSITION_TYPE_SELL){
            distance = (Pos_Open - Pos_Curr) / _Point;
            if(distance >= BE_Trigger_Points && Pos_SL > Pos_Open) {
                trade.PositionModify(tick, Pos_Open - BE_Move_Points * Point(), Pos_TP);
            }
        }
    }
}