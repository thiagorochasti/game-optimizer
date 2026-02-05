#Requires -Version 5.1

<#
.SYNOPSIS
    Game Performance Optimizer - Automatically manage processes when Steam starts/stops
.DESCRIPTION
    Monitors Steam startup using WMI events and automatically closes configured processes
    to free up resources during gaming. Reopens closed processes when Steam exits.
.NOTES
    Author: Game Optimizer
    Version: 3.5
#>

# Script configuration
$script:Config = $null
$script:ClosedProcesses = @{}
$script:StoppedServices = @()
$script:LogPath = ""
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:StateFile = Join-Path $script:ScriptPath "state.json"
$script:SteamRunning = $false

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    if (-not $script:Config.settings.enableLogging) { return }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    try {
        $logDir = Split-Path -Parent $script:LogPath
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $script:LogPath -Value $logMessage -ErrorAction SilentlyContinue
    }
    catch {
        # Silently fail if logging doesn't work
    }
}

# Load configuration
function Load-Config {
    try {
        $configPath = Join-Path $script:ScriptPath "config.json"
        if (-not (Test-Path $configPath)) {
            throw "Configuration file not found: $configPath"
        }
        
        $script:Config = Get-Content $configPath -Raw | ConvertFrom-Json
        $script:LogPath = Join-Path $script:ScriptPath $script:Config.settings.logPath
        
        Write-Log "Configuration loaded successfully" -Level SUCCESS
        return $true
    }
    catch {
        Write-Host "Error loading configuration: $_" -ForegroundColor Red
        return $false
    }
}

# Get full path of a running process
function Get-ProcessPath {
    param([string]$ProcessName)
    
    try {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($process) {
            return $process.Path
        }
    }
    catch {
        Write-Log "Error getting path for process $ProcessName : $_" -Level WARNING
    }
    return $null
}

# Stop managed Windows services
function Stop-ManagedServices {
    if (-not $script:Config.settings.enableServiceManagement) { return }
    
    Write-Log "Stopping Windows services for gaming optimization..." -Level INFO
    
    $script:StoppedServices = @()
    
    foreach ($serviceName in $script:Config.servicesToManage) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            
            if ($service -and $service.Status -eq 'Running') {
                Write-Log "Stopping service: $serviceName ($($service.DisplayName))" -Level INFO
                
                # Store original startup type and current status
                $startupType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$serviceName'").StartMode
                $script:StoppedServices += @{
                    Name                = $serviceName
                    OriginalStartupType = $startupType
                }
                
                # Stop service
                Stop-Service -Name $serviceName -Force -ErrorAction Stop
                Write-Log "Successfully stopped service: $serviceName" -Level SUCCESS
            }
            elseif ($service) {
                Write-Log "Service already stopped: $serviceName" -Level INFO
            }
            else {
                Write-Log "Service not found: $serviceName" -Level WARNING
            }
        }
        catch {
            Write-Log "Error stopping service $serviceName : $_" -Level ERROR
        }
    }
}

# Restart managed Windows services
function Restart-ManagedServices {
    if (-not $script:Config.settings.enableServiceManagement) { return }
    
    Write-Log "Restarting Windows services..." -Level INFO
    
    foreach ($serviceInfo in $script:StoppedServices) {
        try {
            $serviceName = $serviceInfo.Name
            $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
            
            if ($service) {
                Write-Log "Restarting service: $serviceName" -Level INFO
                Start-Service -Name $serviceName -ErrorAction Stop
                Write-Log "Successfully restarted service: $serviceName" -Level SUCCESS
            }
        }
        catch {
            Write-Log "Error restarting service $serviceName : $_" -Level ERROR
        }
    }
    
    $script:StoppedServices = @()
}

# Get current Focus Assist state
function Get-FocusAssistState {
    <#
    .SYNOPSIS
        Retrieves the current Focus Assist state from Windows registry
    .RETURNS
        0 = Focus Assist enabled (notifications blocked)
        1 = Focus Assist disabled (notifications normal)
        $null = Error reading state
    #>
    try {
        $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        
        if (Test-Path $regPath) {
            $value = Get-ItemProperty -Path $regPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -ErrorAction SilentlyContinue
            if ($null -ne $value) {
                return $value.NOC_GLOBAL_SETTING_TOASTS_ENABLED
            }
        }
        
        # Default: notifications enabled
        return 1
    }
    catch {
        Write-Log "Error getting Focus Assist state: $_" -Level WARNING
        return $null
    }
}

# Set Focus Assist state
function Set-FocusAssistState {
    <#
    .SYNOPSIS
        Sets the Focus Assist state in Windows registry
    .PARAMETER Mode
        0 = Enable Focus Assist (block notifications)
        1 = Disable Focus Assist (allow notifications)
    #>
    param([int]$Mode)
    
    try {
        $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        
        # Create key if it doesn't exist
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        
        Set-ItemProperty -Path $regPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value $Mode -Type DWord
        $modeText = if ($Mode -eq 0) { "ENABLED (blocked)" } else { "DISABLED (normal)" }
        Write-Log "Focus Assist set to: $modeText" -Level INFO
        return $true
    }
    catch {
        Write-Log "Error setting Focus Assist: $_" -Level ERROR
        return $false
    }
}


# Get full path of a running process

# Close managed processes
function Close-ManagedProcesses {
    Write-Log "Trigger App started - closing managed processes..." -Level INFO
    
    $script:ClosedProcesses = @{}
    
    foreach ($processName in $script:Config.processesToManage) {
        try {
            # Generic: Try to extract startup info from Startup folder shortcut FIRST
            # This works for ANY app that has a .lnk in the Startup folder
            if (-not $script:ClosedProcesses.ContainsKey($processName)) {
                $startupFolder = [Environment]::GetFolderPath("Startup")
                
                # Try common shortcut name patterns: ProcessName.lnk, ProcessName*.lnk
                # Also try without last character if process ends with 'd' (e.g., espansod -> espanso)
                $possibleShortcuts = @(
                    (Join-Path $startupFolder "$processName.lnk"),
                    (Get-ChildItem -Path $startupFolder -Filter "$processName*.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)
                )
                
                # Fuzzy match: if process ends with 'd', also try without it
                if ($processName -match 'd$') {
                    $baseProcessName = $processName.Substring(0, $processName.Length - 1)
                    $possibleShortcuts += @(
                        (Join-Path $startupFolder "$baseProcessName.lnk"),
                        (Get-ChildItem -Path $startupFolder -Filter "$baseProcessName*.lnk" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)
                    )
                }
                
                foreach ($shortcutPath in $possibleShortcuts) {
                    if ($shortcutPath -and (Test-Path $shortcutPath)) {
                        try {
                            $shell = New-Object -ComObject WScript.Shell
                            $shortcut = $shell.CreateShortcut($shortcutPath)
                            
                            $targetPath = $shortcut.TargetPath
                            $arguments = $shortcut.Arguments
                            
                            if ($targetPath -and (Test-Path $targetPath)) {
                                $script:ClosedProcesses[$processName] = @{
                                    Path = $targetPath
                                    Args = $arguments
                                }
                                Write-Log "Extracted from Startup shortcut [$processName] - Path: $targetPath, Args: '$arguments'" -Level INFO
                                
                                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
                                break  # Found valid shortcut, stop looking
                            }
                            
                            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
                        }
                        catch {
                            Write-Log "Failed to read shortcut for $processName : $_" -Level WARNING
                        }
                    }
                }
            }

            $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue
            
            if ($processes) {
                foreach ($process in $processes) {
                    try {
                        $processPath = $process.Path
                        
                        if ($processPath) {
                            Write-Log "Closing: $processName (Path: $processPath)" -Level INFO
                            
                            # Store the path for later reopening ONLY if it's in the reopen list
                            if ($processName -in $script:Config.processesToReopenOnly) {
                                # IMPORTANT: Only use WMI if we DON'T already have info from shortcut
                                # Shortcut arguments take priority (e.g., Espanso uses "launcher" not "worker --monitor-daemon")
                                if (-not $script:ClosedProcesses.ContainsKey($processName)) {
                                    # Try to get command line arguments via WMI
                                    $args = ""
                                    try {
                                        $wmiProc = Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)" -ErrorAction Stop
                                        if ($wmiProc -and $wmiProc.CommandLine) {
                                            $cmdLine = $wmiProc.CommandLine
                                            if ($cmdLine.StartsWith("`"$processPath`"")) {
                                                $args = $cmdLine.Substring($processPath.Length + 2).Trim()
                                            } 
                                            elseif ($cmdLine.StartsWith($processPath)) {
                                                $args = $cmdLine.Substring($processPath.Length).Trim()
                                            }
                                        }
                                    }
                                    catch {
                                        Write-Log "Failed to get WMI args for $processName : $_" -Level WARNING
                                    }
    
                                    $script:ClosedProcesses[$processName] = @{
                                        Path = $processPath
                                        Args = $args
                                    }
                                    Write-Log "Saved for reopening: $processName (Args: '$args')" -Level INFO
                                }
                                else {
                                    Write-Log "Skipping WMI detection for $processName - already saved from shortcut" -Level INFO
                                }
                            }
                            else {
                                Write-Log "Will not reopen $processName (spawned by main executable)" -Level INFO
                            }
                            
                            # Force kill immediately
                            Stop-Process -Id $process.Id -Force -ErrorAction Stop
                            Write-Log "Successfully closed: $processName (ID: $($process.Id))" -Level SUCCESS
                        }
                        else {
                            Write-Log "Cannot get path for $processName (ID: $($process.Id)) - Access Denied?" -Level WARNING
                            # Attempt to kill anyway if we know the name matches
                            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                        }
                    }
                    catch {
                        Write-Log "Error processing instance of $processName (ID: $($process.Id)) : $_" -Level ERROR
                    }
                }
            }
            else {
                # Write-Log "Process not running: $processName" -Level INFO
            }
        }
        catch {
            Write-Log "General error closing $processName : $_" -Level ERROR
        }
    }
    
    # Stop Windows services
    Stop-ManagedServices
    
    # Save and enable Focus Assist (block notifications during gaming)
    if ($script:Config.settings.enableFocusAssist) {
        $script:OriginalFocusAssist = Get-FocusAssistState
        if ($null -ne $script:OriginalFocusAssist) {
            Set-FocusAssistState -Mode 0  # 0 = Block notifications
            $originalState = if ($script:OriginalFocusAssist -eq 0) { "Enabled" } else { "Disabled" }
            Write-Log "Focus Assist - Original state: $originalState, Now: Enabled" -Level INFO
        }
    }
    
    # Save state
    Save-State
}

# Reopen previously closed processes
function Reopen-ManagedProcesses {
    Write-Log "Trigger App stopped - reopening managed processes..." -Level INFO
    
    # Wait a bit to ensure Steam is fully closed
    Start-Sleep -Seconds $script:Config.settings.reopenDelay
    
    foreach ($processName in $script:ClosedProcesses.Keys) {
        try {
            $processInfo = $script:ClosedProcesses[$processName]
            $processPath = ""
            $processArgs = ""
            
            if ($processInfo -is [string]) {
                $processPath = $processInfo
            }
            elseif ($processInfo -is [System.Collections.Hashtable] -or $processInfo -is [PSCustomObject]) {
                $processPath = $processInfo.Path
                $processArgs = $processInfo.Args
            }
            
            if ($processPath -and (Test-Path $processPath)) {
                Write-Log "Reopening: $processName" -Level INFO
                $workingDir = Split-Path -Parent $processPath
                
                $started = $false
                # Try with args first
                if ($processArgs) {
                    try {
                        Start-Process -FilePath $processPath -ArgumentList $processArgs -WorkingDirectory $workingDir -ErrorAction Stop
                        Write-Log "Successfully reopened: $processName (Args: $processArgs)" -Level SUCCESS
                        $started = $true
                    }
                    catch {
                        Write-Log "Failed to reopen with args. Retrying without args..." -Level WARNING
                    }
                }
                
                # Fallback: Try without args if failed or no args
                if (-not $started) {
                    Start-Process -FilePath $processPath -WorkingDirectory $workingDir -ErrorAction Stop
                    Write-Log "Successfully reopened: $processName" -Level SUCCESS
                }
            }
            else {
                Write-Log "Cannot reopen $processName - path not found: $processPath" -Level WARNING
            }
        }
        catch {
            Write-Log "Error reopening $processName : $_" -Level ERROR
        }
    }
    
    # Restore Focus Assist to original state
    if ($script:Config.settings.enableFocusAssist -and $null -ne $script:OriginalFocusAssist) {
        Set-FocusAssistState -Mode $script:OriginalFocusAssist
        $restoredState = if ($script:OriginalFocusAssist -eq 0) { "Enabled" } else { "Disabled" }
        Write-Log "Focus Assist restored to: $restoredState" -Level INFO
        $script:OriginalFocusAssist = $null
    }
    
    # Restart Windows services
    Restart-ManagedServices
    
    # Clear closed processes list
    $script:ClosedProcesses = @{}
    Save-State
}

# Wait for ANY Trigger App to start
function Wait-ForTriggerStart {
    $triggers = @($script:Config.triggerProcess)
    $triggerListStr = $triggers -join ", "
    Write-Log "Monitoring for triggers: [$triggerListStr]" -Level INFO
    
    # Building dynamic WMI query with LIKE for better reliability (case-insensitive usually but safe)
    $conditions = @()
    foreach ($t in $triggers) {
        # Using LIKE to catch 'steam.exe' or 'Steam.exe' if case sensitivity is an issue in some WMI namespaces
        # Also handles slight name variations if needed
        $conditions += "TargetInstance.Name = '$t.exe'"
    }
    $whereClause = $conditions -join " OR "
    $query = "SELECT * FROM __InstanceCreationEvent WITHIN 3 WHERE TargetInstance ISA 'Win32_Process' AND ($whereClause)"
    
    try {
        # Using a shorter 3 second polling interval for the event
        Register-CimIndicationEvent -Query $query -SourceIdentifier "TriggerAppStarted" -MessageData "TriggerAppStarted" -ErrorAction Stop | Out-Null
        
        # Wait for the event
        Wait-Event -SourceIdentifier "TriggerAppStarted" | Out-Null
        
        # Clean up
        Unregister-Event -SourceIdentifier "TriggerAppStarted" -ErrorAction SilentlyContinue
        
        $script:SteamRunning = $true
        # Slight delay to allow process to fully initialize/stabilize
        Start-Sleep -Milliseconds 500
        return $true
    }
    catch {
        Write-Log "WMI event registration failed (or fallback): $_" -Level WARNING
        # Polling fallback - reliable backend
        while (-not (Is-TriggerAppRunning)) {
            Start-Sleep -Seconds 5
        }
        $script:SteamRunning = $true
        return $true
    }
}

# Main monitoring loop
function Start-OptimizationLoop {
    Write-Log "=== Game Optimizer Started ===" -Level INFO
    $triggers = @($script:Config.triggerProcess)
    Write-Log "Monitoring Triggers: $($triggers -join ', ')" -Level INFO
    
    # Load previous state
    if (Test-Path $script:StateFile) {
        Load-State
    }
    
    # Check initial state
    $script:SteamRunning = Is-TriggerAppRunning
    if ($script:SteamRunning) {
        Write-Log "Trigger App already running on startup" -Level INFO
    }
    
    try {
        while ($true) {
            $currentlyRunning = Is-TriggerAppRunning
            
            # Just started
            if ($currentlyRunning -and -not $script:SteamRunning) {
                # Double-check with delay to avoid ghost processes
                Start-Sleep -Seconds 2
                if (Is-TriggerAppRunning) {
                    $script:SteamRunning = $true
                    Write-Log "Trigger confirmed running. Optimizing..." -Level INFO
                    Close-ManagedProcesses
                }
                else {
                    Write-Log "False start detected (ghost process). Ignoring." -Level WARNING
                }
            }
            # Just stopped
            elseif (-not $currentlyRunning -and $script:SteamRunning) {
                $script:SteamRunning = $false
                Reopen-ManagedProcesses
            }
            # Waiting for start
            elseif (-not $script:SteamRunning) {
                Wait-ForTriggerStart
                # WMI fired - verify it's real
                Start-Sleep -Seconds 2
                if (Is-TriggerAppRunning) {
                    $script:SteamRunning = $true
                    Write-Log "WMI Event confirmed. Optimizing..." -Level INFO
                    Close-ManagedProcesses
                }
                else {
                    Write-Log "Ghost WMI Event detected. Process not found. Retrying..." -Level WARNING
                    $script:SteamRunning = $false
                }
            }
            # Waiting for stop
            else {
                Monitor-TriggerAppSession
                Reopen-ManagedProcesses
            }
        }
    }
    catch {
        Write-Log "Critical error in monitoring loop: $_" -Level ERROR
        throw
    }
}

# Save state to file
function Save-State {
    try {
        $state = @{
            ClosedProcesses = $script:ClosedProcesses
            SteamRunning    = $script:SteamRunning
            LastUpdate      = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        $state | ConvertTo-Json | Set-Content $script:StateFile
    }
    catch {
        Write-Log "Error saving state: $_" -Level WARNING
    }
}

# Load state from file
function Load-State {
    try {
        if (Test-Path $script:StateFile) {
            $state = Get-Content $script:StateFile -Raw | ConvertFrom-Json
            
            # Convert PSCustomObject to Hashtable
            $script:ClosedProcesses = @{}
            if ($state.ClosedProcesses) {
                $state.ClosedProcesses.PSObject.Properties | ForEach-Object {
                    $script:ClosedProcesses[$_.Name] = $_.Value
                }
            }
            
            $script:SteamRunning = $state.SteamRunning
            Write-Log "State loaded from previous session" -Level INFO
        }
    }
    catch {
        Write-Log "Error loading state: $_" -Level WARNING
    }
}

# Check if ANY Trigger App is running
function Is-TriggerAppRunning {
    $triggers = @($script:Config.triggerProcess)
    foreach ($trigger in $triggers) {
        $p = Get-Process -Name $trigger -ErrorAction SilentlyContinue
        if ($p) { return $true }
    }
    return $false
}

# Monitor until ALL Trigger Apps are closed
function Monitor-TriggerAppSession {
    while (Is-TriggerAppRunning) {
        Start-Sleep -Seconds $script:Config.settings.steamCheckInterval
    }
    
    $script:SteamRunning = $false
    Write-Log "All Trigger Apps closed." -Level INFO
}

# Main execution
try {
    # Load configuration
    if (-not (Load-Config)) {
        exit 1
    }
    
    # Start monitoring
    Start-OptimizationLoop
}
catch {
    Write-Log "Fatal error: $_" -Level ERROR
    Write-Host "Fatal error occurred. Check log file: $script:LogPath" -ForegroundColor Red
    exit 1
}
finally {
    Write-Log "=== Game Optimizer Stopped ===" -Level INFO
}
