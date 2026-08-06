@echo off
title Khata Dalo - Dev Mode
cd /d "%~dp0"
echo Starting Khata Dalo in development mode (hot reload)...

if not exist "backend\.venv\Scripts\python.exe" (
    echo Backend not set up yet - running backend-setup.bat first...
    call "%~dp0backend-setup.bat" --silent-continue
)

if exist node_modules (
    echo Using existing node_modules. If you hit a "native binding" error,
    echo delete node_modules and package-lock.json, then run build.bat once.
)
call npm install
call npm run electron:dev
