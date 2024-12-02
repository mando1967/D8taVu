@echo off
echo Enabling wfastcgi for IIS...

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

REM Activate the conda environment
call "%CONDA_PATH%\Scripts\activate.bat" %APP_NAME%

REM Enable wfastcgi
wfastcgi-enable

echo.
echo If no errors occurred, wfastcgi has been enabled successfully.
pause
