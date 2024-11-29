@echo off
echo Unlocking IIS configuration sections...

REM Unlock handlers section
%windir%\system32\inetsrv\appcmd unlock config -section:system.webServer/handlers

REM Unlock FastCGI section
%windir%\system32\inetsrv\appcmd unlock config -section:system.webServer/fastCgi

echo Done unlocking IIS sections.
pause
