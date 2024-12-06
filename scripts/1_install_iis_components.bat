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
    echo [WhatIf] Would install IIS components
    echo [WhatIf] Components to install:
    echo [WhatIf] - IIS-WebServerRole
    echo [WhatIf] - IIS-WebServer
    echo [WhatIf] - IIS-CommonHttpFeatures
    echo [WhatIf] - IIS-StaticContent
    echo [WhatIf] - IIS-DefaultDocument
    echo [WhatIf] - IIS-DirectoryBrowsing
    echo [WhatIf] - IIS-HttpErrors
    echo [WhatIf] - IIS-ApplicationDevelopment
    echo [WhatIf] - IIS-CGI
    exit /b 0
)

REM Check for administrator privileges
net session >nul 2>&1
if !errorLevel! neq 0 (
    echo This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

REM Function to check and install IIS feature
:CheckAndInstallFeature
setlocal
set featureName=%~1
set featureDesc=%~2

if "%featureName%"=="" goto :eof
if "%featureDesc%"=="" set "featureDesc=%featureName%"

echo Checking %featureDesc%...
dism /online /get-featureinfo /featurename:%featureName% | find "State : Enabled" > nul
if !errorLevel! equ 0 (
    echo %featureDesc% is already installed
) else (
    echo Installing %featureDesc%...
    dism /online /enable-feature /featurename:%featureName% /quiet /norestart
    if !errorLevel! neq 0 (
        echo Failed to install %featureDesc%
        endlocal
        exit /b 1
    )
)
endlocal
goto :eof

REM Install IIS components using DISM
echo Checking and installing IIS components...

call :CheckAndInstallFeature IIS-WebServerRole "IIS Web Server Role"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-WebServer "IIS Web Server"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-CommonHttpFeatures "IIS Common HTTP Features"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-StaticContent "IIS Static Content"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-DefaultDocument "IIS Default Document"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-DirectoryBrowsing "IIS Directory Browsing"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-HttpErrors "IIS HTTP Errors"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-HttpLogging "IIS HTTP Logging"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-LoggingLibraries "IIS Logging Libraries"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-RequestMonitor "IIS Request Monitor"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-HttpTracing "IIS HTTP Tracing"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-ISAPIExtensions "IIS ISAPI Extensions"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-ISAPIFilter "IIS ISAPI Filters"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-BasicAuthentication "IIS Basic Authentication"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-WindowsAuthentication "IIS Windows Authentication"
if !errorLevel! neq 0 goto :error

call :CheckAndInstallFeature IIS-CGI "IIS CGI"
if !errorLevel! neq 0 goto :error

echo.
echo IIS component installation completed successfully.
exit /b 0

:error
echo An error occurred during IIS component installation.
exit /b 1
