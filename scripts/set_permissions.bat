@echo off
echo Setting permissions for IIS and Python...

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

REM Get the root directory (one level up from scripts)
pushd %~dp0
cd ..
set ROOT_DIR=%CD%
popd

REM Set environment variables
set WEB_ROOT=C:\inetpub\wwwroot\D8TAVu
set ENV_PATH=%WEB_ROOT%\env
set APP_POOL_USER=IIS AppPool\D8TAVu

echo Setting permissions for web root directory: %WEB_ROOT%
icacls "%WEB_ROOT%" /grant "IIS_IUSRS:(OI)(CI)(RX)" /T
icacls "%WEB_ROOT%" /grant "IUSR:(OI)(CI)(RX)" /T
icacls "%WEB_ROOT%" /grant "%APP_POOL_USER%:(OI)(CI)(F)" /T

echo Setting permissions for Python environment: %ENV_PATH%
icacls "%ENV_PATH%" /grant "IIS_IUSRS:(OI)(CI)(RX)" /T
icacls "%ENV_PATH%" /grant "IUSR:(OI)(CI)(RX)" /T
icacls "%ENV_PATH%" /grant "%APP_POOL_USER%:(OI)(CI)(RX)" /T

echo Setting permissions for application directory: %ROOT_DIR%
icacls "%ROOT_DIR%" /grant "%APP_POOL_USER%:(OI)(CI)(F)" /T

echo Done setting permissions.
echo If you experience any issues, try running scripts\fix_permissions.ps1
pause
