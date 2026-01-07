# 🚀 Full Media Stack - Quick Start Guide

Get a complete media automation platform running in 30 minutes!

## What You Get

- **TV Shows**: Automatic downloads, organization (Sonarr)
- **Movies**: Automatic downloads, organization (Radarr)
- **Music**: Optional (Lidarr)
- **Books**: Optional (Readarr)
- **Indexers**: Centralized tracker management (Prowlarr)
- **Downloads**: Torrents (qBittorrent) + Usenet (SABnzbd)
- **VPN**: All downloads through VPN with kill-switch (Gluetun)
- **Requests**: User-friendly request interface (Jellyseerr/Overseerr)
- **Dashboard**: Single landing page for all services (Heimdall)
- **Security**: Optional MFA + reverse proxy (Authentik + Traefik)
- **Transcoding**: Optional media optimization (Tdarr)

---

## Prerequisites

1. **Docker** installed ([Get Docker](https://docs.docker.com/get-docker/))
2. **VPN subscription** with WireGuard or OpenVPN (Mullvad, ProtonVPN, NordVPN, etc.)
3. **VPN credentials** (WireGuard private key or OpenVPN username/password)
4. **20+ GB disk space** (more for media library)
5. **4GB+ RAM** recommended

---

## Installation Methods

### Option A: Using Go CLI (Recommended - In Development)

```bash
# Install mediastack binary
brew install ddmoney420/mediastack/mediastack

# Interactive setup wizard
mediastack init

# Start all core services
mediastack start

# Check status
mediastack status
```

**Note**: Go CLI is currently in development. Use Option B for now.

---

### Option B: Using Docker Compose Directly

#### Step 1: Clone Repository

```bash
git clone https://github.com/ddmoney420/torrent-vpn-stack.git
cd torrent-vpn-stack
```

#### Step 2: Configure Environment

```bash
# Copy example environment file
cp .env.mediastack.example .env

# Edit configuration
nano .env  # or your preferred editor
```

**Required Settings:**
```env
# VPN Credentials (CRITICAL)
VPN_SERVICE_PROVIDER=mullvad  # or protonvpn, nordvpn, etc.
WIREGUARD_PRIVATE_KEY=your_key_here
WIREGUARD_ADDRESSES=10.2.0.2/32

# Paths
MEDIA_PATH=/path/to/your/media/library
DOWNLOADS_PATH=/path/to/downloads

# Network
LOCAL_SUBNET=192.168.1.0/24  # Your home network

# User/Group IDs (get with: id -u and id -g)
PUID=1000
PGID=1000
```

#### Step 3: Create Directory Structure

```bash
# Create base directories
mkdir -p /media-stack/{media,downloads,config}

# Create media subdirectories
mkdir -p /media-stack/media/{tv,movies,music,books}

# Create download subdirectories
mkdir -p /media-stack/downloads/torrents/{complete,incomplete}
mkdir -p /media-stack/downloads/usenet/{complete,incomplete}
```

Or use the provided script:
```bash
./scripts/create-media-dirs.sh
```

#### Step 4: Start Core Services

```bash
# Start VPN + downloaders + Prowlarr + Sonarr + Radarr
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.media.yml \
  up -d
```

#### Step 5: Verify VPN Connection

```bash
# Check VPN is connected
docker logs gluetun | grep "You are running"

# Verify qBittorrent uses VPN
docker exec qbittorrent wget -qO- https://api.ipify.org
# ^ Should show VPN IP, not your real IP
```

#### Step 6: Initial Configuration

**Prowlarr** (http://localhost:9696):
1. Add indexers (trackers):
   - Public: The Pirate Bay, 1337x, RARBG
   - Private: Add if you have accounts
2. Configure apps:
   - Add Sonarr (http://sonarr:8989, API key from Sonarr settings)
   - Add Radarr (http://radarr:7878, API key from Radarr settings)
3. Test indexers

**Sonarr** (http://localhost:8989):
1. Settings → Download Clients → Add qBittorrent
   - Host: `qbittorrent` (container name)
   - Port: 8080
   - Category: `tv-sonarr`
2. Settings → Media Management:
   - Enable: Rename Episodes, Unmonitor Deleted
   - Root Folder: `/tv`
3. Add TV shows

**Radarr** (http://localhost:7878):
1. Settings → Download Clients → Add qBittorrent
   - Host: `qbittorrent`
   - Port: 8080
   - Category: `movies-radarr`
2. Settings → Media Management:
   - Enable: Rename Movies, Unmonitor Deleted
   - Root Folder: `/movies`
3. Add movies

**qBittorrent** (http://localhost:8080):
1. Login: `admin` / `adminadmin`
2. **Change password immediately!**
3. Settings → Downloads:
   - Default Save Path: `/downloads/complete`
   - Keep incomplete in: `/downloads/incomplete`
4. Settings → Connection:
   - Listening Port: 6881 (or VPN forwarded port if enabled)
   - Disable UPnP/NAT-PMP

---

## Optional Services

### Add Request Management (Jellyseerr)

```bash
# Start with Jellyfin profile
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.media.yml \
  -f compose/compose.request.yml \
  --profile jellyfin \
  up -d
```

**Configure Jellyseerr** (http://localhost:5055):
1. Connect to Jellyfin server
2. Sync libraries
3. Connect to Sonarr (http://sonarr:8989 + API key)
4. Connect to Radarr (http://radarr:7878 + API key)
5. Configure users and permissions

### Add Dashboard (Heimdall)

```bash
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.media.yml \
  -f compose/compose.infrastructure.yml \
  --profile dashboard \
  up -d
```

**Configure Heimdall** (http://localhost:8082):
1. Add applications (Sonarr, Radarr, qBittorrent, etc.)
2. Customize layout

### Add Music (Lidarr)

```bash
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.media.yml \
  --profile music \
  up -d
```

### Add Transcoding (Tdarr)

```bash
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.infrastructure.yml \
  --profile transcoding \
  up -d
```

---

## Service URLs

| Service | URL | Default Login |
|---------|-----|---------------|
| **Sonarr** | http://localhost:8989 | No login |
| **Radarr** | http://localhost:7878 | No login |
| **Prowlarr** | http://localhost:9696 | No login |
| **qBittorrent** | http://localhost:8080 | admin / adminadmin |
| **SABnzbd** | http://localhost:8081 | Setup wizard |
| **Jellyseerr** | http://localhost:5055 | Setup wizard |
| **Heimdall** | http://localhost:8082 | No login |
| **Gluetun Control** | http://localhost:8000 | No login |

**Security Note**: All *arr apps have no authentication by default. Enable auth or use a reverse proxy with authentication (Traefik + Authentik).

---

## Common Tasks

### Start/Stop All Services

```bash
# Start
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.media.yml \
  -f compose/compose.request.yml \
  --profile jellyfin \
  up -d

# Stop (preserves data)
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.media.yml \
  -f compose/compose.request.yml \
  down
```

### View Logs

```bash
# All services
docker compose -f compose/compose.core.yml logs -f

# Specific service
docker logs -f gluetun
docker logs -f sonarr
docker logs -f radarr
```

### Update Services

```bash
# Pull latest images
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.media.yml \
  pull

# Restart with new images
docker compose \
  -f compose/compose.core.yml \
  -f compose/compose.media.yml \
  up -d
```

### Backup Configuration

```bash
# Backup all config volumes
docker run --rm \
  -v torrent-vpn-stack_sonarr-config:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/sonarr-backup.tar.gz -C /data .

# Repeat for other services: radarr-config, prowlarr-config, etc.
```

### Check VPN Status

```bash
# VPN connection status
docker exec gluetun wget -qO- http://localhost:8000/v1/publicip/ip

# Expected output: {"public_ip":"185.65.134.xxx"}
# ^ This should be your VPN IP, NOT your real IP

# Full status
curl http://localhost:8000/v1/status
```

---

## Troubleshooting

### VPN Not Connecting

**Symptoms**: Gluetun logs show connection errors

**Solutions**:
1. Verify VPN credentials in `.env`
2. Check VPN provider status page
3. Try different server: `SERVER_COUNTRIES=Sweden`
4. Enable debug: `LOG_LEVEL=debug` in `.env`, restart

### Downloads Not Starting

**Symptoms**: Sonarr/Radarr says "No releases found"

**Solutions**:
1. Check Prowlarr has indexers configured
2. Test indexers in Prowlarr (Test button)
3. Verify Sonarr/Radarr are connected to Prowlarr:
   - Settings → Indexers (should see synced indexers)
4. Check category mappings in Prowlarr

### IP Leak Detected

**Symptoms**: qBittorrent shows real IP instead of VPN IP

**Solutions**:
1. Verify `network_mode: "service:gluetun"` in compose file
2. Restart qBittorrent: `docker restart qbittorrent`
3. Test: `docker exec qbittorrent wget -qO- https://api.ipify.org`

### Permission Errors

**Symptoms**: Can't write to media/downloads folders

**Solutions**:
1. Check PUID/PGID match your user:
   ```bash
   id -u  # Should match PUID in .env
   id -g  # Should match PGID in .env
   ```
2. Fix ownership:
   ```bash
   sudo chown -R $USER:$USER /media-stack
   ```

---

## Next Steps

1. **Add Content**: Use Sonarr/Radarr web UIs to add TV shows and movies
2. **Configure Quality Profiles**: Set preferred video quality (1080p, 4K, etc.)
3. **Set Up Jellyseerr**: Allow family/friends to request content
4. **Enable Reverse Proxy**: Use Traefik for secure external access
5. **Add Monitoring**: Enable Prometheus + Grafana for metrics

---

## Getting Help

- **Documentation**: [Full Stack Architecture](FULL_STACK_ARCHITECTURE.md)
- **GitHub Issues**: [Report bugs or request features](https://github.com/ddmoney420/torrent-vpn-stack/issues)
- **Discussions**: [Ask questions](https://github.com/ddmoney420/torrent-vpn-stack/discussions)

---

**Security Reminder**: This stack downloads media from the internet. Ensure you comply with copyright laws in your jurisdiction. Use a trusted VPN provider.
