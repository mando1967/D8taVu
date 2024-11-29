@echo off
echo Installing IIS Components...

REM Install IIS components using DISM
dism /online /enable-feature /featurename:IIS-WebServerRole
dism /online /enable-feature /featurename:IIS-WebServer
dism /online /enable-feature /featurename:IIS-CommonHttpFeatures
dism /online /enable-feature /featurename:IIS-StaticContent
dism /online /enable-feature /featurename:IIS-DefaultDocument
dism /online /enable-feature /featurename:IIS-DirectoryBrowsing
dism /online /enable-feature /featurename:IIS-HttpErrors
dism /online /enable-feature /featurename:IIS-ApplicationDevelopment
dism /online /enable-feature /featurename:IIS-CGI
dism /online /enable-feature /featurename:IIS-ISAPIExtensions
dism /online /enable-feature /featurename:IIS-ISAPIFilter

REM Specifically enable FastCGI
dism /online /enable-feature /featurename:IIS-CGI

echo.
echo Installation complete. Please restart IIS or your computer.
pause
