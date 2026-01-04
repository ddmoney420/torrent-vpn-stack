# Torrent VPN Stack - Chocolatey Uninstallation Script

$ErrorActionPreference = 'Stop'

# Package info
$packageName = 'torrent-vpn-stack'
$installDir = Join-Path $env:ProgramData "torrent-vpn-stack"

Write-Host "Uninstalling $packageName..." -ForegroundColor Yellow

# Warning about data preservation
Write-Host ""
Write-Host "WARNING: This will remove the Torrent VPN Stack installation." -ForegroundColor Red
Write-Host "Your Docker volumes and downloaded files will be preserved." -ForegroundColor Yellow
Write-Host ""

# Check if Docker containers are running
try {
    $composeFile = Join-Path $installDir "docker-compose.yml"
    if (Test-Path $composeFile) {
        Write-Host "Checking for running containers..." -ForegroundColor Cyan

        Push-Location $installDir
        try {
            $containers = docker compose ps -q 2>$null
            if ($containers) {
                Write-Host ""
                Write-Host "Active containers found. You should stop them first:" -ForegroundColor Yellow
                Write-Host "  cd `"$installDir`"" -ForegroundColor Cyan
                Write-Host "  docker compose down" -ForegroundColor Cyan
                Write-Host ""

                $response = Read-Host "Stop containers now? (y/N)"
                if ($response -eq 'y' -or $response -eq 'Y') {
                    Write-Host "Stopping containers..." -ForegroundColor Cyan
                    docker compose down
                    Write-Host "Containers stopped." -ForegroundColor Green
                } else {
                    Write-Host "Skipping container shutdown. You'll need to stop them manually." -ForegroundColor Yellow
                }
            }
        } finally {
            Pop-Location
        }
    }
} catch {
    Write-Warning "Could not check Docker containers: $_"
}

# Remove wrapper scripts
$shimScripts = @(
    'torrent-vpn-setup.bat'
    'torrent-vpn-verify.bat'
    'torrent-vpn-check-leaks.bat'
    'torrent-vpn-backup.bat'
    'torrent-vpn-restore.bat'
    'torrent-vpn-benchmark.bat'
    'torrent-vpn-setup-automation.bat'
    'torrent-vpn-setup-automation.ps1'
    'torrent-vpn-remove-automation.bat'
    'torrent-vpn-remove-automation.ps1'
)

foreach ($script in $shimScripts) {
    $scriptPath = Join-Path $installDir $script
    if (Test-Path $scriptPath) {
        Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
    }
}

# Remove installation directory
if (Test-Path $installDir) {
    Write-Host "Removing installation directory: $installDir" -ForegroundColor Cyan

    # Backup .env file if it exists
    $envFile = Join-Path $installDir ".env"
    if (Test-Path $envFile) {
        $backupDir = Join-Path $env:USERPROFILE ".torrent-vpn-stack-backup"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupFile = Join-Path $backupDir ".env.$timestamp"
        Copy-Item $envFile $backupFile -Force

        Write-Host "Backed up .env to: $backupFile" -ForegroundColor Green
    }

    # Remove directory
    try {
        Remove-Item $installDir -Recurse -Force -ErrorAction Stop
        Write-Host "Installation directory removed." -ForegroundColor Green
    } catch {
        Write-Warning "Could not fully remove installation directory: $_"
        Write-Warning "You may need to manually delete: $installDir"
    }
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  Torrent VPN Stack has been uninstalled." -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Preserved Data:" -ForegroundColor Yellow
Write-Host "  - Docker volumes (gluetun-config, qbittorrent-config)" -ForegroundColor White
Write-Host "  - Downloaded files (if outside installation directory)" -ForegroundColor White
Write-Host ""
Write-Host "To completely remove all data (WARNING: deletes everything):" -ForegroundColor Red
Write-Host "  docker volume rm torrent-vpn-stack_gluetun-config" -ForegroundColor Cyan
Write-Host "  docker volume rm torrent-vpn-stack_qbittorrent-config" -ForegroundColor Cyan
Write-Host ""
Write-Host "To reinstall:" -ForegroundColor Yellow
Write-Host "  choco install torrent-vpn-stack" -ForegroundColor Cyan
Write-Host ""
