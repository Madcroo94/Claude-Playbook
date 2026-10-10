@echo off
rem Telemetry scheduled tasks
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group scheduled-tasks
