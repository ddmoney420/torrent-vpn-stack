# Port Forwarding Setup Guide

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Supported VPN Providers](#supported-vpn-providers)
- [Quick Start](#quick-start)
- [Provider-Specific Setup](#provider-specific-setup)
  - [Mullvad](#mullvad)
  - [ProtonVPN](#protonvpn)
  - [Private Internet Access (PIA)](#private-internet-access-pia)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [FAQ](#faq)

---

## Overview

Port forwarding allows incoming connections to reach your torrent client through the VPN tunnel, significantly improving:

- **Download/Upload Speeds**: Direct peer connections without NAT traversal
- **Swarm Connectivity**: Better peer discovery and connection rates
- **Seeding Performance**: More peers can connect to you as a seed

### How It Works

1. Your VPN provider assigns you a dynamic forwarded port
2. Gluetun detects this port and exposes it via its control API
3. The port sync helper (`gluetun-qbittorrent-port-manager`) monitors for changes
4. qBittorrent's listening port is automatically updated when the VPN port changes

```
┌─────────────────────────────────────────────────────────────────┐
│                    VPN Provider Network                         │
│  Assigns dynamic port (e.g., 51234) → Your VPN connection       │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                        ┌────────▼────────┐
                        │     Gluetun     │
                        │  VPN Container  │
                        │  Exposes port   │
                        │  info via API   │
                        └────────┬────────┘
                                 │
                    ┌────────────▼─────────────┐
                    │  Port Sync Helper        │
                    │  Polls: http://localhost │
                    │         :8000/v1/openvpn │
                    │         /portforwarded   │
                    └────────────┬─────────────┘
                                 │
                        ┌────────▼────────┐
                        │  qBittorrent    │
                        │  Listening port │
                        │  auto-updated   │
                        └─────────────────┘
```

---

## Prerequisites

Before enabling port forwarding:

1. **VPN Provider Support**: Verify your provider supports port forwarding
   - ✅ Supported: ProtonVPN, Private Internet Access (PIA)
   - ❌ Not Supported: Mullvad (discontinued July 2023), NordVPN, Surfshark, ExpressVPN
   - See [Gluetun's port forwarding wiki](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md) for full list

2. **Active VPN Account**: Must have an active subscription with a supported provider

3. **Stack Running**: Basic stack must be working without port forwarding first
   - Run `./scripts/verify-vpn.sh` to verify VPN connectivity
   - Access qBittorrent Web UI at http://localhost:8080

---

## Supported VPN Providers

### Mullvad (No Longer Supported)
- **Port Forwarding**: ❌ **Discontinued July 2023**
- Mullvad removed port forwarding citing abuse concerns
- Still works for torrenting, but without port forwarding benefits
- Consider ProtonVPN or PIA if port forwarding is important

### ProtonVPN
- **Port Forwarding**: Requires Plus or Visionary plan
- **Protocol**: WireGuard or OpenVPN
- **Cost**: Included with eligible plans
- **Port Type**: Dynamic
- **Special Config**: Set `VPN_PORT_FORWARDING_PROVIDER=protonvpn` in .env

### Private Internet Access (PIA)
- **Port Forwarding**: Automatic
- **Protocol**: WireGuard or OpenVPN
- **Cost**: Free (included with subscription)
- **Port Type**: Dynamic

---

## Quick Start

### 1. Enable Port Forwarding in `.env`

```bash
# Edit your .env file
VPN_PORT_FORWARDING=on

# For ProtonVPN only, also set:
VPN_PORT_FORWARDING_PROVIDER=protonvpn

# Optional: Adjust sync interval (default: 300 seconds = 5 minutes)
PORT_SYNC_INTERVAL=300
```

### 2. Start Stack with Port Forwarding Profile

```bash
# Stop existing stack (if running)
docker compose down

# Start with port forwarding enabled
docker compose --profile port-forwarding up -d
```

### 3. Verify Port Forwarding

```bash
# Check Gluetun logs for forwarded port
docker logs gluetun 2>&1 | grep -i "port forward"

# Check port sync helper logs
docker logs gluetun-qbittorrent-sync

# Get current forwarded port from Gluetun API
curl -s http://localhost:8000/v1/openvpn/portforwarded
```

Expected output:
```json
{"port":51234}
```

### 4. Verify qBittorrent Configuration

1. Open qBittorrent Web UI: http://localhost:8080
2. Go to **Settings** → **Connection**
3. Verify **Port used for incoming connections** matches the forwarded port
4. Ensure **Use UPnP / NAT-PMP** is **disabled** (port sync handles this)

---

## Provider-Specific Setup

### Mullvad (Port Forwarding Discontinued)

> **⚠️ Important:** Mullvad discontinued port forwarding in July 2023.
> If you need port forwarding, consider ProtonVPN or PIA instead.

Mullvad still works for torrenting, but without port forwarding you will have reduced connectivity (fewer peers, slower seeding).

#### Configuration (without port forwarding)

```bash
# .env file
VPN_SERVICE_PROVIDER=mullvad
VPN_TYPE=wireguard

# Get your WireGuard config from: https://mullvad.net/en/account/wireguard-config
WIREGUARD_PRIVATE_KEY=your_private_key_here
WIREGUARD_ADDRESSES=10.2.0.2/32

# Port forwarding is NOT available with Mullvad
VPN_PORT_FORWARDING=off
```

---

### ProtonVPN

ProtonVPN requires Plus or Visionary plan and additional configuration.

#### Configuration

```bash
# .env file
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=wireguard  # or openvpn

# WireGuard configuration
# Get config from: ProtonVPN Account → Downloads → WireGuard configuration
WIREGUARD_PRIVATE_KEY=your_private_key_here
WIREGUARD_ADDRESSES=10.2.0.2/32

# Enable port forwarding with ProtonVPN-specific setting
VPN_PORT_FORWARDING=on
VPN_PORT_FORWARDING_PROVIDER=protonvpn
```

#### Verification

```bash
# Start stack
docker compose --profile port-forwarding up -d

# Monitor Gluetun logs for port assignment
docker logs -f gluetun
```

Look for:
```
[INFO] Port forwarding: enabled
[INFO] Port forwarding service: protonvpn
[INFO] Forwarded port: 12345
```

#### ProtonVPN-Specific Notes

1. **Plan Requirements**: Free plan does NOT support port forwarding
2. **Server Selection**: Not all servers support port forwarding
   - P2P-optimized servers are recommended
   - Leave `SERVER_COUNTRIES` empty or use P2P-friendly countries

3. **NAT-PMP Protocol**: ProtonVPN uses NAT-PMP for port forwarding
   - Requires `VPN_PORT_FORWARDING_PROVIDER=protonvpn`

#### Troubleshooting ProtonVPN

- **Issue**: "Port forwarding not supported on this server"
  - **Fix**: Connect to P2P-optimized server or change `SERVER_COUNTRIES`

- **Issue**: Port forwarding shows as "off" in logs
  - **Fix**: Verify `VPN_PORT_FORWARDING_PROVIDER=protonvpn` is set

---

### Private Internet Access (PIA)

PIA provides automatic port forwarding with both WireGuard and OpenVPN.

#### Configuration

```bash
# .env file
VPN_SERVICE_PROVIDER=privateinternetaccess
VPN_TYPE=wireguard  # or openvpn

# WireGuard configuration
WIREGUARD_PRIVATE_KEY=your_private_key_here
WIREGUARD_ADDRESSES=10.2.0.2/32

# Enable port forwarding (auto-detected for PIA)
VPN_PORT_FORWARDING=on

# No VPN_PORT_FORWARDING_PROVIDER needed - auto-detected
```

#### Verification

```bash
# Start stack
docker compose --profile port-forwarding up -d

# Check logs
docker logs gluetun 2>&1 | grep -i "forward"
docker logs gluetun-qbittorrent-sync
```

#### PIA-Specific Notes

1. **All Servers Support Port Forwarding**: Any PIA server works
2. **Port Persistence**: Port may change on reconnect
3. **Auto-Detection**: No need to specify `VPN_PORT_FORWARDING_PROVIDER`

---

## Verification

### Check Port Forwarding Status

```bash
# 1. Check Gluetun API
curl -s http://localhost:8000/v1/openvpn/portforwarded | jq

# 2. Check qBittorrent port
# Visit: http://localhost:8080 → Settings → Connection → Port used for incoming connections

# 3. Test external connectivity
docker exec gluetun wget -qO- https://portchecker.co/check?port=YOUR_PORT_HERE
```

### End-to-End Test

1. **Get Current Port**:
   ```bash
   FORWARDED_PORT=$(curl -s http://localhost:8000/v1/openvpn/portforwarded | jq -r '.port')
   echo "Forwarded port: $FORWARDED_PORT"
   ```

2. **Verify Port in qBittorrent**:
   - Open Web UI: http://localhost:8080
   - Settings → Connection
   - Port should match `$FORWARDED_PORT`

3. **Test with Active Torrent**:
   - Add a popular torrent with many seeds
   - Check **Peers** tab - you should see incoming connections
   - Status should show "✓" (connectable)

### Success Indicators

✅ **Working Port Forwarding**:
- Gluetun logs show "port forwarded is XXXXX"
- Port sync helper logs show "Successfully updated port to XXXXX"
- qBittorrent shows matching port in settings
- qBittorrent status shows "Connectable"
- Incoming peer connections visible in torrent details

❌ **Not Working**:
- Gluetun logs show "port forwarding is disabled"
- Port sync helper not running (`docker ps` doesn't show it)
- qBittorrent port doesn't match forwarded port
- No incoming connections after 5+ minutes

---

## Troubleshooting

### Port Sync Helper Not Running

**Symptoms**: `docker ps` doesn't show `gluetun-qbittorrent-sync` container

**Diagnosis**:
```bash
# Check if profile is activated
docker compose ps --all
```

**Solutions**:
1. **Ensure you started with profile**:
   ```bash
   docker compose --profile port-forwarding up -d
   ```

2. **Check .env configuration**:
   ```bash
   grep VPN_PORT_FORWARDING .env
   # Should show: VPN_PORT_FORWARDING=on
   ```

---

### Port Not Updating in qBittorrent

**Symptoms**: Gluetun shows forwarded port, but qBittorrent still uses old port

**Diagnosis**:
```bash
# Check port sync logs
docker logs gluetun-qbittorrent-sync

# Check qBittorrent credentials
docker logs gluetun-qbittorrent-sync 2>&1 | grep -i "auth\|login\|401"
```

**Solutions**:

1. **Verify qBittorrent credentials in .env**:
   ```bash
   grep QBITTORRENT_USER .env
   grep QBITTORRENT_PASS .env
   ```

2. **Restart port sync helper**:
   ```bash
   docker restart gluetun-qbittorrent-sync
   ```

3. **Manual port update** (temporary workaround):
   - Get port: `curl -s http://localhost:8000/v1/openvpn/portforwarded`
   - Set in qBittorrent Web UI → Settings → Connection

---

### "Port Forwarding Not Supported" Error

**Symptoms**: Gluetun logs show "port forwarding is not supported"

**Diagnosis**:
```bash
# Check VPN provider
grep VPN_SERVICE_PROVIDER .env

# Check provider documentation
# https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md
```

**Solutions**:

1. **Verify provider supports port forwarding**:
   - ✅ Supported: ProtonVPN (Plus+), PIA
   - ❌ Not supported: Mullvad (discontinued July 2023), NordVPN, Surfshark, ExpressVPN

2. **For ProtonVPN**:
   ```bash
   # Add to .env:
   VPN_PORT_FORWARDING_PROVIDER=protonvpn
   ```

---

### Port Changes Frequently

**Symptoms**: Forwarded port changes every few hours or on reconnect

**Explanation**: This is **normal behavior** for most VPN providers with dynamic port forwarding

**Solutions**:

1. **Verify port sync is running** (it will auto-update):
   ```bash
   docker logs gluetun-qbittorrent-sync
   ```

2. **Adjust sync interval** (check more frequently):
   ```bash
   # In .env
   PORT_SYNC_INTERVAL=120  # Check every 2 minutes
   ```

3. **Accept dynamic ports**: This is expected; the sync helper handles it automatically

---

### No Incoming Connections

**Symptoms**: Port is configured correctly, but no peers connect to you

**Diagnosis**:
```bash
# 1. Get current port
FORWARDED_PORT=$(curl -s http://localhost:8000/v1/openvpn/portforwarded | jq -r '.port')

# 2. Check if port is open (use external service)
docker exec gluetun wget -qO- "https://portchecker.co/check?port=$FORWARDED_PORT"

# 3. Check qBittorrent status
# Web UI → Status bar (bottom right) → Network icon
```

**Solutions**:

1. **Wait 5-10 minutes**: Swarm discovery takes time

2. **Verify firewall rules**:
   ```bash
   # Check Gluetun firewall configuration
   docker logs gluetun 2>&1 | grep -i firewall
   ```

3. **Test with popular torrent**: Use a well-seeded Linux distribution torrent

4. **Check VPN server**: Some servers may have restrictive firewall rules
   - Try different server: Set `SERVER_COUNTRIES` or `SERVER_HOSTNAMES` in .env

---

## Advanced Configuration

### Custom Sync Interval

Adjust how often the port sync helper checks for port changes:

```bash
# .env
PORT_SYNC_INTERVAL=60   # Check every 1 minute (more CPU usage)
PORT_SYNC_INTERVAL=600  # Check every 10 minutes (less responsive)
```

**Recommendations**:
- **Default (300s)**: Good balance for most users
- **Frequent changes**: Use 60-120 seconds
- **Stable connection**: Use 600 seconds

---

### Monitoring Port Changes

Create a simple monitoring script:

```bash
#!/bin/bash
# watch-port.sh

while true; do
    PORT=$(curl -s http://localhost:8000/v1/openvpn/portforwarded | jq -r '.port')
    echo "$(date): Current forwarded port: $PORT"
    sleep 60
done
```

Usage:
```bash
chmod +x watch-port.sh
./watch-port.sh
```

---

### Disable Port Forwarding

To disable port forwarding and return to standard mode:

```bash
# 1. Set VPN_PORT_FORWARDING=off in .env
sed -i.bak 's/VPN_PORT_FORWARDING=on/VPN_PORT_FORWARDING=off/' .env

# 2. Restart without port-forwarding profile
docker compose down
docker compose up -d  # Without --profile flag
```

---

## FAQ

### Q: Do I need port forwarding?

**A**: Not required, but highly recommended for optimal torrent performance:

- **Without port forwarding**: You can still download, but only connect to peers with open ports
- **With port forwarding**: You become a "connectable" peer, improving speeds and swarm health

### Q: Why does my port keep changing?

**A**: Most VPN providers assign dynamic ports that change on reconnect. The port sync helper automatically updates qBittorrent, so no manual intervention is needed.

### Q: Can I use a specific port?

**A**: No, VPN providers assign ports dynamically. You cannot request a specific port.

### Q: Does port forwarding affect privacy?

**A**: No, port forwarding does NOT expose your real IP. All traffic still routes through the VPN tunnel.

### Q: My VPN provider isn't listed. Can I still use port forwarding?

**A**: Check [Gluetun's provider list](https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md). If your provider isn't listed, they likely don't support port forwarding or Gluetun doesn't have support yet.

### Q: Can I run port forwarding without the sync helper?

**A**: Yes, but you'll need to manually update qBittorrent's port whenever it changes:
1. Get port: `curl http://localhost:8000/v1/openvpn/portforwarded`
2. Update in qBittorrent Web UI → Settings → Connection

### Q: How do I know if port forwarding is working?

**A**: Check these indicators:
1. Gluetun logs show forwarded port
2. qBittorrent settings show matching port
3. qBittorrent status shows "Connectable" (green network icon)
4. Torrent details show incoming peer connections

### Q: Does this work with IPv6?

**A**: No, this stack disables IPv6 to prevent leaks. Port forwarding is IPv4 only.

### Q: Can I use multiple forwarded ports?

**A**: No, VPN providers typically assign one port per connection.

---

## Additional Resources

- **Gluetun Port Forwarding Wiki**: https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md
- **Port Sync Helper Repository**: https://github.com/snoringdragon/gluetun-qbittorrent-port-manager
- **qBittorrent Connection Settings**: https://github.com/qbittorrent/qBittorrent/wiki/Explanation-of-Options-in-qBittorrent#connection

---

**Need Help?** If you're still having issues, check the [main troubleshooting guide](../README.md#troubleshooting) or open an issue on GitHub.
