# Full Media Stack Architecture

## Overview

A complete, self-hosted media automation platform combining download management, media organization, request handling, and security infrastructure.

## Architecture Layers

### Layer 1: Go Orchestration & Control Plane

```
┌─────────────────────────────────────────────────────────────┐
│               mediastack (Go Binary)                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   CLI Interface                       │   │
│  │  • mediastack init        - Setup wizard             │   │
│  │  • mediastack start       - Start all services       │   │
│  │  • mediastack stop        - Stop all services        │   │
│  │  • mediastack status      - Health dashboard         │   │
│  │  • mediastack vpn         - VPN management           │   │
│  │  • mediastack config      - Configuration editor     │   │
│  │  • mediastack upgrade     - Update all containers    │   │
│  │  • mediastack backup      - Backup configurations    │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   API Server                          │   │
│  │  • REST API for web dashboard                        │   │
│  │  • Service health monitoring                         │   │
│  │  • Configuration management                          │   │
│  │  • Log aggregation                                   │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │             Docker Compose Orchestrator              │   │
│  │  • Template rendering                                │   │
│  │  • Service lifecycle management                      │   │
│  │  • Volume management                                 │   │
│  │  • Network configuration                             │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Responsibilities:**
- Cross-platform setup wizard (Linux, macOS, Windows)
- VPN lifecycle control (start, stop, health checks)
- Service orchestration (start/stop individual or all services)
- Configuration templating (generate Docker Compose from user input)
- Health monitoring (aggregate status from all services)
- Upgrade management (pull latest images, restart services)
- Backup/restore (configurations, metadata, not media files)

---

### Layer 2: Container Stack (Docker Compose)

#### Core Services (Always Running)

```
┌──────────────────────────────────────────────────────────┐
│                      VPN Gateway                         │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Gluetun                               │  │
│  │  • WireGuard/OpenVPN client                        │  │
│  │  • Kill switch (firewall rules)                    │  │
│  │  • DNS leak protection (DoT)                       │  │
│  │  • Supports 50+ VPN providers                      │  │
│  │  • Port forwarding (if supported)                  │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
                          │
                          │ Network namespace sharing
                          ▼
┌──────────────────────────────────────────────────────────┐
│                    Download Clients                      │
│  ┌────────────────┬──────────────────────────────────┐   │
│  │ qBittorrent    │ SABnzbd                          │   │
│  │ • BitTorrent   │ • Usenet (NZB)                   │   │
│  │ • Magnet links │ • Par2 verification              │   │
│  │ • Web UI       │ • Web UI                         │   │
│  │ • Port 8080    │ • Port 8081                      │   │
│  │ network_mode: service:gluetun                     │   │
│  └────────────────┴──────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

**Network Isolation:**
- qBittorrent and SABnzbd share Gluetun's network namespace
- All download traffic forced through VPN
- Kill switch prevents IP leaks if VPN drops

---

#### Media Management (*arr Suite)

```
┌──────────────────────────────────────────────────────────┐
│                 Indexer Management                       │
│  ┌────────────────────────────────────────────────────┐  │
│  │              Prowlarr                              │  │
│  │  • Centralized indexer/tracker management         │  │
│  │  • Torrent + Usenet indexer support               │  │
│  │  • Syncs to Sonarr/Radarr/Lidarr/Readarr         │  │
│  │  • Search aggregation                             │  │
│  │  • Port 9696                                      │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
                          │
                          │ Indexer sync
                          ▼
┌──────────────────────────────────────────────────────────┐
│                  Media Automation                        │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │ Sonarr   │ Radarr   │ Lidarr   │ Readarr  │          │
│  │ TV Shows │ Movies   │ Music    │ Books    │          │
│  │ Port 8989│ Port 7878│ Port 8686│ Port 8787│          │
│  └──────────┴──────────┴──────────┴──────────┘          │
│                                                          │
│  Each *arr service:                                      │
│  • Monitors RSS feeds for new releases                   │
│  • Searches indexers (via Prowlarr)                      │
│  • Sends downloads to qBittorrent or SABnzbd            │
│  • Renames and organizes files                          │
│  • Updates media server (Jellyfin/Plex)                 │
└──────────────────────────────────────────────────────────┘
```

**Data Flow:**
1. User adds TV show to Sonarr (or request via Jellyseerr)
2. Sonarr monitors RSS feeds + searches Prowlarr
3. Prowlarr searches all configured indexers
4. Sonarr selects best release (quality, size, seeders)
5. Sends to qBittorrent (via Gluetun VPN)
6. Download completes → Sonarr renames/moves to media library
7. Jellyfin/Plex updates library

---

#### Request Management

```
┌──────────────────────────────────────────────────────────┐
│                 User Request Interface                   │
│  ┌────────────────┬──────────────────────────────────┐   │
│  │ Jellyseerr     │ Overseerr                        │   │
│  │ (Jellyfin)     │ (Plex)                           │   │
│  │ Port 5055      │ Port 5055                        │   │
│  └────────────────┴──────────────────────────────────┘   │
│                                                          │
│  Features:                                               │
│  • User-friendly request interface                       │
│  • Approval workflows (optional)                         │
│  • Integrates with Sonarr/Radarr                        │
│  • Email notifications                                   │
│  • User quotas and restrictions                         │
└──────────────────────────────────────────────────────────┘
```

**Use Case:**
- Users visit Jellyseerr web UI
- Browse available or search for new content
- Request movie/TV show
- Admin approves (or auto-approve)
- Jellyseerr sends to Radarr/Sonarr
- Download and organization happens automatically

---

#### Infrastructure Services

**Reverse Proxy (Traefik or SWAG):**
```
┌──────────────────────────────────────────────────────────┐
│                    Traefik                               │
│  ┌────────────────────────────────────────────────────┐  │
│  │  • Automatic SSL (Let's Encrypt)                   │  │
│  │  • Reverse proxy for all web UIs                   │  │
│  │  • Domain routing (sonarr.example.com)             │  │
│  │  • Middleware (auth, rate limiting)                │  │
│  │  • Dashboard (Port 8080)                           │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**Dashboard (Heimdall or Homepage):**
```
┌──────────────────────────────────────────────────────────┐
│                    Heimdall                              │
│  ┌────────────────────────────────────────────────────┐  │
│  │  • Single landing page for all services            │  │
│  │  • Application launcher                            │  │
│  │  • Service status indicators                       │  │
│  │  • Customizable layout                             │  │
│  │  • Port 8082                                       │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**Authentication (Authentik or Authelia):**
```
┌──────────────────────────────────────────────────────────┐
│                    Authentik                             │
│  ┌────────────────────────────────────────────────────┐  │
│  │  • Single Sign-On (SSO)                            │  │
│  │  • Multi-Factor Authentication (MFA)               │  │
│  │  • LDAP/OAuth/SAML support                         │  │
│  │  • User management                                 │  │
│  │  • Port 9000                                       │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**Transcoding (Tdarr):**
```
┌──────────────────────────────────────────────────────────┐
│                     Tdarr                                │
│  ┌────────────────────────────────────────────────────┐  │
│  │  • Automated media transcoding                     │  │
│  │  • Distributed processing (nodes)                  │  │
│  │  • Health checks (corrupt files)                   │  │
│  │  • Storage optimization (HEVC/H.265)               │  │
│  │  • Port 8265 (Web UI)                              │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## Complete Service Map

| Service | Port | Purpose | VPN? | Priority |
|---------|------|---------|------|----------|
| **Gluetun** | 8000 | VPN gateway + control | - | Critical |
| **qBittorrent** | 8080 | Torrent downloads | ✅ Yes | Critical |
| **SABnzbd** | 8081 | Usenet downloads | ✅ Yes | High |
| **Prowlarr** | 9696 | Indexer management | ❌ No | High |
| **Sonarr** | 8989 | TV show automation | ❌ No | High |
| **Radarr** | 7878 | Movie automation | ❌ No | High |
| **Lidarr** | 8686 | Music automation | ❌ No | Medium |
| **Readarr** | 8787 | Book automation | ❌ No | Medium |
| **Jellyseerr** | 5055 | Request management | ❌ No | Medium |
| **Overseerr** | 5055 | Request management (alt) | ❌ No | Medium |
| **Traefik** | 80/443 | Reverse proxy | ❌ No | High |
| **Heimdall** | 8082 | Dashboard | ❌ No | Low |
| **Homepage** | 3000 | Dashboard (alt) | ❌ No | Low |
| **Authentik** | 9000 | Authentication | ❌ No | Medium |
| **Authelia** | 9091 | Authentication (alt) | ❌ No | Medium |
| **Tdarr** | 8265 | Transcoding | ❌ No | Low |
| **Prometheus** | 9090 | Metrics (optional) | ❌ No | Low |
| **Grafana** | 3001 | Metrics UI (optional) | ❌ No | Low |

---

## Data Flow Examples

### Example 1: User Requests Movie

```
1. User opens Jellyseerr → Browses/searches for movie
   ↓
2. User clicks "Request"
   ↓
3. Jellyseerr → Radarr API: POST /api/v3/movie
   ↓
4. Radarr adds to monitoring → Searches Prowlarr
   ↓
5. Prowlarr searches all indexers → Returns results
   ↓
6. Radarr selects best release → Sends to qBittorrent
   ↓
7. qBittorrent (via Gluetun VPN) → Downloads torrent
   ↓
8. Download complete → Radarr renames/moves to library
   ↓
9. Jellyfin rescans library → Movie appears
   ↓
10. Jellyseerr notifies user → Email: "Your request is available!"
```

### Example 2: Automatic TV Show Monitoring

```
1. Sonarr monitors RSS feeds → New episode detected
   ↓
2. Sonarr checks quality profile → Episode meets criteria
   ↓
3. Sonarr → Prowlarr: Search for episode
   ↓
4. Prowlarr → Indexers: Query all configured trackers
   ↓
5. Prowlarr → Sonarr: Return results (sorted by seeders, quality)
   ↓
6. Sonarr selects best → Sends to qBittorrent
   ↓
7. qBittorrent (VPN) → Downloads episode
   ↓
8. Complete → Sonarr imports → Renames to format:
   "Show Name - S01E05 - Episode Title.mkv"
   ↓
9. Jellyfin updates library → Episode available
```

### Example 3: VPN Kill-Switch Activation

```
1. VPN connection drops (network issue, auth failure, etc.)
   ↓
2. Gluetun firewall blocks all non-VPN traffic
   ↓
3. qBittorrent loses network connectivity
   ↓
4. Downloads pause (no IP leak)
   ↓
5. Gluetun auto-reconnects (retry with backoff)
   ↓
6. VPN tunnel re-established
   ↓
7. qBittorrent resumes downloads
```

---

## Directory Structure

```
/media-stack/
├── downloads/              # Download destination
│   ├── torrents/          # qBittorrent downloads
│   │   ├── incomplete/   # In-progress
│   │   └── complete/     # Finished
│   └── usenet/           # SABnzbd downloads
│       ├── incomplete/
│       └── complete/
├── media/                 # Organized media library
│   ├── tv/               # TV shows (Sonarr)
│   ├── movies/           # Movies (Radarr)
│   ├── music/            # Music (Lidarr)
│   └── books/            # Books (Readarr)
├── config/               # Service configurations
│   ├── gluetun/
│   ├── qbittorrent/
│   ├── sabnzbd/
│   ├── sonarr/
│   ├── radarr/
│   ├── lidarr/
│   ├── readarr/
│   ├── prowlarr/
│   ├── jellyseerr/
│   ├── traefik/
│   ├── heimdall/
│   ├── authentik/
│   └── tdarr/
└── compose/              # Docker Compose files
    ├── compose.core.yml
    ├── compose.media.yml
    ├── compose.request.yml
    ├── compose.infrastructure.yml
    └── compose.override.yml
```

---

## Configuration Management

### User Configuration (`~/.config/mediastack/config.yaml`)

```yaml
version: "1.0"

stack:
  name: media-stack
  base_path: /media-stack

vpn:
  enabled: true
  provider: gluetun
  service_provider: mullvad  # protonvpn, nordvpn, etc.
  wireguard_private_key: ${WIREGUARD_PRIVATE_KEY}
  wireguard_addresses: 10.2.0.2/32
  kill_switch: true

downloaders:
  qbittorrent:
    enabled: true
    port: 8080
    vpn_required: true
  sabnzbd:
    enabled: true
    port: 8081
    vpn_required: true

media_management:
  sonarr:
    enabled: true
    port: 8989
  radarr:
    enabled: true
    port: 7878
  lidarr:
    enabled: false  # Optional
    port: 8686
  readarr:
    enabled: false  # Optional
    port: 8787
  prowlarr:
    enabled: true
    port: 9696

request_management:
  jellyseerr:
    enabled: true
    port: 5055
  overseerr:
    enabled: false  # Alternative to Jellyseerr

infrastructure:
  traefik:
    enabled: true
    domain: example.com
    ssl: true  # Let's Encrypt
  heimdall:
    enabled: true
    port: 8082
  authentik:
    enabled: false  # Optional
    port: 9000
  tdarr:
    enabled: false  # Optional
    port: 8265

monitoring:
  prometheus:
    enabled: false
    port: 9090
  grafana:
    enabled: false
    port: 3001
```

### Environment Variables (`.env`)

```bash
# VPN Credentials (DO NOT COMMIT)
WIREGUARD_PRIVATE_KEY=your_private_key_here
WIREGUARD_ADDRESSES=10.2.0.2/32

# Timezone
TZ=America/Los_Angeles

# User/Group IDs (for file permissions)
PUID=1000
PGID=1000

# Paths
MEDIA_PATH=/media-stack/media
DOWNLOADS_PATH=/media-stack/downloads
CONFIG_PATH=/media-stack/config

# Domain (for Traefik)
DOMAIN=example.com

# Admin passwords
SONARR_API_KEY=generated_on_first_run
RADARR_API_KEY=generated_on_first_run
# ... etc
```

---

## Security Architecture

### Defense Layers

1. **VPN Kill Switch** (Gluetun)
   - Network namespace isolation
   - Firewall rules block non-VPN traffic
   - DNS leak protection (DoT)

2. **Reverse Proxy** (Traefik)
   - SSL termination (HTTPS only)
   - Rate limiting
   - IP allowlisting/blocklisting

3. **Authentication** (Authentik/Authelia)
   - SSO for all services
   - MFA enforcement
   - Session management

4. **Network Segmentation**
   - VPN network: qBittorrent, SABnzbd
   - App network: *arr suite, request mgmt
   - Infrastructure network: Traefik, Authentik

5. **Least Privilege**
   - Containers run as non-root (PUID/PGID)
   - Minimal capabilities
   - Read-only root filesystems where possible

---

## Deployment Scenarios

### Scenario A: Home Server (Most Common)

**Hardware:**
- Intel NUC or similar (4+ cores, 8GB+ RAM)
- NAS for media storage

**Services:**
- Core: Gluetun, qBittorrent, Sonarr, Radarr, Prowlarr
- Optional: SABnzbd (if Usenet), Jellyseerr, Heimdall

**Access:**
- Local network only
- VPN (Tailscale/WireGuard) for remote access

### Scenario B: Cloud VPS (Advanced)

**Hardware:**
- DigitalOcean/Linode/Hetzner VPS (4GB+ RAM)
- Block storage for downloads

**Services:**
- All core services
- Traefik with public domain
- Authentik for secure access
- Tdarr for transcoding (separate node)

**Access:**
- Public HTTPS via domain
- MFA required

### Scenario C: Homelab + Remote Storage

**Hardware:**
- Local: Intel NUC (orchestration only)
- Remote: NAS or cloud storage

**Services:**
- Local: Gluetun, *arr suite, Jellyseerr
- Remote: qBittorrent (on VPS with VPN)
- Media stored on NAS (NFS/SMB mount)

---

## Monitoring & Observability

### Health Checks

**Go Orchestrator Monitors:**
- VPN connection status (ping Gluetun)
- Download client status (API health endpoints)
- *arr service status (API /health endpoints)
- Disk usage (downloads + media paths)
- Container resource usage (CPU, RAM)

**Aggregated Status:**
```bash
mediastack status

┌─────────────────────────────────────────────────────┐
│ Media Stack Status                                  │
├─────────────────┬───────────┬──────────────────────┤
│ Service         │ Status    │ Info                 │
├─────────────────┼───────────┼──────────────────────┤
│ Gluetun         │ ✅ Running│ VPN: 185.65.134.240  │
│ qBittorrent     │ ✅ Running│ 2 active, 5.2 MB/s   │
│ SABnzbd         │ ✅ Running│ 1 active, 12.3 MB/s  │
│ Prowlarr        │ ✅ Running│ 15 indexers          │
│ Sonarr          │ ✅ Running│ 42 series monitored  │
│ Radarr          │ ✅ Running│ 187 movies monitored │
│ Jellyseerr      │ ✅ Running│ 3 pending requests   │
│ Traefik         │ ✅ Running│ SSL: Valid           │
│ Heimdall        │ ✅ Running│ -                    │
└─────────────────┴───────────┴──────────────────────┘

Disk Usage:
  Downloads: 45.2 GB / 500 GB (9%)
  Media: 1.2 TB / 4 TB (30%)
```

---

## Upgrade Strategy

**Update All Containers:**
```bash
mediastack upgrade

# What it does:
1. Pull latest images for all enabled services
2. Stop containers gracefully
3. Recreate with new images
4. Run health checks
5. Rollback if any service fails
```

**Update Specific Service:**
```bash
mediastack upgrade sonarr

# What it does:
1. Pull latest sonarr image
2. Stop sonarr container
3. Recreate with new image
4. Verify health
```

---

## Backup Strategy

**What Gets Backed Up:**
- ✅ Service configurations (`/media-stack/config/`)
- ✅ Database files (Sonarr/Radarr/etc metadata)
- ✅ Docker Compose files
- ✅ Go orchestrator config (`config.yaml`)
- ❌ Media files (too large, use NAS snapshots instead)
- ❌ Downloads in progress

**Automated Backups:**
```bash
mediastack backup

# What it does:
1. Tar + gzip all config directories
2. Export database dumps
3. Save to ~/backups/mediastack-YYYY-MM-DD.tar.gz
4. Rotate old backups (keep last 7 days)
```

**Restore:**
```bash
mediastack restore ~/backups/mediastack-2026-01-05.tar.gz

# What it does:
1. Stop all services
2. Extract configs to /media-stack/config/
3. Restore databases
4. Restart services
5. Verify health
```

---

## Next Steps

See [Issue #18](https://github.com/ddmoney420/torrent-vpn-stack/issues/18) for implementation roadmap.

**Phase 1 Focus:**
- Go orchestration CLI
- Interactive setup wizard
- Docker Compose template generation
- VPN lifecycle control
- Health monitoring

**Phase 2+:**
- Request management integration
- Dashboard
- Authentication
- Transcoding
- Advanced monitoring
