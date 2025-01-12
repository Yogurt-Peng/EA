#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

input group "基本参数";
input int MagicNumber = 46151;                // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input int LotType = 2;                            // 1:固定手数,2:固定百分比
input double LotSize = 0.01;                      // 手数
input double Percent = 1;                         // 百分比 1%
input int KAMAValue = 14;                     // KAMA指标值
input int FastEMAValue = 2;                   // 快速EMA
input int SlowEMAValue = 20;                  // 慢速EMA
input double EntryFilter = 1;                 // 进场过滤
input double ExitFilter = 0.5;                // 出场过滤

// 有盈利可能，但是品种要趋势好

CATR ATR(_Symbol, TimeFrame, 14);
CAMA AMA(_Symbol, TimeFrame, KAMAValue, FastEMAValue, SlowEMAValue);
CTrade trade;
CTools tools(_Symbol, &trade);
CDraw draw;

// 初始化函数
int OnInit()
{
    AMA.Initialize();
    ATR.Initialize();
    ChartIndicatorAdd(0, 0, AMA.GetHandle());
    ChartIndicatorAdd(0, 1, ATR.GetHandle());
    trade.SetExpertMagicNumber(MagicNumber); // 设置交易的MagicNumber
    return(INIT_SUCCEEDED);
}

// 辅助函数，检查值是否接近零（在一定的容差范围内）
bool IsZero(double val, double eps) {
   return MathAbs(val) <= eps;
}

// 计算和的函数，按照特定条件处理
double SUM(double fst, double snd) {
    double EPS = 1e-10;
    double res = fst + snd;
    if (IsZero(res, EPS)) {
        return 0;
    } else {
        return res;
    }
}

// 计算标准差的函数，接收一个数据数组和长度参数
double Stdev(const double &src[], int length) {
    // 计算简单移动平均（SMA）
    double avg = 0.0;
    for (int i = 0; i < length; i++) {
        avg += src[i];
    }
    avg /= length;

    // 计算平方偏差的总和
    double sumOfSquareDeviations = 0.0;
    for (int i = 0; i < length; i++) {
        double sum = SUM(src[i], -avg);
        sumOfSquareDeviations += sum * sum;
    }

    // 计算标准差
    return MathSqrt(sumOfSquareDeviations / length);
}


void OnTick()
{
    if (!tools.IsNewBar(TimeFrame))
        return;
    double AMAValueBuffer[];
    ArraySetAsSeries(AMAValueBuffer, true);
    AMA.GetValues(KAMAValue*3,AMAValueBuffer);

    for(int i = 0; i < KAMAValue*3-1; i++)
    {
        AMAValueBuffer[i]=AMAValueBuffer[i]-AMAValueBuffer[i+1];
    }

    double entryMAAF = EntryFilter*Stdev(AMAValueBuffer,KAMAValue);
    double exitMAAF = ExitFilter*Stdev(AMAValueBuffer,KAMAValue);


    bool longCondition = AMAValueBuffer[0] > 0 && AMAValueBuffer[0]  > entryMAAF;
    bool longClose = AMAValueBuffer[0] < 0 && MathAbs( AMAValueBuffer[0])>entryMAAF;

    bool shortCondition = AMAValueBuffer[0] < 0 && AMAValueBuffer[0] < -entryMAAF;
    bool shortClose = AMAValueBuffer[0] > 0 && MathAbs( AMAValueBuffer[0])>entryMAAF;

    if(longCondition && tools.GetPositionCount(MagicNumber) == 0)
    {
        double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double lotSize=LotType==1?LotSize:tools.CalcLots(ask,ask-ATR.GetValue(1),Percent);
        trade.Buy(lotSize);
    }
    else if(longClose)
    {
        tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY);
    }

    if(shortCondition && tools.GetPositionCount(MagicNumber) == 0)
    {
        double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double lotSize=LotType==1?LotSize:tools.CalcLots(bid,ATR.GetValue(1)+bid,Percent);
        trade.Sell(lotSize);
    }
    else if(shortClose)
    {
        tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL);
    }

}

