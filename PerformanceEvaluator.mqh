// PerformanceEvaluator.mqh
#include <Trade/Trade.mqh>
class CPerformanceEvaluator
{
private:


public:
    // 构造函数
    CPerformanceEvaluator(){};
    ~CPerformanceEvaluator(){};
    
    // 初始化函数
    void Initialize(){};

    // 计算离群值比例
    static void CalculateOutlierRatio()
    {
        HistorySelect(0, TimeCurrent());
        int deals = HistoryDealsTotal();
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
    };

    // 计算每周的盈利和亏损
    static void CalculateWeeklyProfitAndLoss()
    {
        // 初始化变量
        double weekly_profit[5] = {0.0, 0.0, 0.0, 0.0, 0.0}; // 周一到周五的盈利
        double weekly_loss[5] = {0.0, 0.0, 0.0, 0.0, 0.0};   // 周一到周五的亏损
        HistorySelect(0, TimeCurrent());                     // 选择所有历史记录
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
                    weekly_profit[weekday - 1] += profit; // 累加盈利
                }
                else if (profit < 0)
                {
                    weekly_loss[weekday - 1] += profit; // 累加亏损
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
    };
};