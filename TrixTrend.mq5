#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 1756;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input int LotType = 2;                            // 1:固定手数,2:固定百分比
input double LotSize = 0.01;                      // 手数
input double Percent = 1;                         // 百分比 1%
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 180;                       // 止盈点数 0:不使用

//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleTrix;
double bufferTrixValue[];
double bufferSignalValue[];


//+------------------------------------------------------------------+

int OnInit()
{

    handleTrix=iCustom(_Symbol,TimeFrame,"Wait_Indicators\\TRIX",14,MODE_SMA,MODE_SMA,MODE_SMA,9,MODE_SMA,PRICE_CLOSE);
    ArraySetAsSeries(bufferTrixValue,true);
    ArraySetAsSeries(bufferSignalValue,true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");
    
    return INIT_SUCCEEDED;
}


void OnTick()
{
    if(!tools.IsNewBar(TimeFrame))
        return;
    CopyBuffer(handleTrix, 0, 1, 2, bufferTrixValue);
    CopyBuffer(handleTrix, 1, 1, 2, bufferSignalValue);
    Print("✔️[TrixTrend.mq5:45]: bufferTrixValue[0]: ", bufferSignalValue[0]);
    Print("✔️[TrixTrend.mq5:46]: bufferTrixValue[1]: ", bufferSignalValue[1]);

    // 零轴下死叉
    if (bufferTrixValue[0] < 0 && bufferTrixValue[1] < 0 && bufferSignalValue[0] < 0 && bufferSignalValue[1] <0) {
        // Trix上穿信号线
        if (bufferSignalValue[0] < bufferTrixValue[0] && bufferSignalValue[1] > bufferTrixValue[1])
        {
            tools.CloseAllPositions(MagicNumber,POSITION_TYPE_SELL);
            trade.Buy(LotSize);    

        }
    }

    // 零轴上金叉
    if (bufferTrixValue[0] > 0 && bufferTrixValue[1] > 0 && bufferSignalValue[0] > 0 && bufferSignalValue[1] >0) {
        // Trix下穿信号线
        if (bufferSignalValue[0] > bufferTrixValue[0] && bufferSignalValue[1] < bufferTrixValue[1])
        {
            tools.CloseAllPositions(MagicNumber,POSITION_TYPE_BUY);
            trade.Sell(LotSize);
        }
    }
    

}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 EA移除");
}
