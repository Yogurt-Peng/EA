#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"
#include "PerformanceEvaluator.mqh"

// 基本参数
input group "基本参数";
input int MagicNumber = 12572;                   // EA编号 (专家交易系统编号)
input ENUM_TIMEFRAMES TimeFrame = PERIOD_H1; // 交易周期
input double LotSize = 0.01;                      // 交易手数
input int GridDistance = 400;                     // 网格间距（以点数为单位）
input group "指标参数";
input int DonchianValue = 60;   // 唐奇安通道指标值

// 声明交易和工具对象
CTrade trade;
CTools tools(_Symbol, &trade);
CDraw draw;
CDonchian donchian(_Symbol, TimeFrame, DonchianValue);

// 跟踪基础价格和当前网格层级的变量
SIGN currentMode = NONE;  // 当前模式（0：等待买入，1：等待卖出）
double basePrice = 0;     // 基础价格
int GridNumber = 3;       // 网格数量
string EmailSubject = "外汇网格交易通知";        // 邮件主题
bool IsDebug = true; // 是否调试模式
// 初始化策略的函数
int OnInit()
{
    donchian.Initialize();
    trade.SetExpertMagicNumber(MagicNumber); // 设置交易的MagicNumber
    // 将初始基准价格设为当前买价
    EventSetTimer(2); // 设置定时器，每30秒执行一次OnTimer函数
    IsDebug=MQLInfoInteger(MQL_TESTER);
    // ChartIndicatorAdd(0, 1, rsi.GetHandle());
    ChartIndicatorAdd(0, 0, donchian.GetHandle());
    return (INIT_SUCCEEDED);
}



void OnTick()
{

    // 检查是否在指定时间周期内生成了新K线
    if (!tools.IsNewBar(PERIOD_M1))
        return;

    CheckFridayClose();
    ManagePositions();
    SIGN sign = GetSign();

    // SYMBOL_SPREAD 检查当前交易品种的点差是否超过指定值
    if (SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > 40)
        return;
    if (sign != NONE) HandleNewSignal(sign);

}


void OnTimer()
{
    if (!IsDebug)
    {
        bool isAutoTradingEnabled = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
        string dbgInfo[4] = {"外汇网格", "", "",""};
        dbgInfo[1] = "AutoTrading: " + (isAutoTradingEnabled ? "Enabled" : "Disabled");
        dbgInfo[2] = StringFormat("状态: %s 点差: %d", tools.GetPositionCount(MagicNumber) > 0 ? "持仓中" : "等待中",SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
        // 绘制时间
        dbgInfo[3] = StringFormat("时间: %s", TimeToString(TimeLocal()));
        draw.DrawLabels("Debug", dbgInfo, 4, 10, 200, C'53, 153, 130', 10, CORNER_LEFT_UPPER);

    }
}

void OnDeinit(const int reason)
{
    EventKillTimer();
    CPerformanceEvaluator::CalculateOutlierRatio();
    CPerformanceEvaluator::CalculateWeeklyProfitAndLoss();

    IndicatorRelease(donchian.GetHandle());
    Print("🚀🚀🚀 策略停止...");
}
SIGN GetSign()
{

    double close = iClose(_Symbol, TimeFrame, 1);

    if (close > donchian.GetValue(0))
        return SELL;
    else if (close < donchian.GetValue(1))
        return BUY;
    return NONE;
};

// 重置交易状态
void ResetTradeState()
{
    basePrice = 0;
    currentMode = NONE;
};

// 变量声明

void CheckFridayClose()
{
    MqlDateTime currentTimeStruct;
    TimeToStruct( TimeCurrent(), currentTimeStruct);
    static bool isFridayClosed = false; // 标记是否周五已经平仓

    // 检查是否是周五晚上 22 点或之后
    if (currentTimeStruct.day_of_week == 5 && currentTimeStruct.hour >= 22)
    {
        if (!isFridayClosed) // 如果尚未平仓
        {
            if (tools.CloseAllPositions(MagicNumber) && tools.DeleteAllOrders(MagicNumber))
            {
                ResetTradeState();
                isFridayClosed = true; // 设置周五已平仓标记
                Print("周五晚上平仓完成，禁止开仓至周一");
                if (!IsDebug)
                    SendEmail(EmailSubject, "周五：平仓成功，禁止开仓至周一");

            }else
            {
                if (!IsDebug)
                    SendEmail(EmailSubject, "周五：平仓失败，请检查");
            }
        }
    }
    else if (currentTimeStruct.day_of_week == 1 && currentTimeStruct.hour < 1)
    {
        // 周一凌晨 00:00 重置平仓标记，允许开仓
        isFridayClosed = false;
    }

    // 如果周五已平仓且尚未到周一，则返回，不允许开仓
    if (isFridayClosed)
    {
        return;
    }
}
// 处理新信号
void HandleNewSignal(SIGN signal)
{
    // 如果已有持仓或当前模式非空，不处理新信号
    if (tools.GetPositionCount(MagicNumber) > 0 || currentMode != NONE)
        return;

    double price = (signal == BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    bool orderPlaced = false;



    // 根据信号执行下单
    if (signal == BUY)
        orderPlaced = trade.Buy(LotSize, _Symbol, 0, 0, 0, "初始买单");
    else
        orderPlaced = trade.Sell(LotSize, _Symbol, 0, 0, 0, "初始卖单");

    // 仅当下单成功时，执行后续逻辑
    if (orderPlaced)
    {
        basePrice = price;          // 更新基准价格
        PlaceGridOrders(signal);    // 创建网格订单
        currentMode = signal;       // 更新当前模式
    }
    else
    {
        Print("下单失败，未更新状态和网格订单");
        if (!IsDebug)
            SendEmail(EmailSubject, "初始下单失败，请检查");
    }
}


// 创建网格订单
void PlaceGridOrders(SIGN signal)
{
    for (int i = 1; i < GridNumber; i++)
    {
        double price = (signal == BUY)
            ? basePrice - i * GridDistance * _Point
            : basePrice + i * GridDistance * _Point;

        if (signal == BUY)
            trade.BuyLimit(LotSize, price, _Symbol);
        else
            trade.SellLimit(LotSize, price, _Symbol);
    }
}

// 管理持仓和网格逻辑
void ManagePositions()
{
    int positionCount = tools.GetPositionCount(MagicNumber);
    double totalProfit = tools.GetTotalProfit(MagicNumber) * 100.0; // 当前总盈利，单位：点
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);             // 当前买入价
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);             // 当前卖出价

    switch (positionCount)
    {
    case 1: // 持仓数量为 1
        HandlePosition(totalProfit);
        break;
    case 2: // 持仓数量为 2
        HandlePosition(totalProfit);
        break;
    case 3: // 持仓数量为 3
        HandleTriplePosition(totalProfit, ask, bid);
        break;
    default:
        // 持仓数量大于 3 的其他逻辑可在此添加
        break;
    }
}

// 通用处理持仓关闭逻辑
bool CloseAllAndReset()
{
    if (tools.CloseAllPositions(MagicNumber) && tools.DeleteAllOrders(MagicNumber))
    {
        ResetTradeState();
        return true;
    }else
    {
        if (!IsDebug)
            SendEmail(EmailSubject, "平仓失败，请检查");
    }
    return false;
}

// 处理持仓数量为 1 或 2 的情况
void HandlePosition(double totalProfit)
{
    if (totalProfit > GridDistance)
    {
        CloseAllAndReset();
    }
}

// 处理持仓数量为 3 的情况
void HandleTriplePosition(double totalProfit, double ask, double bid)
{
    bool shouldClose = false;

    if (currentMode == SELL)
    {
        shouldClose = (bid > basePrice + GridNumber * GridDistance * _Point);
    }
    else if (currentMode == BUY)
    {
        shouldClose = (ask < basePrice - GridNumber * GridDistance * _Point);
    }

    if (shouldClose || totalProfit > 0)
    {
        CloseAllAndReset();
    }
}

