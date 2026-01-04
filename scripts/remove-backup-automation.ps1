#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Removes automated backup task for Torrent VPN Stack on Windows.

.DESCRIPTION
    This script removes the Windows Task Scheduler job created by setup-backup-automation.ps1.

.PARAMETER TaskName
    Name of the scheduled task to remove. Default: TorrentVPNStackBackup

.PARAMETER Force
    Skip confirmation prompt

.EXAMPLE
    .\remove-backup-automation.ps1

.EXAMPLE
    .\remove-backup-automation.ps1 -Force
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$TaskName = "TorrentVPNStackBackup",

    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

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

# Main execution
Write-Info "=========================================="
Write-Info "  REMOVE BACKUP AUTOMATION"
Write-Info "  Platform: Windows (Task Scheduler)"
Write-Info "=========================================="
Write-Info ""

# Check administrator rights
if (-not (Test-Administrator)) {
    Write-Error-Custom "This script requires Administrator privileges."
    Write-Info "Please run PowerShell as Administrator and try again."
    exit 1
}

# Check if task exists
try {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop

    Write-Info "Found task: $TaskName"
    Write-Info "State       : $($task.State)"
    Write-Info "Description : $($task.Description)"
    Write-Info ""

    # Confirm removal
    if (-not $Force) {
        $response = Read-Host "Remove this scheduled task? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Info "Cancelled by user"
            exit 0
        }
    }

    # Remove task
    Write-Info "Removing scheduled task..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

    Write-Info "✓ Backup automation removed successfully"
    Write-Info ""
    Write-Info "To re-enable automation, run:"
    Write-Host "  .\setup-backup-automation.ps1" -ForegroundColor Cyan
    Write-Info ""
}
catch {
    if ($_.Exception.Message -like "*No MSFT_ScheduledTask objects found*") {
        Write-Warning-Custom "Task '$TaskName' not found. Nothing to remove."
        exit 0
    }
    else {
        Write-Error-Custom "Failed to remove task: $_"
        exit 1
    }
}
