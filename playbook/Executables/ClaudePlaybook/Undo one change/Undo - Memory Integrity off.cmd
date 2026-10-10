@echo off
rem Memory Integrity off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Internal\Restore.ps1" -Group gaming-memory-integrity
