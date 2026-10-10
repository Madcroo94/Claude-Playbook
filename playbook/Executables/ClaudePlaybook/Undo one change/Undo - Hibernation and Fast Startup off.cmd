@echo off
rem Hibernation and Fast Startup off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group disable-hibernation
