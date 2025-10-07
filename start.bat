@echo off
setlocal enabledelayedexpansion

echo.
echo 🧰 Checking for Docker...

where docker >nul 2>nul
if %errorlevel% neq 0 (
  echo ⚠ Docker not found! Please install Docker Desktop first:
  echo 👉 https://www.docker.com/get-started
  exit /b 1
)

where docker-compose >nul 2>nul
if %errorlevel% neq 0 (
  echo ⚠ docker-compose not found! Docker Desktop should include it.
  exit /b 1
)

echo.
echo 🔑 Enter your GitHub Personal Access Token (PAT) for private repos:
set /p GITHUB_TOKEN=Token: 
echo.

rem --- Your GitHub org name ---
set ORG=ekalavya-io

rem --- List of repositories to clone ---
set REPOS=ekalavya-web ekalavya-users-service ekalavya-content-service ekalavya-erp-service ekalavya-notifications-service ekalavya-files-service ekalavya-scratch-editor

rem --- Create project folder ---
if not exist project mkdir project
cd project

for %%R in (%REPOS%) do (
  if exist %%R (
    echo ✅ %%R already exists, skipping
  ) else (
    echo ⬇ Downloading %%R...
    curl -L -H "Authorization: token %GITHUB_TOKEN%" -o %%R.zip https://api.github.com/repos/%ORG%/%%R/zipball/develop >nul
    mkdir %%R
    powershell -Command "Expand-Archive -Path '%%R.zip' -DestinationPath '%%R_tmp' -Force"
    for /d %%D in (%%R_tmp\*) do (
      xcopy /E /I /Y %%D %%R >nul
    )
    rmdir /S /Q %%R_tmp
    del %%R.zip
  )
)

echo.
echo 🎉 All repositories cloned successfully!

echo Building Docker images and starting services...
docker compose build --build-arg GITHUB_PAT=%GITHUB_TOKEN%

set GITHUB_TOKEN=
docker compose up -d

echo.
echo ✅ Setup complete! All services are running.
pause