# Chocolatey Package Troubleshooting

## Common Installation Issues

### "Docker is not installed or not in PATH"

**Symptom:**
```
ERROR: Docker is not installed or not in PATH

Please install Docker Desktop first:
  1. Download from: https://www.docker.com/products/docker-desktop
  ...
```

**Cause:** Docker Desktop is not installed on your system.

**Solution:**

**Option 1: Install Docker Desktop Manually**
1. Download from: https://www.docker.com/products/docker-desktop
2. Install Docker Desktop
3. Start Docker Desktop and wait for it to be ready (whale icon in system tray should be stable)
4. Run installation again: `choco install torrent-vpn-stack --force`

**Option 2: Install via Chocolatey**
```powershell
# Install Docker Desktop via Chocolatey
choco install docker-desktop -y

# Wait for Docker to start (check system tray)
# Then install torrent-vpn-stack
choco install torrent-vpn-stack -y
```

---

### "Docker is installed but not running"

**Symptom:**
```
WARNING: Docker is installed but not running

Please start Docker Desktop and wait for it to be ready, then run:
  choco install torrent-vpn-stack --force
```

**Cause:** Docker Desktop is installed but the Docker daemon is not running.

**Solution:**
1. **Start Docker Desktop**:
   - Find Docker Desktop in Start Menu
   - Click to launch
   - Wait for the whale icon in system tray to stop animating

2. **Verify Docker is ready**:
   ```powershell
   docker version
   ```
   Should show both Client and Server versions

3. **Reinstall the package**:
   ```powershell
   choco install torrent-vpn-stack --force
   ```

---

### Windows Server Installation

**Symptom:**
```
WARNING: Detected Windows Server installation

This package is designed for Windows 10/11 desktop and may not work on
Windows Server due to Docker Desktop requirements.
```

**Cause:** Docker Desktop is not supported on Windows Server.

**Solution:**

**For Windows Server users**, use manual installation instead:

1. **Install Docker Engine for Windows Server**:
   - Follow: https://docs.docker.com/engine/install/

2. **Clone the repository manually**:
   ```powershell
   git clone https://github.com/ddmoney420/torrent-vpn-stack.git
   cd torrent-vpn-stack
   ```

3. **Follow the manual setup guide**:
   - See: https://github.com/ddmoney420/torrent-vpn-stack

**Note:** The Chocolatey package is designed for Windows 10/11 desktop environments only.

---

### "Git Bash is required but not found"

**Symptom:**
```
ERROR: Git Bash is required but not found in PATH
Please install Git for Windows: https://git-scm.com/download/win
```

**Cause:** Bash scripts (setup, verify, etc.) require Git Bash to run on Windows.

**Solution:**

**Option 1: Install Git for Windows**
```powershell
choco install git -y
```

**Option 2: Manual Download**
1. Download from: https://git-scm.com/download/win
2. Install with default options (ensure "Git Bash" is selected)
3. Open a new terminal (to refresh PATH)
4. Try running the command again

---

## Package Dependency Information

### Why doesn't the package auto-install Docker?

**Short answer:** Docker Desktop installation can fail on certain environments (especially Windows Server), and it's better to check for Docker and provide clear instructions than to have a silent failure.

**Details:**
- **Previous version (v1.0.0 initial)**: Had hard dependency on `docker-desktop`
- **Issue**: Failed automated tests on Windows Server (Docker Desktop not supported)
- **Fix (v1.0.0 resubmitted)**: Removed dependency, added pre-install checks

**Benefits of current approach:**
- ✅ Clear error messages when Docker is missing
- ✅ Works on Windows 10/11 where users typically already have Docker
- ✅ Provides helpful install instructions
- ✅ Doesn't fail silently
- ✅ Users can choose how to install Docker (manual vs Chocolatey)

---

## Version History

### v1.0.0 (Resubmitted - 2026-01-04)

**Changes from initial submission:**
- Removed hard `docker-desktop` dependency
- Added Windows Server detection
- Added Docker installed/running checks
- Added helpful error messages with install instructions

**Why the change?**
Initial submission failed automated tests on Windows Server 2019 because Docker Desktop doesn't support Windows Server. The fix makes the package more robust by checking for Docker in the install script and providing clear guidance.

**Test failure report:** https://gist.github.com/choco-bot/a987a2f67dd82142ea3746720ababf25

---

## Advanced Troubleshooting

### Verify Package Installation

```powershell
# Check if package is installed
choco list --local-only torrent-vpn-stack

# View installation directory
dir $env:ProgramData\torrent-vpn-stack

# Test commands are available
torrent-vpn-setup --help
```

### Reinstall Package

```powershell
# Uninstall
choco uninstall torrent-vpn-stack -y

# Reinstall
choco install torrent-vpn-stack -y
```

### Check Docker Requirements

```powershell
# Verify Docker is installed
docker version

# Verify Docker Compose
docker compose version

# Test Docker is working
docker run hello-world
```

---

## Getting Help

If you encounter issues not covered here:

1. **Check the main repository issues**: https://github.com/ddmoney420/torrent-vpn-stack/issues
2. **Check Chocolatey package page**: https://community.chocolatey.org/packages/torrent-vpn-stack
3. **Review installation guides**:
   - Windows Guide: `docs/install-windows.md`
   - Quick Start: `QUICKSTART.md`
4. **Create an issue**: Include:
   - Windows version (run: `winver`)
   - Docker version (run: `docker version`)
   - Full error message
   - Output of: `choco list --local-only`

---

## Related Documentation

- **Main README**: https://github.com/ddmoney420/torrent-vpn-stack
- **Windows Installation Guide**: `docs/install-windows.md`
- **Quick Start Guide**: `QUICKSTART.md`
- **Chocolatey Package Source**: https://github.com/ddmoney420/torrent-vpn-stack/tree/main/packaging/chocolatey
