# macOS Installation Guide

Complete installation guide for Torrent VPN Stack on macOS.

---

## Prerequisites

### System Requirements

- **macOS:** 11.0 (Big Sur) or later
- **RAM:** 8 GB minimum, 16 GB recommended
- **Disk:** 20 GB free space minimum
- **CPU:** Intel or Apple Silicon (M1/M2/M3)

### Required Software

- **Docker Desktop for Mac**
- **Git** (included in Xcode Command Line Tools)
- **Homebrew** (optional but recommended)

---

## Installation

### 1. Install Docker Desktop

**Option A: Direct Download**

1. Download [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
   - Choose the correct version:
     - **Apple Silicon (M1/M2/M3):** ARM64 version
     - **Intel Mac:** AMD64 version

2. Open the `.dmg` file and drag Docker to Applications
3. Launch Docker Desktop from Applications
4. Follow the setup wizard
5. Grant necessary permissions when prompted

**Option B: Using Homebrew**

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Launch Docker
open -a Docker
```

### 2. Verify Docker Installation

```bash
# Check Docker version
docker --version
docker compose version

# Test Docker
docker run hello-world
```

### 3. Install Git (if needed)

```bash
# Check if Git is installed
git --version

# If not installed, install Xcode Command Line Tools
xcode-select --install
```

---

## Setup Torrent VPN Stack

### 1. Clone Repository

```bash
cd ~
git clone https://github.com/ddmoney420/torrent-vpn-stack.git
cd torrent-vpn-stack
```

### 2. Run Interactive Setup Wizard

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run setup wizard
./scripts/setup.sh
```

The wizard will guide you through:
- VPN provider selection and credentials
- Network configuration (auto-detects your Mac's local subnet)
- Downloads directory setup
- Optional features (port forwarding, monitoring)

### 3. Start the Stack

```bash
# Basic stack (VPN + qBittorrent)
docker compose up -d

# With port forwarding (ProtonVPN Plus, PIA)
docker compose --profile port-forwarding up -d

# With monitoring (Prometheus + Grafana)
docker compose --profile monitoring up -d

# All features
docker compose --profile port-forwarding --profile monitoring up -d
```

### 4. Verify VPN Connection

```bash
./scripts/verify-vpn.sh
```

Expected output:
```
✓ VPN connection active
✓ IP address: 123.45.67.89 (VPN provider IP)
✓ DNS leak test: PASSED
```

---

## Backup Automation

macOS uses **launchd** for scheduled tasks (macOS's native alternative to cron).

### Automated Backups with launchd

```bash
# Set up daily backups at 3 AM
sudo ./scripts/setup-backup-automation.sh

# Customize schedule
sudo ./scripts/setup-backup-automation.sh --hour 2 --retention 14

# Custom backup location
sudo BACKUP_DIR=~/my-backups ./scripts/setup-backup-automation.sh
```

**Note:** Requires `sudo` because launchd runs as a system service.

### Manage launchd Job

```bash
# Check if job is loaded
launchctl list | grep torrent-vpn-stack

# View job status
sudo launchctl list com.torrent-vpn-stack.backup

# Run backup manually
sudo launchctl start com.torrent-vpn-stack.backup

# View logs
tail -f ~/Library/Logs/torrent-vpn-stack/backup.log

# Disable automation
sudo ./scripts/remove-backup-automation.sh
```

### Manual Backups

```bash
# Run backup manually
./scripts/backup.sh

# Custom backup location
BACKUP_DIR=~/my-backups ./scripts/backup.sh

# Keep backups for 14 days
BACKUP_RETENTION_DAYS=14 ./scripts/backup.sh
```

---

## Accessing Services

All services are accessible at `localhost`:

- **qBittorrent Web UI:** http://localhost:8080
  - Default credentials: `admin` / `adminpass` (change in `.env`)

- **Grafana (if monitoring enabled):** http://localhost:3000
  - Default credentials: `admin` / `admin`

- **Prometheus (if monitoring enabled):** http://localhost:9090

---

## macOS-Specific Configuration

### Docker Desktop Resource Allocation

1. Open **Docker Desktop** → **Settings** (gear icon)
2. Go to **Resources**
3. Recommended settings:
   - **CPUs:** 4 cores (minimum 2)
   - **Memory:** 4 GB (minimum 2 GB)
   - **Disk:** 20 GB+
   - **Swap:** 1 GB

4. Click **Apply & Restart**

### File Sharing

Docker Desktop needs access to the directories you're using:

1. **Settings** → **Resources** → **File Sharing**
2. Ensure these paths are shared:
   - `/Users` (for downloads directory)
   - `/tmp` (for temporary files)
   - `/private` (if using /private/tmp)

### Network Configuration

Docker Desktop for Mac uses a VM, so network settings may differ:

- Container network: `192.168.65.0/24` (default)
- Host network: Your Mac's Wi-Fi/Ethernet network

The setup wizard will auto-detect your Mac's local subnet using:
```bash
ipconfig getifaddr en0  # Wi-Fi
ipconfig getifaddr en1  # Ethernet (if applicable)
```

---

## Firewall Configuration

### Allow Docker Through macOS Firewall

If you have the macOS Firewall enabled:

1. **System Settings** → **Network** → **Firewall** → **Options**
2. Click **+** to add an application
3. Navigate to `/Applications/Docker.app`
4. Set to **Allow incoming connections**

### Port Access from Other Devices

To access qBittorrent from other devices on your network:

1. Ensure `LOCAL_SUBNET` in `.env` matches your network
2. Test access from another device:
   ```
   http://<your-mac-ip>:8080
   ```

---

## Troubleshooting

### Docker Desktop Not Starting

**Error:** "Docker Desktop starting..." (never finishes)

**Solutions:**

1. **Check macOS version:** Requires macOS 11.0+
   ```bash
   sw_vers
   ```

2. **Reset Docker Desktop:**
   - **Docker Desktop** → **Troubleshoot** → **Reset to factory defaults**

3. **Check for conflicting software:**
   - VirtualBox, VMware, or other virtualization software may conflict

4. **Reinstall Docker Desktop:**
   ```bash
   brew uninstall --cask docker
   brew install --cask docker
   ```

### VPN Connection Fails

**Error:** Gluetun container constantly restarting

**Solutions:**

1. Check VPN credentials in `.env`:
   ```bash
   cat .env | grep VPN
   ```

2. View Gluetun logs:
   ```bash
   docker logs gluetun
   ```

3. Verify VPN provider configuration:
   - See [Provider Comparison](provider-comparison.md)

4. Test network from container:
   ```bash
   docker exec gluetun ping -c 3 8.8.8.8
   ```

### Cannot Access qBittorrent WebUI

**Error:** `localhost:8080` not accessible

**Solutions:**

1. Verify containers are running:
   ```bash
   docker ps
   ```

2. Check `LOCAL_SUBNET` in `.env` matches your network:
   ```bash
   ipconfig getifaddr en0
   # Should match first 3 octets of LOCAL_SUBNET
   ```

3. Restart Docker containers:
   ```bash
   docker compose down
   docker compose up -d
   ```

4. Check Docker Desktop network settings:
   - **Settings** → **Resources** → **Network**
   - Try changing subnet if conflicts exist

5. **"Unauthorized" error instead of login page:**
   ```bash
   # Stop qBittorrent
   docker compose stop qbittorrent

   # Disable host header validation
   docker run --rm -v torrent-vpn-stack_qbittorrent-config:/config alpine sh -c '
   echo "WebUI\HostHeaderValidation=false" >> /config/qBittorrent/qBittorrent.conf'

   # Restart
   docker compose start qbittorrent
   ```

### Downloads Path Error

**Error:** Volume mount fails with "path is not shared from the host"

**Solution:** Use absolute paths in `.env` (tilde `~` expansion may fail):
```bash
# Wrong:
DOWNLOADS_PATH=~/Downloads/torrents

# Correct:
DOWNLOADS_PATH=/Users/yourusername/Downloads/torrents
```

Also ensure the path is shared in Docker Desktop:
- **Settings** → **Resources** → **File Sharing**
- Add `/Users/yourusername/Downloads` if not listed

### Port Forwarding Not Working

**Error:** No forwarded port assigned

**Solutions:**

1. Verify your VPN provider supports port forwarding:
   - ✅ ProtonVPN Plus, PIA
   - ❌ Mullvad (discontinued July 2023), NordVPN, Surfshark, ExpressVPN

2. Enable port forwarding profile:
   ```bash
   docker compose --profile port-forwarding up -d
   ```

3. For ProtonVPN, ensure `.env` has:
   ```
   VPN_PORT_FORWARDING_PROVIDER=protonvpn
   ```

4. Check port sync logs:
   ```bash
   docker logs gluetun-qbittorrent-sync
   ```

### launchd Job Not Running

**Error:** Backups not running automatically

**Solutions:**

1. Check if job is loaded:
   ```bash
   sudo launchctl list | grep torrent-vpn-stack
   ```

2. Reload job:
   ```bash
   sudo launchctl unload /Library/LaunchDaemons/com.torrent-vpn-stack.backup.plist
   sudo launchctl load /Library/LaunchDaemons/com.torrent-vpn-stack.backup.plist
   ```

3. Check logs:
   ```bash
   tail -50 ~/Library/Logs/torrent-vpn-stack/backup.log
   ```

4. Verify plist syntax:
   ```bash
   plutil -lint /Library/LaunchDaemons/com.torrent-vpn-stack.backup.plist
   ```

### Apple Silicon (M1/M2/M3) Issues

**Error:** "no matching manifest for linux/arm64/v8"

**Solution:** Use ARM64-compatible images (already configured in `docker-compose.yml`)

If issues persist:
```bash
# Force pull ARM64 images
docker pull --platform linux/arm64 qmcgaw/gluetun
docker pull --platform linux/arm64 linuxserver/qbittorrent

# Restart stack
docker compose down
docker compose up -d
```

---

## Performance Tuning

### Docker Desktop Settings

1. **Increase resources** (see Resource Allocation above)
2. **Enable VirtioFS** (faster file sharing):
   - **Settings** → **General** → **Choose file sharing implementation for your containers**
   - Select **VirtioFS** (default on macOS 12.5+)

3. **Disable unnecessary features**:
   - **Settings** → **Kubernetes** → Uncheck "Enable Kubernetes" (unless needed)

### macOS System Optimization

```bash
# Disable Spotlight indexing on Downloads directory (optional)
sudo mdutil -i off ~/Downloads/torrents

# Increase file descriptor limit
sudo launchctl limit maxfiles 65536 200000
```

See [Performance Tuning Guide](performance-tuning.md) for more optimizations.

---

## Uninstallation

### Remove Stack

```bash
# Stop and remove containers
docker compose down

# Remove volumes (WARNING: deletes all data)
docker volume rm torrent-vpn-stack_gluetun-config torrent-vpn-stack_qbittorrent-config

# Remove images (optional)
docker image rm qmcgaw/gluetun linuxserver/qbittorrent
```

### Remove Backup Automation

```bash
sudo ./scripts/remove-backup-automation.sh
```

### Uninstall Docker Desktop

**Option A: Manual**
1. Quit Docker Desktop
2. Move `/Applications/Docker.app` to Trash
3. Remove Docker data:
   ```bash
   rm -rf ~/Library/Group\ Containers/group.com.docker
   rm -rf ~/Library/Containers/com.docker.docker
   rm -rf ~/.docker
   ```

**Option B: Using Homebrew**
```bash
brew uninstall --cask docker
```

---

## Next Steps

- [Configure VPN Provider](provider-comparison.md)
- [Set Up Port Forwarding](port-forwarding.md)
- [Enable Monitoring](monitoring.md)
- [Performance Tuning](performance-tuning.md)
- [Backup and Restore](backups.md)

---

## Additional Resources

- [Docker Desktop for Mac Documentation](https://docs.docker.com/desktop/install/mac-install/)
- [macOS launchd Documentation](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
- [Homebrew Package Manager](https://brew.sh/)
- [Gluetun VPN Client](https://github.com/qdm12/gluetun)
