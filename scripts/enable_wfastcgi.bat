@echo off
echo Enabling wfastcgi for IIS...

REM Get the root directory (one level up from scripts)
pushd %~dp0
cd ..
set ROOT_DIR=%CD%
popd

REM Activate the conda environment
call C:\Users\a-gon\anaconda3\Scripts\activate.bat D8TAVu

REM Enable wfastcgi
wfastcgi-enable

echo.
echo If no errors occurred, wfastcgi has been enabled successfully.
pause
