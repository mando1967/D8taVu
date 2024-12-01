# D8TAVu Stock Data Visualization Web Application

A web application for visualizing stock market data using Flask, React, and yfinance.

## Interface Example
![D8TAVu Interface Example](docs/interface_example.png)
*Example of D8TAVu showing stock data visualization with interactive controls*

## Setup and Configuration Scripts

All setup and configuration scripts are located in the `scripts` directory. The setup process is divided into two main phases, each managed by a master script:

### 1. IIS Setup (master_setup.ps1)
This script handles all IIS-related configurations in the following sequence:

1. Install IIS Components (1_install_iis_components.bat)
2. Unlock IIS Sections (1_unlock_iis_sections.bat)
3. Install URL Rewrite Module (1_install_url_rewrite.ps1)
4. Create Application Pool (1_create_app_pool.ps1)
5. Enable FastCGI (1_enable_wfastcgi.bat)
6. Set Environment Variables (1_set_env_variables.ps1)
7. Configure Virtual Directory (1_configure_virtual_directory.ps1)
8. Check and Set Permissions (1_check_set_permissions.ps1)
9. Restart IIS (3_restart_iis.ps1)

### 2. Environment Setup (master_setup_env.ps1)
This script handles Python environment and application setup:

1. Create Python Environment (2_create_web_env.ps1)
2. Copy Static Files (2_copy_static_files.ps1)
3. Set Permissions (2_set_permissions.ps1)
4. Fix Permissions (2_fix_permissions.ps1)
5. Grant Access (2_grant_access.ps1)
6. Restart IIS (3_restart_iis.ps1)

## Deployment Steps

1. Prerequisites:
   - Windows Server with PowerShell
   - Administrator privileges
   - Anaconda/Miniconda installed
   - Git for version control

2. Clone the repository:
   ```powershell
   git clone https://github.com/yourusername/D8TAVu.git
   cd D8TAVu
   ```

3. Run IIS Setup (as Administrator):
   ```powershell
   cd scripts
   .\master_setup.ps1
   ```

4. Run Environment Setup (as Administrator):
   ```powershell
   .\master_setup_env.ps1
   ```

## Error Handling

Both master scripts include comprehensive error handling:
- Administrator privilege verification
- Script existence checks
- Detailed error reporting
- Automatic process abortion on failure
- Color-coded console output

If a script fails:
1. Check the error message in the console
2. Fix the reported issue
3. Re-run the master script

## Common Issues and Solutions

### Permission Issues
- Verify administrator privileges
- Check IIS app pool identity
- Ensure proper file system permissions
- Run 2_fix_permissions.ps1 individually if needed

### IIS Configuration
- Verify IIS installation with CGI support
- Check URL Rewrite Module installation
- Confirm FastCGI configuration
- Run 1_check_set_permissions.ps1 for permission verification

### Python Environment
- Ensure Anaconda/Miniconda is installed
- Verify Python version compatibility (3.9+)
- Check environment variables configuration
- Review 2_create_web_env.ps1 logs

## Application Structure

### Key Components
- `app.py`: Main Flask application
- `file_manager.py`: File system operations
- `templates/`: HTML templates
  - `index.html`: Main application template
  - `file_browser.html`: File browser interface
- `scripts/`: Configuration and management scripts
- `web.config`: IIS configuration file

## Security Considerations
- Basic authentication enabled for file access
- File operations restricted to virtual directory
- IIS app pool permissions limited to necessary access
- Path normalization implemented
- File deletion functionality disabled

## Logging
- Application logs in `app.log`
- IIS logs in default location
- Script execution logs in console output
- Comprehensive error reporting

## Environment Requirements

- Windows Server with IIS
- Python 3.9+
- IIS URL Rewrite Module
- FastCGI module for IIS
- Anaconda/Miniconda
- Administrator privileges

## Development Notes

The application uses a secure file browsing system with:
- IIS virtual directory ("share") pointing to Documents folder
- Proper access controls through IIS
- Limited file system operations
- Comprehensive permission management
