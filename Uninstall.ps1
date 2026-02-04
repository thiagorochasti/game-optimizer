#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstallation script for Game Performance Optimizer
.DESCRIPTION
    Removes the scheduled task and optionally cleans up log files
#>

$ErrorActionPreference = "Stop"

# Configuration
$TaskName = "GamePerformanceOptimizer"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogPath = Join-Path $ScriptPath "logs"

Write-Host "`n=== Otimizador de Desempenho para Jogos - Desinstalação ===" -ForegroundColor Cyan
Write-Host ""

# Check if task exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

if (-not $existingTask) {
    Write-Host "[INFO] A tarefa '$TaskName' não está instalada." -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

Write-Host "[1/2] Parando e removendo tarefa agendada..." -ForegroundColor Yellow

try {
    # Stop the task if running
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($taskInfo -and $taskInfo.LastTaskResult -eq 267009) {
        Write-Host "      Parando tarefa em execução..." -ForegroundColor Yellow
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
    
    # Remove the task
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "      Tarefa removida com sucesso!" -ForegroundColor Green
}
catch {
    Write-Host "      [ERRO] Falha ao remover tarefa: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n[2/2] Limpando..." -ForegroundColor Yellow

# Ask about log files
if (Test-Path $LogPath) {
    Write-Host "      Deseja excluir os arquivos de log? (S/N): " -ForegroundColor Yellow -NoNewline
    $deleteLogs = Read-Host
    
    if ($deleteLogs -eq 'S' -or $deleteLogs -eq 's' -or $deleteLogs -eq 'Y' -or $deleteLogs -eq 'y') {
        try {
            Remove-Item -Path $LogPath -Recurse -Force
            Write-Host "      Arquivos de log excluídos." -ForegroundColor Green
        }
        catch {
            Write-Host "      [AVISO] Falha ao excluir logs: $_" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "      Logs mantidos em: $LogPath" -ForegroundColor Cyan
    }
}

# Ask about state file
$StateFile = Join-Path $ScriptPath "state.json"
if (Test-Path $StateFile) {
    try {
        Remove-Item -Path $StateFile -Force
        Write-Host "      Arquivo de estado limpo." -ForegroundColor Green
    }
    catch {
        Write-Host "      [AVISO] Falha ao excluir arquivo de estado: $_" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Desinstalação Concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "O Otimizador de Desempenho foi removido." -ForegroundColor White
Write-Host ""
Write-Host "Os arquivos do script permanecem em:" -ForegroundColor Yellow
Write-Host "  $ScriptPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Você pode excluir a pasta inteira se não precisar mais." -ForegroundColor Yellow
Write-Host ""
