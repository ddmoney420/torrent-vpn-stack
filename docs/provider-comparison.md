# VPN Provider Comparison for Torrenting

## Quick Recommendation

**Best for Torrenting:** Mullvad, Private Internet Access (PIA), ProtonVPN Plus
**Not Recommended:** NordVPN, Surfshark, ExpressVPN (no port forwarding)

---

## Comparison Table

| Provider | Port Forwarding | WireGuard | Speed | Privacy | Price/Month | Best For |
|----------|----------------|-----------|-------|---------|-------------|----------|
| **Mullvad** | ✅ All servers | ✅ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | $5.50 | Privacy + Performance |
| **ProtonVPN** | ✅ Plus plan | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | $4.99+ | Swiss privacy laws |
| **PIA** | ✅ All servers | ✅ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | $2.19+ | Budget + Performance |
| **NordVPN** | ❌ | Limited | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | $3.39+ | General use, streaming |
| **Surfshark** | ❌ | ✅ | ⭐⭐⭐ | ⭐⭐⭐ | $2.49+ | Unlimited devices |
| **ExpressVPN** | ❌ | ❌ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | $8.32+ | Ease of use |

---

## Detailed Provider Analysis

### Mullvad ⭐⭐⭐⭐⭐

**Port Forwarding:** ✅ Yes (all servers, WireGuard only)
**Protocols:** WireGuard, OpenVPN
**Pricing:** €5/month (simple, no tiers)

**Strengths:**
- Excellent privacy (anonymous payment, no logs, audited)
- Port forwarding on ALL servers
- Fast WireGuard implementation
- Works perfectly with this stack
- No account required (just a number)

**Performance:**
- Download: 250-400 Mbps
- Upload: 150-250 Mbps
- Latency: 10-30ms
- CPU Usage: 2-5%

**Best For:** Privacy-conscious torrent users who need reliable port forwarding

**Setup Difficulty:** ⭐ Easy

**Configuration:** See `examples/providers/mullvad.env.example`

---

### ProtonVPN ⭐⭐⭐⭐

**Port Forwarding:** ✅ Yes (Plus/Visionary plans only)
**Protocols:** WireGuard, OpenVPN
**Pricing:** Free (no PF), Plus $4.99/month, Visionary $24/month

**Strengths:**
- Strong privacy (Swiss jurisdiction, no logs)
- Port forwarding on Plus+ plans
- Integrated with Proton ecosystem
- Free tier available (limited)

**Limitations:**
- Port forwarding NOT on Free plan
- Must set `VPN_PORT_FORWARDING_PROVIDER=protonvpn`
- Not all servers support port forwarding

**Performance:**
- Download: 150-300 Mbps (WireGuard), 100-200 Mbps (OpenVPN)
- Upload: 80-150 Mbps
- Latency: 15-40ms
- CPU Usage: 3-6%

**Best For:** Users who want privacy + port forwarding, already use ProtonMail

**Setup Difficulty:** ⭐⭐ Medium (requires provider setting)

**Configuration:** See `examples/providers/protonvpn.env.example`

---

### Private Internet Access (PIA) ⭐⭐⭐⭐

**Port Forwarding:** ✅ Yes (all servers)
**Protocols:** WireGuard, OpenVPN
**Pricing:** $2.19/month (3-year), $7.50/month (1-year)

**Strengths:**
- Affordable with port forwarding
- Large server network
- Proven no-logs policy
- Works well with Gluetun

**Limitations:**
- US jurisdiction (some privacy concerns)
- Not as privacy-focused as Mullvad

**Performance:**
- Download: 200-350 Mbps
- Upload: 100-200 Mbps
- Latency: 20-40ms
- CPU Usage: 3-5%

**Best For:** Budget-conscious users who need port forwarding

**Setup Difficulty:** ⭐ Easy

---

### NordVPN ⭐⭐⭐

**Port Forwarding:** ❌ NO
**Protocols:** OpenVPN (WireGuard support limited in Gluetun)
**Pricing:** $3.39/month (2-year), $12.99/month

**Strengths:**
- Huge server network (5900+ servers)
- Good for streaming
- User-friendly
- Fast speeds

**Limitations for Torrenting:**
- **NO port forwarding** - major limitation
- Reduced swarm connectivity
- Can only connect to peers with open ports
- Not ideal for seeding

**Performance:**
- Download: 200-350 Mbps (but limited peers)
- Upload: 100-200 Mbps (but limited peers)
- Latency: 15-35ms
- CPU Usage: 4-7%

**Best For:** Users who prioritize streaming over torrenting

**NOT Recommended For:** Heavy torrent users, seeders

**Setup Difficulty:** ⭐ Easy

**Configuration:** See `examples/providers/nordvpn.env.example`

---

### Surfshark ⭐⭐⭐

**Port Forwarding:** ❌ NO
**Protocols:** WireGuard, OpenVPN
**Pricing:** $2.49/month (2-year), $12.95/month

**Strengths:**
- Unlimited simultaneous devices
- Affordable
- Good speeds

**Limitations:**
- No port forwarding (same issues as NordVPN for torrenting)

**Performance:** Similar to NordVPN

**Best For:** Users with many devices, not heavy torrent users

---

### ExpressVPN ⭐⭐⭐

**Port Forwarding:** ❌ NO
**Protocols:** OpenVPN (no WireGuard)
**Pricing:** $8.32/month (1-year), $12.95/month

**Strengths:**
- Very user-friendly
- Good customer support
- Fast servers

**Limitations:**
- No port forwarding
- Expensive
- No WireGuard in Gluetun
- Not optimized for torrenting

**Best For:** Users who prioritize ease of use over performance/price

**NOT Recommended For:** Torrent users

---

## Port Forwarding Impact

### With Port Forwarding (ProtonVPN Plus, PIA)
- ✅ Connect to ALL peers in swarm
- ✅ Better download speeds
- ✅ Much better upload/seeding performance
- ✅ More connections to rare torrents
- ✅ Faster torrent startup

### Without Port Forwarding (NordVPN, Surfshark, ExpressVPN)
- ⚠️ Can ONLY connect to peers with open ports (~30-40% of swarm)
- ⚠️ Slower downloads on less-popular torrents
- ⚠️ Very poor seeding performance
- ⚠️ May struggle with private trackers
- ⚠️ Reduced swarm health contribution

---

## Benchmark Your Current Provider

Test your VPN performance:

```bash
./scripts/benchmark-vpn.sh
```

Results saved to `benchmark-results.json`

---

## Switching Providers

To switch providers:

1. Stop stack: `docker compose down`
2. Update `.env` with new provider config (see `examples/providers/`)
3. Start stack: `docker compose up -d`
4. Verify: `./scripts/verify-vpn.sh`

---

## Additional Resources

- [Mullvad Configuration Guide](https://mullvad.net/en/help/wireguard-and-mullvad-vpn/)
- [ProtonVPN Setup](https://protonvpn.com/support/linux-vpn-setup/)
- [Gluetun Provider List](https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers)
- [Performance Tuning Guide](./performance-tuning.md)
