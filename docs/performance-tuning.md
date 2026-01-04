# Performance Tuning Guide

## Quick Wins

1. **Use WireGuard** (vs OpenVPN): 50-100% faster
2. **Enable Port Forwarding** (if supported): 2-3x more peers
3. **Choose nearby servers**: Lower latency, better speeds
4. **Increase Docker resources**: 4GB+ RAM, 4+ CPUs recommended

---

## VPN Protocol: WireGuard vs OpenVPN

### WireGuard (Recommended)
- **Speed:** 2-3x faster than OpenVPN
- **CPU Usage:** 50-70% less CPU than OpenVPN
- **Latency:** 20-40% lower ping
- **Modern Crypto:** ChaCha20, faster on most hardware

**Use WireGuard for:** Mullvad, ProtonVPN, PIA, Surfshark

### OpenVPN
- **Speed:** Slower but more mature
- **Compatibility:** Works everywhere
- **CPU Usage:** Higher overhead

**Use OpenVPN when:** Provider doesn't support WireGuard, or compatibility needed

---

## Docker Desktop Settings (macOS)

Optimize Docker Desktop for better performance:

1. **Open Docker Desktop** → **Settings** → **Resources**

2. **Recommended Settings:**
   - **CPUs:** 4-6 cores
   - **Memory:** 4-8 GB
   - **Swap:** 2 GB
   - **Disk:** 50 GB+

3. **Apply & Restart**

### Why It Matters:
- More CPUs = Better encryption performance
- More RAM = More connections, better caching
- More Disk = Prometheus metrics storage

---

## qBittorrent Settings

### Connection Settings

1. **Open qBittorrent** → **Settings** → **Connection**

2. **Recommended:**
   ```
   Global maximum connections: 500
   Maximum per torrent: 100
   Global maximum upload slots: 50
   Maximum per torrent upload slots: 4

   ✅ Use UPnP/NAT-PMP: DISABLE (conflicts with port forwarding)
   ✅ Use different port on each startup: DISABLE
   ```

3. **With Port Forwarding:**
   - Port will be auto-synced by `gluetun-qbittorrent-port-manager`
   - Don't manually change port

4. **Without Port Forwarding:**
   - Increase max connections to compensate
   - Lower expectations for seeding

### Speed Settings

1. **Settings** → **Speed**

2. **Recommended:**
   ```
   Global Download Limit: 0 (unlimited)
   Global Upload Limit: 0 or set reasonable limit

   Alternative Rate Limits:
   - Use if you need bandwidth for other apps
   - Set schedule for off-peak hours
   ```

### BitTorrent Settings

1. **Settings** → **BitTorrent**

2. **Recommended:**
   ```
   ✅ Enable DHT
   ✅ Enable PeX
   ✅ Enable Local Peer Discovery
   ✅ Enable encryption: Require encryption (for privacy)
   ✅ Enable anonymous mode (for extra privacy)
   ```

---

## Provider-Specific Tuning

### Mullvad

**Best Servers:** Netherlands, Sweden, Switzerland (low latency, high speed)

**Optimal Settings:**
```bash
VPN_TYPE=wireguard  # Much faster than OpenVPN
VPN_PORT_FORWARDING=on  # Enable on all servers
SERVER_COUNTRIES=Netherlands,Sweden
```

**Expected Performance:**
- Download: 250-400 Mbps
- Upload: 150-250 Mbps
- Peers: 100-200+ with port forwarding

---

### ProtonVPN

**Best Servers:** Plus servers (pm) in Netherlands, Switzerland, Iceland

**Optimal Settings:**
```bash
VPN_TYPE=wireguard  # Faster than OpenVPN
VPN_PORT_FORWARDING=on
VPN_PORT_FORWARDING_PROVIDER=protonvpn  # REQUIRED
SERVER_COUNTRIES=Netherlands,Switzerland
```

**Important:** Use P2P-optimized servers for port forwarding

**Expected Performance:**
- Download: 150-300 Mbps
- Upload: 80-150 Mbps
- Peers: 80-150+ with port forwarding

---

### NordVPN (No Port Forwarding)

**Best Servers:** P2P-optimized servers in Netherlands, Canada, Spain

**Optimal Settings:**
```bash
VPN_TYPE=openvpn  # WireGuard support limited
VPN_PORT_FORWARDING=off  # Not supported
SERVER_COUNTRIES=Netherlands,Canada
```

**Compensating for No Port Forwarding:**
1. Increase max connections in qBittorrent (500-1000)
2. Use well-seeded torrents
3. Be patient with peer discovery
4. Consider switching to Mullvad/PIA if torrenting is priority

**Expected Performance:**
- Download: 200-350 Mbps (but fewer peers)
- Upload: 100-200 Mbps (but limited connectivity)
- Peers: 30-60 (limited without port forwarding)

---

## Troubleshooting Slow Speeds

### 1. Test VPN Speed

```bash
# Run benchmark
./scripts/benchmark-vpn.sh

# Check results
cat benchmark-results.json
```

### 2. Check VPN Connection

```bash
# Verify connected to VPN
docker exec gluetun wget -qO- https://api.ipify.org

# Check Gluetun logs
docker logs gluetun | tail -50
```

### 3. Try Different Server

```bash
# In .env, try different country
SERVER_COUNTRIES=Netherlands  # or Sweden, Switzerland, etc.

# Restart
docker compose restart gluetun
```

### 4. Switch to WireGuard

```bash
# In .env
VPN_TYPE=wireguard  # Change from openvpn

# Restart
docker compose down && docker compose up -d
```

### 5. Check Docker Resources

```bash
# Check Docker stats
docker stats

# If high CPU/memory, increase Docker resources (see above)
```

---

## Advanced Optimizations

### 1. Reduce Monitoring Overhead

If monitoring (Prometheus/Grafana) is using too much resources:

```bash
# Reduce Prometheus retention
# In docker-compose.yml:
prometheus:
  command:
    - '--storage.tsdb.retention.time=7d'  # Reduce from 30d
```

### 2. Optimize Backup Schedule

```bash
# Run backups during off-peak hours
BACKUP_SCHEDULE_HOUR=3  # 3 AM
```

### 3. Test Different VPN Protocols

```bash
# WireGuard (faster)
VPN_TYPE=wireguard

# OpenVPN TCP (more stable, slower)
VPN_TYPE=openvpn
OPENVPN_PROTOCOL=tcp

# OpenVPN UDP (faster, less stable)
VPN_TYPE=openvpn
OPENVPN_PROTOCOL=udp
```

---

## Expected Performance Ranges

### With Port Forwarding + WireGuard (Mullvad, ProtonVPN Plus, PIA)

- **Download:** 200-400 Mbps
- **Upload:** 100-250 Mbps
- **Peers:** 100-300+
- **Seeding:** Excellent
- **Latency:** 10-30ms

### Without Port Forwarding (NordVPN, Surfshark)

- **Download:** 150-300 Mbps (limited peers)
- **Upload:** 80-150 Mbps (very limited)
- **Peers:** 30-80
- **Seeding:** Poor
- **Latency:** 15-40ms

### With Port Forwarding + OpenVPN

- **Download:** 100-250 Mbps
- **Upload:** 50-150 Mbps
- **Peers:** 100-250+
- **Seeding:** Good
- **Latency:** 20-50ms

---

## Monitoring Performance

Use Grafana dashboards (if monitoring enabled):

1. **VPN Dashboard:** Connection status, uptime
2. **qBittorrent Dashboard:** Download/upload speeds, peers
3. **System Dashboard:** CPU, memory, network usage

Access: http://localhost:3000

---

## Summary: Quick Optimization Checklist

- [ ] Use WireGuard (not OpenVPN)
- [ ] Enable port forwarding (if provider supports)
- [ ] Choose nearby servers
- [ ] Allocate 4GB+ RAM to Docker
- [ ] Disable UPnP in qBittorrent
- [ ] Enable encryption in qBittorrent
- [ ] Increase max connections (500+)
- [ ] Test with benchmark script
- [ ] Monitor performance with Grafana

---

**Need more help?** Check [Provider Comparison](./provider-comparison.md) or [Troubleshooting Guide](../README.md#troubleshooting)
