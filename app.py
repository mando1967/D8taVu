import os
import sys
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
from flask import Flask, render_template, request, send_file, jsonify, send_from_directory, abort, url_for, redirect, Response
from werkzeug.security import check_password_hash
from werkzeug.utils import secure_filename
from functools import wraps
from file_manager import FileManager
import matplotlib
matplotlib.use('Agg')
import pandas as pd
import yfinance as yf
import matplotlib.pyplot as plt
import mplfinance as mpf
from io import BytesIO
import base64
from pathlib import Path

# Configure logging
log_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'app.log')
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        RotatingFileHandler(log_file, maxBytes=1024*1024, backupCount=5),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['APPLICATION_ROOT'] = '/D8TAVu'

# Initialize FileManager with the user files directory
USER_FILES_PATH = "C:/Users/a-gon/OneDrive/Documents"
VIRTUAL_DIR_URL = "/D8TAVu/share"
try:
    # Ensure the directory exists
    if not os.path.exists(USER_FILES_PATH):
        logger.error(f"User files directory does not exist: {USER_FILES_PATH}")
        raise ValueError(f"User files directory does not exist: {USER_FILES_PATH}")
    
    logger.info(f"Initializing FileManager with USER_FILES_PATH: {USER_FILES_PATH}")
    file_manager = FileManager(USER_FILES_PATH, VIRTUAL_DIR_URL)
    logger.info("FileManager initialized successfully")
except Exception as e:
    logger.error(f"Error initializing FileManager: {str(e)}", exc_info=True)
    raise

# Add error handling middleware
@app.errorhandler(Exception)
def handle_exception(e):
    """Handle any unhandled exception"""
    logger.error(f"Unhandled exception: {str(e)}", exc_info=True)
    return jsonify({
        "error": "An unexpected error occurred",
        "details": str(e) if app.debug else None
    }), 500

@app.before_request
def log_request():
    """Log incoming request details"""
    logger.info(f"Received {request.method} request to {request.path}")
    logger.debug(f"Request headers: {dict(request.headers)}")

@app.before_request
def check_share_access():
    if request.path.startswith('/D8TAVu/share'):
        try:
            # Test if we can access the share directory
            Path(USER_FILES_PATH).stat()
        except PermissionError:
            logger.error(f"Permission denied accessing share directory: {USER_FILES_PATH}")
            return jsonify({
                'error': 'Access to share directory is not available. Please contact administrator.'
            }), 500
        except Exception as e:
            logger.error(f"Error accessing share directory: {str(e)}", exc_info=True)
            return jsonify({
                'error': 'Share directory is not available'
            }), 500

# Add static file serving for the share directory
@app.route('/D8TAVu/share/static/<path:filename>')
def serve_static(filename):
    try:
        return send_from_directory(USER_FILES_PATH, filename, as_attachment=True)
    except Exception as e:
        logger.error(f"Error serving static file: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 404

# Authentication decorator
def requires_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.authorization
        if not auth or not check_auth(auth.username, auth.password):
            return authenticate()
        return f(*args, **kwargs)
    return decorated

def check_auth(username, password):
    """Check if username/password combination is valid"""
    # TODO: Replace with proper authentication system
    return username == 'admin' and password == 'admin'

def authenticate():
    """Send 401 response that enables basic auth"""
    return Response(
        'Could not verify your access level for that URL.\n'
        'You have to login with proper credentials', 401,
        {'WWW-Authenticate': 'Basic realm="Login Required"'})

@app.route('/D8TAVu')
@app.route('/D8TAVu/')
@app.route('/')
def home():
    """Home page - Stock Data Visualization"""
    logger.info('Accessing home page')
    # Always redirect to /D8TAVu/ to maintain consistency
    if request.path == '/':
        return redirect('/D8TAVu/')
    return render_template('index.html')

@app.route('/D8TAVu/health')
@app.route('/health')
def health():
    """Health check endpoint"""
    logger.info('Health check endpoint accessed')
    return {'status': 'healthy'}, 200

@app.route('/D8TAVu/stock-data', methods=['POST'])
@app.route('/stock-data', methods=['POST'])
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

@app.route('/D8TAVu/share/')
@app.route('/D8TAVu/share/<path:subpath>')
@app.route('/share/')
@app.route('/share/<path:subpath>')
@requires_auth
def browse_files(subpath=''):
    """Browse files in the share directory"""
    logger.info(f'Accessing share directory with subpath: {subpath}')
    try:
        # Normalize subpath to handle both /D8TAVu/share and /share URLs
        if subpath.startswith('D8TAVu/share/'):
            subpath = subpath[len('D8TAVu/share/'):]
        elif subpath.startswith('share/'):
            subpath = subpath[len('share/'):]
            
        # Log the actual paths being used
        logger.info(f'Normalized subpath: {subpath}')
        logger.info(f'Root path: {file_manager.root_path}')
        logger.info(f'Full requested path: {file_manager.root_path / subpath if subpath else file_manager.root_path}')
        
        # Test directory access
        access_result = file_manager.check_access()
        logger.info(f'Directory access check result: {access_result}')
        
        if not access_result:
            logger.error(f"Permission denied accessing share directory: {USER_FILES_PATH}")
            return jsonify({
                'error': 'Access to share directory is not available. Please contact administrator.'
            }), 500

        # Try to list files
        try:
            files = file_manager.list_directory(subpath)
            logger.info(f'Successfully listed {len(files)} files')
        except Exception as e:
            logger.error(f'Error listing directory: {str(e)}', exc_info=True)
            raise

        # Try to get breadcrumbs
        try:
            breadcrumbs = file_manager.get_breadcrumbs(subpath)
            logger.info(f'Successfully generated breadcrumbs')
        except Exception as e:
            logger.error(f'Error generating breadcrumbs: {str(e)}', exc_info=True)
            raise

        return render_template('file_browser.html',
                             files=files,
                             breadcrumbs=breadcrumbs,
                             current_path=subpath)
    except ValueError as e:
        logger.error(f"ValueError browsing files: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 404
    except Exception as e:
        logger.error(f"Unexpected error browsing files: {str(e)}", exc_info=True)
        return jsonify({'error': 'An unexpected error occurred', 'details': str(e)}), 500

@app.route('/D8TAVu/share/download/<path:filepath>')
@app.route('/share/download/<path:filepath>')
@requires_auth
def download_file(filepath):
    logger.info(f'File download requested: {filepath}')
    try:
        file_path, mime_type = file_manager.get_file(filepath)
        logger.debug(f'Sending file: {file_path} (type: {mime_type})')
        return send_file(file_path, mimetype=mime_type, as_attachment=True)
    except ValueError as e:
        logger.error(f"Error downloading file: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 404
    except Exception as e:
        logger.error(f"Unexpected error downloading file: {str(e)}", exc_info=True)
        return jsonify({'error': 'An unexpected error occurred'}), 500

@app.route('/D8TAVu/share/upload', methods=['POST'])
@app.route('/share/upload', methods=['POST'])
@requires_auth
def upload_file():
    logger.info('File upload initiated')
    try:
        path = request.form.get('path', '')
        logger.debug(f'Upload path: {path}')
        
        if 'file' not in request.files:
            logger.warning('No file provided in upload request')
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            logger.warning('Empty filename in upload request')
            return jsonify({'error': 'No file selected'}), 400
            
        filename = secure_filename(file.filename)
        upload_path = f"{path}/{filename}" if path else filename
        logger.debug(f'Processing upload: {filename} to {upload_path}')
        
        file_manager.upload_file(upload_path, file)
        logger.info(f'File uploaded successfully: {upload_path}')
        
        return jsonify({'message': 'File uploaded successfully'})
    except ValueError as e:
        logger.error(f"Error uploading file: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        logger.error(f"Unexpected error uploading file: {str(e)}", exc_info=True)
        return jsonify({'error': 'An unexpected error occurred'}), 500

@app.route('/D8TAVu/share/create-directory', methods=['POST'])
@app.route('/share/create-directory', methods=['POST'])
@requires_auth
def create_directory():
    logger.info('Directory creation initiated')
    try:
        data = request.get_json()
        logger.debug(f'Create directory request data: {data}')
        
        path = data.get('path', '')
        name = data.get('name', '')
        if not name:
            logger.warning('No directory name provided')
            return jsonify({'error': 'Directory name is required'}), 400
            
        new_dir_path = f"{path}/{name}" if path else name
        logger.debug(f'Creating directory: {new_dir_path}')
        
        file_manager.create_directory(new_dir_path)
        logger.info(f'Directory created successfully: {new_dir_path}')
        
        return jsonify({'message': 'Directory created successfully'})
    except ValueError as e:
        logger.error(f"Error creating directory: {str(e)}", exc_info=True)
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        logger.error(f"Unexpected error creating directory: {str(e)}", exc_info=True)
        return jsonify({'error': 'An unexpected error occurred'}), 500

@app.route('/D8TAVu/share/delete', methods=['POST'])
@app.route('/share/delete', methods=['POST'])
def delete_item():
    """
    This endpoint has been disabled for security reasons.
    File deletion is not permitted through the web interface.
    """
    app.logger.warning("File deletion attempt blocked - functionality disabled")
    return jsonify({"error": "File deletion is not permitted"}), 403

if __name__ == '__main__':
    app.run(debug=True)
