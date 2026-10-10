@echo off
rem Foreground priority
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group gaming-latency
