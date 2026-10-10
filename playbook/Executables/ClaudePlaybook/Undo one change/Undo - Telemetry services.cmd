@echo off
rem Telemetry services
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group services
