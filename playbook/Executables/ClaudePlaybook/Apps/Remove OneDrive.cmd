@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\OneDrive.ps1" -Action Remove
