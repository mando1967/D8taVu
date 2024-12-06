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
    exit /b 1
)

REM Install IIS components using DISM
echo Checking and installing IIS components...

REM Helper function to check and install a feature
:install_feature
set feature_name=%~1
set feature_desc=%~2
if "%feature_desc%"=="" set feature_desc=%feature_name%

echo Checking %feature_desc%...
%SYSTEMROOT%\system32\dism.exe /online /get-featureinfo /featurename:%feature_name% | find "State : Enabled" >nul 2>&1
if !errorLevel! equ 0 (
    echo %feature_desc% is already installed
    goto :eof
)

echo Installing %feature_desc%...
%SYSTEMROOT%\system32\dism.exe /online /enable-feature /featurename:%feature_name% /all /quiet /norestart
if !errorLevel! neq 0 (
    echo Failed to install %feature_desc%
    exit /b 1
)
echo Successfully installed %feature_desc%
goto :eof

REM Install each feature
call :install_feature IIS-WebServerRole "IIS Web Server Role"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-WebServer "IIS Web Server"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-CommonHttpFeatures "IIS Common HTTP Features"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-StaticContent "IIS Static Content"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-DefaultDocument "IIS Default Document"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-DirectoryBrowsing "IIS Directory Browsing"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-HttpErrors "IIS HTTP Errors"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-HttpLogging "IIS HTTP Logging"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-LoggingLibraries "IIS Logging Libraries"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-RequestMonitor "IIS Request Monitor"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-HttpTracing "IIS HTTP Tracing"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-ISAPIExtensions "IIS ISAPI Extensions"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-ISAPIFilter "IIS ISAPI Filters"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-BasicAuthentication "IIS Basic Authentication"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-WindowsAuthentication "IIS Windows Authentication"
if !errorLevel! neq 0 goto :error

call :install_feature IIS-CGI "IIS CGI"
if !errorLevel! neq 0 goto :error

echo.
echo IIS component installation completed successfully.
exit /b 0

:error
echo An error occurred during IIS component installation.
exit /b 1
