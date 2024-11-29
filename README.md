# D8TAVu Project

## Project Setup
1. Create and configure Anaconda environment:
```bash
conda create -n D8TAVu python=3.9
conda activate D8TAVu
conda install conda-forge::flask=2.3.3
conda install conda-forge::werkzeug=2.3.7
conda install conda-forge::wfastcgi
```

## IIS Configuration Requirements

### Prerequisites
1. Run `install_iis_components.bat` as administrator to install required IIS components:
   - CGI
   - ISAPI Extensions
   - ISAPI Filters
   - Common HTTP Features
2. Install URL Rewrite Module for IIS
3. Run `enable_wfastcgi.bat` as administrator to enable wfastcgi for IIS
4. Run `unlock_iis_sections.bat` as administrator to unlock necessary IIS configuration sections:
   - handlers section
   - FastCGI section

### IIS Configuration Steps

1. **Create Application Pool:**
   - Name: "D8TAVu"
   - .NET CLR version: "No Managed Code"
   - Managed pipeline mode: "Integrated"

2. **Create Application:**
   - Under Default Web Site, create application
   - Alias: "D8TAVu"
   - Application Pool: "D8TAVu"
   - Physical Path: `[Project Directory Path]`

3. **Set Permissions:**
   Run `set_permissions.bat` as administrator to set:
   - IIS_IUSRS and IUSR read access to Python environment
   - Application Pool Identity full control of application directory
   - Application Pool Identity read access to Python environment

## Application Structure

### Key Files
- `app.py`: Flask application with route handlers
- `web.config`: IIS configuration for Python/Flask
- `requirements.txt`: Project dependencies
- `install_iis_components.bat`: Script to install required IIS components
- `unlock_iis_sections.bat`: Script to unlock IIS configuration sections
- `enable_wfastcgi.bat`: Script to enable wfastcgi in IIS
- `set_permissions.bat`: Script to set required permissions

### Working URLs
- Main application: `http://localhost/D8TAVu`
- Health check: `http://localhost/D8TAVu/health`

## Configuration Details

### web.config
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <handlers>
            <remove name="Python FastCGI" />
            <add name="Python FastCGI"
                 path="*"
                 verb="*"
                 modules="FastCgiModule"
                 scriptProcessor="[Python Path]|[wfastcgi.py Path]"
                 resourceType="Unspecified"
                 requireAccess="Script" />
        </handlers>
        <fastCgi>
            <application fullPath="[Python Path]"
                        arguments="[wfastcgi.py Path]"
                        maxInstances="4"
                        idleTimeout="300">
            </application>
        </fastCgi>
    </system.webServer>
    <appSettings>
        <add key="WSGI_HANDLER" value="app.app" />
        <add key="PYTHONPATH" value="[Project Directory Path]" />
        <add key="WSGI_LOG" value="[Project Directory Path]\wfastcgi.log" />
        <add key="SCRIPT_NAME" value="/D8TAVu" />
    </appSettings>
</configuration>
```

## Troubleshooting
1. Check wfastcgi.log in the project directory for errors
2. Ensure all paths in web.config match your system
3. Verify IIS Application Pool is running
4. Confirm permissions are set correctly using `set_permissions.bat`
5. If configuration sections are locked, run `unlock_iis_sections.bat`
6. If IIS components are missing, run `install_iis_components.bat`
7. If wfastcgi is not properly enabled, run `enable_wfastcgi.bat`
8. Restart IIS or the application after configuration changes

## Security Considerations
- Keep Conda environment isolated and dedicated to this application
- Regularly update dependencies
- Use secure coding practices and input validation
- Implement proper error handling and logging
- Consider using HTTPS with appropriate SSL certificates
