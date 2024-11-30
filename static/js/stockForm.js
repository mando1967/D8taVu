// StockForm Component
const StockForm = () => {
    const [ticker, setTicker] = React.useState('');
    const [startDate, setStartDate] = React.useState('');
    const [endDate, setEndDate] = React.useState('');
    const [plotImage, setPlotImage] = React.useState('');
    const [error, setError] = React.useState('');
    const [loading, setLoading] = React.useState(false);
    const [plotType, setPlotType] = React.useState('line');
    const [showMA, setShowMA] = React.useState(false);
    const [showVolume, setShowVolume] = React.useState(false);
    const [maPeriod, setMaPeriod] = React.useState(20);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setLoading(true);
        try {
            const response = await fetch('/D8TAVu/stock-data', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    ticker,
                    startDate,
                    endDate,
                    plotType,
                    showMA,
                    showVolume,
                    maPeriod
                })
            });
            
            const data = await response.json();
            
            if (response.ok) {
                setPlotImage(`data:image/png;base64,${data.plot}`);
            } else {
                setError(data.error || 'Failed to fetch stock data');
            }
        } catch (error) {
            setError('An error occurred while fetching the data');
            console.error('Error:', error);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="container">
            <h1>Stock Data Visualization</h1>
            <form onSubmit={handleSubmit}>
                <div className="form-group">
                    <label>Ticker Symbol:</label>
                    <input
                        type="text"
                        value={ticker}
                        onChange={(e) => setTicker(e.target.value.toUpperCase())}
                        placeholder="e.g., AAPL"
                        required
                    />
                </div>
                <div className="form-group">
                    <label>Start Date:</label>
                    <input
                        type="date"
                        value={startDate}
                        onChange={(e) => setStartDate(e.target.value)}
                        required
                    />
                </div>
                <div className="form-group">
                    <label>End Date:</label>
                    <input
                        type="date"
                        value={endDate}
                        onChange={(e) => setEndDate(e.target.value)}
                        required
                    />
                </div>
                <div className="form-group">
                    <label>Plot Type:</label>
                    <select value={plotType} onChange={(e) => setPlotType(e.target.value)}>
                        <option value="line">Line</option>
                        <option value="candlestick">Candlestick</option>
                        <option value="ohlc">OHLC</option>
                    </select>
                </div>
                <div className="form-group">
                    <label>
                        <input
                            type="checkbox"
                            checked={showMA}
                            onChange={(e) => setShowMA(e.target.checked)}
                        />
                        Show Moving Average
                    </label>
                    {showMA && (
                        <input
                            type="number"
                            value={maPeriod}
                            onChange={(e) => setMaPeriod(parseInt(e.target.value))}
                            min="1"
                            max="200"
                            placeholder="MA Period"
                            className="ma-period-input"
                        />
                    )}
                </div>
                <div className="form-group">
                    <label>
                        <input
                            type="checkbox"
                            checked={showVolume}
                            onChange={(e) => setShowVolume(e.target.checked)}
                        />
                        Show Volume
                    </label>
                </div>
                <button type="submit" disabled={loading}>
                    {loading ? 'Loading...' : 'Generate Plot'}
                </button>
            </form>
            
            {error && <div className="error">{error}</div>}
            
            {plotImage && (
                <div id="plot-container">
                    <img src={plotImage} alt="Stock Plot" style={{width: '100%'}} />
                </div>
            )}
        </div>
    );
};

// Render the app
ReactDOM.render(<StockForm />, document.getElementById('root'));
