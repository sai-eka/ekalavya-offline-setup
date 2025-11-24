@echo off
echo Starting Setup...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\run.ps1"
if %errorlevel% neq 0 (
    echo.
    echo Setup failed or was cancelled.
    pause
    exit /b %errorlevel%
)
echo.
echo Setup completed successfully.
pause
