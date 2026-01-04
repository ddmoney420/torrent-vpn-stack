# Torrent VPN Stack

[![CI](https://github.com/ddmoney420/torrent-vpn-stack/workflows/CI/badge.svg)](https://github.com/ddmoney420/torrent-vpn-stack/actions)

> **Containerized torrent downloader behind VPN using Gluetun + qBittorrent for macOS (Apple Silicon compatible)**

A production-ready, security-hardened Docker Compose stack that routes all torrent traffic through a VPN with leak protection, kill switch, and web UI access from your local network.

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
- ✅ **macOS Apple Silicon** - Tested on M1/M2/M3 Macs
- ✅ **Multiple VPN Providers** - Supports Mullvad, NordVPN, ProtonVPN, Surfshark, PIA, and [many more](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)
- ✅ **WireGuard & OpenVPN** - Modern WireGuard (recommended) or classic OpenVPN

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Detailed Setup](#detailed-setup)
- [Configuration](#configuration)
- [Usage](#usage)
- [Security Notes](#security-notes)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Architecture](#architecture)
- [Contributing](#contributing)

## Prerequisites

### Required
- **macOS** (Apple Silicon M1/M2/M3 or Intel)
- **Docker Desktop** 4.0+ ([Download](https://www.docker.com/products/docker-desktop/))
- **Docker Compose** 2.0+ (included with Docker Desktop)
- **VPN Subscription** with one of the [supported providers](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)
- **VPN Credentials** (WireGuard config or OpenVPN username/password)

### Recommended
- At least 4GB RAM allocated to Docker
- 20GB free disk space (more for downloads)
- Stable internet connection

## Quick Start

### 1. Clone and Configure

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

### 2. Get VPN Credentials

**For WireGuard (Recommended):**
- **Mullvad**: [Account → WireGuard Config](https://mullvad.net/en/account/wireguard-config)
- **ProtonVPN**: [Account → Downloads → WireGuard](https://account.protonvpn.com/downloads)
- **NordVPN**: [Dashboard → Manual Setup → WireGuard](https://my.nordaccount.com/dashboard/nordvpn/)

**For OpenVPN:**
- Use your VPN account username and password

### 3. Start the Stack

```bash
# Start all services in detached mode
docker-compose up -d

# Check logs to verify VPN connection
docker-compose logs -f gluetun

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
# Run automated verification
./scripts/verify-vpn.sh

# Check for DNS leaks
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

### Q: Will this work on Linux or Windows?
**A:** Yes! Minor changes needed:
- **Linux:** Already works, just adjust `DOWNLOADS_PATH` and `PUID/PGID`
- **Windows:** Use WSL2 + Docker Desktop, adjust paths to Windows format

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
┌─────────────────────────────────────────────────────────────┐
│                      macOS Host                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Docker Compose Stack                    │   │
│  │  ┌────────────────────────────────────────────────┐  │   │
│  │  │            Gluetun (VPN Gateway)               │  │   │
│  │  │  ┌──────────────────────────────────────────┐  │  │   │
│  │  │  │  • WireGuard/OpenVPN client              │  │  │   │
│  │  │  │  • Firewall (kill switch)                │  │  │   │
│  │  │  │  • DNS-over-TLS                          │  │  │   │
│  │  │  │  • IPv6 disabled                         │  │  │   │
│  │  │  │  • Port forwarding                       │  │  │   │
│  │  │  └──────────────────────────────────────────┘  │  │   │
│  │  │                                                 │  │   │
│  │  │  Exposes ports to host:                        │  │   │
│  │  │    - 8080 (qBittorrent Web UI)                 │  │   │
│  │  │    - 6881 (Torrent connections)                │  │   │
│  │  └────────────────────────────────────────────────┘  │   │
│  │                          ▲                           │   │
│  │                          │ network_mode: service     │   │
│  │                          │                           │   │
│  │  ┌───────────────────────┴──────────────────────┐   │   │
│  │  │         qBittorrent (Torrent Client)         │   │   │
│  │  │  • Shares Gluetun's network namespace        │   │   │
│  │  │  • All traffic forced through VPN            │   │   │
│  │  │  • No independent internet access            │   │   │
│  │  │  • Web UI @ localhost:8080                   │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│                          │ Bind mount                        │
│                          ▼                                   │
│              ~/Downloads/torrents/                           │
│              (Persistent storage)                            │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ VPN Tunnel (Encrypted)
                          ▼
                    Internet via VPN
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
