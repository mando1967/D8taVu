# D8TAVu Stock Data Visualization Web Application

A web application for visualizing stock market data using Flask, React, and yfinance.

## Interface Example
![D8TAVu Interface Example](docs/interface_example.png)
*Example of D8TAVu showing stock data visualization with interactive controls*

## Setup and Configuration Scripts

All setup and configuration scripts are located in the `scripts` directory:

### IIS Configuration Scripts (Run as Administrator)
- `scripts/configure_iis.bat`: Configures IIS virtual directory and permissions
- `scripts/configure_iis.ps1`: PowerShell script for detailed IIS configuration
- `scripts/configure_virtual_directory.ps1`: Sets up and configures the virtual directory for file access
- `scripts/check_set_permissions.ps1`: Checks and sets required permissions for IIS
- `scripts/grant_access.ps1`: Grants necessary file system permissions to IIS app pool

### Common Tasks

### Initial Setup
1. Configure IIS and Virtual Directory:
   ```powershell
   .\scripts\configure_iis.ps1
   .\scripts\configure_virtual_directory.ps1
   ```

2. Set Permissions:
   ```powershell
   .\scripts\check_set_permissions.ps1
   ```

### Troubleshooting

1. Permission Issues:
   ```powershell
   # Check and fix permissions
   .\scripts\check_set_permissions.ps1
   
   # Grant specific access to app pool
   .\scripts\grant_access.ps1
   ```

2. Virtual Directory Issues:
   ```powershell
   # Reconfigure virtual directory
   .\scripts\configure_virtual_directory.ps1
   ```

## Common Issues and Solutions

### Permission Issues
1. IIS App Pool Access:
   ```powershell
   # Run check_set_permissions.ps1 with administrator privileges
   .\scripts\check_set_permissions.ps1
   ```

2. File System Access:
   ```powershell
   # Use grant_access.ps1 for specific permissions
   .\scripts\grant_access.ps1
   ```

### IIS Configuration
1. Virtual Directory Setup:
   ```powershell
   # Configure or reconfigure virtual directory
   .\scripts\configure_virtual_directory.ps1
   ```

2. General IIS Configuration:
   ```powershell
   # Run full IIS configuration
   .\scripts\configure_iis.ps1
   ```

## Application Structure

### Key Components
- `app.py`: Main Flask application
- `file_manager.py`: File system operations and management
- `templates/`: HTML templates
  - `index.html`: Main application template
  - `file_browser.html`: File browser interface
- `scripts/`: Configuration and management scripts
- `web.config`: IIS configuration file

## Development Notes

### Virtual Directory Configuration
The application uses an IIS virtual directory named "share" that points to the user's Documents folder. This allows secure file browsing while maintaining proper access controls through IIS.

### Security Considerations
- Basic authentication is enabled for file access
- File operations are restricted to the virtual directory
- IIS app pool permissions are limited to necessary access levels

### Logging
- Application logs are stored in `app.log`
- IIS logs are in their default location
- Each script includes detailed logging of its operations

## Deployment Steps

1. Ensure IIS is installed with Python support
2. Run the configuration scripts in this order:
   ```powershell
   .\scripts\configure_iis.ps1
   .\scripts\configure_virtual_directory.ps1
   .\scripts\check_set_permissions.ps1
   ```
3. Verify the application pool and virtual directory settings
4. Test file access through the web interface

## Environment Requirements

- Windows Server with IIS
- Python 3.9+
- IIS URL Rewrite Module (optional)
- FastCGI module for IIS
