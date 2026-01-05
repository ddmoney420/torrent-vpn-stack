# Torrent VPN Stack

[![CI](https://github.com/ddmoney420/torrent-vpn-stack/workflows/CI/badge.svg)](https://github.com/ddmoney420/torrent-vpn-stack/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)](https://github.com/ddmoney420/torrent-vpn-stack)

> **Cross-platform containerized torrent downloader behind VPN using Gluetun + qBittorrent**

A production-ready, security-hardened Docker Compose stack that routes all torrent traffic through a VPN with leak protection, kill switch, and web UI access from your local network.

**Supports Windows 10/11, Linux, and macOS (including Apple Silicon M1/M2/M3).**

---

## ⚡ Quick Start

**Want to get started in 5 minutes?** See the **[Quick Start Guide](QUICKSTART.md)** for express installation and setup.

<details>
<summary><strong>📦 One-Command Installation</strong></summary>

**Linux (Ubuntu, Debian, Fedora, etc.) - Homebrew:**
```bash
brew tap ddmoney420/torrent-vpn-stack && brew install torrent-vpn-stack
```

**Arch Linux / Manjaro - AUR:**
```bash
yay -S torrent-vpn-stack
```

**macOS (Intel & Apple Silicon) - Homebrew:**
```bash
brew tap ddmoney420/torrent-vpn-stack && brew install torrent-vpn-stack
```

**Windows - Chocolatey (Pending Approval):**
```powershell
choco install torrent-vpn-stack
```

Then follow the [Quick Start Guide](QUICKSTART.md) for setup.
</details>

---

## Features

### Security & Privacy
- ✅ **VPN Kill Switch** - All traffic routed through VPN; no leaks if VPN drops
- ✅ **DNS Leak Protection** - DNS-over-TLS (DoT) to Cloudflare prevents DNS leaks
- ✅ **IPv6 Disabled** - Prevents IPv6 leaks (most VPNs don't support IPv6)
- ✅ **Firewall Rules** - Strict firewall allows only VPN and local network access
- ✅ **No Root** - qBittorrent runs as unprivileged user (configurable UID/GID)
- ✅ **Automatic Health Checks** - Monitors VPN connection and restarts if unhealthy

### Usability
- ✅ **Web UI Access** - qBittorrent accessible from Mac and LAN devices
- ✅ **Single .env Configuration** - All settings in one file
- ✅ **Persistent Storage** - Config and downloads survive restarts
- ✅ **Automated Port Forwarding** - Syncs VPN forwarded port to qBittorrent (if supported)
- ✅ **Setup Wizard** - Interactive script for easy configuration
- ✅ **Verification Tools** - Scripts to check VPN connection and detect leaks

### Compatibility
- ✅ **Cross-Platform** - Windows 10/11, Linux (Ubuntu, Debian, Fedora, Arch), macOS (Intel & Apple Silicon M1/M2/M3)
- ✅ **Multiple VPN Providers** - Supports Mullvad, NordVPN, ProtonVPN, Surfshark, PIA, and [many more](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)
- ✅ **WireGuard & OpenVPN** - Modern WireGuard (recommended) or classic OpenVPN
- ✅ **Automated Backups** - Native automation for all platforms (Task Scheduler, systemd/cron, launchd)

## Table of Contents

**New User?** Start with the **[⚡ Quick Start Guide](QUICKSTART.md)**

- [Prerequisites](#prerequisites)
- [VPN Provider Selection](#vpn-provider-selection)
- [Installation](#installation)
  - [Package Managers (Recommended)](#package-managers-recommended)
  - [Manual Installation](#manual-installation-git-clone)
- [Quick Start (Inline)](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Starting and Stopping](#starting-and-stopping)
  - [Accessing from LAN](#accessing-from-lan)
  - [Backups & Disaster Recovery](#backups--disaster-recovery)
- [Security Notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Architecture](#architecture)
- [Contributing](#contributing)
- [License](#license)

## Prerequisites

### Required
- **Operating System:** Windows 10/11, Linux (Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch), or macOS 11+
- **Docker:** Docker Desktop (Windows/macOS) or Docker Engine (Linux)
- **Docker Compose:** v2.0+ (included with Docker Desktop)
- **VPN Subscription:** One of the [supported providers](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)
- **VPN Credentials:** WireGuard config or OpenVPN username/password

### Recommended
- 8 GB RAM (4 GB minimum)
- 20 GB free disk space (more for downloads)
- Stable internet connection

### Platform-Specific Installation Guides

Choose your platform for detailed installation instructions:

- **[Windows Installation Guide](docs/install-windows.md)** - WSL 2, Git Bash, PowerShell automation
- **[Linux Installation Guide](docs/install-linux.md)** - Ubuntu, Debian, Fedora, Arch, systemd/cron
- **[macOS Installation Guide](docs/install-macos.md)** - Intel and Apple Silicon, launchd automation

## VPN Provider Selection

**Choosing the right VPN provider is critical for torrent performance.**

### ✅ Recommended for Torrenting (with Port Forwarding)

| Provider | Speed | Privacy | Price/Month | Notes |
|----------|-------|---------|-------------|-------|
| **Mullvad** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | $5.50 | Best overall, port forwarding on all servers |
| **ProtonVPN Plus** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | $4.99+ | Swiss privacy, port forwarding on Plus+ plans |
| **Private Internet Access** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | $2.19+ | Budget-friendly, port forwarding supported |

### ⚠️ Not Recommended for Torrenting (no Port Forwarding)

| Provider | Why Not Recommended |
|----------|---------------------|
| **NordVPN** | No port forwarding = 60-70% fewer peers, poor seeding |
| **Surfshark** | No port forwarding, limited torrent performance |
| **ExpressVPN** | No port forwarding, expensive, no WireGuard |

**Port forwarding allows incoming connections = 2-3x more peers = faster downloads and better seeding.**

### Quick Comparison

- **Best Performance:** Mullvad (port forwarding + WireGuard + privacy)
- **Best Privacy:** Mullvad or ProtonVPN (Swiss/Swedish jurisdiction)
- **Best Budget:** PIA ($2.19/month with port forwarding)
- **Already Have NordVPN?** Works, but expect slower speeds without port forwarding

**📖 Full comparison:** [docs/provider-comparison.md](docs/provider-comparison.md)

**⚡ Performance tuning:** [docs/performance-tuning.md](docs/performance-tuning.md)

**🔧 Provider examples:** See `examples/providers/` for ready-to-use configurations

### Custom/Unsupported VPN Providers

If your VPN provider is not natively supported by Gluetun, you can use custom WireGuard mode:

```bash
# In .env, use:
VPN_SERVICE_PROVIDER=custom
VPN_TYPE=wireguard

# Required fields from your provider's WireGuard config:
WIREGUARD_PRIVATE_KEY=<from [Interface] PrivateKey>
WIREGUARD_ADDRESSES=<from [Interface] Address>
WIREGUARD_PUBLIC_KEY=<from [Peer] PublicKey>
WIREGUARD_ENDPOINT_IP=<from [Peer] Endpoint, IP only>
WIREGUARD_ENDPOINT_PORT=<from [Peer] Endpoint, port only>
```

**📄 Full example:** See `examples/providers/custom.env.example`

## Installation

Choose your preferred installation method:

### Package Managers (Recommended)

Install with a single command using your platform's package manager:

#### Linux (All Distributions) - Homebrew ✅

**Supports:** Ubuntu, Debian, Fedora, openSUSE, Rocky Linux, AlmaLinux, and more!

```bash
# Option 1: Install from tap
brew tap ddmoney420/torrent-vpn-stack
brew install torrent-vpn-stack

# Option 2: Install directly
brew install ddmoney420/torrent-vpn-stack/torrent-vpn-stack

# Quick start after installation
cd $(brew --prefix)/opt/torrent-vpn-stack
torrent-vpn-setup
docker compose up -d
```

**📖 [Homebrew Installation Guide](packaging/homebrew/README.md)**

#### Arch Linux / Manjaro - AUR ✅

**Arch users can use AUR instead of Homebrew:**

```bash
# Using yay
yay -S torrent-vpn-stack

# Using paru
paru -S torrent-vpn-stack

# Quick start after installation
cd /usr/share/torrent-vpn-stack
torrent-vpn-setup
docker compose up -d
```

**📖 [AUR Installation Guide](packaging/aur/README.md)**

#### macOS (Intel & Apple Silicon) - Homebrew ✅

```bash
# Install from tap
brew tap ddmoney420/torrent-vpn-stack
brew install torrent-vpn-stack

# Quick start after installation
cd $(brew --prefix)/opt/torrent-vpn-stack
torrent-vpn-setup
docker compose up -d
```

**📖 [Homebrew Installation Guide](packaging/homebrew/README.md)**

#### Windows - Chocolatey 🔄

*Submitted - Pending Moderation*

```powershell
# Will be available as (pending approval):
choco install torrent-vpn-stack

# Quick start after installation
cd $env:ProgramData\torrent-vpn-stack
torrent-vpn-setup
docker compose up -d
```

**📖 [Chocolatey Installation Guide](packaging/chocolatey/README.md)**
**Status**: Resubmitted with fixes - pending moderation (24-48 hours)
**Note**: Fixed Docker dependency issue, now checks for Docker in install script

### Manual Installation (Git Clone)

If you prefer manual installation or your platform doesn't have a package manager:

```bash
# Clone the repository
git clone https://github.com/ddmoney420/torrent-vpn-stack.git
cd torrent-vpn-stack

# Run the setup wizard (recommended for first-time setup)
./scripts/setup.sh

# Or manually copy and edit the configuration
cp .env.example .env
nano .env  # Edit with your VPN credentials
```

## Quick Start

This guide assumes you've already installed via one of the methods above. If using manual installation, start here:

### 1. Get VPN Credentials

**For WireGuard (Recommended):**
- **Mullvad**: [Account → WireGuard Config](https://mullvad.net/en/account/wireguard-config)
- **ProtonVPN**: [Account → Downloads → WireGuard](https://account.protonvpn.com/downloads)
- **NordVPN**: [Dashboard → Manual Setup → WireGuard](https://my.nordaccount.com/dashboard/nordvpn/)

**For OpenVPN:**
- Use your VPN account username and password

### 2. Run Setup Wizard

```bash
# Package manager installations
torrent-vpn-setup  # Available system-wide

# Manual installation
./scripts/setup.sh
```

The interactive wizard will guide you through:
- VPN provider selection
- VPN credentials configuration
- Network settings
- Downloads path
- Security settings

### 3. Start the Stack

```bash
# Start all services in detached mode
docker compose up -d

# Check logs to verify VPN connection
docker compose logs -f gluetun

# Look for: "You are running on the bleeding edge of latest"
# and "ip getter: 1.2.3.4" (your VPN IP, not your real IP)
```

### 4. Access qBittorrent

Open http://localhost:8080 (or your configured `QBITTORRENT_WEBUI_PORT`)

**Default Credentials:**
- Username: `admin`
- Password: `adminadmin` (CHANGE THIS IMMEDIATELY in Settings → Web UI)

### 5. Verify VPN & Leak Protection

```bash
# Package manager installations
torrent-vpn-verify       # Verify VPN connection
torrent-vpn-check-leaks  # Check for DNS/IP leaks

# Manual installation
./scripts/verify-vpn.sh
./scripts/check-leaks.sh
```

## Detailed Setup

### Step 1: Environment Configuration

Edit `.env` and configure the following critical settings:

#### VPN Provider (Required)
```env
VPN_SERVICE_PROVIDER=mullvad  # Your VPN provider
VPN_TYPE=wireguard            # wireguard or openvpn
```

#### WireGuard Credentials (Required if using WireGuard)
```env
WIREGUARD_PRIVATE_KEY=your_private_key_here
WIREGUARD_ADDRESSES=10.2.0.2/32
```

#### Downloads Path (Required)
```env
DOWNLOADS_PATH=~/Downloads/torrents  # Where files will be saved
```

#### Network Configuration (Required)
```env
LOCAL_SUBNET=192.168.1.0/24  # Your home network subnet
```

Find your subnet:
```bash
# macOS
ipconfig getifaddr en0 | awk -F. '{print $1"."$2"."$3".0/24"}'

# Or check your router's DHCP range
```

#### qBittorrent Security (Required)
```env
QBITTORRENT_PASS=your_strong_password_here  # CHANGE FROM DEFAULT!
```

### Step 2: File Permissions (macOS Specific)

Get your user and group IDs:
```bash
id -u  # User ID (PUID)
id -g  # Group ID (PGID)
```

Update in `.env`:
```env
PUID=501   # Your user ID
PGID=20    # Your group ID
```

### Step 3: Create Downloads Directory

```bash
mkdir -p ~/Downloads/torrents
```

### Step 4: Port Forwarding (Optional)

Port forwarding significantly improves torrent performance by allowing incoming peer connections.

**Supported Providers:** Mullvad, ProtonVPN (Plus+), Private Internet Access (PIA)

#### Enable Port Forwarding

Edit `.env`:

```env
VPN_PORT_FORWARDING=on

# For ProtonVPN only, also set:
VPN_PORT_FORWARDING_PROVIDER=protonvpn

# Optional: Adjust sync interval (default: 300 seconds)
PORT_SYNC_INTERVAL=300
```

#### Start with Port Forwarding Profile

The port sync helper runs as a Docker Compose profile. Start the stack with:

```bash
docker compose --profile port-forwarding up -d
```

The `gluetun-qbittorrent-port-manager` service will automatically sync the forwarded port from Gluetun to qBittorrent whenever it changes.

**📖 For detailed setup, verification, and troubleshooting, see [docs/port-forwarding.md](docs/port-forwarding.md)**

### Step 5: Start Services

```bash
# Start in detached mode
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f

# View only VPN logs
docker-compose logs -f gluetun
```

### Step 6: Initial qBittorrent Setup

1. Open http://localhost:8080
2. Login with default credentials (admin/adminadmin)
3. **Immediately change password**: Settings → Web UI → Authentication
4. **Configure downloads path**: Settings → Downloads → Default Save Path: `/downloads`
5. **Disable UPnP/NAT-PMP**: Settings → Connection → uncheck both (VPN handles this)
6. **Set connection port**: Settings → Connection → Listening Port: `6881` (or your configured port)

### Step 7: Verify Everything Works

```bash
# Run all verification checks
./scripts/verify-vpn.sh

# Expected output:
# ✅ VPN container is running
# ✅ VPN IP detected: 1.2.3.4 (not your real IP)
# ✅ DNS leak test passed
# ✅ qBittorrent is accessible
# ✅ No IPv6 leaks detected
```

## Configuration

### Environment Variables Reference

See [.env.example](.env.example) for full documentation of all variables.

**Critical Settings:**
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VPN_SERVICE_PROVIDER` | Yes | - | Your VPN provider (mullvad, nordvpn, protonvpn, etc.) |
| `VPN_TYPE` | Yes | wireguard | Protocol: `wireguard` or `openvpn` |
| `WIREGUARD_PRIVATE_KEY` | Yes* | - | Your WireGuard private key (*if using WireGuard) |
| `WIREGUARD_ADDRESSES` | Yes* | - | Your WireGuard IP address (*if using WireGuard) |
| `DOWNLOADS_PATH` | Yes | ./downloads | Local path for downloaded files |
| `LOCAL_SUBNET` | Yes | 192.168.1.0/24 | Your home network subnet for LAN access |
| `QBITTORRENT_PASS` | Yes | adminadmin | Web UI password (CHANGE THIS!) |

### Port Configuration

The stack exposes these ports on your Mac:

| Port | Service | Purpose |
|------|---------|---------|
| 8080 | qBittorrent Web UI | Browser access to qBittorrent |
| 6881 | qBittorrent Connections | Default torrent peer connections (TCP/UDP) |
| 8000 | Gluetun Control | Health checks and port forwarding info (optional) |
| *Dynamic* | VPN Port Forwarding | Auto-assigned by VPN provider (if enabled) |

**Note:** All ports are defined on the `gluetun` service because qBittorrent uses Gluetun's network stack (`network_mode: service:gluetun`). This is intentional for the kill switch.

**Port Forwarding:** When enabled, your VPN provider assigns a dynamic port (e.g., 51234) that automatically syncs to qBittorrent. See [docs/port-forwarding.md](docs/port-forwarding.md) for setup.

### Volume Management

**Persistent Volumes:**
- `gluetun-config` - VPN configuration and state
- `qbittorrent-config` - qBittorrent settings and torrent metadata
- `${DOWNLOADS_PATH}` - Downloaded files (bind mount to your Mac)

**Backup Important Data:**
```bash
# Backup qBittorrent config (includes torrent list and settings)
docker run --rm -v torrent-vpn-stack_qbittorrent-config:/config -v $(pwd):/backup alpine tar czf /backup/qbittorrent-backup.tar.gz -C /config .

# Restore from backup
docker run --rm -v torrent-vpn-stack_qbittorrent-config:/config -v $(pwd):/backup alpine sh -c "cd /config && tar xzf /backup/qbittorrent-backup.tar.gz"
```

## Usage

### Starting and Stopping

```bash
# Start all services
docker-compose up -d

# Stop all services (keeps data)
docker-compose down

# Stop and remove volumes (DELETES ALL DATA)
docker-compose down -v

# Restart specific service
docker-compose restart gluetun
docker-compose restart qbittorrent

# View logs
docker-compose logs -f
docker-compose logs -f gluetun     # VPN logs only
docker-compose logs -f qbittorrent  # qBittorrent logs only
```

### Accessing from LAN

To access qBittorrent from other devices on your network:

1. Find your Mac's IP: `ipconfig getifaddr en0`
2. Open `http://YOUR_MAC_IP:8080` from another device
3. Ensure your `LOCAL_SUBNET` in `.env` includes that device's IP

**Security Warning:** Anyone on your LAN can access qBittorrent's Web UI. Use a strong password and consider IP allowlisting in qBittorrent's settings.

### Updating

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d

# Clean up old images
docker image prune
```

### Monitoring & Observability

#### Quick Health Checks

**Check VPN Connection:**
```bash
# Get current VPN IP
docker exec gluetun wget -qO- https://api.ipify.org
# Should return your VPN IP, NOT your real IP

# Check Gluetun health
curl http://localhost:8000/v1/publicip/ip
```

**Check qBittorrent Status:**
```bash
# Via Web UI: http://localhost:8080
# Or via API:
curl -u admin:your_password http://localhost:8080/api/v2/app/version
```

**View Port Forwarding (if enabled):**
```bash
curl http://localhost:8000/v1/openvpn/portforwarded
```

#### Full Monitoring Stack (Optional)

Enable comprehensive monitoring with Prometheus + Grafana:

```bash
# Start stack with monitoring enabled
docker compose --profile monitoring up -d
```

**Features:**
- **Grafana Dashboards**: Visual metrics at http://localhost:3000
  - System: Container CPU, memory, network usage
  - qBittorrent: Download/upload speeds, torrents, peers, ratio
  - VPN: Connection status, uptime, throughput
- **Prometheus**: Metrics collection at http://localhost:9090
- **30-day retention**: Historical trend analysis
- **Real-time updates**: Auto-refresh every 10 seconds

**Access:**
- Grafana: http://localhost:3000 (login: admin/admin)
- Prometheus: http://localhost:9090

**📖 For detailed setup and dashboard guide, see [docs/monitoring.md](docs/monitoring.md)**

### Backups & Disaster Recovery

Protect your configuration with automated or manual backups:

```bash
# Manual backup
./scripts/backup.sh

# Setup automated daily backups (macOS)
./scripts/setup-backup-automation.sh
```

**Features:**
- Backs up qBittorrent config, Gluetun config, and optionally monitoring data
- Automated daily backups via macOS launchd
- 7-day retention by default (configurable)
- Easy restore with interactive selection

**Restore from backup:**
```bash
# List available backups
./scripts/restore.sh --list

# Interactive restore
./scripts/restore.sh
```

**📖 For complete backup guide, see [docs/backups.md](docs/backups.md)**

## Security Notes

### Kill Switch Mechanism

The kill switch works through Docker's network isolation:

1. qBittorrent uses `network_mode: service:gluetun`
2. All qBittorrent traffic **must** go through Gluetun's network stack
3. If Gluetun's VPN drops, qBittorrent has **no route to the internet**
4. Gluetun's firewall blocks all non-VPN traffic

**Test the Kill Switch:**
```bash
# Stop VPN while qBittorrent is running
docker-compose stop gluetun

# Try to access internet from qBittorrent container (should fail)
docker exec qbittorrent wget -T 5 -O- https://api.ipify.org
# Expected: Connection timeout/failure
```

### DNS Leak Protection

**Layers of Protection:**
1. **DNS-over-TLS (DoT)** - Gluetun uses encrypted DNS to Cloudflare
2. **Custom DNS servers** - Bypasses your ISP's DNS
3. **IPv6 disabled** - Prevents IPv6 DNS leaks
4. **Firewall rules** - Blocks DNS queries outside VPN tunnel

**Verify DNS:**
```bash
./scripts/check-leaks.sh
# Or manually:
docker exec qbittorrent nslookup google.com
# Should resolve through Cloudflare (1.1.1.1) or VPN DNS
```

### IPv6 Leak Protection

IPv6 is **disabled** by default because:
- Most VPN providers don't support IPv6
- IPv6 can leak your real location
- Torrents don't require IPv6

If you need IPv6 (rare), ensure your VPN supports it first.

### Firewall Rules

Gluetun's firewall allows:
- ✅ VPN traffic
- ✅ Local subnet (your home network)
- ✅ Incoming torrent connections on configured port
- ❌ Everything else (kill switch)

**Firewall is configured via:**
```env
FIREWALL_OUTBOUND_SUBNETS=192.168.1.0/24  # Your local network
FIREWALL_VPN_INPUT_PORTS=6881              # Torrent port
```

### Least Privilege

- qBittorrent runs as non-root user (PUID/PGID)
- Gluetun requires `NET_ADMIN` capability (minimum for VPN)
- No unnecessary capabilities granted
- Read-only root filesystem where possible

### Credential Storage

**CRITICAL:** Never commit `.env` to version control!

```.gitignore
.env
*.env
!.env.example
```

**Secure Your `.env`:**
```bash
chmod 600 .env  # Only you can read/write
```

## Troubleshooting

### VPN Won't Connect

**Symptoms:** Gluetun logs show connection errors, timeouts, or "context canceled"

**Solutions:**
1. **Verify credentials:**
   ```bash
   grep WIREGUARD_PRIVATE_KEY .env  # Should not be empty
   ```
2. **Check VPN provider status** - Visit your provider's status page
3. **Try different server:**
   ```env
   SERVER_COUNTRIES=Sweden  # Or another country
   ```
4. **Enable debug logging:**
   ```env
   LOG_LEVEL=debug
   ```
   Then check logs: `docker-compose logs gluetun | grep -i error`

5. **Verify Docker has internet:**
   ```bash
   docker run --rm alpine wget -O- https://cloudflare.com
   ```

### Custom WireGuard Provider Issues

**Symptoms:** Using `VPN_SERVICE_PROVIDER=custom` but VPN won't connect

**Solutions:**
1. **"endpoint IP is not set" error:**
   ```env
   # All fields are REQUIRED for custom provider:
   WIREGUARD_ENDPOINT_IP=1.2.3.4
   WIREGUARD_ENDPOINT_PORT=51820
   ```

2. **"private key is not valid" error:**
   - Check for copy/paste errors (extra spaces, missing characters)
   - Ensure the full key is copied (usually ends with `=`)

3. **Connection timeout (no internet after connect):**
   - Verify `WIREGUARD_ADDRESSES` matches your provider's config exactly
   - Verify `WIREGUARD_PUBLIC_KEY` is the server's public key (from `[Peer]` section)
   - Test endpoint is reachable: `nc -vz -u <endpoint_ip> 51820`

4. **"endpoint port is set" error with built-in provider:**
   - Remove or leave empty: `WIREGUARD_ENDPOINT_PORT=`
   - Built-in providers auto-detect the port

### qBittorrent Shows "Connection Refused"

**Symptoms:** Can't access http://localhost:8080 or qBittorrent won't start

**Solutions:**
1. **Wait for Gluetun to be healthy:**
   ```bash
   docker-compose ps  # Gluetun should show "healthy"
   ```
   qBittorrent won't start until Gluetun is healthy (by design).

2. **Check port conflicts:**
   ```bash
   lsof -i :8080  # Should only show Docker
   ```
   If another service uses 8080, change `QBITTORRENT_WEBUI_PORT` in `.env`.

3. **Check container logs:**
   ```bash
   docker-compose logs qbittorrent | grep -i error
   ```

### qBittorrent Shows "Unauthorized" (No Login Page)

**Symptoms:** Accessing the Web UI shows "Unauthorized" instead of a login page

**Solutions:**
1. **Disable host header validation** (required for Docker):
   ```bash
   # Stop qBittorrent
   docker-compose stop qbittorrent

   # Edit config (find your volume path)
   docker run --rm -v torrent-vpn-stack_qbittorrent-config:/config alpine sh -c '
   cat >> /config/qBittorrent/qBittorrent.conf << EOF
   WebUI\HostHeaderValidation=false
   WebUI\CSRFProtection=false
   WebUI\LocalHostAuth=false
   EOF'

   # Restart
   docker-compose start qbittorrent
   ```

2. **Check the temporary password** (first run only):
   ```bash
   docker-compose logs qbittorrent | grep -i password
   ```

### Torrents Not Connecting / No Upload/Download

**Symptoms:** Torrents stuck in "Stalled" or "Downloading" with 0 peers

**Solutions:**
1. **Check VPN connection:**
   ```bash
   ./scripts/verify-vpn.sh
   ```

2. **Verify port forwarding (if enabled):**
   ```bash
   curl http://localhost:8000/v1/openvpn/portforwarded
   # Should return a port number
   ```
   Then check qBittorrent Settings → Connection → Port matches this number.

3. **Disable problematic settings in qBittorrent:**
   - Settings → Connection → Disable UPnP/NAT-PMP
   - Settings → Connection → Disable "Use different port on each startup"

4. **Try a different VPN server** - Some servers may block torrent traffic

5. **Check if you're firewalled:**
   - A 🔥 fire icon in qBittorrent means you're behind a firewall
   - Enable port forwarding or use a VPN server that supports it

### DNS Leaks Detected

**Symptoms:** `./scripts/check-leaks.sh` shows your ISP's DNS

**Solutions:**
1. **Verify DoT is enabled:**
   ```bash
   docker-compose logs gluetun | grep -i "dns"
   # Should see "DNS over TLS" enabled
   ```

2. **Force DNS-over-TLS:**
   ```env
   DOT=on
   DOT_PROVIDERS=cloudflare
   ```

3. **Check for IPv6 leaks:**
   ```bash
   docker exec qbittorrent ip -6 addr
   # Should be empty or only show local IPv6
   ```

### macOS-Specific Issues

#### File Permissions Issues

**Symptoms:** Can't write to downloads folder, permission denied errors

**Solutions:**
```bash
# Fix ownership
sudo chown -R $(id -u):$(id -g) ~/Downloads/torrents

# Update PUID/PGID in .env to match your user
id -u  # Use this for PUID
id -g  # Use this for PGID
```

#### Docker Desktop Resource Limits

**Symptoms:** Slow performance, containers restarting

**Solutions:**
- Docker Desktop → Settings → Resources
- Increase RAM to 4GB+
- Increase Swap to 2GB+
- Increase Disk image size if low on space

#### Apple Silicon Compatibility

All images used support ARM64 (Apple Silicon). If you see warnings about platform:
```bash
# Force ARM64 platform
DOCKER_DEFAULT_PLATFORM=linux/arm64 docker-compose up -d
```

### Can't Access from LAN

**Symptoms:** qBittorrent works on Mac but not from other devices

**Solutions:**
1. **Check firewall:**
   ```bash
   # Temporarily disable macOS firewall to test
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
   ```
   If it works, add Docker to firewall allowlist.

2. **Verify LOCAL_SUBNET:**
   ```env
   LOCAL_SUBNET=192.168.1.0/24  # Must match your network
   ```
   Find your network: `netstat -nr | grep default`

3. **Check Docker port binding:**
   ```bash
   lsof -i :8080 | grep LISTEN
   # Should show 0.0.0.0:8080 (not 127.0.0.1:8080)
   ```

## FAQ

### Q: Is this legal?
**A:** Torrenting itself is legal. Using a VPN is legal. Downloading copyrighted material without permission is illegal. This stack is a tool; you are responsible for how you use it.

### Q: Will my ISP know I'm torrenting?
**A:** With this setup and a proper VPN:
- Your ISP sees encrypted VPN traffic only
- They cannot see what you're downloading
- They cannot see torrent protocol
- All DNS queries are encrypted (DoT)

**However:** Your ISP knows you're using a VPN. In some jurisdictions, that alone may raise flags.

### Q: Which VPN provider should I use?
**A:** Look for:
- ✅ WireGuard support
- ✅ Port forwarding support (optional but improves speeds)
- ✅ No-logging policy
- ✅ Fast speeds (10+ Gbps servers)
- ✅ P2P/torrenting allowed

**Recommended:**
- **Mullvad** - Best privacy, port forwarding, flat rate
- **ProtonVPN** - Port forwarding, secure core, Switzerland-based
- **Private Internet Access (PIA)** - Port forwarding, many servers, affordable

**Avoid:**
- Free VPNs (slow, logging, malware)
- VPNs that block P2P traffic
- VPNs in 14-Eyes countries (if privacy is critical)

### Q: Do I need port forwarding?
**A:** Not required, but highly recommended for optimal performance:
- **Without:** You can download, but only from peers who have port forwarding (limited connectivity)
- **With:** You become "connectable" — faster speeds, better seeding, healthier swarms

**Supported Providers:** Mullvad, ProtonVPN (Plus+), Private Internet Access (PIA)

**📖 See [docs/port-forwarding.md](docs/port-forwarding.md) for complete setup guide**

### Q: How much does this cost?
**A:**
- VPN: $5-15/month (depends on provider, cheaper with annual plans)
- This stack: Free and open source
- Docker Desktop: Free (paid for enterprise use)

### Q: Does this work on my platform?
**A:** Yes! Fully cross-platform support:
- ✅ **Windows 10/11** - Native support with WSL2 or Git Bash (install via Chocolatey)
- ✅ **Linux** - Ubuntu, Debian, Fedora, Arch, etc. (install via Homebrew or AUR)
- ✅ **macOS** - Intel and Apple Silicon M1/M2/M3 (install via Homebrew)

See the [Installation](#installation) section for platform-specific package managers and detailed guides in [docs/](docs/).

### Q: Can I run multiple instances?
**A:** Yes, but you'll need separate VPN credentials for each:
1. Copy the entire folder: `cp -r torrent-vpn-stack torrent-vpn-stack-2`
2. Change container names in `docker-compose.yml`
3. Change ports in `.env` (8081, 6882, etc.)
4. Use different VPN credentials

### Q: What if my VPN doesn't support WireGuard?
**A:** Use OpenVPN:
```env
VPN_TYPE=openvpn
OPENVPN_USER=your_username
OPENVPN_PASSWORD=your_password
```
WireGuard is faster and more modern, but OpenVPN works fine.

### Q: How do I know if there's a leak?
**A:** Run the verification:
```bash
./scripts/check-leaks.sh

# Or manually check your IP:
docker exec qbittorrent wget -qO- https://api.ipify.org
# Should show VPN IP, NOT your real IP
```

### Q: Can I use a free VPN?
**A:** Not recommended:
- ❌ Free VPNs often log and sell your data
- ❌ Slow speeds (congested servers)
- ❌ Block P2P traffic
- ❌ Data caps
- ❌ Some inject ads or malware

Quality VPNs cost $3-10/month with annual plans.

### Q: What happens if the VPN disconnects?
**A:** The **kill switch** activates:
1. qBittorrent loses all internet connectivity
2. All torrent traffic stops immediately
3. Your real IP is **never** exposed
4. Gluetun attempts to reconnect automatically
5. When VPN reconnects, torrenting resumes

### Q: How do I add more torrents remotely?
**A:** If your qBittorrent Web UI is accessible from outside your home:
1. **Don't expose it directly to the internet** (security risk!)
2. Use a VPN to your home network (Tailscale, WireGuard, ZeroTier)
3. Or use a reverse proxy with authentication (Traefik, nginx)
4. Or use qBittorrent's mobile apps (connect via VPN)

**Never port forward qBittorrent Web UI to the internet without strong auth + IP allowlist!**

## Architecture

See [docs/architecture.md](docs/architecture.md) for detailed architecture diagrams and flow charts.

**High-Level Overview:**

```
┌─────────────────────────────────────────────────────────────────────┐
│            Host System (Windows / Linux / macOS)                    │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                   Docker Compose Stack                       │   │
│  │  ┌────────────────────────────────────────────────────────┐  │   │
│  │  │              Gluetun (VPN Gateway)                     │  │   │
│  │  │  ┌──────────────────────────────────────────────────┐  │  │   │
│  │  │  │  • WireGuard/OpenVPN client                      │  │  │   │
│  │  │  │  • Firewall (kill switch)                        │  │  │   │
│  │  │  │  • DNS-over-TLS (DoT)                            │  │  │   │
│  │  │  │  • IPv6 disabled                                 │  │  │   │
│  │  │  │  • Port forwarding                               │  │  │   │
│  │  │  │  • Health monitoring                             │  │  │   │
│  │  │  └──────────────────────────────────────────────────┘  │  │   │
│  │  │                                                         │  │   │
│  │  │  Exposes ports to host:                                │  │   │
│  │  │    - 8080 (qBittorrent Web UI)                         │  │   │
│  │  │    - 6881 (Torrent connections)                        │  │   │
│  │  │    - 8000 (Gluetun control - optional)                 │  │   │
│  │  └────────────────────────────────────────────────────────┘  │   │
│  │                            ▲                                 │   │
│  │                            │ network_mode: service:gluetun   │   │
│  │                            │ (Shares network namespace)      │   │
│  │  ┌─────────────────────────┴────────────────────────────┐   │   │
│  │  │           qBittorrent (Torrent Client)               │   │   │
│  │  │  • Shares Gluetun's network namespace                │   │   │
│  │  │  • All traffic forced through VPN tunnel             │   │   │
│  │  │  • No independent internet access (kill switch)      │   │   │
│  │  │  • Web UI accessible @ http://localhost:8080         │   │   │
│  │  │  • Runs as unprivileged user (PUID/PGID)             │   │   │
│  │  └──────────────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                            │                                         │
│                            │ Bind mount to host filesystem           │
│                            ▼                                         │
│     Downloads Path (configurable):                                  │
│       • Windows: C:\Users\<user>\Downloads\torrents                 │
│       • Linux:   /home/<user>/Downloads/torrents                    │
│       • macOS:   /Users/<user>/Downloads/torrents                   │
│                                                                      │
│     Docker Volumes (persistent config):                             │
│       • gluetun-config (VPN state)                                  │
│       • qbittorrent-config (settings & torrents)                    │
└─────────────────────────────────────────────────────────────────────┘
                            │
                            │ Encrypted VPN Tunnel
                            │ (WireGuard or OpenVPN)
                            ▼
                  Internet via VPN Provider
            (Your real IP is never exposed)
```

**Traffic Flow:**
1. qBittorrent → Gluetun's network stack (forced, no alternatives)
2. Gluetun → Firewall check → Allowed?
3. If VPN up: Encrypt → VPN server → Internet
4. If VPN down: Drop packet (kill switch)

**No traffic can leave qBittorrent without going through the VPN.**

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

**Areas for contribution:**
- Additional VPN provider examples
- Setup wizard improvements
- More verification scripts
- Platform-specific guides (Linux, Windows)
- Performance optimizations
- Security hardening

## License

MIT License - See LICENSE file for details

## Acknowledgments

- [Gluetun](https://github.com/qdm12/gluetun) by [@qdm12](https://github.com/qdm12) - Excellent VPN client container
- [LinuxServer.io](https://www.linuxserver.io/) - qBittorrent Docker image
- [qBittorrent](https://www.qbittorrent.org/) - Feature-rich torrent client

## Disclaimer

This tool is provided for educational and legitimate use only. The authors are not responsible for any misuse or illegal activity. Always comply with copyright laws and terms of service of your VPN provider and ISP.

## Contributing

Contributions are welcome! This is an open source project under the MIT License.

- 🤝 [Contributing Guide](CONTRIBUTING.md) - How to contribute code, documentation, or bug reports
- 🔒 [Security Policy](SECURITY.md) - Reporting vulnerabilities responsibly
- 📜 [Code of Conduct](CODE_OF_CONDUCT.md) - Community standards
- 📝 [MIT License](LICENSE) - Free and open source

### Ways to Contribute

- Report bugs or suggest features via [GitHub Issues](https://github.com/ddmoney420/torrent-vpn-stack/issues)
- Improve documentation (especially platform-specific guides)
- Test on different platforms and report compatibility
- Submit pull requests for bug fixes or enhancements
- Help answer questions in [Discussions](https://github.com/ddmoney420/torrent-vpn-stack/discussions)

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## Support

- 📖 [Documentation](docs/)
- 🐛 [Report Issues](https://github.com/ddmoney420/torrent-vpn-stack/issues)
- 💬 [Discussions](https://github.com/ddmoney420/torrent-vpn-stack/discussions)

---

**Made with ❤️ for privacy-conscious torrenters**

**Research Sources:**
- [Gluetun with ProtonVPN Discussion](https://github.com/qdm12/gluetun/discussions/2686)
- [Port Conflicts with Gluetun and qBittorrent](https://forums.docker.com/t/mystery-conflicting-port-options-gluetun-qbittorrent-sabnzbd/139363)
- [qBittorrent with GlueTUN VPN Setup Guide](https://drfrankenstein.co.uk/qbittorrent-with-gluetun-vpn-in-container-manager-on-a-synology-nas/)
- [Troubleshooting Errored Status](https://forums.docker.com/t/qbittorrent-running-through-gluetun-vpn-container-makes-all-torrents-get-errored-status/149615)
- [YAMS Installation Issues](https://forum.yams.media/viewtopic.php?t=151)
- [Gluetun API Connection Issue](https://github.com/qdm12/gluetun/issues/2674)
- [AirVPN Troubleshooting Guide](https://airvpn.org/forums/topic/66670-help-with-gluetun-qbittorrent/)
- [Gluetun+qBittorrent Bug Report](https://github.com/qdm12/gluetun/issues/2819)
- [Automated Port Manager](https://github.com/SnoringDragon/gluetun-qbittorrent-port-manager)
- [QBittorrent with Gluetun Setup](https://www.tatewalker.com/blog/docker-torrent/)
