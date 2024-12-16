#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

input group "基本参数";
input int MagicNumber = 45752;                    // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用
input int AsiaStartTime = 0;                      // 亚洲盘统计开始时间
input int AsiaEndTime = 7;                        // 亚洲盘统计结束时间
input int LondonStartTime = 8;                    // 伦敦盘统计开始时间
input int StopTime = 9;                           // 伦敦盘平仓时间

CTrade trade;
CDraw draw;
CTools tools(_Symbol, &trade);

double asiaHigh = 0;
double asiaLow = 0;

bool berakOutUp = false;
bool berakOutDown = false;

datetime orderTime=0;

int OnInit()
{
    Print("🚀🚀🚀 LondonBreakOut初始化中...");
    trade.SetExpertMagicNumber(MagicNumber);
    return INIT_SUCCEEDED;
}

void OnTick()
{

    
    if (!tools.IsNewBar(TimeFrame))
        return;


    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double buySl = (StopLoss == 0) ? 0 : ask - StopLoss * _Point;
    double buyTp = (TakeProfit == 0) ? 0 : ask + TakeProfit * _Point;
    double sellSl = (StopLoss == 0) ? 0 : bid + StopLoss * _Point;
    double sellTp = (TakeProfit == 0) ? 0 : bid - TakeProfit * _Point;

    // if (tools.GetPositionCount(MagicNumber) > 0)
    // {
    //     return;
    // }

    if (tools.GetPositionCount(MagicNumber) > 0 &&iTime(_Symbol, TimeFrame,StopTime)>=orderTime)
    {
        tools.CloseAllPositions(MagicNumber);
        orderTime=0;
                
    }

    if (tools.GetPositionCount(MagicNumber) > 0)return;

    

    datetime currentTime = TimeCurrent();

    if (currentTime > GetStartHourTime(AsiaStartTime) && currentTime <= GetStartHourTime(AsiaEndTime))
    {
        double priceHigh = GetHighestLowestPrice(MODE_HIGH);
        double priceLow = GetHighestLowestPrice(MODE_LOW);
        if (priceHigh > 0 && priceLow > 0)
        {
            asiaHigh = priceHigh;
            asiaLow = priceLow;
            draw.DrawRectangleFill("Asia", (int)GetStartHourTime(AsiaStartTime), priceHigh, (int)TimeCurrent(), priceLow, C'148, 255, 255');
        }

        berakOutUp = false;
        berakOutDown = false;
    }


    // 如果在 LondonStartTime- 1 Hour 内，产生了突破Asia，记录
    if (currentTime < GetStartHourTime(LondonStartTime) && currentTime >=GetStartHourTime(LondonStartTime - 1))
    {
        double close = iClose(_Symbol, TimeFrame, 1);
        if (close > asiaHigh && berakOutUp==false)
            berakOutUp = true;
        else if (close < asiaLow && berakOutDown==false)
            berakOutDown = true;
    }

    // 如果在LondonStartTime+1 Hour 内，又产生了相反方向的突破，则顺着方向开仓
    if (currentTime >= GetStartHourTime(LondonStartTime) && currentTime <GetStartHourTime(LondonStartTime + 2))
    {
        double close = iClose(_Symbol, TimeFrame, 1);
        if (berakOutUp && close < asiaHigh)
        {
            trade.Sell(LotSize,_Symbol,0,sellSl,sellTp);
            berakOutUp = false;
            orderTime = iTime(_Symbol, TimeFrame, 1);

        }
        else if (berakOutDown && close > asiaLow)
        {
            trade.Buy(LotSize,_Symbol,0,buySl,buyTp);
            berakOutDown = false;
            orderTime = iTime(_Symbol, TimeFrame, 1);
        }
    }
}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 LondonBreakOut移除");
}

// 获取 从0点到指定时间的范围内的最高价或者最低价
// 获取从指定时间范围内的最高价或最低价
double GetHighestLowestPrice(ENUM_SERIESMODE priceType)
{
    MqlDateTime currentTimeStruct;
    TimeToStruct(TimeCurrent(), currentTimeStruct);

    // 计算从 startTime 开始的秒数
    int secondsSinceStart = (currentTimeStruct.hour) * 3600 + currentTimeStruct.min * 60 + currentTimeStruct.sec;

    // 时间框架的秒数
    int secondsTimeFrame[21] = {
        60,     // PERIOD_M1: 1 minute
        120,    // PERIOD_M2: 2 minutes
        180,    // PERIOD_M3: 3 minutes
        240,    // PERIOD_M4: 4 minutes
        300,    // PERIOD_M5: 5 minutes
        360,    // PERIOD_M6: 6 minutes
        600,    // PERIOD_M10: 10 minutes
        720,    // PERIOD_M12: 12 minutes
        900,    // PERIOD_M15: 15 minutes
        1200,   // PERIOD_M20: 20 minutes
        1800,   // PERIOD_M30: 30 minutes
        3600,   // PERIOD_H1: 1 hour
        7200,   // PERIOD_H2: 2 hours
        10800,  // PERIOD_H3: 3 hours
        14400,  // PERIOD_H4: 4 hours
        21600,  // PERIOD_H6: 6 hours
        28800,  // PERIOD_H8: 8 hours
        43200,  // PERIOD_H12: 12 hours
        86400,  // PERIOD_D1: 1 day
        604800, // PERIOD_W1: 1 week
        2592000 // PERIOD_MN1: 1 month
    };

    // 获取当前时间框架对应的秒数
    int timeframeIndex = ArrayBsearch(secondsTimeFrame, PeriodSeconds());
    if (timeframeIndex == -1)
    {
        Print("无法匹配当前时间框架的秒数");
        return 0;
    }
    int period_seconds = secondsTimeFrame[timeframeIndex];
    datetime currentTime = TimeCurrent();
    Print("✔️[LondonBreakOut.mq5:165]: currentTime: ", currentTime);

    // 计算有多少根K线
    int barsCount = secondsSinceStart / period_seconds;
    if (barsCount <= 0)
    {
        Print("指定时间范围内没有有效的K线");
        return 0;
    }

    // 获取最高价或最低价
    double price = 0;
    int index1 = 0;
    int index2 = 0;

    switch (priceType)
    {
    case MODE_OPEN:
        index1 = iHighest(_Symbol, _Period, MODE_OPEN, barsCount, 1);
        index2 = iHighest(_Symbol, _Period, MODE_CLOSE, barsCount, 1);
        price = iOpen(_Symbol, _Period, index1);
        price = iClose(_Symbol, _Period, index2) > price ? iOpen(_Symbol, _Period, index2) : price;
        break;

    case MODE_CLOSE:
        index1 = iLowest(_Symbol, _Period, MODE_CLOSE, barsCount, 1);
        index2 = iLowest(_Symbol, _Period, MODE_OPEN, barsCount, 1);
        price = iClose(_Symbol, _Period, index1);
        price = iOpen(_Symbol, _Period, index2) < price ? iClose(_Symbol, _Period, index2) : price;
        break;

    case MODE_HIGH:
        index1 = iHighest(_Symbol, _Period, MODE_HIGH, barsCount, 1);
        price = iHigh(_Symbol, _Period, index1);
        break;

    case MODE_LOW:
        index1 = iLowest(_Symbol, _Period, MODE_LOW, barsCount, 1);
        price = iLow(_Symbol, _Period, index1);
        break;

    default:
        Print("仅支持最高价或最低价模式");
        return 0;
    }

    return price;
};

datetime GetStartHourTime(int startHour)
{
    // 验证输入的小时是否有效
    if (startHour < 0 || startHour > 23)
    {
        Print("startHour 参数无效，应在 0 到 23 之间");
        return 0;
    }

    // 获取当前时间
    datetime currentTime = TimeCurrent();
    // 每天的总秒数
    int secondsInDay = 86400;

    // 计算当天午夜时间戳
    datetime midnight = currentTime - (currentTime % secondsInDay);

    // 加上指定的小时数对应的秒数
    datetime startTime = midnight + startHour * 3600;

    return startTime;
}
