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

REM Install each feature
call :install_feature IIS-WebServerRole "IIS Web Server Role"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-WebServer "IIS Web Server"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-CommonHttpFeatures "IIS Common HTTP Features"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-StaticContent "IIS Static Content"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-DefaultDocument "IIS Default Document"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-DirectoryBrowsing "IIS Directory Browsing"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-HttpErrors "IIS HTTP Errors"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-HttpLogging "IIS HTTP Logging"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-LoggingLibraries "IIS Logging Libraries"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-RequestMonitor "IIS Request Monitor"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-HttpTracing "IIS HTTP Tracing"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-ISAPIExtensions "IIS ISAPI Extensions"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-ISAPIFilter "IIS ISAPI Filters"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-BasicAuthentication "IIS Basic Authentication"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-WindowsAuthentication "IIS Windows Authentication"
if !errorLevel! neq 0 goto :exit /b 1

call :install_feature IIS-CGI "IIS CGI"
if !errorLevel! neq 0 goto :exit /b 1

echo.
echo IIS component installation completed successfully.
exit /b 0

REM Helper function to check and install a feature
:install_feature
setlocal EnableDelayedExpansion
set "feature_name=%~1"
set "feature_desc=%~2"

REM Validate input parameters
if "%feature_name%"=="" (
    echo Error: Feature name cannot be empty
    exit /b 1
)

if "%feature_desc%"=="" set "feature_desc=%feature_name%"

echo.
echo ========================================
echo Checking feature: [%feature_name%]
echo Description: %feature_desc%
echo ========================================

REM Debug: Show exact command being executed
set "check_cmd=%SYSTEMROOT%\system32\dism.exe /online /get-featureinfo /featurename:%feature_name%"
echo Executing: %check_cmd%
%check_cmd%
set check_error=!errorLevel!
echo Check command exit code: !check_error!

if !check_error! equ 0 (
    echo Feature exists, checking if enabled...
    %check_cmd% | find "State : Enabled" >nul
    if !errorLevel! equ 0 (
        echo Feature is already enabled
        endlocal
        exit /b 0
    )
)

echo Installing feature...
set "install_cmd=%SYSTEMROOT%\system32\dism.exe /online /enable-feature /featurename:%feature_name% /all /quiet /norestart"
echo Executing: %install_cmd%
%install_cmd%
set install_error=!errorLevel!
echo Install command exit code: !install_error!

if !install_error! neq 0 (
    echo Failed to install %feature_desc%
    echo Error code: !install_error!
    endlocal
    exit /b 1
)

echo Successfully installed %feature_desc%
endlocal
exit /b 0


