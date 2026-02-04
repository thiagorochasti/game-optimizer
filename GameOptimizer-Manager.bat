@echo off
REM Game Performance Optimizer - Launcher
REM Inicia o gerenciador em modo elevado

chcp 65001 >nul
powershell -ExecutionPolicy Bypass -File "%~dp0GameOptimizer-Manager.ps1"
pause
