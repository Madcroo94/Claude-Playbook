@echo off
rem Classic right-click menu
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group ui-classic-menu
