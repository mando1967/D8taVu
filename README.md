# D8TAVu Project

## Project Setup
1. Create Anaconda environment:
```bash
conda create -n D8TAVu python=3.9
conda activate D8TAVu
```

## IIS Configuration Requirements

### Prerequisites
1. Install IIS with CGI module enabled
2. Install URL Rewrite Module for IIS
3. Install Windows Configuration Platform (WFastCGI)

### IIS Configuration Steps

1. **Install Required IIS Components:**
   - World Wide Web Services > Application Development Features
     - CGI
     - ISAPI Extensions
     - ISAPI Filters
   - World Wide Web Services > Common HTTP Features (all)

2. **Install Python Dependencies:**
   ```bash
   conda activate D8TAVu
   pip install wfastcgi
   wfastcgi-enable
   ```

3. **IIS Configuration Files:**

   #### web.config (to be placed in site root)
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <configuration>
       <system.webServer>
           <handlers>
               <add name="Python FastCGI"
                    path="*"
                    verb="*"
                    modules="FastCgiModule"
                    scriptProcessor="[Path to Python in Conda Env]\python.exe|[Path to wfastcgi.py in Conda Env]\wfastcgi.py"
                    resourceType="Unspecified"
                    requireAccess="Script" />
           </handlers>
           <fastCgi>
               <application fullPath="[Path to Python in Conda Env]\python.exe"
                           arguments="[Path to wfastcgi.py in Conda Env]\wfastcgi.py"
                           maxInstances="4"
                           idleTimeout="300" />
           </fastCgi>
       </system.webServer>
       <appSettings>
           <add key="PYTHONPATH" value="[Path to Your Application Root]" />
           <add key="WSGI_HANDLER" value="app.app" />
           <add key="WSGI_LOG" value="[Path to Log File]\wfastcgi.log" />
       </appSettings>
   </configuration>
   ```

4. **IIS Application Pool Configuration:**
   - Create new Application Pool
   - Set to "No Managed Code"
   - Enable 32-bit applications if using 32-bit Python
   - Identity: Set to a user with appropriate permissions

5. **File System Permissions:**
   - Grant IIS_IUSRS and IUSR read access to Python installation
   - Grant Application Pool Identity full control of application directory

## Important Notes
- Replace all `[Path...]` placeholders with actual paths from your system
- Python path should point to the Python executable in the D8TAVu Conda environment
- Application root path should point to where your WSGI application is located
- Ensure all paths use escaped backslashes or forward slashes
- Log file location must be writable by the Application Pool identity

## Security Considerations
- Keep Conda environment isolated and dedicated to this application
- Regularly update dependencies
- Use secure coding practices and input validation
- Implement proper error handling and logging
- Consider using HTTPS with appropriate SSL certificates
