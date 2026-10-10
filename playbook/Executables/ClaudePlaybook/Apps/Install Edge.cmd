@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Edge.ps1" -Action Install
