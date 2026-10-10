@echo off
rem Copilot and Recall
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group remove-copilot
