# AUR Package for Torrent VPN Stack

This is the AUR (Arch User Repository) package for installing Torrent VPN Stack on Arch Linux and derivatives.

## Installation

### Option 1: Using an AUR Helper (Recommended)

Using `yay`:
```bash
yay -S torrent-vpn-stack
```

Using `paru`:
```bash
paru -S torrent-vpn-stack
```

### Option 2: Manual Installation

```bash
# Clone the AUR repository
git clone https://aur.archlinux.org/torrent-vpn-stack.git
cd torrent-vpn-stack

# Build and install
makepkg -si
```

## Quick Start

After installation:

```bash
# Navigate to installation directory
cd /usr/share/torrent-vpn-stack

# Copy example config
cp .env.example .env

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
- `torrent-vpn-setup-automation` - Setup automated backups (systemd/cron)
- `torrent-vpn-remove-automation` - Remove automated backups

## Requirements

- **Arch Linux** or derivatives (Manjaro, EndeavourOS, etc.)
- **Docker** - Install with: `sudo pacman -S docker`
- **Docker Compose** - Install with: `sudo pacman -S docker-compose`
- **VPN Subscription** - Mullvad, ProtonVPN, PIA, or others
- **8 GB RAM minimum** (16 GB recommended)

### Enable Docker Service

```bash
# Start Docker service
sudo systemctl start docker

# Enable Docker to start on boot
sudo systemctl enable docker

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

## Upgrading

```bash
# Using yay
yay -Syu torrent-vpn-stack

# Using paru
paru -Syu torrent-vpn-stack

# Manual
cd /path/to/torrent-vpn-stack
git pull
makepkg -si
```

## Uninstallation

```bash
# Stop and remove containers first
cd /usr/share/torrent-vpn-stack
docker compose down

# Uninstall package
yay -R torrent-vpn-stack
# OR
sudo pacman -R torrent-vpn-stack

# Optionally remove Docker volumes (WARNING: deletes data)
docker volume rm torrent-vpn-stack_gluetun-config
docker volume rm torrent-vpn-stack_qbittorrent-config
```

## Installation Directory

The package installs to: `/usr/share/torrent-vpn-stack`

Files:
- `docker-compose.yml` - Main compose file
- `.env.example` - Example configuration
- `scripts/` - Setup and utility scripts
- `docs/` - Documentation

Symlinks in `/usr/bin`:
- All `torrent-vpn-*` commands

## Publishing to AUR

To publish or update this package on AUR:

### 1. Create AUR Account

1. Create account at: https://aur.archlinux.org/register
2. Upload SSH key in account settings
3. Create AUR package repository

### 2. Initial AUR Setup

```bash
# Clone AUR repository (will be empty initially)
git clone ssh://aur@aur.archlinux.org/torrent-vpn-stack.git aur-torrent-vpn-stack
cd aur-torrent-vpn-stack

# Copy package files
cp ../PKGBUILD .
cp ../torrent-vpn-stack.install .
```

### 3. Update Package for Release

Before publishing a new version:

1. Create a GitHub release with tag (e.g., `v1.0.0`)

2. Calculate SHA256 checksum:
   ```bash
   curl -sL https://github.com/ddmoney420/torrent-vpn-stack/archive/refs/tags/v1.0.0.tar.gz | sha256sum
   ```

3. Update `PKGBUILD`:
   ```bash
   # Update pkgver
   pkgver=1.0.0

   # Update sha256sums with calculated value
   sha256sums=('actual_sha256_hash_here')
   ```

4. Generate `.SRCINFO`:
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

### 4. Test Package Locally

```bash
# Build package
makepkg -sf

# Install and test
sudo pacman -U torrent-vpn-stack-1.0.0-1-any.pkg.tar.zst

# Test all commands
torrent-vpn-setup --help
torrent-vpn-verify --help

# Test setup
torrent-vpn-setup

# Verify files
ls -la /usr/share/torrent-vpn-stack
ls -la /usr/bin/torrent-vpn-*
```

### 5. Push to AUR

```bash
# Add files
git add PKGBUILD .SRCINFO torrent-vpn-stack.install

# Commit
git commit -m "Update to version 1.0.0"

# Push to AUR
git push origin master
```

### 6. Verify on AUR

Check your package page:
- https://aur.archlinux.org/packages/torrent-vpn-stack

## Package Validation

Run validation checks:

```bash
# Check PKGBUILD syntax
namcap PKGBUILD

# Check built package
namcap torrent-vpn-stack-1.0.0-1-any.pkg.tar.zst

# Verify package contents
tar -tvf torrent-vpn-stack-1.0.0-1-any.pkg.tar.zst
```

## Testing

### Full Installation Test

```bash
# Clean build
rm -rf pkg/ src/ *.pkg.tar.zst

# Build from scratch
makepkg -sf

# Install
sudo pacman -U torrent-vpn-stack-*.pkg.tar.zst

# Test commands
torrent-vpn-setup --help
torrent-vpn-verify --help
torrent-vpn-check-leaks --help

# Test setup wizard
torrent-vpn-setup

# Check installation
ls -la /usr/share/torrent-vpn-stack
cat /usr/share/torrent-vpn-stack/.env.example

# Test Docker compose
cd /usr/share/torrent-vpn-stack
docker compose config

# Clean up
sudo pacman -R torrent-vpn-stack
```

### Upgrade Test

```bash
# Install older version first
makepkg -si

# Update PKGBUILD to new version
vim PKGBUILD

# Build new version
makepkg -sf

# Upgrade
sudo pacman -U torrent-vpn-stack-*.pkg.tar.zst

# Verify upgrade message appears
```

## Common Issues

### Docker Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login for changes to take effect
# OR
newgrp docker
```

### Scripts Not Executable

```bash
# Fix permissions
sudo chmod +x /usr/share/torrent-vpn-stack/scripts/*.sh
```

### Missing Dependencies

```bash
# Install all dependencies
sudo pacman -S docker docker-compose bash

# Enable Docker service
sudo systemctl enable --now docker
```

## AUR Guidelines

This package follows AUR guidelines:
- https://wiki.archlinux.org/title/AUR_submission_guidelines
- https://wiki.archlinux.org/title/PKGBUILD
- https://wiki.archlinux.org/title/Creating_packages

## Support

For issues with the AUR package:
- AUR page: https://aur.archlinux.org/packages/torrent-vpn-stack
- Project issues: https://github.com/ddmoney420/torrent-vpn-stack/issues
- AUR comments: Leave comments on AUR page

## Maintainer

- Maintainer: ddmoney420
- Email: your-email@example.com
- GitHub: https://github.com/ddmoney420

## License

MIT License - See LICENSE file in the repository
