from flask import Flask, render_template, request, jsonify
import pandas as pd
import yfinance as yf
import matplotlib.pyplot as plt
import mplfinance as mpf
from io import BytesIO
import base64
from datetime import datetime
import logging
import sys
import os
import numpy as np

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Ensure the matplotlib backend is set to Agg for non-GUI environments
plt.switch_backend('Agg')

app = Flask(__name__)

# Enable subdirectory support
app.config['APPLICATION_ROOT'] = '/D8TAVu'

@app.route('/D8TAVu')
@app.route('/D8TAVu/')
@app.route('/')
def home():
    logger.info('Accessing home page')
    return render_template('index.html')

@app.route('/D8TAVu/health')
@app.route('/health')
def health():
    logger.info('Health check endpoint accessed')
    return {'status': 'healthy'}, 200

@app.route('/D8TAVu/stock-data', methods=['POST'])
def get_stock_data():
    logger.info('Stock data endpoint accessed')
    try:
        data = request.get_json()
        logger.debug(f'Received data: {data}')
        
        # Extract parameters
        ticker = data.get('ticker')
        start_date = data.get('startDate')
        end_date = data.get('endDate')
        plot_type = data.get('plotType', 'line')
        show_ma = data.get('showMA', False)
        show_volume = data.get('showVolume', False)
        ma_period = int(data.get('maPeriod', 20))

        # Input validation
        if not all([ticker, start_date, end_date]):
            logger.error('Missing required parameters')
            return jsonify({'error': 'Missing required parameters'}), 400

        # Convert dates to datetime objects
        try:
            # Parse dates in YYYY-MM-DD format
            start_date = pd.to_datetime(start_date)
            end_date = pd.to_datetime(end_date)
        except ValueError as e:
            logger.error(f'Invalid date format: {e}')
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400

        # Get stock data
        logger.info(f'Fetching stock data for {ticker} from {start_date} to {end_date}')
        try:
            stock = yf.Ticker(ticker)
            hist = stock.history(start=start_date, end=end_date)
            
            if hist.empty:
                logger.warning(f'No data found for {ticker}')
                return jsonify({'error': 'No data found for the specified stock and date range'}), 404

            # Convert DataFrame to dictionary with date strings as keys
            hist_dict = hist.to_dict('index')
            formatted_data = {
                k.strftime('%Y-%m-%d'): {
                    'Close': float(v['Close']),
                    'Volume': int(v['Volume']) if show_volume else None,
                    'MA': float(v['MA']) if show_ma and 'MA' in v else None
                }
                for k, v in hist_dict.items()
            }

            # Calculate moving average if requested
            if show_ma:
                hist['MA'] = hist['Close'].rolling(window=ma_period).mean()

            # Create plot based on type
            logger.info(f'Creating {plot_type} plot')
            
            if plot_type in ['candlestick', 'ohlc']:
                # Use mplfinance for candlestick/OHLC charts
                fig, axes = mpf.plot(
                    hist,
                    type='candle' if plot_type == 'candlestick' else 'ohlc',
                    volume=show_volume,
                    style='yahoo',
                    title=f'{ticker} Stock Price',
                    ylabel='Price ($)',
                    ylabel_lower='Volume' if show_volume else '',
                    returnfig=True
                )
                
                # Add moving average if requested
                if show_ma:
                    ax = axes[0]
                    ax.plot(hist.index, hist['MA'], label=f'{ma_period}-day MA', color='red')
                    ax.legend()
            
            else:  # Line plot
                fig, ax1 = plt.subplots(figsize=(12, 8))
                
                # Plot price
                ax1.plot(hist.index, hist['Close'], label='Close Price', color='blue')
                
                if show_ma:
                    ax1.plot(hist.index, hist['MA'], label=f'{ma_period}-day MA', color='red')
                
                ax1.set_title(f'{ticker} Stock Price')
                ax1.set_xlabel('Date')
                ax1.set_ylabel('Price ($)')
                ax1.grid(True)
                ax1.legend()
                
                # Add volume subplot if requested
                if show_volume:
                    ax2 = ax1.twinx()
                    ax2.bar(hist.index, hist['Volume'], alpha=0.3, color='gray')
                    ax2.set_ylabel('Volume')
                    
                plt.tight_layout()

            # Save plot to base64 string
            buffer = BytesIO()
            plt.savefig(buffer, format='png', dpi=300, bbox_inches='tight')
            buffer.seek(0)
            image_base64 = base64.b64encode(buffer.getvalue()).decode()
            plt.close()

            logger.info('Successfully generated plot')
            return jsonify({
                'plot': image_base64,
                'data': formatted_data
            })

        except Exception as e:
            logger.error(f'Error fetching stock data: {str(e)}', exc_info=True)
            return jsonify({'error': str(e)}), 500

    except Exception as e:
        logger.error(f'Error processing request: {str(e)}', exc_info=True)
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
