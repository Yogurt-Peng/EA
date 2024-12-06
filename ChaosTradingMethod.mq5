#include "Tools.mqh"
input group "基本参数";
input int MagicNumber = 7456;                     // EA编号
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 周期
input double LotSize = 0.01;                      // 手数
input int StopLoss = 100;                         // 止损点数 0:不使用
input int TakeProfit = 100;                       // 止盈点数 0:不使用

input group "指标参数";
input bool UseFractal = true; // 分型
input bool UseJaws1 = true;   // 鳄鱼线1
input bool UseJaws2 = true;   // 鳄鱼线2
input bool UseAC = true;      // 加速

//+------------------------------------------------------------------+

CTrade trade;
COrderInfo orderInfo;
CPositionInfo positionInfo;
CTools tools(_Symbol, &trade, &positionInfo, &orderInfo);

int handleFractals;  // 分型
int handleAlligator; // 鳄鱼线
int handleAO;        // 动量
int handleAC;        // 加速

double bufferFractalsUp[];
double bufferFractalsDown[];
double bufferAlligatorJaws[];
double bufferAlligatorTeeth[];
double bufferAlligatorLips[];
double bufferAO[];
double bufferAC[];

//+------------------------------------------------------------------+
int OnInit()
{
    handleFractals = iFractals(_Symbol, TimeFrame);
    if (handleFractals == INVALID_HANDLE)
    {
        Alert("iFractals 指标加载失败，请检查相关设定是否合理，或者检查您的mt5是否包含相关指标");
        return (INIT_FAILED);
    }

    handleAlligator = iAlligator(_Symbol, TimeFrame, 13, 8, 8, 5, 5, 3, MODE_SMMA, PRICE_MEDIAN);
    if (handleAlligator == INVALID_HANDLE)
    {
        Alert("handleAlligator 指标加载失败，请检查相关参数设定是否合理，或者检查您的mt5是否有对应的指标存在");
        return (INIT_FAILED);
    }

    handleAO = iAO(_Symbol, TimeFrame);
    if (handleAO == INVALID_HANDLE)
    {
        Alert("iAO 指标加载失败，请检查相关参数设定是否合理，或者检查您的mt5是否有对应的指标存在");
        return (INIT_FAILED);
    }

    handleAC = iAC(_Symbol, TimeFrame);
    if (handleAC == INVALID_HANDLE)
    {
        Alert("iAC 指标加载失败，请检查相关参数设定是否合理，或者检查您的mt5是否有对应的指标存在");
        return (INIT_FAILED);
    }

    ChartIndicatorAdd(0, 0, handleFractals);
    ChartIndicatorAdd(0, 0, handleAlligator);
    ChartIndicatorAdd(0, 1, handleAC);
    ChartIndicatorAdd(0, 2, handleAO);

    ArraySetAsSeries(bufferFractalsUp, true);
    ArraySetAsSeries(bufferFractalsDown, true);
    ArraySetAsSeries(bufferAlligatorJaws, true);
    ArraySetAsSeries(bufferAlligatorTeeth, true);
    ArraySetAsSeries(bufferAlligatorLips, true);
    ArraySetAsSeries(bufferAO, true);
    ArraySetAsSeries(bufferAC, true);

    trade.SetExpertMagicNumber(MagicNumber);
    Print("🚀🚀🚀 初始化成功");
    return INIT_SUCCEEDED;
}

void OnTick()
{

    if (CopyBuffer(handleFractals, 0, 3, 1, bufferFractalsUp) < 1)
    {
        Print("CopyBuffer bufferFractalsUp 错误");
        return;
    }

    if (CopyBuffer(handleFractals, 1, 3, 1, bufferFractalsDown) < 1)
    {
        Print("CopyBuffer bufferFractalsDown 错误");
        return;
    }

    if (CopyBuffer(handleAlligator, 0, 0, 3, bufferAlligatorJaws) < 3)
    {
        Print("CopyBuffer bufferAlligatorJaws 错误");
        return;
    }

    if (CopyBuffer(handleAlligator, 1, 0, 3, bufferAlligatorTeeth) < 3)
    {
        Print("CopyBuffer bufferAlligatorTeeth 错误");
        return;
    }

    if (CopyBuffer(handleAlligator, 2, 0, 3, bufferAlligatorLips) < 3)
    {
        Print("CopyBuffer bufferAlligatorLips 错误");
        return;
    }

    if (CopyBuffer(handleAO, 0, 0, 3, bufferAO) < 3)
    {
        Print("CopyBuffer bufferAO 错误");
        return;
    }
    // 获取颜色 1:绿 0:红
    if (CopyBuffer(handleAC, 1, 0, 3, bufferAC) < 3)
    {
        Print("CopyBuffer bufferAC 错误");
        return;
    }

    if (tools.IsNewBar(TimeFrame))
    {

        // 分型
        bool sigSell = false;
        bool sigBuy = false;
        if (UseFractal)
        {
            if (bufferFractalsUp[0] != EMPTY_VALUE)
                sigSell = true;
            if (bufferFractalsDown[0] != EMPTY_VALUE)
                sigBuy = true;
        }
        else
        {
            sigSell = false;
            sigBuy = false;
        }
        // 鳄鱼线
        bool sigJawBuy1 = false;
        bool sigJawSell1 = false;
        if (UseJaws1)
        {
            if (iClose(_Symbol, TimeFrame, 1) > bufferAlligatorJaws[1])
                sigJawBuy1 = true;
            if (iClose(_Symbol, TimeFrame, 1) < bufferAlligatorJaws[1])
                sigJawSell1 = true;
        }
        else
        {
            sigJawBuy1 = true;
            sigJawSell1 = true;
        }

        bool sigJawBuy2 = false;
        bool sigJawSell2 = false;
        if (UseJaws2)
        {   
            if (iClose(_Symbol, TimeFrame, 2) < bufferAlligatorJaws[2] && iClose(_Symbol, TimeFrame, 1) > bufferAlligatorJaws[1])
                sigJawBuy2 = true;
            if (iClose(_Symbol, TimeFrame, 2) > bufferAlligatorJaws[2] && iClose(_Symbol, TimeFrame, 1) < bufferAlligatorJaws[1])
                sigJawSell2 = true;
        }
        else
        {
            sigJawBuy2 = true;
            sigJawSell2 = true;
        }

        // AO
        bool sigAOBuy = bufferAO[1] > 0 && bufferAO[2] < 0;
        bool sigAOSell = bufferAO[1] < 0 && bufferAO[2] > 0;

        // AC
        bool sigAcBuy = false;
        bool sigAcSell = false;
        if (UseAC)
        {
            if (bufferAC[1] == 0)
                sigAcBuy = true;
            if (bufferAC[1] == 1)
                sigAcSell = true;
        }
        else
        {
            sigAcBuy = true;
            sigAcSell = true;
        }

        if (sigBuy && sigJawBuy1 && sigJawBuy2 && sigAcBuy && sigAOBuy)
        {
            trade.Buy(LotSize);
        }

        if (sigSell && sigJawSell1 && sigJawSell2 && sigAcSell && sigAOSell)
        {
            trade.Sell(LotSize);
        }

        if (sigAOSell)
        {
            Print("close all buy");
            tools.CloseAllPositions(MagicNumber, POSITION_TYPE_BUY);
        }

        if (sigAOBuy)
        {
            Print("close all sell");
            tools.CloseAllPositions(MagicNumber, POSITION_TYPE_SELL);

        }
    }
}

void OnDeinit(const int reason)
{
    Print("🚀🚀🚀 EA移除");
}
