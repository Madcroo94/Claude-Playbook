@echo off
rem No drivers from Windows Update
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group wu-no-drivers
