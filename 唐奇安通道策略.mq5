#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

input group "基本参数";
input int MagicNumber = 555245;               // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_M30; // 周期
input double LotSize = 0.01;                  // 手数
input double StopLossK = 1;                   // 止损系数
input double TakeProfitK = 1;                 // 止盈系数

input int ShortAtrValue = 40; // 短期ATR值
input int LongAtrValue = 95;  // 长期ATR值

CTrade trade;
CTools tools(_Symbol, &trade);
CDraw draw;

CATR shortAtr(_Symbol, TimeFrame, ShortAtrValue);
CATR longAtr(_Symbol, TimeFrame, LongAtrValue);
CDonchian donchian(_Symbol, TimeFrame, LongAtrValue);

int OnInit()
{
    Print("🚀🚀🚀 唐安奇通道策略启动...");

    EventSetTimer(10); // 设置定时器，每30秒执行一次OnTimer函数

    shortAtr.Initialize();
    longAtr.Initialize();
    donchian.Initialize();

    ChartIndicatorAdd(0, 1, shortAtr.GetHandle());
    ChartIndicatorAdd(0, 2, longAtr.GetHandle());
    ChartIndicatorAdd(0, 0, donchian.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber);
    return (INIT_SUCCEEDED);
}

void OnTimer()
{
    if (!MQLInfoInteger(MQL_TESTER))
    {
        bool isAutoTradingEnabled = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
        string dbgInfo[4] = {"唐奇安通道", "", "",""};
        dbgInfo[1] = "AutoTrading: " + (isAutoTradingEnabled ? "Enabled" : "Disabled");
        dbgInfo[2] = StringFormat("状态: %s", tools.GetPositionCount(MagicNumber) > 0 ? "持仓中" : "等待中");
        // 绘制时间
        dbgInfo[3] = StringFormat("时间: %s", TimeToString(TimeLocal()));
        draw.DrawLabels("Debug", dbgInfo, 4, 10, 200, C'53, 153, 130', 10, CORNER_LEFT_UPPER);

    }

}

void OnTick()
{

    if (!tools.IsNewBar(TimeFrame))
        return;


    SIGN sign = GetSign();

    double donchianDifference = MathAbs(donchian.GetValue(0) - donchian.GetValue(1));

    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double buySl = ask - donchianDifference * StopLossK;
    double buyTp = ask + donchianDifference * StopLossK * TakeProfitK;
    double sellSl = bid + donchianDifference * StopLossK;
    double sellTp = bid - donchianDifference * StopLossK * TakeProfitK;

    if (sign == BUY)
    {
        tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL);
        if (tools.GetPositionCount(MagicNumber) == 0)
            trade.Buy(LotSize, _Symbol, ask, buySl, buyTp);
    }
    else if (sign == SELL)
    {
        tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY);
        if (tools.GetPositionCount(MagicNumber) == 0)
            trade.Sell(LotSize, _Symbol, bid, sellSl, sellTp);
    }
}

void OnDeinit(const int reason)
{
    EventKillTimer();
    IndicatorRelease(shortAtr.GetHandle());
    IndicatorRelease(longAtr.GetHandle());
    IndicatorRelease(donchian.GetHandle());
    CalculateOutlierRatio();
    CalculateWeeklyProfitAndLoss();
    Print("🚀🚀🚀 唐安奇通道策略停止...");
}

SIGN GetSign()
{
    if (shortAtr.GetValue(1) <= longAtr.GetValue(1))
        return NONE;
    double close = iClose(_Symbol, TimeFrame, 1);

    if (close > donchian.GetValue(0))
        return SELL;
    else if (close < donchian.GetValue(1))
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