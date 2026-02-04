#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installation script for Game Performance Optimizer
.DESCRIPTION
    Creates a scheduled task to run the optimizer on Windows startup
#>

$ErrorActionPreference = "Stop"

# Configuration
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$MainScript = Join-Path $ScriptPath "GameOptimizer.ps1"
$TaskName = "GamePerformanceOptimizer"
$TaskDescription = "Automatically manages processes when Steam starts/stops to optimize gaming performance"

Write-Host "`n=== Otimizador de Desempenho para Jogos v3.5 - Instalação ===" -ForegroundColor Cyan
Write-Host ""

# Check if main script exists
if (-not (Test-Path $MainScript)) {
    Write-Host "[ERRO] Script principal não encontrado: $MainScript" -ForegroundColor Red
    exit 1
}

# Check if config exists
$ConfigPath = Join-Path $ScriptPath "config.json"
if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERRO] Arquivo de configuração não encontrado: $ConfigPath" -ForegroundColor Red
    exit 1
}

Write-Host "[1/4] Verificando tarefa agendada..." -ForegroundColor Yellow

# Check if task already exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($existingTask) {
    Write-Host "      Tarefa já existe. Deseja reinstalar? (S/N): " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    
    if ($response -eq 'S' -or $response -eq 's' -or $response -eq 'Y' -or $response -eq 'y') {
        Write-Host "      Removendo tarefa antiga..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "      Tarefa antiga removida." -ForegroundColor Green
    }
    else {
        Write-Host "`n[CANCELADO] Instalação cancelada pelo usuário." -ForegroundColor Yellow
        exit 0
    }
}
else {
    Write-Host "      Nenhuma tarefa existente encontrada." -ForegroundColor Green
}

Write-Host "`n[2/4] Criando tarefa agendada..." -ForegroundColor Yellow

try {
    # Define the action
    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$MainScript`""
    
    # Define the trigger (at logon)
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    
    # Define settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false `
        -DontStopOnIdleEnd `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)
    
    # Define principal (run with highest privileges)
    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType Interactive `
        -RunLevel Highest
    
    # Register the task
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Description $TaskDescription `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Force | Out-Null
    
    Write-Host "      Tarefa criada com sucesso!" -ForegroundColor Green
}
catch {
    Write-Host "      [ERRO] Falha ao criar tarefa: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n[3/4] Verificando instalação..." -ForegroundColor Yellow

$verifyTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if ($verifyTask) {
    Write-Host "      Tarefa verificada: $($verifyTask.TaskName)" -ForegroundColor Green
    Write-Host "      Estado: $($verifyTask.State)" -ForegroundColor Green
}
else {
    Write-Host "      [ERRO] Falha na verificação da tarefa!" -ForegroundColor Red
    exit 1
}

Write-Host "`n[4/4] Testando script..." -ForegroundColor Yellow

try {
    # Quick syntax check
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $MainScript -Raw), [ref]$null)
    Write-Host "      Teste de sintaxe PowerShell passou!" -ForegroundColor Green
}
catch {
    Write-Host "      [AVISO] Verificação de sintaxe falhou: $_" -ForegroundColor Yellow
    Write-Host "      Por favor, verifique o script manualmente." -ForegroundColor Yellow
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Instalação Concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nome da Tarefa:" -ForegroundColor White -NoNewline
Write-Host " $TaskName" -ForegroundColor Cyan
Write-Host "Local do Script:" -ForegroundColor White -NoNewline
Write-Host " $MainScript" -ForegroundColor Cyan
Write-Host "Configuração:" -ForegroundColor White -NoNewline
Write-Host " $ConfigPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "O otimizador iniciará automaticamente:" -ForegroundColor Yellow
Write-Host "  - No próximo login do Windows" -ForegroundColor White
Write-Host "  - Ou você pode iniciá-lo manualmente agora" -ForegroundColor White
Write-Host ""
Write-Host "Para iniciar agora, execute:" -ForegroundColor Yellow
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para desinstalar, execute:" -ForegroundColor Yellow
Write-Host "  .\Uninstall.ps1" -ForegroundColor Cyan
Write-Host ""

# Ask if user wants to start now
Write-Host "Deseja iniciar o otimizador agora? (S/N): " -ForegroundColor Yellow -NoNewline
$startNow = Read-Host

if ($startNow -eq 'S' -or $startNow -eq 's' -or $startNow -eq 'Y' -or $startNow -eq 'y') {
    try {
        Start-ScheduledTask -TaskName $TaskName
        Write-Host "`n[SUCESSO] Otimizador iniciado!" -ForegroundColor Green
        Write-Host "Verifique os logs em: $(Join-Path $ScriptPath 'logs\game-optimizer.log')" -ForegroundColor Cyan
    }
    catch {
        Write-Host "`n[ERRO] Falha ao iniciar tarefa: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "`nO otimizador iniciará no próximo login." -ForegroundColor Yellow
}

Write-Host ""
