# Torrent VPN Stack - Chocolatey Installation Script

$ErrorActionPreference = 'Stop'

# Package info
$packageName = 'torrent-vpn-stack'
$version = '1.0.0'
$url = "https://github.com/ddmoney420/torrent-vpn-stack/archive/refs/tags/v$version.zip"
$checksum = 'PLACEHOLDER_SHA256'  # Will be updated with actual release
$checksumType = 'sha256'

# Installation directory
$installDir = Join-Path $env:ProgramData "torrent-vpn-stack"
$scriptsDir = Join-Path $installDir "scripts"

# Package parameters
$packageArgs = @{
    packageName    = $packageName
    unzipLocation  = $installDir
    url            = $url
    checksum       = $checksum
    checksumType   = $checksumType
}

Write-Host "Installing $packageName to $installDir..." -ForegroundColor Green

# Download and extract
Install-ChocolateyZipPackage @packageArgs

# The extracted folder will be named 'torrent-vpn-stack-1.0.0'
# Move contents to proper location
$extractedDir = Get-ChildItem -Path $installDir -Directory | Where-Object { $_.Name -like "torrent-vpn-stack-*" } | Select-Object -First 1
if ($extractedDir) {
    Get-ChildItem -Path $extractedDir.FullName | Move-Item -Destination $installDir -Force
    Remove-Item $extractedDir.FullName -Recurse -Force
}

# Create shim wrappers for easy command access
$shimScripts = @{
    'torrent-vpn-setup'              = 'setup.sh'
    'torrent-vpn-verify'             = 'verify-vpn.sh'
    'torrent-vpn-check-leaks'        = 'check-leaks.sh'
    'torrent-vpn-backup'             = 'backup.sh'
    'torrent-vpn-restore'            = 'restore.sh'
    'torrent-vpn-benchmark'          = 'benchmark-vpn.sh'
    'torrent-vpn-setup-automation'   = 'setup-backup-automation-windows.ps1'
    'torrent-vpn-remove-automation'  = 'remove-backup-automation-windows.ps1'
}

# Create wrapper batch files for bash scripts (Git Bash required)
foreach ($command in $shimScripts.GetEnumerator()) {
    $shimName = $command.Key
    $scriptName = $command.Value
    $scriptPath = Join-Path $scriptsDir $scriptName

    if ($scriptName -match '\.sh$') {
        # Bash script - create .bat wrapper
        $batFile = Join-Path $installDir "$shimName.bat"
        @"
@echo off
REM Torrent VPN Stack - $shimName wrapper
REM Requires Git Bash to be installed

WHERE bash >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git Bash is required but not found in PATH
    echo Please install Git for Windows: https://git-scm.com/download/win
    exit /b 1
)

bash "$scriptPath" %*
"@ | Set-Content -Path $batFile -Encoding ASCII

        Install-ChocolateyPath -PathToInstall $installDir -PathType 'Machine'

    } elseif ($scriptName -match '\.ps1$') {
        # PowerShell script - create direct shim
        $ps1File = Join-Path $installDir "$shimName.ps1"
        @"
# Torrent VPN Stack - $shimName wrapper
& "$scriptPath" @args
"@ | Set-Content -Path $ps1File -Encoding UTF8

        # Also create .bat wrapper for easier invocation
        $batFile = Join-Path $installDir "$shimName.bat"
        @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps1File" %*
"@ | Set-Content -Path $batFile -Encoding ASCII

        Install-ChocolateyPath -PathToInstall $installDir -PathType 'Machine'
    }
}

# Make scripts executable (if using WSL or Git Bash)
if (Get-Command bash -ErrorAction SilentlyContinue) {
    bash -c "chmod +x '$scriptsDir'/*.sh" 2>$null
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  Torrent VPN Stack has been installed successfully!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation Directory:" -ForegroundColor Yellow
Write-Host "  $installDir" -ForegroundColor White
Write-Host ""
Write-Host "Quick Start:" -ForegroundColor Yellow
Write-Host "  1. Open a new terminal (to refresh PATH)" -ForegroundColor White
Write-Host "  2. Run the interactive setup wizard:" -ForegroundColor White
Write-Host "     torrent-vpn-setup" -ForegroundColor Cyan
Write-Host "  3. Start the stack:" -ForegroundColor White
Write-Host "     cd `"$installDir`"" -ForegroundColor Cyan
Write-Host "     docker compose up -d" -ForegroundColor Cyan
Write-Host "  4. Access qBittorrent Web UI:" -ForegroundColor White
Write-Host "     http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available Commands:" -ForegroundColor Yellow
Write-Host "  torrent-vpn-setup              - Interactive setup wizard" -ForegroundColor White
Write-Host "  torrent-vpn-verify             - Verify VPN connection" -ForegroundColor White
Write-Host "  torrent-vpn-check-leaks        - Check for IP/DNS leaks" -ForegroundColor White
Write-Host "  torrent-vpn-backup             - Backup configuration" -ForegroundColor White
Write-Host "  torrent-vpn-restore            - Restore from backup" -ForegroundColor White
Write-Host "  torrent-vpn-benchmark          - Benchmark VPN performance" -ForegroundColor White
Write-Host "  torrent-vpn-setup-automation   - Setup automated backups" -ForegroundColor White
Write-Host "  torrent-vpn-remove-automation  - Remove automated backups" -ForegroundColor White
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Yellow
Write-Host "  README:       $installDir\README.md" -ForegroundColor White
Write-Host "  Architecture: $installDir\docs\architecture.md" -ForegroundColor White
Write-Host "  Windows Guide: $installDir\docs\install-windows.md" -ForegroundColor White
Write-Host ""
Write-Host "Requirements:" -ForegroundColor Yellow
Write-Host "  - Docker Desktop for Windows (must be installed)" -ForegroundColor White
Write-Host "  - Git Bash (for bash script support)" -ForegroundColor White
Write-Host "  - VPN subscription (Mullvad, ProtonVPN, PIA, or others)" -ForegroundColor White
Write-Host "  - 8 GB RAM minimum (16 GB recommended)" -ForegroundColor White
Write-Host ""
Write-Host "Support:" -ForegroundColor Yellow
Write-Host "  Issues: https://github.com/ddmoney420/torrent-vpn-stack/issues" -ForegroundColor White
Write-Host ""
