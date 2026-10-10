@echo off
rem OneDrive removal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group remove-onedrive
