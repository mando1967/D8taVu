@echo off
REM Run this script as Administrator

REM Set variables
set SITE_NAME="Default Web Site"
set APP_NAME="D8TAVu"
set VDIR_NAME="share"
set PHYSICAL_PATH="C:\Users\a-gon\OneDrive\Documents"

REM Configure virtual directory settings
"%systemroot%\system32\inetsrv\appcmd.exe" set vdir "%SITE_NAME%/%APP_NAME%/%VDIR_NAME%" -physicalPath:%PHYSICAL_PATH%
"%systemroot%\system32\inetsrv\appcmd.exe" set config "%SITE_NAME%/%APP_NAME%/%VDIR_NAME%" /section:anonymousAuthentication /enabled:true /commit:apphost
"%systemroot%\system32\inetsrv\appcmd.exe" set config "%SITE_NAME%/%APP_NAME%/%VDIR_NAME%" /section:windowsAuthentication /enabled:false /commit:apphost

REM Set folder permissions
icacls %PHYSICAL_PATH% /grant "IIS AppPool\DefaultAppPool":(OI)(CI)RX /T

echo Configuration complete!
pause
