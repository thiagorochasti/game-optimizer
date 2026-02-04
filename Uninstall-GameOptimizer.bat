@echo off
:: Game Performance Optimizer - Uninstaller Launcher
:: This script requests administrator privileges and launches the uninstaller

title Game Performance Optimizer - Uninstaller

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_uninstaller
) else (
    goto :request_admin
)

:request_admin
echo.
echo ============================================
echo  Game Performance Optimizer - Uninstall
echo ============================================
echo.
echo Este desinstalador precisa de permissoes de
echo Administrador para remover o otimizador.
echo.
echo Uma janela de Controle de Conta de Usuario 
echo (UAC) aparecera. Clique em "Sim" para continuar.
echo.
pause

:: Re-launch as administrator
powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit

:run_uninstaller
echo.
echo ============================================
echo  Executando desinstalador...
echo ============================================
echo.

:: Execute Uninstall.ps1 with admin privileges
powershell -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1"

if %errorLevel% == 0 (
    echo.
    echo Desinstalacao concluida com sucesso!
    echo.
) else (
    echo.
    echo Erro durante desinstalacao.
    echo.
)

pause
exit
