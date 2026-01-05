# Linux Installation Guide

Complete installation guide for Torrent VPN Stack on Linux distributions.

---

## Prerequisites

### System Requirements

- **OS:** Ubuntu 20.04+, Debian 11+, Fedora 35+, Arch Linux, or other modern Linux distributions
- **RAM:** 2 GB minimum, 4 GB recommended
- **Disk:** 10 GB free space minimum
- **CPU:** 64-bit processor

### Required Software

- **Docker Engine** (20.10+)
- **Docker Compose** v2 (included with Docker Engine)
- **Git**
- **Bash** (4.0+)

---

## Installation by Distribution

### Ubuntu / Debian

#### 1. Install Docker Engine

```bash
# Update package index
sudo apt update

# Install dependencies
sudo apt install -y ca-certificates curl gnupg

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to docker group (avoids needing sudo)
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

#### 2. Verify Docker Installation

```bash
# Check Docker version
docker --version
docker compose version

# Test Docker (may require logout/login first)
docker run hello-world
```

---

### Fedora / RHEL / CentOS

#### 1. Install Docker Engine

```bash
# Remove old Docker versions
sudo dnf remove docker docker-client docker-client-latest docker-common \
  docker-latest docker-latest-logrotate docker-logrotate docker-selinux \
  docker-engine-selinux docker-engine

# Install Docker repository
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo

# Install Docker Engine
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

---

### Arch Linux / Manjaro

#### 1. Install Docker Engine

```bash
# Install Docker
sudo pacman -Syu docker docker-compose

# Start and enable Docker
sudo systemctl start docker.service
sudo systemctl enable docker.service

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in
```

---

## Setup Torrent VPN Stack

### 1. Clone Repository

```bash
cd ~
git clone https://github.com/ddmoney420/torrent-vpn-stack.git
cd torrent-vpn-stack
```

### 2. Run Interactive Setup Wizard

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run setup wizard
./scripts/setup.sh
```

The wizard will guide you through:
- VPN provider selection and credentials
- Network configuration
- Downloads directory setup
- Optional features (port forwarding, monitoring)

### 3. Start the Stack

```bash
# Basic stack (VPN + qBittorrent)
docker compose up -d

# With port forwarding (Mullvad, ProtonVPN Plus, PIA)
docker compose --profile port-forwarding up -d

# With monitoring (Prometheus + Grafana)
docker compose --profile monitoring up -d

# All features
docker compose --profile port-forwarding --profile monitoring up -d
```

### 4. Verify VPN Connection

```bash
./scripts/verify-vpn.sh
```

Expected output:
```
✓ VPN connection active
✓ IP address: 123.45.67.89 (VPN provider IP)
✓ DNS leak test: PASSED
```

---

## Backup Automation

The Linux version supports both **systemd timers** (preferred) and **cron** (fallback).

### Automated Backups with systemd (Recommended)

```bash
# Set up daily backups at 3 AM (runs as your user, no sudo needed)
./scripts/setup-backup-automation-linux.sh

# Customize schedule
./scripts/setup-backup-automation-linux.sh --hour 2 --retention 14
```

#### Manage systemd Timer

```bash
# View timer status
systemctl --user status torrent-vpn-backup.timer

# Check next run time
systemctl --user list-timers torrent-vpn-backup.timer

# Run backup manually
systemctl --user start torrent-vpn-backup.service

# View logs
journalctl --user -u torrent-vpn-backup.service

# Disable automation
./scripts/remove-backup-automation-linux.sh
```

### Automated Backups with cron (Fallback)

If systemd is not available:

```bash
# Set up cron job
./scripts/setup-backup-automation-linux.sh --method cron

# Verify cron job
crontab -l
```

### Manual Backups

```bash
# Run backup manually
./scripts/backup.sh

# Custom backup location
BACKUP_DIR=~/my-backups ./scripts/backup.sh

# Keep backups for 14 days
BACKUP_RETENTION_DAYS=14 ./scripts/backup.sh
```

---

## Accessing Services

All services are accessible at `localhost` or your server IP:

- **qBittorrent Web UI:** http://localhost:8080
  - Default credentials: `admin` / `adminpass` (change in `.env`)

- **Grafana (if monitoring enabled):** http://localhost:3000
  - Default credentials: `admin` / `admin`

- **Prometheus (if monitoring enabled):** http://localhost:9090

---

## Firewall Configuration

### UFW (Ubuntu/Debian)

If using UFW firewall:

```bash
# Allow qBittorrent WebUI (from local network only)
sudo ufw allow from 192.168.1.0/24 to any port 8080

# Allow Grafana (optional)
sudo ufw allow 3000/tcp

# Reload firewall
sudo ufw reload
```

### firewalld (Fedora/RHEL)

```bash
# Allow qBittorrent WebUI
sudo firewall-cmd --permanent --add-port=8080/tcp

# Allow Grafana (optional)
sudo firewall-cmd --permanent --add-port=3000/tcp

# Reload firewall
sudo firewall-cmd --reload
```

---

## Systemd Service (Optional)

To start the stack automatically on boot:

### Create systemd Service

Create `/etc/systemd/system/torrent-vpn-stack.service`:

```ini
[Unit]
Description=Torrent VPN Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/YOUR_USERNAME/torrent-vpn-stack
ExecStart=/usr/bin/docker compose --profile port-forwarding up -d
ExecStop=/usr/bin/docker compose down
User=YOUR_USERNAME
Group=YOUR_USERNAME

[Install]
WantedBy=multi-user.target
```

**Replace `YOUR_USERNAME` with your actual username.**

### Enable Service

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable on boot
sudo systemctl enable torrent-vpn-stack.service

# Start now
sudo systemctl start torrent-vpn-stack.service

# Check status
sudo systemctl status torrent-vpn-stack.service
```

---

## Troubleshooting

### Permission Denied (Docker)

**Error:** `permission denied while trying to connect to the Docker daemon`

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, OR run:
newgrp docker

# Verify
docker ps
```

### VPN Connection Fails

**Error:** Gluetun container constantly restarting

**Solutions:**

1. Check VPN credentials in `.env`:
   ```bash
   cat .env | grep VPN
   ```

2. View Gluetun logs:
   ```bash
   docker logs gluetun
   ```

3. Verify VPN provider configuration:
   - See [Provider Comparison](provider-comparison.md)

4. Test network connectivity:
   ```bash
   docker exec gluetun ping -c 3 8.8.8.8
   ```

### Cannot Access qBittorrent WebUI

**Error:** `localhost:8080` not accessible

**Solutions:**

1. Verify containers are running:
   ```bash
   docker ps
   ```

2. Check `LOCAL_SUBNET` in `.env` matches your network:
   ```bash
   ip addr show | grep inet
   # Update LOCAL_SUBNET in .env accordingly
   ```

3. Check firewall rules:
   ```bash
   # UFW
   sudo ufw status

   # firewalld
   sudo firewall-cmd --list-all
   ```

4. Restart stack:
   ```bash
   docker compose down
   docker compose up -d
   ```

5. **"Unauthorized" error instead of login page:**
   ```bash
   # Stop qBittorrent
   docker compose stop qbittorrent

   # Disable host header validation
   docker run --rm -v torrent-vpn-stack_qbittorrent-config:/config alpine sh -c '
   echo "WebUI\HostHeaderValidation=false" >> /config/qBittorrent/qBittorrent.conf'

   # Restart
   docker compose start qbittorrent
   ```

### Downloads Path Error

**Error:** Volume mount fails or "path not found"

**Solution:** Use absolute paths in `.env` (tilde `~` expansion may fail):
```bash
# Wrong:
DOWNLOADS_PATH=~/Downloads/torrents

# Correct:
DOWNLOADS_PATH=/home/yourusername/Downloads/torrents
```

### Port Forwarding Not Working

**Error:** No forwarded port assigned

**Solutions:**

1. Verify your VPN provider supports port forwarding:
   - ✅ Mullvad, ProtonVPN Plus, PIA
   - ❌ NordVPN, Surfshark, ExpressVPN

2. Enable port forwarding profile:
   ```bash
   docker compose --profile port-forwarding up -d
   ```

3. For ProtonVPN, ensure `.env` has:
   ```
   VPN_PORT_FORWARDING_PROVIDER=protonvpn
   ```

4. Check port sync logs:
   ```bash
   docker logs gluetun-qbittorrent-sync
   ```

### systemd Timer Not Running

**Error:** Backups not running automatically

**Solutions:**

1. Check timer status:
   ```bash
   systemctl --user status torrent-vpn-backup.timer
   ```

2. Enable linger (allows user services to run when not logged in):
   ```bash
   sudo loginctl enable-linger $USER
   ```

3. View service logs:
   ```bash
   journalctl --user -u torrent-vpn-backup.service -n 50
   ```

---

## Performance Tuning

### Docker Resource Limits

Edit `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

Restart Docker:
```bash
sudo systemctl restart docker
```

### System Optimization

```bash
# Increase file descriptor limits
echo "fs.file-max = 100000" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Optimize network settings
echo "net.core.rmem_max = 134217728" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 134217728" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

See [Performance Tuning Guide](performance-tuning.md) for more optimizations.

---

## Uninstallation

### Remove Stack

```bash
# Stop and remove containers
docker compose down

# Remove volumes (WARNING: deletes all data)
docker volume rm torrent-vpn-stack_gluetun-config torrent-vpn-stack_qbittorrent-config

# Remove images (optional)
docker image rm qmcgaw/gluetun linuxserver/qbittorrent
```

### Remove Backup Automation

```bash
# systemd
./scripts/remove-backup-automation-linux.sh --method systemd

# cron
./scripts/remove-backup-automation-linux.sh --method cron

# Both
./scripts/remove-backup-automation-linux.sh
```

### Uninstall Docker (Optional)

**Ubuntu/Debian:**
```bash
sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker /var/lib/containerd
```

**Fedora:**
```bash
sudo dnf remove docker-ce docker-ce-cli containerd.io
sudo rm -rf /var/lib/docker /var/lib/containerd
```

---

## Next Steps

- [Configure VPN Provider](provider-comparison.md)
- [Set Up Port Forwarding](port-forwarding.md)
- [Enable Monitoring](monitoring.md)
- [Performance Tuning](performance-tuning.md)
- [Backup and Restore](backups.md)

---

## Additional Resources

- [Docker Engine Installation (Official)](https://docs.docker.com/engine/install/)
- [Docker Post-Installation Steps](https://docs.docker.com/engine/install/linux-postinstall/)
- [systemd Timers](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [Gluetun VPN Client](https://github.com/qdm12/gluetun)
