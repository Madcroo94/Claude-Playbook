@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Appx.ps1" -Action Reinstall -Group remove-copilot
