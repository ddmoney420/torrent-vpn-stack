# Homebrew Tap for Torrent VPN Stack

This is the Homebrew formula for installing Torrent VPN Stack on macOS and Linux.

## Installation

### Option 1: Install from tap (once published)

```bash
brew tap ddmoney420/torrent-vpn-stack
brew install torrent-vpn-stack
```

### Option 2: Install directly (once published)

```bash
brew install ddmoney420/torrent-vpn-stack/torrent-vpn-stack
```

### Option 3: Install from HEAD (development version)

```bash
brew install --HEAD ddmoney420/torrent-vpn-stack/torrent-vpn-stack
```

## Quick Start

After installation:

```bash
# Navigate to installation directory
cd $(brew --prefix)/opt/torrent-vpn-stack

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
- `torrent-vpn-setup-automation` - Setup automated backups (macOS: launchd, Linux: systemd/cron)
- `torrent-vpn-remove-automation` - Remove automated backups

## Upgrading

```bash
# Update Homebrew
brew update

# Upgrade torrent-vpn-stack
brew upgrade torrent-vpn-stack
```

## Uninstallation

```bash
# Stop and remove containers first
cd $(brew --prefix)/opt/torrent-vpn-stack
docker compose down

# Uninstall via Homebrew
brew uninstall torrent-vpn-stack

# Optionally remove Docker volumes (WARNING: deletes data)
docker volume rm torrent-vpn-stack_gluetun-config torrent-vpn-stack_qbittorrent-config
```

## Creating the Tap Repository

To publish this formula, create a new repository named `homebrew-torrent-vpn-stack`:

1. Create repository: `https://github.com/ddmoney420/homebrew-torrent-vpn-stack`
2. Copy `torrent-vpn-stack.rb` to the root of that repository
3. Users can then install with:
   ```bash
   brew install ddmoney420/torrent-vpn-stack/torrent-vpn-stack
   ```

## Testing the Formula Locally

Before publishing:

```bash
# Audit the formula
brew audit --strict torrent-vpn-stack.rb

# Test installation locally
brew install --build-from-source ./torrent-vpn-stack.rb

# Run formula tests
brew test torrent-vpn-stack
```

## Updating the Formula

When releasing a new version:

1. Create a new Git tag and release on GitHub
2. Calculate SHA256 of the tarball:
   ```bash
   curl -sL https://github.com/ddmoney420/torrent-vpn-stack/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
   ```
3. Update the `url` and `sha256` in the formula
4. Commit and push to the tap repository

## Support

For issues with the Homebrew formula:
- Formula issues: https://github.com/ddmoney420/homebrew-torrent-vpn-stack/issues
- Project issues: https://github.com/ddmoney420/torrent-vpn-stack/issues
