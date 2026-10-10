@echo off
rem dotnet and PowerShell telemetry opt-out
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group dev-telemetry-optout
