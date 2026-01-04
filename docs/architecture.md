# Torrent VPN Stack - Architecture Documentation

## Table of Contents

- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Network Architecture](#network-architecture)
- [Security Architecture](#security-architecture)
- [Data Flow](#data-flow)
- [Container Interaction](#container-interaction)
- [Kill Switch Mechanism](#kill-switch-mechanism)
- [Port Forwarding Architecture](#port-forwarding-architecture)
- [Persistence & Storage](#persistence--storage)
- [Failure Modes & Recovery](#failure-modes--recovery)

---

## Overview

This stack implements a secure, containerized torrent downloader that routes **all** traffic through a VPN connection with multiple layers of leak protection. The architecture is designed for macOS (Apple Silicon) but is portable to any Docker-capable platform.

### Core Principles

1. **VPN-First Routing**: All torrent traffic MUST go through VPN; no exceptions
2. **Kill Switch**: If VPN fails, torrent client loses all network access
3. **Least Privilege**: Containers run with minimal capabilities
4. **Defense in Depth**: Multiple layers of leak protection (IP, DNS, IPv6)
5. **Usability**: Single configuration file, Web UI access, persistent data

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          macOS Host Machine                         │
│                      (Apple Silicon / Intel)                        │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                   Docker Desktop for Mac                      │ │
│  │                                                               │ │
│  │  ┌─────────────────────────────────────────────────────────┐ │ │
│  │  │            Docker Compose Stack                         │ │ │
│  │  │                                                         │ │ │
│  │  │  ┌───────────────────────────────────────────────────┐ │ │ │
│  │  │  │         Gluetun (VPN Gateway)                     │ │ │ │
│  │  │  │  ┌─────────────────────────────────────────────┐  │ │ │ │
│  │  │  │  │  WireGuard/OpenVPN Client                   │  │ │ │ │
│  │  │  │  │  • Creates encrypted tunnel to VPN server   │  │ │ │ │
│  │  │  │  │  • Handles authentication & key exchange    │  │ │ │ │
│  │  │  │  └─────────────────────────────────────────────┘  │ │ │ │
│  │  │  │  ┌─────────────────────────────────────────────┐  │ │ │ │
│  │  │  │  │  Firewall / Kill Switch                     │  │ │ │ │
│  │  │  │  │  • Blocks non-VPN traffic                   │  │ │ │ │
│  │  │  │  │  • LOCAL_SUBNET whitelist for LAN access    │  │ │ │ │
│  │  │  │  └─────────────────────────────────────────────┘  │ │ │ │
│  │  │  │  ┌─────────────────────────────────────────────┐  │ │ │ │
│  │  │  │  │  DNS-over-TLS (DoT)                         │  │ │ │ │
│  │  │  │  │  • Encrypted DNS queries (1.1.1.1)          │  │ │ │ │
│  │  │  │  │  • Prevents DNS leak to ISP                 │  │ │ │ │
│  │  │  │  └─────────────────────────────────────────────┘  │ │ │ │
│  │  │  │                                                   │ │ │ │
│  │  │  │  Network Namespace: gluetun                      │ │ │ │
│  │  │  │  Ports Exposed:                                  │ │ │ │
│  │  │  │    - 8080:8080 → qBittorrent Web UI             │ │ │ │
│  │  │  │    - 6881:6881 → Torrent connections            │ │ │ │
│  │  │  │    - 8000:8000 → Gluetun control server         │ │ │ │
│  │  │  └───────────────────────────────────────────────────┘ │ │ │
│  │  │                                                         │ │ │
│  │  │  ┌───────────────────────────────────────────────────┐ │ │ │
│  │  │  │      qBittorrent (Torrent Client)                │ │ │ │
│  │  │  │  ┌─────────────────────────────────────────────┐  │ │ │ │
│  │  │  │  │  Web UI Server (Port 8080)                  │  │ │ │ │
│  │  │  │  │  • Authentication (admin/password)          │  │ │ │ │
│  │  │  │  │  • Torrent management interface             │  │ │ │ │
│  │  │  │  └─────────────────────────────────────────────┘  │ │ │ │
│  │  │  │  ┌─────────────────────────────────────────────┐  │ │ │ │
│  │  │  │  │  BitTorrent Engine (Port 6881)              │  │ │ │ │
│  │  │  │  │  • DHT, PEX, trackers                       │  │ │ │ │
│  │  │  │  │  • Upload/download connections              │  │ │ │ │
│  │  │  │  └─────────────────────────────────────────────┘  │ │ │ │
│  │  │  │                                                   │ │ │ │
│  │  │  │  network_mode: "service:gluetun"                 │ │ │ │
│  │  │  │  (Shares Gluetun's network namespace)            │ │ │ │
│  │  │  │  NO direct internet access                       │ │ │ │
│  │  │  └───────────────────────────────────────────────────┘ │ │ │
│  │  │                                                         │ │ │
│  │  │  ┌───────────────────────────────────────────────────┐ │ │ │
│  │  │  │   Docker Volumes (Persistent Storage)            │ │ │ │
│  │  │  │   • qbittorrent-config: /config                  │ │ │ │
│  │  │  │   • gluetun-config: /gluetun                     │ │ │ │
│  │  │  │   • downloads: $DOWNLOADS_PATH (bind mount)      │ │ │ │
│  │  │  └───────────────────────────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                     Host File System                          │ │
│  │   ~/Downloads/torrents ← Bind mount to qBittorrent           │ │
│  └───────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ Encrypted VPN Tunnel
                                 │ (WireGuard/OpenVPN)
                                 ▼
                    ┌────────────────────────────┐
                    │    VPN Provider Server     │
                    │  (Mullvad/ProtonVPN/etc.)  │
                    └────────────────────────────┘
                                 │
                                 │ Exit IP: VPN Provider's IP
                                 │ (NOT your real IP)
                                 ▼
                        ┌──────────────────┐
                        │    Internet      │
                        │  • Trackers      │
                        │  • Torrent Peers │
                        └──────────────────┘
```

---

## Network Architecture

### Network Namespace Sharing (Kill Switch Mechanism)

The kill switch is implemented using Docker's `network_mode: "service:gluetun"`. This is the **most critical security feature**.

```
┌────────────────────────────────────────────────────────────┐
│                  Docker Network Stack                      │
│                                                            │
│  ┌──────────────────────────────────────────────────────┐ │
│  │       Gluetun Network Namespace                      │ │
│  │                                                      │ │
│  │  ┌────────────┐         ┌────────────┐              │ │
│  │  │  Gluetun   │         │ qBittorrent│              │ │
│  │  │  Process   │         │  Process   │              │ │
│  │  └────────────┘         └────────────┘              │ │
│  │         │                      │                    │ │
│  │         └──────────┬───────────┘                    │ │
│  │                    │                                │ │
│  │                    ▼                                │ │
│  │         ┌──────────────────────┐                    │ │
│  │         │  Network Interfaces  │                    │ │
│  │         │  ┌────────────────┐  │                    │ │
│  │         │  │  tun0 (VPN)    │  │                    │ │
│  │         │  │  10.x.x.x      │  │                    │ │
│  │         │  └────────────────┘  │                    │ │
│  │         │  ┌────────────────┐  │                    │ │
│  │         │  │  eth0 (Docker) │  │                    │ │
│  │         │  │  172.x.x.x     │  │                    │ │
│  │         │  └────────────────┘  │                    │ │
│  │         └──────────────────────┘                    │ │
│  │                    │                                │ │
│  │                    ▼                                │ │
│  │         ┌──────────────────────┐                    │ │
│  │         │  Routing Table       │                    │ │
│  │         │  Default: tun0       │ ← Forces VPN route │ │
│  │         │  LAN: eth0           │ ← Allows LAN access│ │
│  │         └──────────────────────┘                    │ │
│  │                    │                                │ │
│  │                    ▼                                │ │
│  │         ┌──────────────────────┐                    │ │
│  │         │  Firewall Rules      │                    │ │
│  │         │  • ALLOW: tun0       │                    │ │
│  │         │  • ALLOW: LOCAL_SUBNET│                   │ │
│  │         │  • DROP: everything else                 │ │
│  │         └──────────────────────┘                    │ │
│  └──────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────┘

Key Point: qBittorrent CANNOT create its own network routes.
           It MUST use Gluetun's network stack.
           If tun0 (VPN) is down → qBittorrent has NO internet access.
```

### Traffic Flow Comparison

**WITHOUT Kill Switch (INSECURE):**
```
qBittorrent → eth0 (Docker bridge) → Host → ISP → Internet
                                      ↑
                                  LEAK: Real IP exposed!
```

**WITH Kill Switch (SECURE):**
```
qBittorrent → (shares Gluetun namespace) → tun0 (VPN) → VPN Server → Internet
                                             ↑
                                     If VPN down: NO ROUTE = NO LEAK
```

### Port Mappings

Ports are mapped **only** on the Gluetun container because qBittorrent shares its network:

| Host Port | Container Port | Service       | Purpose                  |
|-----------|----------------|---------------|--------------------------|
| 8080      | 8080           | qBittorrent   | Web UI access            |
| 6881      | 6881           | qBittorrent   | Torrent connections      |
| 8000      | 8000           | Gluetun       | Control server / health  |

**Why qBittorrent has no ports defined:**
```yaml
qbittorrent:
  network_mode: "service:gluetun"  # Uses Gluetun's network
  # NO ports section - would conflict with network_mode
```

---

## Security Architecture

### Defense in Depth Layers

```
┌─────────────────────────────────────────────────────────────┐
│              Security Layer Stack                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Layer 7: Web UI Authentication                     │   │
│  │  • qBittorrent password protection                  │   │
│  │  • CSRF tokens                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Layer 6: Network Isolation (Kill Switch)           │   │
│  │  • network_mode: service:gluetun                    │   │
│  │  • No direct internet access                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Layer 5: Firewall Rules                            │   │
│  │  • Gluetun built-in firewall                        │   │
│  │  • LOCAL_SUBNET whitelist                           │   │
│  │  • Default: DROP all non-VPN traffic                │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Layer 4: DNS Leak Protection                       │   │
│  │  • DNS-over-TLS (DoT) enabled                       │   │
│  │  • Cloudflare 1.1.1.1 (encrypted)                   │   │
│  │  • Bypasses ISP DNS                                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Layer 3: IPv6 Leak Protection                      │   │
│  │  • IPv6 disabled in containers                      │   │
│  │  • Prevents dual-stack leak                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Layer 2: VPN Encryption                            │   │
│  │  • WireGuard: ChaCha20-Poly1305                     │   │
│  │  • OpenVPN: AES-256-GCM                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                           ↓                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Layer 1: Container Isolation                       │   │
│  │  • Minimal capabilities (NET_ADMIN only)            │   │
│  │  • Non-root user (PUID/PGID)                        │   │
│  │  • Read-only root filesystem (where possible)       │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Threat Model & Mitigations

| Threat                    | Mitigation                          | Verification                  |
|---------------------------|-------------------------------------|-------------------------------|
| IP Leak (VPN drops)       | Kill switch (network_mode)          | `check-leaks.sh` Test 1 & 5   |
| DNS Leak                  | DNS-over-TLS to Cloudflare          | `check-leaks.sh` Test 2       |
| IPv6 Leak                 | IPv6 disabled                       | `check-leaks.sh` Test 3       |
| WebRTC Leak               | N/A (no browser in container)       | Manual check via Web UI       |
| Credential Theft          | `.env` in `.gitignore`, file perms  | File system permissions       |
| Unauthorized Web UI       | Password protection + LAN-only      | Firewall + authentication     |
| Container Escape          | Minimal capabilities, non-root      | Docker security scanning      |
| VPN Server Compromise     | Verify VPN provider's security      | Trust in provider             |

---

## Data Flow

### Torrent Download Flow

```
1. User adds torrent via Web UI (http://localhost:8080)
   │
   ▼
2. qBittorrent Web Server receives request
   │ (runs inside qBittorrent container)
   ▼
3. qBittorrent Engine starts download
   │
   ├─→ Contacts tracker (via Gluetun network)
   │   │
   │   ├─→ DNS lookup: tracker.example.com
   │   │   └─→ Gluetun DNS-over-TLS → Cloudflare 1.1.1.1
   │   │       └─→ Encrypted DNS query (prevents ISP snooping)
   │   │
   │   └─→ HTTP/UDP request to tracker
   │       └─→ Goes through tun0 (VPN interface)
   │           └─→ Encrypted by WireGuard/OpenVPN
   │               └─→ Exits via VPN server IP
   │
   ├─→ Receives peer list from tracker
   │   │
   │   └─→ Peer IP addresses (other torrent users)
   │
   └─→ Connects to peers (Port 6881)
       │
       ├─→ All connections go through tun0 (VPN)
       │   └─→ Encrypted tunnel to VPN server
       │       └─→ VPN server forwards to peer
       │
       └─→ Downloads pieces from multiple peers
           │
           ▼
4. Downloaded data written to /downloads
   │ (Docker volume mounted to host)
   ▼
5. File appears in ~/Downloads/torrents on macOS host
   │ (with PUID/PGID ownership)
   ▼
6. User accesses file from macOS Finder
```

### Web UI Access Flow

```
User Browser (http://localhost:8080)
   │
   ▼
macOS Host Network Stack
   │
   ▼
Docker Desktop Network
   │
   ▼
Gluetun Container (Port 8080 → Port 8080)
   │ (Port mapping on Gluetun because qBittorrent shares its network)
   ▼
qBittorrent Web Server
   │
   ├─→ Authentication Check
   │   │ (Username: admin, Password: from .env)
   │   │
   │   ├─→ Valid: Serve Web UI
   │   └─→ Invalid: 401 Unauthorized
   │
   └─→ Web UI HTML/CSS/JS sent to browser
       │
       └─→ User interacts with torrent list, settings, etc.
```

### LAN Access Flow (from other devices)

```
iPad on LAN (http://192.168.1.100:8080)
   │
   ▼
Local Network (192.168.1.0/24)
   │
   ▼
macOS Host (192.168.1.100)
   │
   ▼
Gluetun Firewall Rule Check
   │
   ├─→ Source IP in LOCAL_SUBNET? (192.168.1.0/24)
   │   │
   │   ├─→ YES: ALLOW
   │   │   └─→ Forward to qBittorrent Web UI
   │   │
   │   └─→ NO: DROP
   │       └─→ Connection refused
   │
   └─→ qBittorrent Web UI (authentication required)
```

---

## Container Interaction

### Startup Sequence

```
┌─────────────────────────────────────────────────────────────┐
│  docker-compose up -d                                       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  1. Docker creates named volumes              │
    │     • gluetun-config                          │
    │     • qbittorrent-config                      │
    │     • downloads (bind mount to host)          │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  2. Gluetun container starts                  │
    │     ┌─────────────────────────────────────┐   │
    │     │ a. Request /dev/net/tun device      │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ b. Load VPN credentials from .env   │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ c. Establish VPN connection         │   │
    │     │    • WireGuard handshake OR         │   │
    │     │    • OpenVPN negotiation            │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ d. Create tun0 interface            │   │
    │     │    (VPN tunnel endpoint)            │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ e. Configure routing table          │   │
    │     │    Default route: tun0              │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ f. Start firewall                   │   │
    │     │    ALLOW: tun0, LOCAL_SUBNET        │   │
    │     │    DROP: everything else            │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ g. Start health check monitor       │   │
    │     │    Checks: VPN connection status    │   │
    │     └─────────────────────────────────────┘   │
    └───────────────────────────────────────────────┘
                           │
                           ▼ (health check passes)
    ┌───────────────────────────────────────────────┐
    │  3. qBittorrent container starts              │
    │     depends_on:                               │
    │       gluetun:                                │
    │         condition: service_healthy ← WAITS    │
    │     ┌─────────────────────────────────────┐   │
    │     │ a. Inherit Gluetun's network        │   │
    │     │    namespace (network_mode)         │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ b. Set PUID/PGID for file perms     │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ c. Load qBittorrent config          │   │
    │     │    /config/qBittorrent.conf         │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ d. Start Web UI server (port 8080)  │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ e. Start torrent engine (port 6881) │   │
    │     └─────────────────────────────────────┘   │
    │     ┌─────────────────────────────────────┐   │
    │     │ f. Resume existing torrents         │   │
    │     └─────────────────────────────────────┘   │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  4. Stack is ready                            │
    │     • Web UI: http://localhost:8080           │
    │     • VPN: Connected                          │
    │     • Kill switch: Active                     │
    └───────────────────────────────────────────────┘
```

### Health Check Mechanism

```yaml
# Gluetun health check (in docker-compose.yml)
healthcheck:
  test: ["CMD", "wget", "--spider", "-q", "https://1.1.1.1"]
  interval: 60s
  timeout: 10s
  retries: 3
  start_period: 30s
```

**How it works:**
1. Every 60 seconds, Docker runs: `wget --spider -q https://1.1.1.1`
2. This tests:
   - VPN tunnel is up (can reach internet)
   - DNS is working (resolves 1.1.1.1)
   - Firewall allows traffic
3. If 3 consecutive failures → Container marked "unhealthy"
4. Docker can be configured to restart unhealthy containers

---

## Kill Switch Mechanism

### Implementation Details

The kill switch uses Docker's network namespace sharing, which is **far more reliable** than iptables rules because it's enforced at the kernel level.

```
┌─────────────────────────────────────────────────────────────┐
│                    Linux Kernel                             │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Network Namespace: gluetun (net:[1234567])         │   │
│  │                                                     │   │
│  │  ┌──────────────────┐      ┌──────────────────┐    │   │
│  │  │ Gluetun Process  │      │ qBittorrent Proc │    │   │
│  │  │ PID: 1001        │      │ PID: 2001        │    │   │
│  │  └──────────────────┘      └──────────────────┘    │   │
│  │          │                          │              │   │
│  │          └──────────┬───────────────┘              │   │
│  │                     │                              │   │
│  │                     ▼                              │   │
│  │       ┌──────────────────────────┐                 │   │
│  │       │  Network Interfaces      │                 │   │
│  │       │  • tun0: 10.2.0.2        │ ← VPN tunnel    │   │
│  │       │  • eth0: 172.20.0.2      │ ← Docker bridge │   │
│  │       └──────────────────────────┘                 │   │
│  │                     │                              │   │
│  │                     ▼                              │   │
│  │       ┌──────────────────────────┐                 │   │
│  │       │  Routing Table           │                 │   │
│  │       │  default via tun0        │                 │   │
│  │       │  192.168.1.0/24 via eth0 │ ← LAN access    │   │
│  │       └──────────────────────────┘                 │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  qBittorrent CANNOT:                                       │
│  • Create new network interfaces                           │
│  • Modify routing table                                    │
│  • Bypass firewall rules                                   │
│  • Escape network namespace (requires CAP_SYS_ADMIN)       │
└─────────────────────────────────────────────────────────────┘
```

### What Happens When VPN Drops

```
Scenario: VPN connection fails
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  1. Gluetun detects VPN disconnection         │
    │     (e.g., auth failure, timeout, etc.)       │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  2. tun0 interface goes down                  │
    │     ip link show tun0 → state DOWN            │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  3. Routing table loses default route         │
    │     BEFORE: default via tun0                  │
    │     AFTER:  (no default route)                │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  4. qBittorrent tries to connect to peer      │
    │     connect(peer.example.com:6881)            │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  5. Kernel checks routing table               │
    │     Destination: 1.2.3.4 (peer IP)            │
    │     Route: (none) → NETWORK UNREACHABLE       │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  6. Connection FAILS                          │
    │     qBittorrent: "Connection timed out"       │
    │     NO TRAFFIC LEAKS TO REAL IP               │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  7. Gluetun attempts reconnection             │
    │     (automatic retry with backoff)            │
    └───────────────────────────────────────────────┘
                           │
                           ▼
    ┌───────────────────────────────────────────────┐
    │  8. When VPN reconnects:                      │
    │     • tun0 comes back up                      │
    │     • Default route restored                  │
    │     • qBittorrent resumes downloads           │
    └───────────────────────────────────────────────┘
```

### Verification

**Manual Test:**
```bash
# Stop VPN
docker-compose stop gluetun

# Try to reach internet from qBittorrent (should FAIL)
docker exec qbittorrent wget -T 5 https://api.ipify.org
# Expected: Connection timeout / Network unreachable

# Restart VPN
docker-compose start gluetun

# Wait for reconnection (check logs)
docker-compose logs -f gluetun

# Try again (should SUCCEED with VPN IP)
docker exec qbittorrent wget -qO- https://api.ipify.org
```

**Automated Test:**
```bash
./scripts/check-leaks.sh
# Select "y" when prompted for kill switch test
```

---

## Port Forwarding Architecture

Some VPN providers (Mullvad, ProtonVPN, PIA) support dynamic port forwarding, which improves torrent connectivity.

### Port Forwarding Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. Gluetun connects to VPN                                 │
│     • Establishes encrypted tunnel                          │
│     • Receives VPN IP address                               │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  2. If VPN_PORT_FORWARDING=on:                              │
│     Gluetun requests forwarded port from VPN provider       │
│     ┌───────────────────────────────────────────────────┐   │
│     │  VPN Provider API Request                         │   │
│     │  POST /api/port-forward                           │   │
│     │  Auth: <VPN credentials>                          │   │
│     └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  3. VPN Provider responds with port number                  │
│     Response: { "port": 54321 }                             │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Gluetun writes port to file                             │
│     /tmp/gluetun/forwarded_port → "54321"                   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  5. OPTIONAL: Port sync helper container                    │
│     (commented out in docker-compose.yml)                   │
│     ┌───────────────────────────────────────────────────┐   │
│     │ a. Read /tmp/gluetun/forwarded_port               │   │
│     │ b. Call qBittorrent API:                          │   │
│     │    POST /api/v2/app/setPreferences               │   │
│     │    { "listen_port": 54321 }                       │   │
│     └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  6. qBittorrent now listens on port 54321                   │
│     • Accepts incoming connections from peers               │
│     • Improved upload/download speeds                       │
└─────────────────────────────────────────────────────────────┘
```

### Why Port Forwarding Helps

```
WITHOUT Port Forwarding:
  You → Can initiate connections to peers
  Peers → CANNOT initiate connections to you (behind NAT)
  Result: Slower speeds, fewer sources

WITH Port Forwarding:
  You → Can initiate connections to peers
  Peers → CAN initiate connections to you (port is open)
  Result: Faster speeds, more sources
```

### Port Sync Helper (Optional)

The stack includes a commented-out helper service that automatically syncs the forwarded port to qBittorrent:

```yaml
# Uncomment in docker-compose.yml to enable
# gluetun-qbittorrent-port-sync:
#   image: ghcr.io/qdm12/gluetun-qbittorrent-port-sync:latest
#   container_name: gluetun-qbittorrent-port-sync
#   network_mode: "service:gluetun"
#   environment:
#     QBITTORRENT_SERVER: "localhost:8080"
#     QBITTORRENT_USER: "${QBITTORRENT_USER}"
#     QBITTORRENT_PASSWORD: "${QBITTORRENT_PASS}"
#     VPN_GATEWAY: "gluetun:8000"
```

**How it works:**
1. Watches `/tmp/gluetun/forwarded_port` for changes
2. When port changes, calls qBittorrent API to update listen port
3. No manual configuration needed

---

## Persistence & Storage

### Volume Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Docker Volumes                           │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  gluetun-config (Named Volume)                      │   │
│  │  /var/lib/docker/volumes/gluetun-config/_data       │   │
│  │  ├── gluetun.log                                    │   │
│  │  ├── auth.conf (if OpenVPN)                         │   │
│  │  └── wg0.conf (if WireGuard)                        │   │
│  │                                                     │   │
│  │  Mounted to: /gluetun in Gluetun container         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  qbittorrent-config (Named Volume)                  │   │
│  │  /var/lib/docker/volumes/qbittorrent-config/_data   │   │
│  │  ├── qBittorrent/                                   │   │
│  │  │   ├── qBittorrent.conf ← Settings               │   │
│  │  │   ├── BT_backup/ ← Torrent metadata (.fastresume)│  │
│  │  │   └── logs/                                      │   │
│  │  └── .config/                                       │   │
│  │                                                     │   │
│  │  Mounted to: /config in qBittorrent container      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  downloads (Bind Mount)                             │   │
│  │  Host: ~/Downloads/torrents                         │   │
│  │  Container: /downloads                              │   │
│  │  ├── movie.mkv ← Completed downloads                │   │
│  │  ├── incomplete/ ← In-progress downloads            │   │
│  │  └── watch/ ← Auto-add .torrent files               │   │
│  │                                                     │   │
│  │  Ownership: PUID:PGID (from .env)                   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Data Persistence Guarantees

| Data Type             | Storage Location        | Survives Container Restart | Survives `docker-compose down` | Survives Docker Uninstall |
|-----------------------|-------------------------|----------------------------|--------------------------------|---------------------------|
| VPN Config            | gluetun-config volume   | ✅ Yes                     | ✅ Yes                         | ❌ No                     |
| qBittorrent Settings  | qbittorrent-config      | ✅ Yes                     | ✅ Yes                         | ❌ No                     |
| Torrent Metadata      | qbittorrent-config      | ✅ Yes                     | ✅ Yes                         | ❌ No                     |
| Downloaded Files      | downloads (bind mount)  | ✅ Yes                     | ✅ Yes                         | ✅ Yes                    |

### Backup Strategy

**Backup Configuration:**
```bash
# Backup qBittorrent settings
docker run --rm -v qbittorrent-config:/data -v $(pwd):/backup \
  alpine tar czf /backup/qbittorrent-config-$(date +%Y%m%d).tar.gz -C /data .

# Backup Gluetun config
docker run --rm -v gluetun-config:/data -v $(pwd):/backup \
  alpine tar czf /backup/gluetun-config-$(date +%Y%m%d).tar.gz -C /data .
```

**Restore Configuration:**
```bash
# Restore qBittorrent settings
docker run --rm -v qbittorrent-config:/data -v $(pwd):/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/qbittorrent-config-YYYYMMDD.tar.gz -C /data"

# Restart containers
docker-compose restart
```

---

## Failure Modes & Recovery

### Failure Mode Matrix

| Failure Scenario                | Detection                          | Automatic Recovery             | Manual Recovery                |
|---------------------------------|------------------------------------|--------------------------------|--------------------------------|
| VPN auth failure                | Gluetun logs "auth failed"         | ❌ No (invalid credentials)    | Fix .env, restart              |
| VPN connection timeout          | Health check fails                 | ✅ Gluetun auto-retries        | Check VPN provider status      |
| VPN drops mid-session           | Health check fails                 | ✅ Gluetun reconnects          | None (automatic)               |
| Docker Desktop crashes          | All containers stop                | ❌ No                          | Restart Docker, `docker-compose up -d` |
| macOS host reboots              | All containers stop                | ✅ If restart:always enabled   | `docker-compose up -d`         |
| qBittorrent crashes             | Container exits                    | ✅ If restart:unless-stopped   | `docker-compose restart qbittorrent` |
| Disk full (downloads)           | qBittorrent errors                 | ❌ No                          | Free up space                  |
| Firewall blocks Docker          | Cannot reach Web UI                | ❌ No                          | Adjust macOS firewall          |
| .env file deleted               | Containers fail to start           | ❌ No                          | Recreate from .env.example     |
| Port conflict (8080 in use)     | docker-compose fails               | ❌ No                          | Change QBITTORRENT_WEBUI_PORT  |

### Recovery Procedures

**VPN Not Connecting:**
```bash
# 1. Check logs
docker-compose logs gluetun | grep -i error

# 2. Verify credentials
grep WIREGUARD_PRIVATE_KEY .env  # Should not be empty

# 3. Test with different server
# Edit .env:
SERVER_COUNTRIES=Sweden

# 4. Restart
docker-compose restart gluetun
```

**Kill Switch Not Working:**
```bash
# 1. Verify network mode
docker inspect qbittorrent | grep -A5 NetworkMode
# Should show: "NetworkMode": "container:<gluetun-id>"

# 2. Test manually
docker-compose stop gluetun
docker exec qbittorrent wget -T 5 https://api.ipify.org
# Should FAIL (timeout)

# 3. If it succeeds, network mode is broken
docker-compose down
docker-compose up -d  # Recreate containers
```

**Web UI Inaccessible:**
```bash
# 1. Check if containers are running
docker-compose ps
# Both should be "Up"

# 2. Check Gluetun health
docker inspect gluetun --format='{{.State.Health.Status}}'
# Should be "healthy"

# 3. Check port mapping
docker port gluetun
# Should show: 8080/tcp -> 0.0.0.0:8080

# 4. Test from host
curl -v http://localhost:8080
# Should get HTTP response (even if 401 auth required)

# 5. Check macOS firewall
# System Preferences → Security & Privacy → Firewall → Options
# Ensure Docker is allowed
```

**Data Loss Prevention:**
```bash
# Regularly backup qBittorrent config
# Add to cron (macOS: launchd)
0 2 * * * cd ~/backups && docker run --rm -v qbittorrent-config:/data -v $(pwd):/backup alpine tar czf /backup/qbit-$(date +\%Y\%m\%d).tar.gz -C /data .

# Keep last 7 days
find ~/backups -name "qbit-*.tar.gz" -mtime +7 -delete
```

---

## Monitoring & Observability

### Log Locations

```bash
# Gluetun logs (VPN connection, errors, IP changes)
docker-compose logs -f gluetun

# qBittorrent logs
docker-compose logs -f qbittorrent

# Both
docker-compose logs -f

# Filter for errors
docker-compose logs | grep -i error

# Filter for VPN IP changes
docker-compose logs gluetun | grep "Public IP"
```

### Health Monitoring

**Check VPN Connection:**
```bash
# Get current VPN IP
docker exec gluetun wget -qO- https://api.ipify.org

# Get health status
docker inspect gluetun --format='{{.State.Health.Status}}'

# Check if qBittorrent can reach internet
docker exec qbittorrent wget -qO- https://api.ipify.org
# Should match Gluetun's IP
```

**Check Torrent Activity:**
```bash
# qBittorrent Web UI: http://localhost:8080
# • Active torrents count
# • Upload/download speeds
# • Connection status

# Or via API:
curl -s "http://localhost:8080/api/v2/torrents/info" \
  --user "admin:your_password" | jq '.[] | {name, state, progress}'
```

### Performance Metrics

**Network Throughput:**
```bash
# qBittorrent stats (via Web UI):
# • Global download rate
# • Global upload rate
# • Connections: X/Y (active/max)

# Container stats
docker stats gluetun qbittorrent
# Shows: CPU %, MEM USAGE, NET I/O
```

**VPN Latency:**
```bash
# Ping VPN gateway (from inside Gluetun)
docker exec gluetun ping -c 5 1.1.1.1
# Look for avg latency

# Traceroute (if needed)
docker exec gluetun traceroute 1.1.1.1
```

---

## Appendix: Network Namespace Deep Dive

### What is `network_mode: "service:gluetun"`?

In Docker, every container normally gets its own network namespace with:
- Its own network interfaces (eth0, lo)
- Its own routing table
- Its own firewall rules (iptables)
- Its own IP address

When you set `network_mode: "service:gluetun"`, qBittorrent **does not** get its own namespace. Instead:

```
Normal Containers:
┌──────────────┐    ┌──────────────┐
│   Gluetun    │    │ qBittorrent  │
│ namespace A  │    │ namespace B  │
│  10.0.1.5    │    │  10.0.1.6    │
└──────────────┘    └──────────────┘
     │                     │
     └──────────┬──────────┘
                │
         Docker Network

With network_mode: "service:gluetun":
┌─────────────────────────────────┐
│      Shared Namespace A         │
│  ┌──────────┐  ┌──────────┐     │
│  │ Gluetun  │  │qBittorrent│    │
│  │ Process  │  │ Process   │    │
│  └──────────┘  └──────────┘     │
│         10.0.1.5                │
└─────────────────────────────────┘
              │
       Docker Network
```

**Key Implications:**
1. Both processes see **identical** network interfaces
2. Both processes share **one** routing table
3. Both processes are subject to **same** firewall rules
4. If Gluetun routes via VPN → qBittorrent routes via VPN
5. If Gluetun's VPN drops → qBittorrent has no route

This is **impossible** to bypass from within qBittorrent because it would require:
- `CAP_NET_ADMIN` capability (not granted)
- Root access (containers run as PUID/PGID)
- Kernel-level network stack modification (impossible from userspace)

---

## Conclusion

This architecture provides **defense in depth** security for torrent downloading:

1. **Kill Switch**: Network namespace sharing prevents any non-VPN traffic
2. **DNS Protection**: DNS-over-TLS prevents ISP snooping
3. **IPv6 Protection**: Disabled to prevent dual-stack leaks
4. **Firewall**: Gluetun blocks non-VPN traffic at iptables level
5. **Encryption**: WireGuard/OpenVPN encrypts all traffic
6. **Isolation**: Containers run with minimal privileges
7. **Authentication**: Web UI requires password

**Verification:**
- Run `./scripts/verify-vpn.sh` after setup
- Run `./scripts/check-leaks.sh` periodically
- Monitor logs for VPN disconnections
- Check https://ipleak.net from qBittorrent Web UI

**Trust Model:**
- ✅ Trust: Docker isolation, Linux kernel networking
- ✅ Trust: Gluetun's firewall implementation
- ⚠️ Trust: VPN provider (to not log your activity)
- ⚠️ Trust: Your .env file security (keep it secret!)
- ❌ Don't Trust: Your ISP (everything is encrypted from them)
