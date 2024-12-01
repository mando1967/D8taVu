@echo off
echo Unlocking IIS configuration sections...

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

REM Unlock handlers section
echo Unlocking handlers section...
%windir%\system32\inetsrv\appcmd unlock config -section:system.webServer/handlers

REM Unlock FastCGI section
echo Unlocking FastCGI section...
%windir%\system32\inetsrv\appcmd unlock config -section:system.webServer/fastCgi

echo.
echo Done unlocking IIS sections.
echo You may need to restart IIS for changes to take effect.
echo You can use scripts\restart_iis.ps1 to restart IIS.
pause
