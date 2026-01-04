# Chocolatey Package for Torrent VPN Stack

This is the Chocolatey package for installing Torrent VPN Stack on Windows.

## Installation

### Option 1: Install from Chocolatey Community Repository (once published)

```powershell
choco install torrent-vpn-stack
```

### Option 2: Install from local package

```powershell
# Build the package first
cd packaging/chocolatey
choco pack

# Install the generated .nupkg file
choco install torrent-vpn-stack -s . -y
```

## Quick Start

After installation:

```powershell
# Open a new terminal to refresh PATH

# Navigate to installation directory
cd $env:ProgramData\torrent-vpn-stack

# Run interactive setup
torrent-vpn-setup

# Start the stack
docker compose up -d

# Verify VPN connection
torrent-vpn-verify
```

## Available Commands

After installation, these commands are available system-wide:

- `torrent-vpn-setup` - Interactive configuration wizard
- `torrent-vpn-verify` - Verify VPN connection
- `torrent-vpn-check-leaks` - Check for IP/DNS leaks
- `torrent-vpn-backup` - Backup Docker volumes
- `torrent-vpn-restore` - Restore from backup
- `torrent-vpn-benchmark` - Benchmark VPN performance
- `torrent-vpn-setup-automation` - Setup automated backups (Task Scheduler)
- `torrent-vpn-remove-automation` - Remove automated backups

## Requirements

- **Windows 10/11** (64-bit)
- **Docker Desktop for Windows** - Required dependency
- **Git Bash** - Recommended for bash script support
  ```powershell
  choco install git
  ```
- **VPN Subscription** - Mullvad, ProtonVPN, PIA, or others
- **8 GB RAM minimum** (16 GB recommended)

## Upgrading

```powershell
# Update Chocolatey package list
choco upgrade torrent-vpn-stack
```

## Uninstallation

```powershell
# Stop containers first
cd $env:ProgramData\torrent-vpn-stack
docker compose down

# Uninstall via Chocolatey
choco uninstall torrent-vpn-stack

# Optionally remove Docker volumes (WARNING: deletes all data)
docker volume rm torrent-vpn-stack_gluetun-config
docker volume rm torrent-vpn-stack_qbittorrent-config
```

## Installation Directory

The package installs to: `C:\ProgramData\torrent-vpn-stack`

Files:
- `docker-compose.yml` - Main compose file
- `.env.example` - Example configuration
- `scripts/` - Setup and utility scripts
- `docs/` - Documentation
- `README.md` - Project readme

## Publishing to Chocolatey Community Repository

To publish this package to the Chocolatey Community Repository:

### 1. Create Account and API Key

1. Create account at: https://community.chocolatey.org/account/Register
2. Get your API key: https://community.chocolatey.org/account
3. Set API key:
   ```powershell
   choco apikey -k YOUR_API_KEY -s https://push.chocolatey.org/
   ```

### 2. Build and Test Package

```powershell
# Navigate to package directory
cd packaging/chocolatey

# Build package
choco pack

# Test installation locally
choco install torrent-vpn-stack -s . -y

# Test functionality
torrent-vpn-setup --help
```

### 3. Update Package for Release

Before publishing a new version:

1. Create a GitHub release with tag (e.g., `v1.0.0`)
2. Calculate SHA256 checksum:
   ```powershell
   $url = "https://github.com/ddmoney420/torrent-vpn-stack/archive/refs/tags/v1.0.0.zip"
   $tempFile = "$env:TEMP\torrent-vpn-stack.zip"
   Invoke-WebRequest -Uri $url -OutFile $tempFile
   (Get-FileHash $tempFile -Algorithm SHA256).Hash
   ```
3. Update `torrent-vpn-stack.nuspec` version
4. Update `chocolateyinstall.ps1`:
   - Update `$version`
   - Update `$checksum` with calculated SHA256

### 4. Push to Chocolatey

```powershell
# Build updated package
choco pack

# Push to Chocolatey Community Repository
choco push torrent-vpn-stack.1.0.0.nupkg -s https://push.chocolatey.org/

# Package will be in moderation queue
# Monitor at: https://community.chocolatey.org/packages/torrent-vpn-stack
```

### 5. Moderation Process

- Package will be reviewed by Chocolatey moderators
- Typical approval time: 24-48 hours
- You'll receive email notifications
- Check status: https://community.chocolatey.org/packages/torrent-vpn-stack

## Testing the Package Locally

Before publishing, thoroughly test:

```powershell
# Build package
choco pack

# Install from local package
choco install torrent-vpn-stack -s . -y --force

# Test all commands
torrent-vpn-setup --help
torrent-vpn-verify --help
torrent-vpn-check-leaks --help

# Test setup wizard
torrent-vpn-setup

# Test Docker compose works
cd $env:ProgramData\torrent-vpn-stack
docker compose config

# Test uninstall
choco uninstall torrent-vpn-stack -y

# Verify cleanup
Test-Path "$env:ProgramData\torrent-vpn-stack"  # Should be False
```

## Package Validation

Run Chocolatey package validation:

```powershell
# Install validation tools
choco install chocolatey-package-validator -y

# Validate package
choco-package-validator torrent-vpn-stack.1.0.0.nupkg
```

## Troubleshooting

### Git Bash Not Found

If you see "bash not found" errors:

```powershell
# Install Git for Windows (includes Git Bash)
choco install git -y

# Refresh environment
refreshenv

# Verify bash is available
bash --version
```

### Docker Not Found

```powershell
# Install Docker Desktop
choco install docker-desktop -y

# Restart required after Docker installation
# Then verify:
docker --version
docker compose version
```

### Permission Errors

Run PowerShell as Administrator:
```powershell
Start-Process powershell -Verb runAs
```

### PATH Not Updated

After installation, open a new terminal window to refresh the PATH environment variable.

## Support

For issues with the Chocolatey package:
- Package issues: https://github.com/ddmoney420/torrent-vpn-stack/issues
- Chocolatey validation: https://community.chocolatey.org/packages/torrent-vpn-stack

## License

MIT License - See LICENSE file in the repository
