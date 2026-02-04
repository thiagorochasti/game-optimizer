#Requires -Version 5.1

<#
.SYNOPSIS
    Game Performance Optimizer - Gerenciador Unificado
.DESCRIPTION
    Script unico para instalar, atualizar, desinstalar ou gerenciar o Game Optimizer
#>

# Fix console encoding for Portuguese characters
$OutputEncoding = [System.Text.Encoding]::UTF8
if ($PSVersionTable.PSVersion.Major -ge 6) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
}

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$Host.UI.RawUI.WindowTitle = "Game Performance Optimizer - Manager"

# Cores para output
function Write-Title {
    param([string]$Text)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
}

function Write-Option {
    param([string]$Number, [string]$Text, [string]$Color = "Yellow")
    Write-Host "  [$Number]" -ForegroundColor $Color -NoNewline
    Write-Host " $Text"
}

function Write-Status {
    param([string]$Text, [string]$Status, [string]$Color = "Green")
    Write-Host "  $Text " -NoNewline
    Write-Host $Status -ForegroundColor $Color
}

# Verifica se esta rodando como Admin
function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Solicita privilegios de Admin
function Request-AdminPrivileges {
    if (-not (Test-IsAdmin)) {
        Write-Host "`nEste gerenciador precisa de privilegios de Administrador." -ForegroundColor Yellow
        Write-Host "Solicitando elevacao..." -ForegroundColor Gray
        Start-Sleep -Seconds 1
        
        Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.ScriptName)`"" -Wait
        exit
    }
}

# Verifica status da instalacao
function Get-InstallationStatus {
    $task = Get-ScheduledTask -TaskName "GamePerformanceOptimizer" -ErrorAction SilentlyContinue
    
    if ($task) {
        return @{
            Installed    = $true
            State        = $task.State
            LastRun      = (Get-ScheduledTaskInfo -TaskName "GamePerformanceOptimizer").LastRunTime
            ConfigExists = (Test-Path (Join-Path $ScriptPath "config.json"))
        }
    }
    
    return @{
        Installed    = $false
        State        = "NotInstalled"
        LastRun      = $null
        ConfigExists = $false
    }
}

# Executa instalacao inicial
function Start-Installation {
    Write-Title "Instalacao do Game Optimizer"
    
    $setupScript = Join-Path $ScriptPath "Setup.ps1"
    
    if (-not (Test-Path $setupScript)) {
        Write-Host "  [ERRO] Setup.ps1 nao encontrado!" -ForegroundColor Red
        Write-Host "  Certifique-se de que todos os arquivos estao na pasta." -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "  Iniciando assistente de configuracao...`n" -ForegroundColor Cyan
    
    try {
        & $setupScript
        return $true
    }
    catch {
        Write-Host "`n  [ERRO] Falha na instalacao: $_" -ForegroundColor Red
        return $false
    }
}

# Atualiza instalacao existente
function Start-Update {
    Write-Title "Atualizando Game Optimizer"
    
    Write-Host "  [1/3] Parando servico..." -ForegroundColor Yellow
    Stop-ScheduledTask -TaskName "GamePerformanceOptimizer" -ErrorAction SilentlyContinue
    Write-Host "        Servico parado!" -ForegroundColor Green
    
    Write-Host "`n  [2/3] Atualizando arquivos..." -ForegroundColor Yellow
    # Arquivos ja estao atualizados (usuario substituiu manualmente ou via git)
    Write-Host "        Arquivos prontos!" -ForegroundColor Green
    
    Write-Host "`n  [3/3] Reiniciando servico..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName "GamePerformanceOptimizer"
    Start-Sleep -Seconds 2
    
    $task = Get-ScheduledTask -TaskName "GamePerformanceOptimizer"
    if ($task.State -eq "Running") {
        Write-Host "        Servico reiniciado com sucesso!" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "        Atencao: Servico nao esta rodando." -ForegroundColor Yellow
        return $false
    }
}

# Desinstala completamente
function Start-Uninstallation {
    Write-Title "Desinstalacao do Game Optimizer"
    
    $uninstallScript = Join-Path $ScriptPath "Uninstall.ps1"
    
    if (Test-Path $uninstallScript) {
        & $uninstallScript
    }
    else {
        Write-Host "  Removendo tarefa agendada..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName "GamePerformanceOptimizer" -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  Desinstalacao concluida!" -ForegroundColor Green
    }
}

# Mostra status detalhado
function Show-DetailedStatus {
    Write-Title "Status do Game Optimizer"
    
    $status = Get-InstallationStatus
    $configPath = Join-Path $ScriptPath "config.json"
    
    Write-Status "Instalado:" $(if ($status.Installed) { "SIM" } else { "NAO" }) $(if ($status.Installed) { "Green" } else { "Red" })
    
    if ($status.Installed) {
        Write-Status "Estado da Tarefa:" $status.State $(if ($status.State -eq "Running") { "Green" } else { "Yellow" })
        
        if ($status.LastRun) {
            Write-Status "Ultima Execucao:" $status.LastRun.ToString("dd/MM/yyyy HH:mm:ss") "Cyan"
        }
        
        if ($status.ConfigExists) {
            try {
                $config = Get-Content $configPath -Raw | ConvertFrom-Json
                Write-Host "`n  Configuracao Atual:" -ForegroundColor White
                Write-Host "    Gatilhos: " -NoNewline
                Write-Host (($config.triggerProcess | Sort-Object) -join ", ") -ForegroundColor Cyan
                Write-Host "    Apps Gerenciados: " -NoNewline
                Write-Host (($config.processesToManage | Sort-Object) -join ", ") -ForegroundColor Cyan
            }
            catch {
                Write-Host "  [AVISO] Erro ao ler configuracao" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host ""
}

# Abre arquivo de log
function Open-LogFile {
    $logPath = Join-Path $ScriptPath "logs\game-optimizer.log"
    
    if (Test-Path $logPath) {
        Write-Host "`n  Abrindo log no Bloco de Notas..." -ForegroundColor Cyan
        notepad $logPath
    }
    else {
        Write-Host "`n  [AVISO] Arquivo de log nao encontrado." -ForegroundColor Yellow
        Write-Host "  Caminho esperado: $logPath" -ForegroundColor Gray
    }
}

# Menu principal
function Show-MainMenu {
    $status = Get-InstallationStatus
    
    Clear-Host
    Write-Title "Game Performance Optimizer v3.5"
    
    if (-not $status.Installed) {
        Write-Host "  Status: " -NoNewline
        Write-Host "NAO INSTALADO" -ForegroundColor Red
        Write-Host "`n  O Game Optimizer nao esta instalado neste sistema." -ForegroundColor Yellow
        Write-Host "  Ele fecha automaticamente aplicativos quando voce joga," -ForegroundColor Gray
        Write-Host "  melhorando o desempenho em jogos.`n" -ForegroundColor Gray
        
        Write-Option "1" "Instalar Game Optimizer" "Green"
        Write-Option "0" "Sair" "Gray"
    }
    else {
        Write-Host "  Status: " -NoNewline
        Write-Host "INSTALADO" -ForegroundColor Green
        Write-Host "  Estado: " -NoNewline
        Write-Host $status.State -ForegroundColor $(if ($status.State -eq "Running") { "Green" } else { "Yellow" })
        Write-Host ""
        
        Write-Option "1" "Ver Status Detalhado"
        Write-Option "2" "Atualizar/Reiniciar Servico" "Cyan"
        Write-Option "3" "Reconfigurar (mudar apps)" "Yellow"
        Write-Option "4" "Ver Logs"
        Write-Option "5" "Desinstalar" "Red"
        Write-Option "0" "Sair" "Gray"
    }
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host -NoNewline "  Escolha uma opcao: "
    
    $choice = Read-Host
    return $choice
}

# Funcao principal
function Main {
    Request-AdminPrivileges
    
    do {
        $choice = Show-MainMenu
        $status = Get-InstallationStatus
        
        switch ($choice) {
            "1" {
                if (-not $status.Installed) {
                    $success = Start-Installation
                    if ($success) {
                        Write-Host "`n  Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    }
                }
                else {
                    Show-DetailedStatus
                    Write-Host "  Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "2" {
                if ($status.Installed) {
                    $success = Start-Update
                    Write-Host "`n  Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "3" {
                if ($status.Installed) {
                    Start-Installation  # Reinstala, permitindo reconfiguracao
                    Write-Host "`n  Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
            "4" {
                if ($status.Installed) {
                    Open-LogFile
                }
            }
            "5" {
                if ($status.Installed) {
                    Write-Host "`n  Tem certeza que deseja desinstalar? (S/N): " -ForegroundColor Yellow -NoNewline
                    $confirm = Read-Host
                    if ($confirm -eq 'S' -or $confirm -eq 's' -or $confirm -eq 'Y' -or $confirm -eq 'y') {
                        Start-Uninstallation
                        Write-Host "`n  Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Gray
                        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    }
                }
            }
            "0" {
                Write-Host "`n  Saindo..." -ForegroundColor Gray
                Start-Sleep -Seconds 1
                exit
            }
            default {
                Write-Host "`n  Opcao invalida! Pressione qualquer tecla..." -ForegroundColor Red
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
        }
        
    } while ($true)
}

# Executa
Main
