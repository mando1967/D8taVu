@echo off
echo Checking IIS Components...

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

REM Function to check and install IIS feature
:CheckAndInstallFeature
set "feature=%~1"
set "description=%~2"
echo Checking %description%...
dism /online /get-featureinfo /featurename:%feature% | find "State : Enabled" > nul
if %errorLevel% equ 0 (
    echo %description% is already installed
) else (
    echo Installing %description%...
    dism /online /enable-feature /featurename:%feature% /quiet /norestart
    if %errorLevel% neq 0 (
        echo Failed to install %description%
        exit /b 1
    )
)
exit /b 0

REM Install IIS components using DISM
echo Checking and installing IIS components...

call :CheckAndInstallFeature IIS-WebServerRole "IIS Web Server Role"
call :CheckAndInstallFeature IIS-WebServer "IIS Web Server"
call :CheckAndInstallFeature IIS-CommonHttpFeatures "IIS Common HTTP Features"
call :CheckAndInstallFeature IIS-StaticContent "IIS Static Content"
call :CheckAndInstallFeature IIS-DefaultDocument "IIS Default Document"
call :CheckAndInstallFeature IIS-DirectoryBrowsing "IIS Directory Browsing"
call :CheckAndInstallFeature IIS-HttpErrors "IIS HTTP Errors"
call :CheckAndInstallFeature IIS-HttpLogging "IIS HTTP Logging"
call :CheckAndInstallFeature IIS-LoggingLibraries "IIS Logging Libraries"
call :CheckAndInstallFeature IIS-RequestMonitor "IIS Request Monitor"
call :CheckAndInstallFeature IIS-HttpTracing "IIS HTTP Tracing"
call :CheckAndInstallFeature IIS-ISAPIExtensions "IIS ISAPI Extensions"
call :CheckAndInstallFeature IIS-ISAPIFilter "IIS ISAPI Filters"
call :CheckAndInstallFeature IIS-BasicAuthentication "IIS Basic Authentication"
call :CheckAndInstallFeature IIS-WindowsAuthentication "IIS Windows Authentication"
call :CheckAndInstallFeature IIS-CGI "IIS CGI"

echo.
echo IIS component installation completed successfully.
pause
