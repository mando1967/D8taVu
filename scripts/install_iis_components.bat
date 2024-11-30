@echo off
echo Installing IIS Components...

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script requires administrator privileges.
    echo Please run this script as administrator.
    pause
    exit /b 1
)

REM Install IIS components using DISM
echo Installing IIS Web Server Role and basic features...
dism /online /enable-feature /featurename:IIS-WebServerRole /quiet /norestart
dism /online /enable-feature /featurename:IIS-WebServer /quiet /norestart
dism /online /enable-feature /featurename:IIS-CommonHttpFeatures /quiet /norestart
dism /online /enable-feature /featurename:IIS-StaticContent /quiet /norestart
dism /online /enable-feature /featurename:IIS-DefaultDocument /quiet /norestart
dism /online /enable-feature /featurename:IIS-DirectoryBrowsing /quiet /norestart
dism /online /enable-feature /featurename:IIS-HttpErrors /quiet /norestart

echo Installing CGI and ISAPI features...
dism /online /enable-feature /featurename:IIS-ApplicationDevelopment /quiet /norestart
dism /online /enable-feature /featurename:IIS-CGI /quiet /norestart
dism /online /enable-feature /featurename:IIS-ISAPIExtensions /quiet /norestart
dism /online /enable-feature /featurename:IIS-ISAPIFilter /quiet /norestart

REM Specifically enable FastCGI
echo Installing FastCGI...
dism /online /enable-feature /featurename:IIS-CGI /quiet /norestart

echo.
echo Installation complete. Please restart IIS or your computer.
echo You can use scripts\restart_iis.ps1 to restart IIS.
pause
