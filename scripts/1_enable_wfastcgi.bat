@echo off
echo Checking wfastcgi status...

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

REM Get configuration values from PowerShell
for /f "tokens=*" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0get_config_values.ps1" CONDA_PATH APP_NAME') do set CONFIG_VALUES=%%i
for /f "tokens=1,2" %%a in ("%CONFIG_VALUES%") do (
    set CONDA_PATH=%%a
    set APP_NAME=%%b
)

REM Check if wfastcgi is already enabled
%windir%\system32\inetsrv\appcmd list module /name:wfastcgi > nul 2>&1
if %errorLevel% equ 0 (
    echo wfastcgi is already enabled
    exit /b 0
)

REM Activate the conda environment
echo Activating conda environment...
call "%CONDA_PATH%\Scripts\activate.bat" %APP_NAME%

REM Enable wfastcgi
echo Enabling wfastcgi...
wfastcgi-enable

REM Verify installation
%windir%\system32\inetsrv\appcmd list module /name:wfastcgi > nul 2>&1
if %errorLevel% equ 0 (
    echo wfastcgi was successfully enabled
    exit /b 0
) else (
    echo Failed to enable wfastcgi
    exit /b 1
)
