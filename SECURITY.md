# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < Latest| :x:                |

We recommend always using the latest version of Torrent VPN Stack for the best security and features.

---

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow responsible disclosure practices:

### How to Report

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Instead, report privately using one of these methods:

   **Option A: GitHub Security Advisories (Preferred)**
   - Go to the [Security tab](https://github.com/ddmoney420/torrent-vpn-stack/security)
   - Click "Report a vulnerability"
   - Fill out the form with details

   **Option B: Email**
   - Send an email to the project maintainers (check GitHub profile for contact)
   - Use PGP encryption if possible (public key in maintainer's profile)

### What to Include

Provide as much information as possible:
- **Description:** Clear explanation of the vulnerability
- **Impact:** What an attacker could do with this vulnerability
- **Steps to reproduce:** Detailed steps to trigger the vulnerability
- **Affected versions:** Which versions are vulnerable
- **Suggested fix:** If you have ideas for fixing it
- **Proof of concept:** Code or screenshots (if applicable)

**Example:**
```markdown
## Vulnerability: Exposed API Credentials in Logs

**Impact:** HIGH - API credentials are logged in plaintext

**Affected Versions:** All versions prior to v1.2.0

**Steps to Reproduce:**
1. Start stack with DEBUG logging enabled
2. Check `docker logs gluetun`
3. API credentials are visible in logs

**Suggested Fix:**
Sanitize sensitive environment variables before logging.
```

### Response Timeline

- **Initial response:** Within 48 hours
- **Acknowledgment:** Within 5 business days
- **Status updates:** Every 7 days until resolved
- **Fix timeline:** Depends on severity
  - **Critical:** 7 days
  - **High:** 14 days
  - **Medium:** 30 days
  - **Low:** 60 days

### Disclosure Policy

- We will work with you to understand and address the vulnerability
- We will credit you in the security advisory (unless you prefer to remain anonymous)
- We ask for 90 days from initial report before public disclosure
- We will coordinate with you on the disclosure timeline

---

## Security Best Practices

### For Users

#### 1. Protect Your VPN Credentials

**Don't:**
- ❌ Commit `.env` file to version control
- ❌ Share your `.env` file publicly
- ❌ Store credentials in plaintext outside of `.env`

**Do:**
- ✅ Keep `.env` file secure with proper permissions:
  ```bash
  chmod 600 .env
  ```
- ✅ Use environment-specific `.env` files (don't reuse production credentials in dev)
- ✅ Rotate VPN credentials periodically

#### 2. Keep Software Updated

```bash
# Update to latest version
cd ~/torrent-vpn-stack
git pull origin main

# Update Docker images
docker compose pull

# Restart stack
docker compose down
docker compose up -d
```

#### 3. Review Firewall Rules

Ensure only necessary ports are exposed:
- **qBittorrent WebUI:** Port 8080 (restrict to local network)
- **Grafana:** Port 3000 (optional, restrict if needed)
- **Prometheus:** Port 9090 (optional, local only)

**Example (Ubuntu/Debian with UFW):**
```bash
# Allow qBittorrent only from local network
sudo ufw allow from 192.168.1.0/24 to any port 8080

# Deny external access
sudo ufw deny 8080/tcp
```

#### 4. Use Strong qBittorrent Password

Change the default password in `.env`:
```bash
QBITTORRENT_USER=admin
QBITTORRENT_PASS=your_strong_password_here  # Change this!
```

#### 5. Enable Port Forwarding Safely

Only use port forwarding from trusted VPN providers:
- ✅ Mullvad, ProtonVPN, PIA
- ❌ Free VPNs or unknown providers

Port forwarding is handled inside the VPN tunnel, not exposed to the internet directly.

#### 6. Monitor Logs for Suspicious Activity

```bash
# Check for failed login attempts
docker logs qbittorrent | grep -i "failed\|unauthorized"

# Monitor VPN connection
docker logs gluetun | grep -i "error\|disconnect"
```

#### 7. Regular Backups

Use encrypted backups and store them securely:
```bash
# Create backup
./scripts/backup.sh

# Encrypt backup (optional)
gpg --encrypt --recipient your-email@example.com backup.tar.gz
```

---

## Known Security Considerations

### 1. VPN Kill Switch

Gluetun provides a network kill switch:
- If VPN disconnects, all traffic stops
- qBittorrent cannot leak your real IP

Verify kill switch is working:
```bash
./scripts/verify-vpn.sh
```

### 2. DNS Leaks

Gluetun handles DNS to prevent leaks:
- DNS requests go through VPN tunnel
- No local DNS resolution

Test for DNS leaks:
```bash
docker exec gluetun wget -qO- https://www.dnsleaktest.com
```

### 3. Container Isolation

Docker provides process isolation:
- qBittorrent runs in isolated container
- Uses Gluetun's network namespace
- No direct internet access

### 4. File Permissions

Downloaded files inherit user permissions:
- Set `PUID` and `PGID` in `.env` to match your user
- Prevents permission issues and unauthorized access

### 5. WebUI Access

qBittorrent WebUI security:
- **Authentication:** Always enabled
- **Network restriction:** Configured via `LOCAL_SUBNET`
- **HTTPS:** Not enabled by default (consider using reverse proxy)

**Recommendation:** Use a reverse proxy (nginx, Traefik) with SSL/TLS for remote access.

---

## Security Hardening

### Advanced: Enable AppArmor/SELinux for Docker

**Ubuntu/Debian (AppArmor):**
```bash
# Check AppArmor status
sudo aa-status

# Docker uses AppArmor profiles by default
docker info | grep -i security
```

**Fedora/RHEL (SELinux):**
```bash
# Check SELinux status
sestatus

# Ensure Docker is using SELinux
docker info | grep -i security
```

### Advanced: Use Docker Secrets (Swarm Mode)

For production setups, consider Docker Swarm with secrets:
```bash
# Create secret
echo "your_vpn_password" | docker secret create vpn_password -

# Reference in docker-compose.yml
secrets:
  vpn_password:
    external: true
```

### Advanced: Network Segmentation

Isolate torrent stack on separate VLAN or subnet:
- Reduces attack surface
- Limits lateral movement if compromised

---

## Compliance and Legal

### DMCA and Copyright

This project is a tool for **legal torrenting** only:
- ✅ Legal: Open source software, public domain content, authorized distributions
- ❌ Illegal: Copyrighted material without permission

**Disclaimer:** Users are responsible for their own use. This project does not endorse or encourage copyright infringement.

### Privacy Laws

VPN usage may be subject to local laws:
- Check your jurisdiction's regulations
- Choose VPN providers with strong privacy policies
- Prefer providers in privacy-friendly jurisdictions (e.g., Mullvad in Sweden)

---

## Audit History

### Security Audits

No formal security audits have been conducted yet. If you're interested in sponsoring or conducting an audit, please contact the maintainers.

### Past Vulnerabilities

None reported yet.

---

## Contact

For security concerns:
- **Private reports:** Use [GitHub Security Advisories](https://github.com/ddmoney420/torrent-vpn-stack/security)
- **General questions:** Open a [GitHub Discussion](https://github.com/ddmoney420/torrent-vpn-stack/discussions)

---

## Acknowledgments

We thank the following individuals for responsibly disclosing vulnerabilities:

_(No vulnerabilities reported yet)_

If you report a vulnerability, you will be acknowledged here (unless you prefer anonymity).
