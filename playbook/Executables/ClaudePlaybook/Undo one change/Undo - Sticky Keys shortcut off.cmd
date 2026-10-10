@echo off
rem Sticky Keys shortcut off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group gaming-stickykeys
