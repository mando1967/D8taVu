from flask import Flask, request

app = Flask(__name__)

# Enable subdirectory support
app.config['APPLICATION_ROOT'] = '/D8TAVu'

@app.route('/D8TAVu')
@app.route('/D8TAVu/')
@app.route('/')
def home():
    return 'D8TAVu Application is running!'

@app.route('/D8TAVu/health')
@app.route('/health')
def health():
    return {'status': 'healthy'}, 200

# Add error handlers
@app.errorhandler(404)
def not_found_error(error):
    return f'Page not found. Request path was: {request.path}', 404

if __name__ == '__main__':
    app.run()
