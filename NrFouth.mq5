
#include <Trade/Trade.mqh>

// 趋势形策略

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;

input group "基本参数";
input int MagicNumber = 1001;   // 魔术号
input int NarrowRangeCount = 8; // NRC
input double Lots = 0.01;       // 交易手数
input int StopLoss = 160;    // 止损点数
input int TakeProfit = 220;  // 止盈点数
input bool Long = true;         // 多单
input bool Short = true;        // 空单

input group "过滤参数" input bool Filter = true; // 是否过滤
input ENUM_TIMEFRAMES EMAPeriod = PERIOD_H4;     // EMA周期
input int EMAValue = 100;                        // EMA值

input group "价格保护";
input bool PriceProtection = true; // 价格保护
input int BE_Trigger_Points= 50; // 触发点数
input int BE_Move_Points = 0; // 移动点数



int handleEMA;

double EMABuffer[];

int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    handleEMA = iMA(_Symbol, EMAPeriod, EMAValue, 0, MODE_EMA, PRICE_CLOSE);

    return INIT_SUCCEEDED;
};

void OnTick()
{

    if (!IsNewBar(_Symbol, PERIOD_CURRENT))
        return;

    CopyBuffer(handleEMA, 0, 0, 1, EMABuffer);

    int single = IsNr4();
    if (single == 1 && PositionsTotal() ==0)
    {
        closeAllPositions(_Symbol, MagicNumber);
        double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
        double low = iLow(_Symbol, PERIOD_CURRENT, 1);

        // 过期时间是下一根K线
        datetime expiration = iTime(_Symbol, PERIOD_CURRENT, 0) + 1 * PeriodSeconds(PERIOD_CURRENT);

        double buySl = StopLoss == 0 ? 0 : high - StopLoss * _Point;
        double buyTp = TakeProfit == 0 ? 0 : high + TakeProfit * _Point;

        double sellSl = StopLoss == 0 ? 0 : low + StopLoss * _Point;
        double sellTp = TakeProfit == 0 ? 0 : low - TakeProfit * _Point;

        if (Filter)
        {
            if (EMABuffer[0] < low && Long)
                trade.BuyStop(Lots, high, _Symbol, buySl, buyTp, ORDER_TIME_SPECIFIED, expiration, "buy");

            if (EMABuffer[0] > high && Short)
                trade.SellStop(Lots, low, _Symbol, sellSl, sellTp, ORDER_TIME_SPECIFIED, expiration, "sell");
        }
        else
        {
            if (Long)
                trade.BuyStop(Lots, high, _Symbol, buySl, buyTp, ORDER_TIME_SPECIFIED, expiration, "buy");

            if (Short)
                trade.SellStop(Lots, low, _Symbol, sellSl, sellTp, ORDER_TIME_SPECIFIED, expiration, "sell");
        }


    }
    if(PriceProtection)
        BEFUN();
};

void OnDeinit(const int reason) {

};

// 只要有成交就删除订单
// 保证多单和空单不会同时存在
void OnTrade()
{
    if (PositionsTotal() >= 1)
        deleteAllOrders(_Symbol, MagicNumber);
}

// 1.当前K线的振幅比前面三根都小
// 2. 当前K的高点小于前一根的高点，最低点大于前一跟低点
// 3. 高低点挂单

int IsNr4()
{
    double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);

    double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2 = iLow(_Symbol, PERIOD_CURRENT, 2);

    if (high1 > high2 || low1 < low2)
        return 0;

    for (int i = 1; i < NarrowRangeCount; i++)
    {

        // double high = iHigh(_Symbol, PERIOD_CURRENT, i++);
        // double low = iLow(_Symbol, PERIOD_CURRENT, i++);

        double high = iHigh(_Symbol, PERIOD_CURRENT, i+1);  // 原本的NR4效果不及上面的
        double low = iLow(_Symbol, PERIOD_CURRENT, i+1);  // 原本的NR4效果不及上面的

        if ((high1 - low1) > (high - low))
            return 0;
    }
    return 1;
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

// 平仓所有符合条件的仓位
void closeAllPositions(string symbol, long magicNum)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (positionInfo.SelectByIndex(i))
        {
            if (positionInfo.Symbol() == symbol && positionInfo.Magic() == magicNum)
            {
                bool result = trade.PositionClose(positionInfo.Ticket());
                if (!result)
                    Print(symbol, "|", magicNum, " 平仓失败, Return code=", trade.ResultRetcode(),
                          ". Code description: ", trade.ResultRetcodeDescription());
            }
        }
    }
}
// 删除所有挂单
void deleteAllOrders(string symbol, long magicNum)
{
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (orderInfo.SelectByIndex(i))
        {
            if (orderInfo.Symbol() == symbol && orderInfo.Magic() == magicNum)
            {
                bool result = trade.OrderDelete(orderInfo.Ticket());
                if (!result)
                    Print(symbol, "|", magicNum, " 删除挂单失败, Return code=", trade.ResultRetcode(),
                          ". Code description: ", trade.ResultRetcodeDescription());
            }
        }
    }
}
// 品种 进场价  止损价  止损类型 止损参数
double CalcLots(string symbol, double et, double sl, int slType, double slParam){
    double slMoney = 0;
    if(slType==1) slMoney = AccountInfoDouble(ACCOUNT_BALANCE) * slParam / 100;

    // 计算止损距离
    int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    double slDistance = NormalizeDouble(MathAbs(et - sl), digits) / Point();
    if(slDistance <= 0) return 0;

    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if(tickValue == 0) return 0;

    // 风控 / 止损 / 点值
    double lot = NormalizeDouble(slMoney / slDistance / tickValue, 2);

    double lotstep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    lot = MathRound(lot / lotstep) * lotstep;

    if(lot < SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN)) lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    else if(lot >= SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX)) lot = 10;

    return lot;
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