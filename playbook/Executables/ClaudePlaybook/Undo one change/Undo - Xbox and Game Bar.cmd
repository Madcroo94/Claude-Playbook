@echo off
rem Xbox and Game Bar
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group remove-xbox
