#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

input group "基本参数";
input int MagicNumber = 52422;                // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M15; // 周期
input double LotSize = 0.01;                  // 手数
input int StopLoss = 0;                       // 止损点数 0:不使用
input int TakeProfit = 0;                     // 止盈点数 0:不使用

input group "指标参数";
input int RSIValue = 14;      // RSI指标值
input int RSIOverbought = 70; // 超买区
input int RSIOversold = 30;   // 超卖区
input int BBValue = 20;       // Bollinger Bands指标值
input int BBDeviation = 2;    // Bollinger Bands指标值

input group "过滤参数";
input bool MAFilter = true;                     // 是否使用MA过滤
input bool IsReverse = true;                    // 是否反向过滤条件
input ENUM_TIMEFRAMES MAFilterTF = PERIOD_M2;   // 过滤MA带周期
input int MAFilterValue = 30;                   // MA指标值
input ENUM_MA_METHOD MAFilterMethod = MODE_SMA; // 过滤MA指标类型

CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);

CRSI rsi(_Symbol, TimeFrame, RSIValue);
CBollingerBands bollinger(_Symbol, TimeFrame, BBValue, BBDeviation);
CMA ma(_Symbol, MAFilterTF, MAFilterValue, MAFilterMethod);

SIGN maSign = NONE, rsiSign = NONE;

int OnInit()
{
    Print("🚀🚀🚀 RSITrade初始化中...");
    rsi.Initialize();
    bollinger.Initialize();
    ma.Initialize();

    ChartIndicatorAdd(0, 1, rsi.GetHandle());
    ChartIndicatorAdd(0, 0, bollinger.GetHandle());
    ChartIndicatorAdd(0, 0, ma.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 RSITrade初始化成功");
    return INIT_SUCCEEDED;
}

void OnTick()
{


    if (!MQLInfoInteger(MQL_TESTER))
    {
        bool isAutoTradingEnabled = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
        string dbgInfo[3] = {"RSITrade", "", ""};
        dbgInfo[1] = "AutoTrading: " + (isAutoTradingEnabled ? "Enabled" : "Disabled");
        dbgInfo[2] = StringFormat("MAFilter: %s TF: %d Value: %d  Method: %d", MAFilter ? "Enabled" : "Disabled", MAFilterTF, MAFilterValue, MAFilterMethod);
        draw.DrawLabels("Debug", dbgInfo, 3, 10, 200, C'53, 153, 130', 10, CORNER_LEFT_UPPER);
    }

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double close = iClose(_Symbol, TimeFrame, 1);

    double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
    double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;

    if (tools.GetPositionCount(MagicNumber) > 0)
    {

        if (ask >= bollinger.GetValue(1, 0))
        {
            tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY);
        }
        if (bid <= bollinger.GetValue(2, 0))
        {
            tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL);
        }
        return;
    }

    if (!tools.IsNewBar(TimeFrame))
        return;

    // 过滤周二数据行情
    // if (IsTodayTuesday())
    // {
    //     Print("今天是星期二，不执行交易。");
    //     return;  // 在周二不做单
    // }


    maSign = close > ma.GetValue(1) ? BUY : SELL;
    rsiSign = GetSign();

    bool buyCondition = false;
    bool sellCondition = false;

    if (MAFilter)
    {
        if (IsReverse)
        {
            buyCondition = maSign == SELL && rsiSign == BUY;
            sellCondition = maSign == BUY && rsiSign == SELL;
        }
        else
        {
            buyCondition = maSign == BUY && rsiSign == BUY;
            sellCondition = maSign == SELL && rsiSign == SELL;
        }
    }
    else
    {
        buyCondition = GetSign() == BUY;
        sellCondition = GetSign() == SELL;
    }

    if (buyCondition)
    {
        trade.Buy(LotSize, _Symbol, ask, buySl, buyTp, "RSITrend");
    }
    else if (sellCondition)
    {
        trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp, "RSITrend");
    }
}

void OnDeinit(const int reason)
{

    IndicatorRelease(rsi.GetHandle());
    IndicatorRelease(bollinger.GetHandle());
    IndicatorRelease(ma.GetHandle());
    CalculateOutlierRatio();
    CalculateWeeklyProfitAndLoss();
    Print("🚀🚀🚀 RSITrade移除");
}

SIGN GetSign()
{

    if (rsi.GetValue(2) > RSIOverbought && rsi.GetValue(1) < RSIOverbought)
        return SELL;

    else if (rsi.GetValue(2) < RSIOversold && rsi.GetValue(1) > RSIOversold)
        return BUY;

    return NONE;
}

void CalculateOutlierRatio()
{
    HistorySelect(0, TimeCurrent());
    int deals=HistoryDealsTotal();
    double total_profit = 0.0;
    double top_10_profit = 0.0;
    double profits[];

    // 遍历历史订单，提取所有盈利订单的利润
    for (int i = 0; i < deals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        if (profit > 0) // 仅统计盈利订单
        {
            ArrayResize(profits, ArraySize(profits) + 1);
            profits[ArraySize(profits) - 1] = profit;
            total_profit += profit;
        }
    }

    // 如果没有盈利订单，直接返回
    if (ArraySize(profits) == 0)
    {
        Print("没有盈利订单，无法计算离群值比例。");
        return;
    }

    // 按利润从高到低排序
    ArraySort(profits);

    // 计算前10%的总利润
    int top_10_count = MathMax(1, (int)(ArraySize(profits) * 0.1)); // 至少保留一个
    for (int i = ArraySize(profits) - 1; i >= ArraySize(profits) - top_10_count; i--)
    {
        top_10_profit += profits[i];
    }

    // 计算离群值比例
    double outlier_ratio = (total_profit > 0) ? (top_10_profit / total_profit) : 0.0;

    // 打印结果
    PrintFormat("总利润: %.2f, 前10%%利润: %.2f, 离群值比例: %.2f%%",
                total_profit, top_10_profit, outlier_ratio * 100);
}


void CalculateWeeklyProfitAndLoss()
{
    // 初始化变量
    double weekly_profit[5] = {0.0, 0.0, 0.0, 0.0, 0.0}; // 周一到周五的盈利
    double weekly_loss[5] = {0.0, 0.0, 0.0, 0.0, 0.0};  // 周一到周五的亏损
    HistorySelect(0, TimeCurrent()); // 选择所有历史记录
    int deals = HistoryDealsTotal();

    // 遍历历史订单
    for (int i = 0; i < deals; i++)
    {
        ulong ticket = HistoryDealGetTicket(i);

        // 获取订单的利润
        double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);

        // 获取订单的成交时间
        datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        MqlDateTime dt_struct;
        TimeToStruct(deal_time, dt_struct); // 转换为日期结构

        // 根据日期结构的 "day_of_week" 判断星期几
        int weekday = dt_struct.day_of_week;
        if (weekday >= 1 && weekday <= 5) // 只统计周一到周五的订单
        {
            if (profit > 0)
            {
                weekly_profit[weekday - 1] += profit;  // 累加盈利
            }
            else if (profit < 0)
            {
                weekly_loss[weekday - 1] += profit;  // 累加亏损
            }
        }
    }

    // 打印结果
    Print("周盈利统计：");
    PrintFormat("周一盈利: %.2f, 周一亏损: %.2f", weekly_profit[0], weekly_loss[0]);
    PrintFormat("周二盈利: %.2f, 周二亏损: %.2f", weekly_profit[1], weekly_loss[1]);
    PrintFormat("周三盈利: %.2f, 周三亏损: %.2f", weekly_profit[2], weekly_loss[2]);
    PrintFormat("周四盈利: %.2f, 周四亏损: %.2f", weekly_profit[3], weekly_loss[3]);
    PrintFormat("周五盈利: %.2f, 周五亏损: %.2f", weekly_profit[4], weekly_loss[4]);
}

// 判断今天是否是星期二
bool IsTodayTuesday()
{
    // 获取当前时间
    datetime current_time = TimeCurrent();
    
    // 将当前时间转换为 MqlDateTime 结构
    MqlDateTime dt_struct;
    TimeToStruct(current_time, dt_struct);

    // 返回是否为星期二 (day_of_week = 2 表示星期二)
    return dt_struct.day_of_week == 2;
}
