@echo off
rem Privacy and telemetry settings
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group privacy
