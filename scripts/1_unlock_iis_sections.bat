@echo off
setlocal EnableDelayedExpansion

REM Get arguments
set "whatif=%~1"
set "description=%~2"

REM Echo the description if provided
if not "%description%"=="" (
    echo %description%
)

REM Check for WhatIf mode
if "%whatif%"=="1" (
    echo [WhatIf] Would unlock IIS configuration sections:
    echo [WhatIf] - system.webServer/handlers
    echo [WhatIf] - system.webServer/fastCgi
    exit /b 0
)

REM Check for administrator privileges
net session >nul 2>&1
if !errorLevel! neq 0 (
    echo This script requires administrator privileges.
    echo Please run this script as administrator.
    exit /b 1
)

REM Unlock handlers section
echo Unlocking handlers section...
%windir%\system32\inetsrv\appcmd unlock config -section:system.webServer/handlers
if !errorLevel! neq 0 (
    echo Failed to unlock handlers section
    exit /b 1
)

REM Unlock FastCGI section
echo Unlocking FastCGI section...
%windir%\system32\inetsrv\appcmd unlock config -section:system.webServer/fastCgi
if !errorLevel! neq 0 (
    echo Failed to unlock FastCGI section
    exit /b 1
)

echo.
echo Successfully unlocked IIS sections.
exit /b 0
