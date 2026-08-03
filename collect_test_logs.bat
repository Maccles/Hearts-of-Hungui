@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0collect_test_logs.ps1"
if errorlevel 1 (
    echo.
    echo Log collection failed.
    pause
    exit /b 1
)
echo.
echo Collection complete.
pause
