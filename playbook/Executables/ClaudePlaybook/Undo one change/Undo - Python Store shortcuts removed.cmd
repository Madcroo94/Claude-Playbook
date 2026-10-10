@echo off
rem Python Store shortcuts removed
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group dev-python-alias
