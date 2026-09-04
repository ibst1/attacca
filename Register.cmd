@echo off
rem Double-click to register Attacca (HKCU only). Bypasses the PowerShell execution policy for this run.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Register-Attacca.ps1"
echo.
pause
