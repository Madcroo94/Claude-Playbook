@echo off
rem Taskbar on the left
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group ui-taskbar-left
