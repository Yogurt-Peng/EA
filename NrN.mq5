#include <Trade/Trade.mqh>
// 趋势形策略

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;

// 基本参数
input group "基本参数";
input int MagicNumber = 1001;   // 魔术号
input int NarrowRangeCount = 8; // NRC
input double Lots = 0.01;       // 交易手数
input int StopLoss = 160;       // 止损点数
input int TakeProfit = 220;     // 止盈点数
input bool Long = true;         // 是否允许多单
input bool Short = true;        // 是否允许空单

// 过滤参数
input group "过滤参数";
input ENUM_TIMEFRAMES EMAPeriod = PERIOD_H4; // EMA周期
input int EMAValue = 100;                    // EMA值

// 价格保护
input group "价格保护";
input bool PriceProtection = true; // 是否启用价格保护
input int BE_Trigger_Points = 60;  // 触发点数
input int BE_Move_Points = 10;     // 移动点数

int handleEMA;
double EMABuffer[];

int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber);
    handleEMA = iMA(_Symbol, EMAPeriod, EMAValue, 0, MODE_EMA, PRICE_CLOSE);
    return INIT_SUCCEEDED;
}

void OnTick()
{
    if (!IsNewBar(_Symbol, PERIOD_M1))
        return;

    CopyBuffer(handleEMA, 0, 0, 1, EMABuffer);

    if (IsNr4() && PositionsTotal() == 0 && OrdersTotal() == 0)
    {
        CloseAllPositions(_Symbol, MagicNumber);
        double high = iHigh(_Symbol, PERIOD_CURRENT, 1);
        double low = iLow(_Symbol, PERIOD_CURRENT, 1);

        datetime expiration = iTime(_Symbol, PERIOD_CURRENT, 0) + PeriodSeconds(PERIOD_CURRENT);

        double buySl = (StopLoss == 0) ? 0 : high - StopLoss * _Point;
        double buyTp = (TakeProfit == 0) ? 0 : high + TakeProfit * _Point;

        double sellSl = (StopLoss == 0) ? 0 : low + StopLoss * _Point;
        double sellTp = (TakeProfit == 0) ? 0 : low - TakeProfit * _Point;

        if (EMABuffer[0] < low && Long)
        {
            // 账户余额的1%
            double lots = (Lots == 0) ? CalcLots(_Symbol, high, buySl, 1, 1) : Lots;
            trade.BuyStop(lots, high, _Symbol, buySl, buyTp, ORDER_TIME_SPECIFIED, expiration, "buy");
        }

        if (EMABuffer[0] > high && Short)
        {
            double lots = (Lots == 0) ? CalcLots(_Symbol, low, sellSl, 1, 1) : Lots;
            trade.SellStop(lots, low, _Symbol, sellSl, sellTp, ORDER_TIME_SPECIFIED, expiration, "sell");
        }
    }

    if (PriceProtection)
        ApplyBreakEven(BE_Trigger_Points, BE_Move_Points);

}

void OnDeinit(const int reason) {}

// 保证多单和空单不会同时存在
void OnTrade()
{
    // 删除挂单
    if (PositionsTotal() >= 1)
        DeleteAllOrders(_Symbol, MagicNumber);
}

bool IsNr4()
{
    double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
    double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);
    double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
    double low2 = iLow(_Symbol, PERIOD_CURRENT, 2);


    // 1 2 3
    for (int i = 1; i < NarrowRangeCount; i++)
    {
        double high = iHigh(_Symbol, PERIOD_CURRENT, i + 1);
        double low = iLow(_Symbol, PERIOD_CURRENT, i + 1);
        double time = iTime(_Symbol, PERIOD_CURRENT, i + 1);

        if ((high1 - low1) > (high - low))
        {
            for(int j=i; j<NarrowRangeCount; j++)
                ObjectDelete(0, string(j));

            return false;
        }
        // 绘制NRC
        ObjectCreate(0, string(i), OBJ_VLINE, 0, time, high);
       
    }


    if (high1 > high2 || low1 < low2)
        return false;


    return true;
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

void CloseAllPositions(string symbol, long magicNum)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (positionInfo.SelectByIndex(i) && positionInfo.Symbol() == symbol && positionInfo.Magic() == magicNum)
        {
            if (!trade.PositionClose(positionInfo.Ticket()))
                Print(symbol, "|", magicNum, " 平仓失败, Return code=", trade.ResultRetcode(),
                      ". Code description: ", trade.ResultRetcodeDescription());
        }
    }
}

void DeleteAllOrders(string symbol, long magicNum)
{
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (orderInfo.SelectByIndex(i) && orderInfo.Symbol() == symbol && orderInfo.Magic() == magicNum)
        {
            if (!trade.OrderDelete(orderInfo.Ticket()))
                Print(symbol, "|", magicNum, " 删除挂单失败, Return code=", trade.ResultRetcode(),
                      ". Code description: ", trade.ResultRetcodeDescription());
        }
    }
}

void ApplyBreakEven(int triggerPPoints, int movePoints)
{

    for (int i = 0; i < PositionsTotal(); i++)
    {
        int tick = (int)PositionGetTicket(i);
        int type = (int)PositionGetInteger(POSITION_TYPE);
        int magic = (int)PositionGetInteger(POSITION_MAGIC);

        double Pos_Open = PositionGetDouble(POSITION_PRICE_OPEN), Pos_Curr = PositionGetDouble(POSITION_PRICE_CURRENT);
        double Pos_TP = PositionGetDouble(POSITION_TP), Pos_SL = PositionGetDouble(POSITION_SL);

        double distance = 0;
        if (type == POSITION_TYPE_BUY)
        {
            distance = (Pos_Curr - Pos_Open) / _Point;
            if (distance >= triggerPPoints && Pos_SL < Pos_Open)
            {
                trade.PositionModify(tick, Pos_Open + movePoints * Point(), Pos_TP);
            }
        }
        else if (type == POSITION_TYPE_SELL)
        {
            distance = (Pos_Open - Pos_Curr) / _Point;
            if (distance >= triggerPPoints && Pos_SL > Pos_Open)
            {
                trade.PositionModify(tick, Pos_Open - movePoints * Point(), Pos_TP);
            }
        }
    }
}

// 品种 进场价  止损价  止损类型 止损参数
double CalcLots(string symbol, double et, double sl, int slType, double slParam)
{
    double slMoney = 0;
    if (slType == 1)
        slMoney = AccountInfoDouble(ACCOUNT_BALANCE) * slParam / 100.0;
    // 计算止损距离
    int digits = SymbolInfoInteger(symbol, SYMBOL_DIGITS);

    double slDistance = NormalizeDouble(MathAbs(et - sl), digits) / Point();
    if (slDistance <= 0)
        return 0;

    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if (tickValue == 0)
        return 0;

    // 风控 / 止损 / 点值
    double lot = NormalizeDouble(slMoney / slDistance / tickValue, 2);

    double lotstep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    lot = MathRound(lot / lotstep) * lotstep;

    if (lot < SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN))
        lot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    else if (lot >= SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX))
        lot = 10;

    return lot;
}
// 显示调试信息
// string debugInfo[9];
// debugInfo[0] = "大趋势快线: " + (string)trend_fastma_Buffer[1];
// debugInfo[1] = "大趋势慢线: " + (string)trend_slowma_Buffer[1];
// debugInfo[2] = "大趋势方向: " + (string)(trend==1 ? "多" : trend==-1 ? "空" : "没方向");

void DisplayDebugInfoScreen(string &debugLine[], int startLine = 0, int infoColor = clrRed)
{
    int lineCount = ArraySize(debugLine);
    // 删除上次生成的调试信息
    for (int i = 0; i < lineCount; i++)
    {
        string oldLabelName = "DebugInfo_" + IntegerToString(startLine + i);
        ObjectDelete(0, oldLabelName);
    }

    // 显示生成的新的调试信息
    for (int i = 0; i < lineCount; i++)
    {
        string labelName = "DebugInfo_" + IntegerToString(startLine + i);
        if (ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0))
        {
            ObjectSetString(0, labelName, OBJPROP_TEXT, debugLine[i]);
            ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, 50);
            ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, 50 + (startLine + i) * 20);
            ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, infoColor);
        }
    }
}