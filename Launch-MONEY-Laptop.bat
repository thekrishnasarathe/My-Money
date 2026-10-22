@echo off
title MONEY - Personal Finance Manager for Laptop
echo Starting MONEY Web App on Laptop...
cd /d "%~dp0My-Money\build\web"
start "" "http://localhost:8080"
python -m http.server 8080
