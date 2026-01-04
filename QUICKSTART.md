# ⚡ Quick Start Guide

Get Torrent VPN Stack running in **5 minutes** or less!

## Prerequisites

- ✅ Docker installed ([Get Docker](https://docs.docker.com/get-docker/))
- ✅ VPN subscription with one of these providers: [Mullvad](https://mullvad.net/), [ProtonVPN](https://protonvpn.com/), [PIA](https://www.privateinternetaccess.com/), [NordVPN](https://nordvpn.com/), or [70+ others](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)
- ✅ VPN credentials ready (WireGuard private key OR OpenVPN username/password)

## Installation (Choose Your Platform)

### macOS / Linux (Homebrew)

```bash
# Install
brew tap ddmoney420/torrent-vpn-stack
brew install torrent-vpn-stack

# Navigate to installation
cd $(brew --prefix)/opt/torrent-vpn-stack
```

### Arch Linux (AUR)

```bash
# Install
yay -S torrent-vpn-stack

# Navigate to installation
cd /usr/share/torrent-vpn-stack
```

### Windows (Chocolatey) - Coming Soon

```powershell
# Will be available soon (pending approval)
choco install torrent-vpn-stack

# Navigate to installation
cd $env:ProgramData\torrent-vpn-stack
```

### Any Platform (Git Clone)

```bash
# Clone repository
git clone https://github.com/ddmoney420/torrent-vpn-stack.git
cd torrent-vpn-stack
```

## Setup (3 Steps)

### Step 1: Run Setup Wizard

```bash
./scripts/setup.sh
```

The wizard will:

- ✅ Detect your platform (Windows/Linux/macOS)
- ✅ Guide you through VPN configuration
- ✅ Generate your `.env` file
- ✅ Set secure qBittorrent password

**Answer these questions when prompted:**

1. **VPN Provider**: `mullvad`, `protonvpn`, `private internet access`, `nordvpn`, etc.
2. **VPN Protocol**: `wireguard` (recommended) or `openvpn`
3. **WireGuard Private Key** OR **OpenVPN username/password**
4. **qBittorrent Password**: Create a secure password for the web UI

### Step 2: Start the Stack

```bash
docker compose up -d
```

**Expected output:**

```
[+] Running 2/2
 ✔ Container gluetun      Started
 ✔ Container qbittorrent  Started
```

### Step 3: Access qBittorrent

Open your browser: **http://localhost:8080**

- **Username**: `admin`
- **Password**: (the password you set in Step 1)

## Verify It's Working

### Check VPN Connection

```bash
./scripts/verify-vpn.sh
```

**Expected output:**

```
✓ VPN Connected: Sweden (Mullvad)
✓ IP Address: 185.65.134.XXX (Mullvad servers)
✓ DNS Leak Protection: ENABLED
✓ IPv6: DISABLED (leak prevention)
```

### Check for Leaks

```bash
./scripts/check-leaks.sh
```

This script tests for IP, DNS, and WebRTC leaks.

## What's Happening?

```
┌──────────────────────────────────────────┐
│ Your Computer                            │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ qBittorrent Web UI                 │  │
│  │ http://localhost:8080              │  │
│  └────────────────────────────────────┘  │
│           ↓ Routes through ↓             │
│  ┌────────────────────────────────────┐  │
│  │ Gluetun VPN Container              │  │
│  │ • Kill Switch Enabled              │  │
│  │ • DNS Leak Protection              │  │
│  │ • Firewall Rules                   │  │
│  └────────────────────────────────────┘  │
│                   ↓                      │
└───────────────────┼──────────────────────┘
                    ↓
         ┌──────────────────┐
         │ VPN Provider     │
         │ (Encrypted)      │
         └──────────────────┘
                    ↓
              [Internet]
```

**All torrent traffic goes through the VPN**. If the VPN drops, torrents **stop** (kill switch).

## Common Tasks

### Stop the Stack

```bash
docker compose down
```

### View Logs

```bash
# All logs
docker compose logs -f

# VPN only
docker compose logs -f gluetun

# qBittorrent only
docker compose logs -f qbittorrent
```

### Restart After Config Changes

```bash
docker compose down
docker compose up -d
```

### Update to Latest Version

**Homebrew**:

```bash
brew upgrade torrent-vpn-stack
```

**AUR**:

```bash
yay -Syu torrent-vpn-stack
```

**Git Clone**:

```bash
git pull
docker compose pull
docker compose up -d
```

## Troubleshooting

### VPN Not Connecting

```bash
# Check gluetun logs for errors
docker compose logs gluetun | grep -i error

# Common issues:
# - Wrong VPN provider name (check: https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)
# - Invalid credentials
# - Expired subscription
```

### Can't Access qBittorrent Web UI

```bash
# Check if containers are running
docker compose ps

# Restart containers
docker compose restart
```

### Forgot qBittorrent Password

```bash
# Stop stack
docker compose down

# Edit .env file
nano .env  # or vim, code, etc.

# Find QBITTORRENT_PASS and change it
QBITTORRENT_PASS=your_new_password

# Restart
docker compose up -d
```

### Check VPN IP Address

```bash
docker exec gluetun wget -qO- ifconfig.me
```

Should show your **VPN provider's IP**, NOT your real IP.

## Next Steps

### ✅ You're All Set! Now you can:

1. **Add torrents** via the qBittorrent web UI
2. **Configure automatic backups**: See [Backup Guide](docs/backup-guide.md)
3. **Optimize performance**: See [Performance Tuning](docs/performance-tuning.md)
4. **Compare VPN providers**: See [Provider Comparison](docs/provider-comparison.md)

### Recommended: Set Up Automatic Backups

```bash
# Run the backup automation setup
./scripts/setup-backup-automation.sh
```

This configures platform-specific automation (Task Scheduler on Windows, cron/systemd on Linux, launchd on macOS).

## Important Files

| File | Purpose |
|------|---------|
| `.env` | Your VPN credentials and settings |
| `docker-compose.yml` | Container configuration |
| `data/qbittorrent/` | qBittorrent config and settings |
| `downloads/` | Downloaded files |

## Getting Help

- **Documentation**: [Full README](README.md)
- **Issues**: [GitHub Issues](https://github.com/ddmoney420/torrent-vpn-stack/issues)
- **Discussions**: [GitHub Discussions](https://github.com/ddmoney420/torrent-vpn-stack/discussions)
- **Platform Guides**:
  - [Windows Installation](docs/install-windows.md)
  - [Linux Installation](docs/install-linux.md)
  - [macOS Installation](docs/install-macos.md)

## Security Reminders

- ✅ Never commit `.env` to version control (it's in `.gitignore`)
- ✅ Use a strong qBittorrent password
- ✅ Keep Docker images updated: `docker compose pull`
- ✅ Verify VPN is working: `./scripts/verify-vpn.sh`
- ✅ Check for leaks regularly: `./scripts/check-leaks.sh`

---

**Need more details?** See the [Full README](README.md) for comprehensive documentation, advanced configuration, and troubleshooting.
