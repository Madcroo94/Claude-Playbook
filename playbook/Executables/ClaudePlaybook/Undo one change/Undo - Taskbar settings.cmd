@echo off
rem Taskbar settings
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group ui-taskbar
