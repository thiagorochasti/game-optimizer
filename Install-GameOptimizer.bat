@echo off
:: Game Performance Optimizer - Installer Launcher
:: This script requests administrator privileges and launches the GUI installer

title Otimizador de Desempenho - Instalador

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_installer
) else (
    goto :request_admin
)

:request_admin
echo.
echo ============================================
echo  Otimizador de Desempenho - Instalacao
echo ============================================
echo.
echo Este instalador precisa de permissoes de
echo Administrador para configurar o otimizador.
echo.
echo Uma janela de Controle de Conta de Usuario 
echo (UAC) aparecera. Clique em "Sim" para continuar.
echo.
pause

:: Re-launch as administrator
powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit

:run_installer
echo.
echo ============================================
echo  Iniciando instalador GUI...
echo ============================================
echo.

:: Execute Setup.ps1 with admin privileges
powershell -ExecutionPolicy Bypass -File "%~dp0Setup.ps1"

if %errorLevel% == 0 (
    echo.
    echo Instalacao concluida com sucesso!
    echo.
) else (
    echo.
    echo Erro durante instalacao. Verifique os logs.
    echo.
)

pause
exit
