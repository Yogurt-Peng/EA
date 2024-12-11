

class CIndicator
{
protected:
    int m_handle;                // 指标句柄
    string m_symbol;             // 交易品种
    ENUM_TIMEFRAMES m_timeFrame; // 时间周期
public:
    CIndicator(string symbol, ENUM_TIMEFRAMES timeFrame) : m_handle(INVALID_HANDLE), m_symbol(symbol), m_timeFrame(timeFrame) {};
    virtual ~CIndicator(){};

    // 获取指标句柄
    int GetHandle() { return m_handle; }
};

class CRSI : public CIndicator
{
private:
    int m_value;
    double bufferValue[];

public:
    CRSI(string symbol, ENUM_TIMEFRAMES timeFrame, int rsiValue) : CIndicator(symbol, timeFrame), m_value(rsiValue) {};

    CRSI::~CRSI() {}

    // 初始化RSI指标，获取指标句柄
    bool Initialize()
    {
        ArraySetAsSeries(bufferValue, true);
        m_handle = iRSI(m_symbol, m_timeFrame, m_value, PRICE_CLOSE);
        return (m_handle != INVALID_HANDLE);
    }

    // 获取当前K线的前一个指标当前值
    double GetValue(int index)
    {
        CopyBuffer(m_handle, 0, index, 1, bufferValue);
        return bufferValue[0];
    }
};

class CBollingerBands : public CIndicator
{
private:
    int m_value;
    int m_deviation;
    double bufferValue[];

public:
    CBollingerBands(string symbol, ENUM_TIMEFRAMES timeFrame, int bbValue, int bbDeviation) : CIndicator(symbol, timeFrame), m_value(bbValue), m_deviation(bbDeviation) {};
    ~CBollingerBands(){};

    // 初始化布林带指标，获取指标句柄
    bool Initialize()
    {
        m_handle = iBands(m_symbol, m_timeFrame, m_value, 0, m_deviation, PRICE_CLOSE);
        ArraySetAsSeries(bufferValue, true);
        return (m_handle != INVALID_HANDLE);
    }

    // 获取布林带指标特定缓冲区（比如上轨、中轨、下轨等）的值，传入缓冲区索引参数
    double GetValue(int bufferIndex, int index)
    {
        CopyBuffer(m_handle, bufferIndex, index, 1, bufferValue);
        return bufferValue[0];
    }
};

class CMA : public CIndicator
{
private:
    int m_value;
    ENUM_MA_METHOD m_method;
    double bufferValue[];

public:
    CMA(string symbol, ENUM_TIMEFRAMES timeFrame, int maValue, ENUM_MA_METHOD maMethod) : CIndicator(symbol, timeFrame), m_value(maValue), m_method(maMethod) {};
    ~CMA(){};

    // 初始化移动平均线指标，获取指标句柄
    bool Initialize()
    {
        m_handle = iMA(m_symbol, m_timeFrame, m_value, 0, m_method, PRICE_CLOSE);
        ArraySetAsSeries(bufferValue, true);

        return (m_handle != INVALID_HANDLE);
    }

    // 获取移动平均线指标当前值
    double GetValue(int index)
    {
        CopyBuffer(m_handle, 0, index, 1, bufferValue);
        return bufferValue[0];
    }
};