@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title Khata Dalo - Build Setup
color 0B

echo ============================================================
echo   KHATA DALO  -  Automated Build ^& Setup Script
echo ============================================================
echo.

REM ---------------------------------------------------------------
REM 1. Check for Node.js
REM ---------------------------------------------------------------
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Node.js was not found on this system.
    echo [!] Opening the official Node.js download page...
    echo [!] Please install Node.js LTS, then re-run this script.
    start https://nodejs.org/en/download/
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%v in ('node -v') do echo [OK] Node.js found: %%v
)

REM ---------------------------------------------------------------
REM 2. Check for npm
REM ---------------------------------------------------------------
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] npm was not found. It should ship with Node.js.
    echo [!] Please reinstall Node.js from https://nodejs.org
    pause
    exit /b 1
) else (
    for /f "tokens=*" %%v in ('npm -v') do echo [OK] npm found: v%%v
)

REM ---------------------------------------------------------------
REM 3. Clean any previously installed dependencies / lockfile.
REM    This avoids a known npm bug (npm/cli#4828) where a
REM    node_modules folder or lockfile generated on a different
REM    OS/architecture leaves the wrong native binaries installed.
REM ---------------------------------------------------------------
if exist node_modules (
    echo [..] Removing existing node_modules for a clean install...
    rmdir /s /q node_modules
)
if exist package-lock.json (
    echo [..] Removing existing package-lock.json...
    del /f /q package-lock.json
)

echo.
echo ------------------------------------------------------------
echo   Installing project dependencies (this may take a minute)
echo ------------------------------------------------------------
call npm install
if %errorlevel% neq 0 (
    echo [!] npm install failed. Check your internet connection and try again.
    pause
    exit /b 1
)
echo [OK] All dependencies installed.

echo.
echo ------------------------------------------------------------
echo   Setting up the Python backend (FastAPI + SQLite)
echo ------------------------------------------------------------
call "%~dp0backend-setup.bat" --silent-continue
if not exist "backend\.venv\Scripts\python.exe" (
    echo [!] Backend virtual environment was not created. See backend-setup.bat output above.
    pause
    exit /b 1
)
echo [OK] Backend ready.

echo.
echo ------------------------------------------------------------
echo   Building the React frontend (vite build)
echo ------------------------------------------------------------
call npm run build
if %errorlevel% neq 0 (
    echo [!] Frontend build failed. See the errors above.
    echo [!] If you see an error about a "native binding" or
    echo [!] "rolldown-binding", delete the node_modules folder and
    echo [!] package-lock.json manually and re-run this script.
    pause
    exit /b 1
)
echo [OK] Frontend build complete.

echo.
echo ------------------------------------------------------------
echo   Packaging Windows installer (electron-builder)
echo ------------------------------------------------------------
set CSC_IDENTITY_AUTO_DISCOVERY=false
call npx electron-builder --win
if %errorlevel% neq 0 (
    echo [!] electron-builder failed. See the errors above.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo   BUILD COMPLETE
echo   Your installer is ready inside the "release" folder:
echo   KhataDalo-Setup-v1.0.0.exe
echo ============================================================
echo.
pause
