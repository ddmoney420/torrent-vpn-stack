# Torrent VPN Stack - Chocolatey Installation Script

$ErrorActionPreference = 'Stop'

# Check for Docker (warn but don't fail - allows installation in test environments)
$dockerInstalled = $false
$dockerWarning = $false

if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dockerInstalled = $true
    Write-Host "Docker detected" -ForegroundColor Green
} else {
    $dockerWarning = $true
    Write-Warning "Docker Desktop is REQUIRED to run torrent-vpn-stack but was not found."
    Write-Warning "Please install Docker Desktop for Windows: choco install docker-desktop"
    Write-Warning "Or download from: https://www.docker.com/products/docker-desktop"
    Write-Warning "The package will continue to install, but you must install Docker Desktop before using torrent-vpn-stack."
}

# Package info
$packageName = 'torrent-vpn-stack'
$version = '1.0.1'
$url = "https://github.com/ddmoney420/torrent-vpn-stack/archive/refs/tags/v${version}.zip"
$checksum = 'ffd47d371825ce81add932c3dc8cdb90e19ba1d97d1c0a60605f6ad7ca6aa4c9'
$checksumType = 'sha256'

# Installation directory
$installDir = Join-Path $env:ProgramData 'torrent-vpn-stack'
$scriptsDir = Join-Path $installDir 'scripts'

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

# The extracted folder will be named 'torrent-vpn-stack-X.X.X'
# Move contents to proper location
$extractedDir = Get-ChildItem -Path $installDir -Directory | Where-Object { $_.Name -like 'torrent-vpn-stack-*' } | Select-Object -First 1
if ($extractedDir) {
    Get-ChildItem -Path $extractedDir.FullName | Move-Item -Destination $installDir -Force
    Remove-Item $extractedDir.FullName -Recurse -Force
}

# Create shim wrappers for easy command access
$bashScripts = @{
    'torrent-vpn-setup'              = 'setup.sh'
    'torrent-vpn-verify'             = 'verify-vpn.sh'
    'torrent-vpn-check-leaks'        = 'check-leaks.sh'
    'torrent-vpn-backup'             = 'backup.sh'
    'torrent-vpn-restore'            = 'restore.sh'
    'torrent-vpn-benchmark'          = 'benchmark-vpn.sh'
}

$psScripts = @{
    'torrent-vpn-setup-automation'   = 'setup-backup-automation-windows.ps1'
    'torrent-vpn-remove-automation'  = 'remove-backup-automation-windows.ps1'
}

# Batch wrapper template for bash scripts
$bashBatTemplate = @'
@echo off
REM Torrent VPN Stack - ##SHIMNAME## wrapper
REM Requires Git Bash to be installed

WHERE bash >nul 2>nul
IF ERRORLEVEL 1 (
    echo ERROR: Git Bash is required but not found in PATH
    echo Please install Git for Windows: https://git-scm.com/download/win
    exit /b 1
)

bash "##SCRIPTPATH##" %*
'@

# PowerShell wrapper template
$psWrapperTemplate = @'
# Torrent VPN Stack - ##SHIMNAME## wrapper
& "##SCRIPTPATH##" @args
'@

# Batch wrapper for PowerShell scripts
$psBatTemplate = @'
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "##PS1PATH##" %*
'@

# Create wrapper batch files for bash scripts (Git Bash required)
foreach ($entry in $bashScripts.GetEnumerator()) {
    $shimName = $entry.Key
    $scriptName = $entry.Value
    $scriptPath = Join-Path $scriptsDir $scriptName
    $batFile = Join-Path $installDir "$shimName.bat"

    $batContent = $bashBatTemplate -replace '##SHIMNAME##', $shimName -replace '##SCRIPTPATH##', $scriptPath
    Set-Content -Path $batFile -Value $batContent -Encoding ASCII
}

# Create wrapper files for PowerShell scripts
foreach ($entry in $psScripts.GetEnumerator()) {
    $shimName = $entry.Key
    $scriptName = $entry.Value
    $scriptPath = Join-Path $scriptsDir $scriptName
    $ps1File = Join-Path $installDir "$shimName.ps1"
    $batFile = Join-Path $installDir "$shimName.bat"

    $ps1Content = $psWrapperTemplate -replace '##SHIMNAME##', $shimName -replace '##SCRIPTPATH##', $scriptPath
    Set-Content -Path $ps1File -Value $ps1Content -Encoding UTF8

    $batContent = $psBatTemplate -replace '##PS1PATH##', $ps1File
    Set-Content -Path $batFile -Value $batContent -Encoding ASCII
}

# Add installation directory to PATH
Install-ChocolateyPath -PathToInstall $installDir -PathType 'Machine'

# Make scripts executable (if using WSL or Git Bash)
if (Get-Command bash -ErrorAction SilentlyContinue) {
    try {
        $unixScriptsDir = $scriptsDir -replace '\\', '/'
        bash -c "chmod +x '$unixScriptsDir'/*.sh" 2>$null
    } catch {
        # Ignore chmod errors - not critical
    }
}

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  Torrent VPN Stack has been installed successfully!" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Installation Directory: $installDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Quick Start:" -ForegroundColor Yellow
Write-Host "  1. Open a new terminal (to refresh PATH)"
Write-Host "  2. Run: torrent-vpn-setup"
Write-Host "  3. Start: cd $installDir && docker compose up -d"
Write-Host "  4. Access: http://localhost:8080"
Write-Host ""
Write-Host "Available Commands:" -ForegroundColor Yellow
Write-Host "  torrent-vpn-setup              - Interactive setup wizard"
Write-Host "  torrent-vpn-verify             - Verify VPN connection"
Write-Host "  torrent-vpn-check-leaks        - Check for IP/DNS leaks"
Write-Host "  torrent-vpn-backup             - Backup configuration"
Write-Host "  torrent-vpn-restore            - Restore from backup"
Write-Host "  torrent-vpn-benchmark          - Benchmark VPN performance"
Write-Host "  torrent-vpn-setup-automation   - Setup automated backups"
Write-Host "  torrent-vpn-remove-automation  - Remove automated backups"
Write-Host ""
Write-Host "Documentation: $installDir\README.md" -ForegroundColor Yellow
Write-Host "Issues: https://github.com/ddmoney420/torrent-vpn-stack/issues" -ForegroundColor Yellow
Write-Host ""
