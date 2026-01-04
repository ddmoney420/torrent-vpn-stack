# Windows Installation Guide

Complete installation guide for Torrent VPN Stack on Windows 10/11.

---

## Prerequisites

### Required Software

1. **Docker Desktop for Windows**
   - Download: https://www.docker.com/products/docker-desktop/
   - Minimum version: 4.0+
   - Backend: WSL 2 (recommended) or Hyper-V

2. **Windows Subsystem for Linux (WSL 2)** - Recommended
   - Run in PowerShell (Administrator):
     ```powershell
     wsl --install
     ```
   - Or install manually: https://learn.microsoft.com/en-us/windows/wsl/install
   - Default distribution: Ubuntu (recommended)

3. **Git for Windows** (if not using WSL)
   - Download: https://git-scm.com/download/win
   - Includes Git Bash for running shell scripts

4. **PowerShell 5.1+** (included in Windows 10/11)
   - For backup automation scripts

### System Requirements

- **OS:** Windows 10 version 2004+ or Windows 11
- **RAM:** 8 GB minimum, 16 GB recommended
- **Disk:** 20 GB free space minimum
- **CPU:** 64-bit processor with virtualization support (Intel VT-x or AMD-V)

---

## Installation Methods

### Method 1: Using WSL 2 (Recommended)

WSL 2 provides the best Linux compatibility and performance.

#### 1. Install and Configure WSL

```powershell
# Install WSL with Ubuntu (default distribution)
wsl --install

# Restart your computer when prompted

# After restart, set up Ubuntu username/password
# Then update packages
wsl -e sudo apt update && sudo apt upgrade -y
```

#### 2. Install Docker Desktop

1. Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. During installation, ensure **"Use WSL 2 instead of Hyper-V"** is checked
3. After installation, open Docker Desktop settings:
   - **General** → Enable "Use the WSL 2 based engine"
   - **Resources → WSL Integration** → Enable your Ubuntu distribution

#### 3. Clone Repository (in WSL)

```bash
# Open WSL terminal
wsl

# Clone repository
cd ~
git clone https://github.com/ddmoney420/torrent-vpn-stack.git
cd torrent-vpn-stack
```

#### 4. Run Setup Wizard

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run interactive setup
./scripts/setup.sh
```

Follow the prompts to configure your VPN provider and preferences.

#### 5. Start the Stack

```bash
# Basic stack (VPN + qBittorrent)
docker compose up -d

# With port forwarding (Mullvad, ProtonVPN Plus, PIA)
docker compose --profile port-forwarding up -d

# With monitoring
docker compose --profile monitoring up -d

# All features
docker compose --profile port-forwarding --profile monitoring up -d
```

#### 6. Verify VPN Connection

```bash
./scripts/verify-vpn.sh
```

---

### Method 2: Using Git Bash (Without WSL)

If you prefer not to use WSL, you can run scripts via Git Bash.

#### 1. Install Prerequisites

1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Hyper-V backend)
2. Install [Git for Windows](https://git-scm.com/download/win)

#### 2. Clone Repository

```bash
# Open Git Bash
cd ~
git clone https://github.com/ddmoney420/torrent-vpn-stack.git
cd torrent-vpn-stack
```

#### 3. Run Setup

```bash
./scripts/setup.sh
```

#### 4. Start Stack (Git Bash)

```bash
docker compose up -d
```

**Note:** Some scripts may have limited functionality in Git Bash compared to WSL.

---

## Backup Automation (Windows-Specific)

### Automated Backups with Task Scheduler

The Windows version uses **Task Scheduler** for automated backups.

#### Setup Automated Backups

**Option 1: Using WSL (Recommended)**

```powershell
# Run in PowerShell as Administrator
cd $HOME\torrent-vpn-stack
.\scripts\setup-backup-automation.ps1 -Shell WSL
```

**Option 2: Using Git Bash**

```powershell
# Run in PowerShell as Administrator
cd $HOME\torrent-vpn-stack
.\scripts\setup-backup-automation.ps1 -Shell GitBash
```

#### Customize Backup Schedule

```powershell
# Backup at 2 AM instead of 3 AM
.\scripts\setup-backup-automation.ps1 -BackupHour 2

# Keep backups for 14 days
.\scripts\setup-backup-automation.ps1 -RetentionDays 14

# Custom backup location
.\scripts\setup-backup-automation.ps1 -BackupDir "D:\Backups\torrent-vpn-stack"
```

#### Manage Scheduled Task

```powershell
# View task status
Get-ScheduledTask -TaskName "TorrentVPNStackBackup"

# Run backup manually
Start-ScheduledTask -TaskName "TorrentVPNStackBackup"

# Disable backups
.\scripts\remove-backup-automation.ps1
```

#### Manual Backups

```bash
# In WSL or Git Bash
./scripts/backup.sh
```

---

## Accessing Services

### From Windows Host

All services are accessible from Windows at `localhost`:

- **qBittorrent Web UI:** http://localhost:8080
  - Default credentials: `admin` / `adminpass` (change in `.env`)

- **Grafana (if monitoring enabled):** http://localhost:3000
  - Default credentials: `admin` / `admin`

- **Prometheus (if monitoring enabled):** http://localhost:9090

### Network Configuration

Windows users may need to allow Docker through the Windows Firewall:

1. Open **Windows Defender Firewall** → **Advanced Settings**
2. **Inbound Rules** → **New Rule**
3. Allow port **8080** (qBittorrent)
4. Repeat for other services if needed

---

## File Paths

### WSL File System

- **WSL Ubuntu files (from Windows):** `\\wsl$\Ubuntu\home\<username>\torrent-vpn-stack`
- **Windows C: drive (from WSL):** `/mnt/c/`
- **Downloads:** Configure in `.env` using WSL paths (`/home/<username>/Downloads/torrents`)

### Windows Paths

If using Git Bash without WSL:
- **Project:** `C:\Users\<username>\torrent-vpn-stack`
- **Downloads:** `C:\Users\<username>\Downloads\torrents`

---

## Troubleshooting

### Docker Desktop Not Starting

**Error:** "Docker Desktop starting..."

**Solutions:**
1. Enable WSL 2:
   ```powershell
   wsl --set-default-version 2
   ```

2. Enable virtualization in BIOS:
   - Restart → Enter BIOS (usually F2, Del, or F12)
   - Enable **Intel VT-x** or **AMD-V**

3. Enable Hyper-V (if not using WSL 2):
   ```powershell
   # Run as Administrator
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```

### WSL "File not found" Errors

**Error:** `$'\r': command not found` or similar

**Solution:** Convert line endings to Unix format:
```bash
# In WSL
sudo apt install dos2unix
dos2unix scripts/*.sh
```

### Permission Denied Errors

**Error:** `Permission denied` when running scripts

**Solution:** Make scripts executable:
```bash
chmod +x scripts/*.sh
```

### VPN Connection Fails

**Error:** Gluetun container constantly restarting

**Solutions:**
1. Check VPN credentials in `.env`
2. Verify VPN provider configuration (see [Provider Comparison](provider-comparison.md))
3. Check Gluetun logs:
   ```bash
   docker logs gluetun
   ```

### Cannot Access qBittorrent WebUI

**Error:** `localhost:8080` not accessible

**Solutions:**
1. Verify container is running:
   ```bash
   docker ps
   ```

2. Check `LOCAL_SUBNET` in `.env` matches your network:
   ```bash
   # From WSL
   ip addr show eth0 | grep inet
   ```

3. Restart Docker containers:
   ```bash
   docker compose down
   docker compose up -d
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

3. For ProtonVPN, ensure `VPN_PORT_FORWARDING_PROVIDER=protonvpn` in `.env`

---

## Performance Tuning

### Docker Desktop Resource Allocation

1. Open **Docker Desktop** → **Settings** → **Resources**
2. Recommended settings:
   - **CPUs:** 4 cores (minimum 2)
   - **Memory:** 4 GB (minimum 2 GB)
   - **Disk:** 20 GB+

### WSL 2 Performance

Create/edit `%USERPROFILE%\.wslconfig`:

```ini
[wsl2]
memory=4GB
processors=4
swap=2GB
localhostForwarding=true
```

Restart WSL:
```powershell
wsl --shutdown
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
```

### Remove Scheduled Backup Task

```powershell
# Run in PowerShell as Administrator
.\scripts\remove-backup-automation.ps1
```

### Uninstall Docker Desktop

1. Uninstall via **Settings** → **Apps** → **Docker Desktop**
2. Optionally remove WSL:
   ```powershell
   wsl --unregister Ubuntu
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

- [Docker Desktop for Windows Documentation](https://docs.docker.com/desktop/install/windows-install/)
- [WSL 2 Installation Guide](https://learn.microsoft.com/en-us/windows/wsl/install)
- [Windows Firewall Configuration](https://support.microsoft.com/en-us/windows/windows-firewall-and-network-protection-in-windows-security-87fc52bd-d8f1-f0ec-0e4b-c0b3fa3b36ad)
- [Gluetun VPN Client](https://github.com/qdm12/gluetun)
