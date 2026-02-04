#Requires -Version 5.1
#Requires -RunAsAdministrator

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptPath "config.json"
$lastConfigPath = Join-Path $ScriptPath "setup-last.json"

# --- Process Detection ---
$systemPaths = @('C:\Windows', 'C:\Program Files\Windows', 'C:\Program Files (x86)\Windows')
$systemProcesses = @('svchost', 'csrss', 'wininit', 'services', 'lsass', 'winlogon', 'dwm', 'explorer', 'SearchIndexer', 'RuntimeBroker', 'taskhostw', 'fontdrvhost', 'conhost', 'sihost', 'ctfmon', 'TextInputHost', 'ShellExperienceHost', 'StartMenuExperienceHost', 'SearchApp', 'dllhost', 'spoolsv', 'MsMpEng', 'NisSrv', 'SecurityHealthService', 'powershell', 'pwsh', 'cmd', 'audiodg', 'WmiPrvSE', 'LockApp')

$allProcesses = Get-Process | Where-Object { $_.Path -ne $null -and $_.Name -notin $systemProcesses } | Select-Object Name, Path -Unique
$userProcesses = $allProcesses | Where-Object {
    $path = $_.Path
    $isSystem = $false
    foreach ($sysPath in $systemPaths) {
        if ($path -like "$sysPath*") { $isSystem = $true; break }
    }
    -not $isSystem
} | Sort-Object Name -Unique

# --- State ---
$global:WizardState = @{
    TriggerProcess   = @()
    ManagedProcesses = @()
    ReopenProcesses  = @()
    EnableServices   = $true
}

# --- Load Previous Config ---
$previousTrigger = $null
$previousSelection = @{}

if (Test-Path $lastConfigPath) {
    try {
        $lastConfig = Get-Content $lastConfigPath -Raw | ConvertFrom-Json
        $previousTrigger = $lastConfig.triggerProcess
        foreach ($proc in $lastConfig.processesToManage) { $previousSelection[$proc] = $true }
        $global:WizardState.EnableServices = $lastConfig.settings.enableServiceManagement
    }
    catch {}
}

# --- GUI Setup ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Otimizador Universal v3.5 - Configuração"
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::White

# Container Panel (Holds the steps)
$containerPanel = New-Object System.Windows.Forms.Panel
$containerPanel.Location = New-Object System.Drawing.Point(0, 0)
$containerPanel.Size = New-Object System.Drawing.Size(700, 520)
$form.Controls.Add($containerPanel)

# Footer Panel (Navigation Buttons)
$footerPanel = New-Object System.Windows.Forms.Panel
$footerPanel.Location = New-Object System.Drawing.Point(0, 520)
$footerPanel.Size = New-Object System.Drawing.Size(700, 60)
$footerPanel.BackColor = [System.Drawing.Color]::WhiteSmoke
$form.Controls.Add($footerPanel)

# --- Navigation Buttons ---
$btnBack = New-Object System.Windows.Forms.Button
$btnBack.Text = "< Voltar"
$btnBack.Size = New-Object System.Drawing.Size(100, 35)
$btnBack.Location = New-Object System.Drawing.Point(20, 10)
$btnBack.Enabled = $false
$footerPanel.Controls.Add($btnBack)

$btnNext = New-Object System.Windows.Forms.Button
$btnNext.Text = "Próximo >"
$btnNext.Size = New-Object System.Drawing.Size(100, 35)
$btnNext.Location = New-Object System.Drawing.Point(560, 10)
$btnNext.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$btnNext.ForeColor = [System.Drawing.Color]::White
$footerPanel.Controls.Add($btnNext)

# --- Step 1: Trigger Selection ---
$panelStep1 = New-Object System.Windows.Forms.Panel
$panelStep1.Dock = "Fill"
$containerPanel.Controls.Add($panelStep1)

$lblStep1Headers = New-Object System.Windows.Forms.Label
$lblStep1Headers.Text = "Passo 1: Quais aplicativos ativam o modo foco?"
$lblStep1Headers.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblStep1Headers.Location = New-Object System.Drawing.Point(20, 20)
$lblStep1Headers.AutoSize = $true
$panelStep1.Controls.Add($lblStep1Headers)

$lblStep1Desc = New-Object System.Windows.Forms.Label
$lblStep1Desc.Text = "Selecione um ou mais apps. Ao abrir qualquer um deles, o otimizador será ativado."
$lblStep1Desc.Location = New-Object System.Drawing.Point(25, 60)
$lblStep1Desc.AutoSize = $true
$lblStep1Desc.ForeColor = [System.Drawing.Color]::Gray
$panelStep1.Controls.Add($lblStep1Desc)

$contentPanelStep1 = New-Object System.Windows.Forms.Panel
$contentPanelStep1.Location = New-Object System.Drawing.Point(20, 100)
$contentPanelStep1.Size = New-Object System.Drawing.Size(660, 350)
$contentPanelStep1.AutoScroll = $true
$contentPanelStep1.BorderStyle = "FixedSingle"
$panelStep1.Controls.Add($contentPanelStep1)

$triggerCheckboxes = @{}
$yPosStep1 = 10
foreach ($proc in $userProcesses) {
    if ($proc.Name -in $previousSelection.Keys) { continue }
    
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Location = New-Object System.Drawing.Point(10, $yPosStep1)
    $cb.Size = New-Object System.Drawing.Size(600, 25)
    $cb.Text = $proc.Name
    $cb.Tag = $proc.Name
    
    # Pre-select logic
    if ($previousTrigger -is [array] -and $proc.Name -in $previousTrigger) {
        $cb.Checked = $true
    }
    elseif ($previousTrigger -is [string] -and $proc.Name -eq $previousTrigger) {
        $cb.Checked = $true
    }
    elseif ($null -eq $previousTrigger -and $proc.Name -eq "steam") {
        $cb.Checked = $true
    }
    
    $contentPanelStep1.Controls.Add($cb)
    $triggerCheckboxes[$proc.Name] = $cb
    $yPosStep1 += 30
}

# --- Step 2: Managed Apps Selection ---
$panelStep2 = New-Object System.Windows.Forms.Panel
$panelStep2.Dock = "Fill"
$panelStep2.Visible = $false
$containerPanel.Controls.Add($panelStep2)

$lblStep2Headers = New-Object System.Windows.Forms.Label
$lblStep2Headers.Text = "Passo 2: O que devemos fechar?"
$lblStep2Headers.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblStep2Headers.Location = New-Object System.Drawing.Point(20, 20)
$lblStep2Headers.AutoSize = $true
$panelStep2.Controls.Add($lblStep2Headers)

$contentPanelStep2 = New-Object System.Windows.Forms.Panel
$contentPanelStep2.Location = New-Object System.Drawing.Point(20, 80)
$contentPanelStep2.Size = New-Object System.Drawing.Size(660, 350)
$contentPanelStep2.AutoScroll = $true
$contentPanelStep2.BorderStyle = "FixedSingle"
$panelStep2.Controls.Add($contentPanelStep2)

$managedCheckboxes = @{}
$yPosStep2 = 10
foreach ($proc in $userProcesses) {
    $cb = New-Object System.Windows.Forms.CheckBox
    $cb.Location = New-Object System.Drawing.Point(10, $yPosStep2)
    $cb.Size = New-Object System.Drawing.Size(600, 25)
    $cb.Text = $proc.Name
    $cb.Tag = $proc.Name
    $cb.Checked = $previousSelection.ContainsKey($proc.Name)
    $contentPanelStep2.Controls.Add($cb)
    $managedCheckboxes[$proc.Name] = $cb
    $yPosStep2 += 30
}

$serviceCheckbox = New-Object System.Windows.Forms.CheckBox
$serviceCheckbox.Location = New-Object System.Drawing.Point(20, 450)
$serviceCheckbox.Size = New-Object System.Drawing.Size(600, 25)
$serviceCheckbox.Text = "Otimizar Serviços do Windows (Recomendado)"
$serviceCheckbox.Checked = $global:WizardState.EnableServices
$panelStep2.Controls.Add($serviceCheckbox)

# --- Logic ---
$script:currentStep = 1

$btnNext.Add_Click({
        if ($script:currentStep -eq 1) {
            $selectedTriggers = @()
            foreach ($cb in $triggerCheckboxes.Values) {
                if ($cb.Checked) { $selectedTriggers += $cb.Text }
            }
        
            if ($selectedTriggers.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("Por favor, selecione pelo menos um aplicativo gatilho.")
                return
            }
            $global:WizardState.TriggerProcess = $selectedTriggers
        
            # Move to Step 2
            $panelStep1.Visible = $false
            $panelStep2.Visible = $true
            $script:currentStep = 2
            $btnBack.Enabled = $true
            $btnNext.Text = "Instalar"
            $btnNext.BackColor = [System.Drawing.Color]::Green
        }
        elseif ($script:currentStep -eq 2) {
            # Finish
            $global:WizardState.ManagedProcesses = @()
            $global:WizardState.ReopenProcesses = @()
        
            foreach ($cb in $managedCheckboxes.Values) {
                if ($cb.Checked) {
                    # Don't manage the trigger processes!
                    if ($cb.Text -in $global:WizardState.TriggerProcess) { continue }
                
                    $global:WizardState.ManagedProcesses += $cb.Text
                    $global:WizardState.ReopenProcesses += $cb.Text
                }
            }
        
            if ($global:WizardState.ManagedProcesses.Count -eq 0) {
                [System.Windows.Forms.MessageBox]::Show("Selecione pelo menos um aplicativo para fechar.")
                return
            }
        
            $global:WizardState.EnableServices = $serviceCheckbox.Checked
            $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $form.Close()
        }
    })

$btnBack.Add_Click({
        if ($script:currentStep -eq 2) {
            $panelStep2.Visible = $false
            $panelStep1.Visible = $true
            $script:currentStep = 1
            $btnBack.Enabled = $false
            $btnNext.Text = "Próximo >"
            $btnNext.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
        }
    })

# --- Run ---
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Configurando Otimizador..."
    
    $config = @{
        triggerProcess        = $global:WizardState.TriggerProcess
        processesToManage     = $global:WizardState.ManagedProcesses
        processesToReopenOnly = $global:WizardState.ReopenProcesses
        servicesToManage      = if ($global:WizardState.EnableServices) { @("FA_Scheduler", "DiagTrack", "SysMain", "BITS", "DoSvc", "WerSvc", "MapsBroker", "RemoteRegistry") } else { @() }
        settings              = @{
            enableLogging           = $true
            logPath                 = "logs\game-optimizer.log"
            reopenDelay             = 3
            steamCheckInterval      = 5
            enableServiceManagement = $global:WizardState.EnableServices
        }
    }
    
    $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath -Encoding UTF8
    $config | ConvertTo-Json -Depth 10 | Set-Content $lastConfigPath -Encoding UTF8
    
    $installScript = Join-Path $ScriptPath "Install.ps1"
    if (Test-Path $installScript) {
        & $installScript
        Write-Host "Sucesso!" -ForegroundColor Green
    }
}
