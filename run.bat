@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Load .env
if not exist ".env" (
    echo .env file not found!
    exit /b 1
)

for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
    if not "%%A"=="" set "%%A=%%B"
)

:: Check variables
if "%GITHUB_USERNAME%"=="" (
    echo GITHUB_USERNAME missing
    exit /b 1
)
if "%GITHUB_PAT%"=="" (
    echo GITHUB_PAT missing
    exit /b 1
)

:: Docker login
echo %GITHUB_PAT% | docker login ghcr.io -u %GITHUB_USERNAME% --password-stdin

:: Add hosts entry
set HOST_ENTRY=127.0.0.1 ekalavya-files-service
findstr /c:"%HOST_ENTRY%" C:\Windows\System32\drivers\etc\hosts >nul
if errorlevel 1 (
    echo Adding hosts entry (requires admin privileges)...
    powershell -Command "Add-Content -Path 'C:\Windows\System32\drivers\etc\hosts' -Value '%HOST_ENTRY%'"
) else (
    echo Hosts entry already exists.
)

echo Done!
