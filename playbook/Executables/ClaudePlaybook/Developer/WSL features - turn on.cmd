@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Wsl.ps1" -Action Enable
