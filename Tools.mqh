#include <Trade/Trade.mqh>

class CTools
{
private:
    /* data */
    string m_symbol;
    CTrade *m_trade;
    CPositionInfo *m_positionInfo;
    COrderInfo m_orderInfo;
    datetime m_prevBarTime;

public:
    CTools(string symbol, CTrade *_trade, CPositionInfo *_positionInfo, COrderInfo *_orderInfo);
    ~CTools();
    bool IsNewBar(ENUM_TIMEFRAMES timeframe);
    // 盈亏衡
    void ApplyBreakEven(int triggerPPoints, int movePoints, long magicNum);
    // 关闭所有订单
    void CloseAllPositions(long magicNum,ENUM_POSITION_TYPE type);
    // 删除所有挂单
    void DeleteAllOrders(long magicNum);
    // 获取当前持仓数量
    int GetPositionCount(long magicNum);
    // 获取当前挂单数量
    int GetOrderCount(long magicNum);
    // 计算手数
    double CalcLots(double et, double sl, double slParam);
    // 追踪止损
    void ApplyTrailingStop(int distancePoints, long magicNum);
    // 判断是否阳线
    bool IsUpBar(MqlRates &rates);
};

CTools::CTools(string _symbol, CTrade *_trade, CPositionInfo *_positionInfo, COrderInfo *_orderInfo)
{
    m_symbol = _symbol;
    m_trade = _trade;
    m_positionInfo = _positionInfo;
    m_orderInfo = _orderInfo;
    m_prevBarTime = INT_MIN;
}
CTools::~CTools()
{
    delete m_trade;
    delete m_positionInfo;
}

bool CTools::IsNewBar(ENUM_TIMEFRAMES timeframe)
{
    datetime currentBarTime = iTime(m_symbol, timeframe, 0);
    if (m_prevBarTime < currentBarTime)
    {
        m_prevBarTime = currentBarTime;
        return true;
    }
    return false;
}

void CTools::ApplyBreakEven(int triggerPPoints, int movePoints, long magicNum)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (m_positionInfo.SelectByIndex(i) && m_positionInfo.Magic() == magicNum && m_positionInfo.Symbol() == m_symbol)
        {
            ulong tick = m_positionInfo.Ticket();
            long type = m_positionInfo.PositionType();
            double Pos_Open = m_positionInfo.PriceOpen();
            double Pos_Curr = m_positionInfo.PriceCurrent();
            double Pos_TP = m_positionInfo.TakeProfit();
            double Pos_SL = m_positionInfo.StopLoss();

            double distance = 0;
            if (type == POSITION_TYPE_BUY)
            {
                distance = (Pos_Curr - Pos_Open) / _Point;
                if (distance >= triggerPPoints && Pos_SL < Pos_Open)
                {
                    if (!m_trade.PositionModify(tick, Pos_Open + movePoints * Point(), Pos_TP))
                        Print(m_symbol, "|", magicNum, " 修改止损失败, Return code=", m_trade.ResultRetcode(),
                              ". Code description: ", m_trade.ResultRetcodeDescription());
                }
            }
            else if (type == POSITION_TYPE_SELL)
            {
                distance = (Pos_Open - Pos_Curr) / _Point;
                if (distance >= triggerPPoints && Pos_SL > Pos_Open)
                {
                    if (!m_trade.PositionModify(tick, Pos_Open - movePoints * Point(), Pos_TP))
                        Print(m_symbol, "|", magicNum, " 修改止损失败, Return code=", m_trade.ResultRetcode(),
                              ". Code description: ", m_trade.ResultRetcodeDescription());
                }
            }
        }
    }
}

void CTools::ApplyTrailingStop(int distancePoints, long magicNum)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (m_positionInfo.SelectByIndex(i) && m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == magicNum)
        {
            ulong tick = m_positionInfo.Ticket();
            long type = m_positionInfo.PositionType();
            double Pos_Open = m_positionInfo.PriceOpen();
            double Pos_Curr = m_positionInfo.PriceCurrent();
            double Pos_TP = m_positionInfo.TakeProfit();
            double Pos_SL = m_positionInfo.StopLoss();

            double profitPoints = 0;  // 当前盈利点数
            double moveStopLevel = 0; // 新的止损位置

            if (type == POSITION_TYPE_BUY)
            {

                moveStopLevel=INT_MIN;
                profitPoints =(Pos_SL < Pos_Open)? (Pos_Curr - Pos_Open) / _Point: (Pos_Curr - Pos_SL) / _Point;

                if (profitPoints >= distancePoints && Pos_SL < Pos_Open)
                {
                    // 盈利达到 distancePoints 且止损小于开仓价时，将止损移动到开仓价
                    moveStopLevel = Pos_Open;
                }
                else if (profitPoints >= 2 * distancePoints)
                {
                    // 盈利达到 2 倍 distancePoints，将止损移动到当前价格 - distancePoints
                    moveStopLevel = Pos_Curr - distancePoints * Point();
                }

                if (moveStopLevel > Pos_SL) // 确保止损只向上移动
                {
                    if (!m_trade.PositionModify(tick, moveStopLevel, Pos_TP))
                        Print(m_symbol, "|", magicNum, " 修改止损失败, Return code=", m_trade.ResultRetcode(),
                              ". Code description: ", m_trade.ResultRetcodeDescription());
                }
            }
            else if (type == POSITION_TYPE_SELL)
            {

                moveStopLevel=INT_MAX;

                profitPoints = (Pos_SL > Pos_Open)?(Pos_Open - Pos_Curr) / _Point:(Pos_SL-Pos_Curr) / _Point;

                if (profitPoints >= distancePoints && Pos_SL > Pos_Open)
                {
                    // 盈利达到 distancePoints 且止损高于开仓价时，将止损移动到开仓价
                    moveStopLevel = Pos_Open;
                }
                else if (profitPoints >= 2 * distancePoints)
                {
                    // 盈利达到 2 倍 distancePoints，将止损移动到当前价格 + distancePoints
                    moveStopLevel = Pos_Curr + distancePoints * Point();
                }

                if (moveStopLevel < Pos_SL) // 确保止损只向下移动
                {
                    if (!m_trade.PositionModify(tick, moveStopLevel, Pos_TP))
                        Print(m_symbol, "|", magicNum, " 修改止损失败, Return code=", m_trade.ResultRetcode(),
                              ". Code description: ", m_trade.ResultRetcodeDescription());
                }
            }
        }
    }
}


void CTools::CloseAllPositions(long magicNum,ENUM_POSITION_TYPE type)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (m_positionInfo.SelectByIndex(i) && m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == magicNum)
        {
            if (type == m_positionInfo.PositionType() )
            {
                if (!m_trade.PositionClose(m_positionInfo.Ticket()))
                    Print(m_symbol, "|", magicNum, " 平仓失败, Return code=", m_trade.ResultRetcode(),
                          ". Code description: ", m_trade.ResultRetcodeDescription());
            }
        }
    }
}



void CTools::DeleteAllOrders(long magicNum)
{
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (m_orderInfo.SelectByIndex(i) && m_orderInfo.Symbol() == m_symbol && m_orderInfo.Magic() == magicNum)
        {
            if (!m_trade.OrderDelete(m_orderInfo.Ticket()))
                Print(m_symbol, "|", magicNum, " 删除挂单失败, Return code=", m_trade.ResultRetcode(),
                      ". Code description: ", m_trade.ResultRetcodeDescription());
        }
    }
}

int CTools::GetOrderCount(long magicNum)
{
    int count = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (m_orderInfo.SelectByIndex(i) && m_orderInfo.Symbol() == m_symbol && m_orderInfo.Magic() == magicNum)
        {
            count++;
        }
    }
    return count;
}

int CTools::GetPositionCount(long magicNum)
{
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (m_positionInfo.SelectByIndex(i) && m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == magicNum)
        {
            count++;
        }
    }
    return count;
}

// 进厂价格，止损价格，账户余额的百分数
double CTools::CalcLots(double et, double sl, double slParam)
{
    double slMoney = 0;
    slMoney = AccountInfoDouble(ACCOUNT_BALANCE) * slParam / 100.0;
    // 计算止损距离
    int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);

    double slDistance = NormalizeDouble(MathAbs(et - sl), digits) / Point();

    if (slDistance <= 0)
        return 0;

    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    if (tickValue == 0)
        return 0;
    // 风控 / 止损 / 点值
    double lot = NormalizeDouble(slMoney / slDistance / tickValue, 2);

    double lotstep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
    lot = MathRound(lot / lotstep) * lotstep;

    if (lot < SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN))
        lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    else if (lot >= SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX))
        lot = 10;

    return lot;
}

bool CTools::IsUpBar(MqlRates &rates)
{
    if (rates.close >= rates.open)
        return true;
    else if( rates.close < rates.open)
        return false;

    return true;
};
