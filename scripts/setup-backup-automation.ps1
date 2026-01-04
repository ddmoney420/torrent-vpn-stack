#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Sets up automated daily backups for Torrent VPN Stack on Windows using Task Scheduler.

.DESCRIPTION
    This script creates a Windows Task Scheduler job to run daily backups of Docker volumes.

    Features:
    - Automatic daily backups at specified hour
    - Runs backup.sh via WSL or Git Bash
    - Configurable backup retention
    - Logs to standard location

.PARAMETER BackupHour
    Hour of day to run backup (0-23). Default: 3 (3 AM)

.PARAMETER BackupDir
    Directory to store backups. Default: $HOME\backups\torrent-vpn-stack

.PARAMETER RetentionDays
    Number of days to keep backups. Default: 7

.PARAMETER TaskName
    Name of the scheduled task. Default: TorrentVPNStackBackup

.PARAMETER Shell
    Shell to use for running backup script. Options: WSL, GitBash, Auto. Default: Auto

.EXAMPLE
    .\setup-backup-automation.ps1

.EXAMPLE
    .\setup-backup-automation.ps1 -BackupHour 2 -RetentionDays 14

.EXAMPLE
    .\setup-backup-automation.ps1 -Shell WSL
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateRange(0, 23)]
    [int]$BackupHour = 3,

    [Parameter()]
    [string]$BackupDir = "$HOME\backups\torrent-vpn-stack",

    [Parameter()]
    [ValidateRange(1, 365)]
    [int]$RetentionDays = 7,

    [Parameter()]
    [string]$TaskName = "TorrentVPNStackBackup",

    [Parameter()]
    [ValidateSet("WSL", "GitBash", "Auto")]
    [string]$Shell = "Auto"
)

# Script configuration
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$BackupScript = Join-Path $ProjectDir "scripts\backup.sh"
$LogDir = Join-Path $env:LOCALAPPDATA "torrent-vpn-stack\logs"

# Colors for output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Detect WSL
function Test-WSL {
    try {
        $wslPath = (Get-Command wsl.exe -ErrorAction SilentlyContinue).Path
        if ($wslPath) {
            $wslVersion = wsl.exe --status 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $true
            }
        }
    }
    catch {
        return $false
    }
    return $false
}

# Detect Git Bash
function Get-GitBashPath {
    $possiblePaths = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

# Determine which shell to use
function Get-ShellCommand {
    param([string]$PreferredShell)

    $hasWSL = Test-WSL
    $gitBashPath = Get-GitBashPath

    switch ($PreferredShell) {
        "WSL" {
            if (-not $hasWSL) {
                Write-Error-Custom "WSL not found. Please install WSL or use -Shell GitBash"
                exit 1
            }
            return @{
                Type = "WSL"
                Command = "wsl.exe"
                Args = "bash -c"
            }
        }
        "GitBash" {
            if (-not $gitBashPath) {
                Write-Error-Custom "Git Bash not found. Please install Git for Windows or use -Shell WSL"
                exit 1
            }
            return @{
                Type = "GitBash"
                Command = $gitBashPath
                Args = "-c"
            }
        }
        "Auto" {
            if ($hasWSL) {
                Write-Info "Auto-detected WSL"
                return @{
                    Type = "WSL"
                    Command = "wsl.exe"
                    Args = "bash -c"
                }
            }
            elseif ($gitBashPath) {
                Write-Info "Auto-detected Git Bash at: $gitBashPath"
                return @{
                    Type = "GitBash"
                    Command = $gitBashPath
                    Args = "-c"
                }
            }
            else {
                Write-Error-Custom "No compatible shell found. Please install WSL or Git for Windows."
                exit 1
            }
        }
    }
}

# Create scheduled task
function New-BackupTask {
    param(
        [hashtable]$ShellConfig
    )

    Write-Info "Creating scheduled task: $TaskName"

    # Create log directory
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }

    # Convert Windows paths to Unix paths for WSL
    $backupScriptUnix = $BackupScript -replace '\\', '/' -replace '^([A-Z]):', { "/mnt/$($_.Groups[1].Value.ToLower())" }
    $backupDirUnix = $BackupDir -replace '\\', '/' -replace '^([A-Z]):', { "/mnt/$($_.Groups[1].Value.ToLower())" }
    $projectDirUnix = $ProjectDir -replace '\\', '/' -replace '^([A-Z]):', { "/mnt/$($_.Groups[1].Value.ToLower())" }

    # Build the command
    if ($ShellConfig.Type -eq "WSL") {
        $taskCommand = "wsl.exe"
        $taskArgs = "bash -c `"cd '$projectDirUnix' && BACKUP_DIR='$backupDirUnix' BACKUP_RETENTION_DAYS=$RetentionDays '$backupScriptUnix'`""
    }
    else {
        # Git Bash
        $taskCommand = $ShellConfig.Command
        $taskArgs = "-c `"cd '$ProjectDir' && BACKUP_DIR='$BackupDir' BACKUP_RETENTION_DAYS=$RetentionDays '$BackupScript'`""
    }

    # Create scheduled task action
    $action = New-ScheduledTaskAction `
        -Execute $taskCommand `
        -Argument $taskArgs `
        -WorkingDirectory $ProjectDir

    # Create trigger (daily at specified hour)
    $trigger = New-ScheduledTaskTrigger -Daily -At ([DateTime]::Today.AddHours($BackupHour))

    # Create settings
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RunOnlyIfNetworkAvailable:$false `
        -ExecutionTimeLimit (New-TimeSpan -Hours 2)

    # Create principal (run as current user)
    $principal = New-ScheduledTaskPrincipal `
        -UserId $env:USERNAME `
        -LogonType S4U `
        -RunLevel Highest

    # Register task
    try {
        # Remove existing task if it exists
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Info "Removing existing task..."
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        }

        Register-ScheduledTask `
            -TaskName $TaskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Description "Daily backup for Torrent VPN Stack Docker volumes" | Out-Null

        Write-Info "✓ Scheduled task created successfully"
        return $true
    }
    catch {
        Write-Error-Custom "Failed to create scheduled task: $_"
        return $false
    }
}

# Verify task creation
function Test-BackupTask {
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop

        Write-Info ""
        Write-Info "=========================================="
        Write-Info "  BACKUP AUTOMATION CONFIGURED"
        Write-Info "=========================================="
        Write-Info "Task Name       : $TaskName"
        Write-Info "Task State      : $($task.State)"
        Write-Info "Backup Schedule : Daily at $($BackupHour):00"
        Write-Info "Backup Directory: $BackupDir"
        Write-Info "Retention       : $RetentionDays days"
        Write-Info "Shell           : $($ShellConfig.Type)"
        Write-Info "=========================================="
        Write-Info ""
        Write-Info "Next scheduled run:"

        $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host "  $($taskInfo.NextRunTime)" -ForegroundColor Cyan

        Write-Info ""
        Write-Info "To test the backup manually:"
        Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
        Write-Info ""
        Write-Info "To view task details:"
        Write-Host "  Get-ScheduledTask -TaskName '$TaskName' | Format-List *" -ForegroundColor Cyan
        Write-Info ""
        Write-Info "To disable automation:"
        Write-Host "  .\remove-backup-automation.ps1" -ForegroundColor Cyan
        Write-Info ""

        return $true
    }
    catch {
        Write-Error-Custom "Failed to verify task: $_"
        return $false
    }
}

# Main execution
function Main {
    Write-Info "=========================================="
    Write-Info "  TORRENT VPN STACK - BACKUP AUTOMATION"
    Write-Info "  Platform: Windows (Task Scheduler)"
    Write-Info "=========================================="
    Write-Info ""

    # Check administrator rights
    if (-not (Test-Administrator)) {
        Write-Error-Custom "This script requires Administrator privileges."
        Write-Info "Please run PowerShell as Administrator and try again."
        exit 1
    }

    # Check if backup script exists
    if (-not (Test-Path $BackupScript)) {
        Write-Error-Custom "Backup script not found: $BackupScript"
        exit 1
    }

    # Determine shell
    Write-Info "Detecting available shells..."
    $script:ShellConfig = Get-ShellCommand -PreferredShell $Shell

    # Create backup directory
    if (-not (Test-Path $BackupDir)) {
        Write-Info "Creating backup directory: $BackupDir"
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    # Create task
    $success = New-BackupTask -ShellConfig $ShellConfig

    if ($success) {
        Test-BackupTask
    }
    else {
        Write-Error-Custom "Failed to set up backup automation"
        exit 1
    }
}

# Run main function
Main
