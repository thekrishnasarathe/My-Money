@echo off
title MONEY - Personal Finance Manager
echo ===================================================
echo Starting MONEY Web Application & Interactive Guide...
echo ===================================================
cd /d "%~dp0"

echo Opening browser at http://localhost:8080...
start "" "http://localhost:8080"

where node >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Starting server with Node.js on port 8080...
    node serve_web.js
    goto :end
)

where python >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Starting server with Python on port 8080...
    if exist "%~dp0My-Money\build\web" (
        cd /d "%~dp0My-Money\build\web"
    )
    python -m http.server 8080
    goto :end
)

echo [ERROR] Neither Node.js nor Python was found.
pause

:end
