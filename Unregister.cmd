@echo off
rem Double-click to remove everything Attacca registered. Bypasses the PowerShell execution policy for this run.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Unregister-Attacca.ps1"
echo.
pause
