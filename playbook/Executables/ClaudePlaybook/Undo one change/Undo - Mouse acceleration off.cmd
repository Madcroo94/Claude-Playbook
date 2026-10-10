@echo off
rem Mouse acceleration off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group gaming-mouse
