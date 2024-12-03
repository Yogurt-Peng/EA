#include <Trade/Trade.mqh>

class CTools
{
private:
    /* data */
    string m_symbol;
    CTrade *m_trade;
    CPositionInfo *m_positionInfo;
    COrderInfo m_orderInfo;
    datetime m_prevBarTime ;


public:
    CTools(string symbol, CTrade *_trade,CPositionInfo *_positionInfo, COrderInfo *_orderInfo);
    ~CTools();
    bool IsNewBar(ENUM_TIMEFRAMES timeframe);
    // 移动推损
    void ApplyBreakEven(int triggerPPoints, int movePoints);
    // 关闭所有订单
    void CloseAllPositions( long magicNum);
    // 删除所有挂单
    void DeleteAllOrders(long magicNum);
    // 获取当前持仓数量
    int GetPositionCount(long magicNum);
    // 获取当前挂单数量
    int GetOrderCount(long magicNum);
    // 计算手数
    double CalcLots( double et, double sl, double slParam);


};

CTools::CTools(string _symbol, CTrade *_trade,CPositionInfo *_positionInfo, COrderInfo *_orderInfo)
{
    m_symbol = _symbol;
    m_trade = _trade;
    m_positionInfo = _positionInfo;
    m_orderInfo = _orderInfo;
    m_prevBarTime=INT_MIN;
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

void CTools::ApplyBreakEven(int triggerPPoints, int movePoints)
{

    for (int i = 0; i < PositionsTotal(); i++)
    {
        ulong tick =PositionGetTicket(i);
        long type =PositionGetInteger(POSITION_TYPE);
        long magic = PositionGetInteger(POSITION_MAGIC);

        double Pos_Open = PositionGetDouble(POSITION_PRICE_OPEN), Pos_Curr = PositionGetDouble(POSITION_PRICE_CURRENT);
        double Pos_TP = PositionGetDouble(POSITION_TP), Pos_SL = PositionGetDouble(POSITION_SL);

        double distance = 0;
        if (type == POSITION_TYPE_BUY)
        {
            distance = (Pos_Curr - Pos_Open) / _Point;
            if (distance >= triggerPPoints && Pos_SL < Pos_Open)
            {
                m_trade.PositionModify(tick, Pos_Open + movePoints * Point(), Pos_TP);
            }
        }
        else if (type == POSITION_TYPE_SELL)
        {
            distance = (Pos_Open - Pos_Curr) / _Point;
            if (distance >= triggerPPoints && Pos_SL > Pos_Open)
            {
                m_trade.PositionModify(tick, Pos_Open - movePoints * Point(), Pos_TP);
            }
        }
    }
}

void CTools::CloseAllPositions(long magicNum)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if (m_positionInfo.SelectByIndex(i) && m_positionInfo.Symbol() == m_symbol && m_positionInfo.Magic() == magicNum)
        {
            if (!m_trade.PositionClose(m_positionInfo.Ticket()))
                Print(m_symbol, "|", magicNum, " 平仓失败, Return code=", m_trade.ResultRetcode(),
                      ". Code description: ", m_trade.ResultRetcodeDescription());
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
double CTools::CalcLots( double et, double sl, double slParam)
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