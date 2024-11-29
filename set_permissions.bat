@echo off
echo Setting permissions for IIS and Python...

REM Grant IIS_IUSRS read access to Python environment
icacls "C:\Users\a-gon\anaconda3\envs\D8TAVu" /grant "IIS_IUSRS:(OI)(CI)(RX)" /T
icacls "C:\Users\a-gon\anaconda3\envs\D8TAVu" /grant "IUSR:(OI)(CI)(RX)" /T

REM Grant IIS AppPool full control to application directory
icacls "c:\Users\a-gon\OneDrive\Documents\python\CascadeProjects\windsurf-project\D8TAVu" /grant "IIS AppPool\D8TAVu:(OI)(CI)(F)" /T

REM Grant IIS AppPool read access to Python environment
icacls "C:\Users\a-gon\anaconda3\envs\D8TAVu" /grant "IIS AppPool\D8TAVu:(OI)(CI)(RX)" /T

echo Done setting permissions.
pause
