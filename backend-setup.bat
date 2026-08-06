@echo off
setlocal enabledelayedexpansion
set SILENT=%~1
cd /d "%~dp0"
if "%SILENT%"=="" (
  title Khata Dalo - Backend Setup
  color 0B
)

echo ============================================================
echo   KHATA DALO  -  Python Backend Setup (FastAPI + SQLite)
echo ============================================================
echo.

REM ---------------------------------------------------------------
REM 1. Check for Python
REM ---------------------------------------------------------------
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Python was not found on this system.
    echo [!] Opening the official Python download page...
    echo [!] Please install Python 3.10 or newer - check "Add Python to PATH"
    echo [!] during setup - then re-run this script.
    start https://www.python.org/downloads/
    if "%SILENT%"=="" pause
    exit /b 1
) else (
    for /f "tokens=*" %%v in ('python --version') do echo [OK] Found: %%v
)

pushd "%~dp0backend"

REM ---------------------------------------------------------------
REM 2. Create a virtual environment (kept local to backend/.venv so
REM    it never conflicts with any other Python install on the PC)
REM ---------------------------------------------------------------
if not exist ".venv" (
    echo [..] Creating virtual environment in backend\.venv ...
    python -m venv .venv
    if %errorlevel% neq 0 (
        echo [!] Failed to create the virtual environment.
        popd
        if "%SILENT%"=="" pause
        exit /b 1
    )
) else (
    echo [OK] Virtual environment already exists.
)

echo.
echo ------------------------------------------------------------
echo   Installing backend dependencies (FastAPI, SQLAlchemy, ...)
echo ------------------------------------------------------------
call ".venv\Scripts\python.exe" -m pip install --upgrade pip --quiet
call ".venv\Scripts\python.exe" -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo [!] pip install failed. Check your internet connection and try again.
    popd
    if "%SILENT%"=="" pause
    exit /b 1
)

popd
echo.
echo ============================================================
echo   BACKEND SETUP COMPLETE
echo   The database (khata_dalo.db) will be created automatically
echo   the first time the app runs.
echo   You can now run start-dev.bat or build.bat.
echo ============================================================
echo.
if "%SILENT%"=="" pause
