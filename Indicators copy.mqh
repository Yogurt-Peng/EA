class CIndicator
{
protected:
    int m_handle;
    string m_symbol;
    ENUM_TIMEFRAMES m_timeFrame;

    virtual int CreateHandle() = 0; // 纯虚方法，由子类实现

public:
    CIndicator(string symbol, ENUM_TIMEFRAMES timeFrame) : m_handle(INVALID_HANDLE), m_symbol(symbol), m_timeFrame(timeFrame) {}
    virtual ~CIndicator() {}

    bool Initialize()
    {
        m_handle = CreateHandle();
        return (m_handle != INVALID_HANDLE);
    }

    virtual double GetValue(int index) = 0;
};


// RSI 指标类
class CRSI : public CIndicator
{
private:
    int m_value;
    double bufferValue[];

protected:
    int CreateHandle() override
    {
        ArraySetAsSeries(bufferValue, true);
        return iRSI(m_symbol, m_timeFrame, m_value, PRICE_CLOSE);
    }

public:
    CRSI(string symbol, ENUM_TIMEFRAMES timeFrame, int rsiValue)
        : CIndicator(symbol, timeFrame), m_value(rsiValue) {}

    double GetValue(int index) override
    {
        CopyBuffer(m_handle, 0, index, 1, bufferValue);
        return bufferValue[0];
    }
};

// 布林带指标类
class CBollingerBands : public CIndicator
{
private:
    int m_value;
    int m_deviation;
    double bufferValue[];

protected:
    int CreateHandle() override
    {
        ArraySetAsSeries(bufferValue, true);
        return iBands(m_symbol, m_timeFrame, m_value, 0, m_deviation, PRICE_CLOSE);
    }

public:
    CBollingerBands(string symbol, ENUM_TIMEFRAMES timeFrame, int bbValue, int bbDeviation)
        : CIndicator(symbol, timeFrame), m_value(bbValue), m_deviation(bbDeviation) {}

    double GetValue(int bufferIndex, int index)
    {
        CopyBuffer(m_handle, bufferIndex, index, 1, bufferValue);
        return bufferValue[0];
    }
};

// 移动平均线类
class CMA : public CIndicator
{
private:
    int m_value;
    ENUM_MA_METHOD m_method;
    double bufferValue[];

protected:
    int CreateHandle() override
    {
        ArraySetAsSeries(bufferValue, true);
        return iMA(m_symbol, m_timeFrame, m_value, 0, m_method, PRICE_CLOSE);
    }

public:
    CMA(string symbol, ENUM_TIMEFRAMES timeFrame, int maValue, ENUM_MA_METHOD maMethod)
        : CIndicator(symbol, timeFrame), m_value(maValue), m_method(maMethod) {}

    double GetValue(int index) override
    {
        CopyBuffer(m_handle, 0, index, 1, bufferValue);
        return bufferValue[0];
    }
};



// ATR 指标类
class CATR : public CIndicator
{
private:
    int m_atrValue;
    double bufferValue[];

protected:
    int CreateHandle() override
    {
        ArraySetAsSeries(bufferValue, true);
        return iATR(m_symbol, m_timeFrame, m_atrValue);
    }

public:
    CATR(string symbol, ENUM_TIMEFRAMES timeFrame, int atrValue)
        : CIndicator(symbol, timeFrame), m_atrValue(atrValue) {}

    double GetValue(int index) override
    {
        CopyBuffer(m_handle, 0, index, 1, bufferValue);
        return bufferValue[0];
    }
};
// MFI 指标类
class CMFI : public CIndicator
{
private:
    int m_value;
    double bufferValue[];

public:
    CMFI(string symbol, ENUM_TIMEFRAMES timeFrame, int rsiValue) : CIndicator(symbol, timeFrame), m_value(rsiValue) {};

    CMFI::~CMFI() {}

    // 获取当前K线的前一个指标当前值
    double GetValue(int index)
    {
        CopyBuffer(m_handle, 0, index, 1, bufferValue);
        return bufferValue[0];
    }
};

class CHeiKenAshi : public CIndicator
{
private:
    double bufferValue[];


protected:
    int CreateHandle() override
    {
        ArraySetAsSeries(bufferValue, true);
        return iCustom(m_symbol, m_timeFrame,  "Examples\\Heiken_Ashi.ex5");
    }


public:
    CHeiKenAshi(string symbol, ENUM_TIMEFRAMES timeFrame) : CIndicator(symbol, timeFrame) {};
    ~CHeiKenAshi() {};

    // Opne High Close Low
    double GetValue(int index)
    {
        CopyBuffer(m_handle, index, 1, 1, bufferValue);
        return bufferValue[0];
    }

    void GetValues(int number, double &open[], double &high[], double &low[], double &close[])
    {
        for( int i = 0; i < number; i++)
        {
            CopyBuffer(m_handle, 0, i+1, 1, bufferValue);
            open[i] = bufferValue[0];
            CopyBuffer(m_handle, 1, i+1, 1, bufferValue);
            high[i] = bufferValue[0];
            CopyBuffer(m_handle, 2, i+1, 1, bufferValue);
            low[i] = bufferValue[0];
            CopyBuffer(m_handle, 3, i+1, 1, bufferValue);
            close[i] = bufferValue[0];
        }

    }
};
// Pivots 类
class CPivots : public CIndicator
{
private:
    int m_calcMode;
    ENUM_TIMEFRAMES m_pivotTimeFrame;
    double bufferValue[];

protected:
    int CreateHandle() override
    {
        ArraySetAsSeries(bufferValue, true);
        return iCustom(m_symbol, m_timeFrame, "Wait_Indicators\\All Pivot Points", m_pivotTimeFrame, m_calcMode);
    }

public:
    CPivots(string symbol, ENUM_TIMEFRAMES timeFrame, ENUM_TIMEFRAMES pivotTimeFrame = PERIOD_D1, int calcMode = 0)
        : CIndicator(symbol, timeFrame), m_calcMode(calcMode), m_pivotTimeFrame(pivotTimeFrame) {}

    double GetValue(int index) override
    {
        CopyBuffer(m_handle, index, 1, 1, bufferValue);
        return bufferValue[0];
    }
};


class CDonchian : public CIndicator
{
private:
    int m_donchianValue;
    double bufferValue[];
protected:
    int CreateHandle() override
    {
        ArraySetAsSeries(bufferValue, true);
        return iCustom(m_symbol, m_timeFrame, "Wait_Indicators\\donchian_channel", m_donchianValue);
    }

public:
    CDonchian(string symbol, ENUM_TIMEFRAMES timeFrame, int donchianValue) : CIndicator(symbol, timeFrame), m_donchianValue(donchianValue) {};
    ~CDonchian() {};

    double GetValue(int index)
    {
        CopyBuffer(m_handle, index, 1, 1, bufferValue);

        return bufferValue[0];
    }

};
