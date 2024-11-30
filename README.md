# D8TAVu Stock Data Visualization Web Application

A web application for visualizing stock market data using Flask, React, and yfinance.

## Interface Example
![D8TAVu Interface Example](docs/interface_example.png)
*Example of D8TAVu showing stock data visualization with interactive controls*

## Setup and Configuration Scripts

### Environment Setup
- `create_web_env.ps1`: Creates the Python virtual environment in the IIS web directory
  - Sets up conda environment using environment.yml
  - Installs all required Python packages
  - Configures environment path for IIS

### Permission Management Scripts
- `fix_permissions.ps1`: Comprehensive script to fix file access permissions
  - Grants necessary permissions to IIS_IUSRS and NETWORK SERVICE
  - Ensures proper access to Python environment and application files
  - Run this if experiencing permission-related errors

- `set_permissions.ps1`: Targeted script for specific directory permissions
  - Use for fixing permissions on individual directories
  - Helpful for troubleshooting specific access issues

### IIS Management
- `restart_iis.ps1`: PowerShell script to restart IIS and application pool
  - Use when making configuration changes
  - Helps resolve application pool issues
  - Can be run with elevated privileges

### Deployment Scripts
- `copy_static_files.ps1`: Copies static assets to web directory
  - Handles JavaScript, CSS, and image files
  - Preserves file structure

- `setup_iis_env.ps1`: Initial IIS environment setup
  - Configures application pool
  - Sets up web.config
  - Establishes FastCGI settings

## Common Issues and Solutions

### Permission Issues
1. Environment Access:
   ```powershell
   # Run fix_permissions.ps1 with administrator privileges
   .\fix_permissions.ps1
   ```

2. Site-specific Permissions:
   ```powershell
   # Use set_permissions.ps1 for targeted fixes
   .\set_permissions.ps1 -path "path\to\directory" -user "IIS APPPOOL\D8TAVu"
   ```

### IIS Configuration
1. Application Pool Problems:
   ```powershell
   # Restart IIS and app pool
   .\restart_iis.ps1
   ```

2. Python Integration:
   - Verify web.config settings
   - Check FastCGI configuration
   - Ensure environment paths are correct

### Data Handling
- Date format: YYYY-MM-DD
- Moving averages: Integer periods only
- Volume display: Optional boolean parameter

## Recent Updates

### Plot Branch Merge
- Improved date handling in stock data response
- Enhanced error handling and logging
- Added comprehensive frontend validation
- Updated IIS configuration for better stability

## Configuration Files

### environment.yml
Contains all Python dependencies including:
- Flask
- yfinance
- pandas
- matplotlib
- mplfinance

### web.config
IIS configuration including:
- FastCGI settings
- Python handler mapping
- Environment variables

## Development Notes

### Virtual Environment
Located at: `C:\inetpub\wwwroot\D8TAVu\env`
Activate using:
```powershell
C:\inetpub\wwwroot\D8TAVu\env\Scripts\activate
```

### Debug Mode
Enable debug logging in app.py for troubleshooting:
```python
app.logger.setLevel(logging.DEBUG)
```

## Security Considerations
- All scripts should be run with appropriate privileges
- Regularly update Python packages
- Monitor IIS logs for errors
- Implement rate limiting for API calls
