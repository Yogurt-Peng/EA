#include "Tools.mqh"
#include "Indicators.mqh"
#include "Draw.mqh"

// 基本参数
input group "基本参数";
input int MagicNumber = 555245;                   // EA编号 (专家交易系统编号)
input ENUM_TIMEFRAMES TimeFrame = PERIOD_CURRENT; // 交易周期
input double LotSize = 0.01;                      // 交易手数
input int GridNumber = 4;                         // 网格数量
input int GridDistance = 100;                     // 网格间距（以点数为单位）

// 声明交易和工具对象
CTrade trade;
CTools tools(_Symbol, &trade);
CDraw draw;

// 跟踪基础价格和当前网格层级的变量
double basePrice = 0;     // 起始价格
int currentGridLevel = 0; // 当前网格层级
int currentMode = -1;     // 当前模式（0：等待买入，1：等待卖出）

// 初始化策略的函数
int OnInit()
{
    trade.SetExpertMagicNumber(MagicNumber); // 设置交易的MagicNumber

    // 将初始基准价格设为当前买价
    basePrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    return (INIT_SUCCEEDED);
}

int loopBars = 0;

// 每个行情更新时调用的函数
void OnTick()
{
    // 检查是否在指定时间周期内生成了新K线
    if (!tools.IsNewBar(PERIOD_M1))
        return;
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

    double buyTp = ask + GridDistance*Point();
    double sellTp = bid -GridDistance*Point();


    double gridSellPrice[10];
    double gridBuyPrice[10];
    for (int i = 1; i < GridNumber; i++)
    {
        gridSellPrice[i] = basePrice + i * GridDistance;
    }
    for (int i = 1; i < GridNumber; i++)
    {
        gridBuyPrice[i] = basePrice - i * GridDistance;
    }


    if (currentMode == -1)
    {
        if (bid > gridSellPrice[0])
        {
            trade.Sell(LotSize,_Symbol,bid,0,sellTp);
            currentMode = 1;
            currentGridLevel = 1;
        }
        else if (ask < gridBuyPrice[0])
        {
            currentMode = 0;
            currentGridLevel = 1;
            trade.Buy(LotSize,_Symbol,ask,0,buyTp);
        }
    }

    if( currentMode ==0)
    {
        if (bid > gridSellPrice[1] && currentGridLevel==1)
        {
            trade.Sell(LotSize,_Symbol,bid,0,sellTp);
            currentGridLevel = 2;
        }
        if (bid > gridSellPrice[2] && currentGridLevel==2)
        {
            trade.Sell(LotSize,_Symbol,bid,0,sellTp);
            currentGridLevel = 3;
        }

        if (bid > gridSellPrice[3] && currentGridLevel==3)
        {
            trade.Sell(LotSize,_Symbol,bid,0,sellTp);
            currentGridLevel = 4;
        }


    }

  
}
