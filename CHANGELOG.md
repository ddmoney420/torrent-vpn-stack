# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Cross-Platform Compatibility (Windows, Linux, macOS)** (Issue #13)
  - **Full Windows Support:**
    - Added Windows PowerShell backup automation scripts (`setup-backup-automation.ps1`, `remove-backup-automation.ps1`)
    - Windows Task Scheduler integration for automated backups
    - Support for both WSL 2 and Git Bash environments
    - Comprehensive Windows installation guide (`docs/install-windows.md`)
  - **Full Linux Support:**
    - Added Linux backup automation scripts (`setup-backup-automation-linux.sh`, `remove-backup-automation-linux.sh`)
    - systemd timer support (preferred method)
    - cron fallback support
    - Comprehensive Linux installation guide (`docs/install-linux.md`)
    - Support for Ubuntu, Debian, Fedora, Arch Linux, and derivatives
  - **Enhanced macOS Support:**
    - Maintained existing launchd automation
    - Updated macOS installation guide (`docs/install-macos.md`)
    - Full Apple Silicon (M1/M2/M3) and Intel support
  - **Platform Detection:**
    - Added `scripts/detect-platform.sh` utility
    - Auto-detects Windows (Git Bash/WSL), Linux, macOS
    - Platform-specific path handling (XDG Base Directory spec on Linux, Library on macOS, AppData on Windows)
    - Cross-platform network detection (local IP and subnet)
  - **Cross-Platform Scripts:**
    - Updated `scripts/setup.sh` to use platform detection
    - Cross-platform sed compatibility (macOS vs Linux/Windows)
    - Network detection works on all platforms
  - **Public Repository Preparation:**
    - Added `LICENSE` (MIT License)
    - Added `CONTRIBUTING.md` with contribution guidelines
    - Added `SECURITY.md` with security policy and responsible disclosure process
    - Added `CODE_OF_CONDUCT.md` for community standards
    - Added GitHub issue templates (bug report, feature request, question)
    - Added GitHub pull request template
    - Updated README with platform badges, cross-platform information, and contributing section
  - **CI/CD Enhancements:**
    - Added cross-platform testing in GitHub Actions
    - Matrix builds on Ubuntu, Windows, macOS
    - Platform detection validation
    - Script syntax validation on all platforms
  - **Documentation:**
    - Three comprehensive platform-specific installation guides
    - Platform-specific troubleshooting sections
    - Backup automation instructions for each platform
    - Firewall configuration guides (UFW, firewalld, Windows Firewall)

### Changed

- README now reflects cross-platform support (was macOS-only)
- Setup wizard now auto-detects platform and uses appropriate commands
- All scripts now compatible with Windows, Linux, and macOS

- **Multi-VPN Provider Testing and Performance Benchmarking** (Issue #11)
  - Added provider configuration examples (`examples/providers/`):
    - Mullvad (port forwarding, WireGuard)
    - ProtonVPN (port forwarding on Plus plans)
    - NordVPN (no port forwarding)
  - Added VPN performance benchmark script (`scripts/benchmark-vpn.sh`):
    - Tests download speed, latency, DNS resolution
    - Measures CPU and memory usage
    - Outputs JSON results for comparison
  - Added comprehensive provider comparison documentation (`docs/provider-comparison.md`):
    - Detailed comparison table (port forwarding, speed, privacy, pricing)
    - Provider-specific analysis and recommendations
    - Real-world performance expectations
    - Port forwarding impact analysis
  - Added performance tuning guide (`docs/performance-tuning.md`):
    - WireGuard vs OpenVPN comparison
    - Docker resource optimization
    - qBittorrent connection settings
    - Provider-specific tuning tips
    - Troubleshooting slow speeds
  - Updated README with VPN provider selection section
    - Quick comparison table
    - Recommendations for torrenting
    - Links to detailed documentation
- **Automated Backup Solution** (Issue #9)
  - Added `scripts/backup.sh` for manual and automated backups
  - Added `scripts/restore.sh` for interactive and command-line restore
  - Added `scripts/setup-backup-automation.sh` for macOS launchd integration
  - Added `scripts/remove-backup-automation.sh` to uninstall automation
  - Added launchd plist template for scheduled backups
  - Backup features:
    - Backs up Docker volumes (qBittorrent, Gluetun, optionally monitoring data)
    - Compressed tar.gz archives with timestamps
    - Automatic backup rotation based on retention policy (default: 7 days)
    - Dry-run mode for testing
    - Verbose logging
  - Restore features:
    - Interactive backup selection
    - Safety backup before restore
    - Automatic container stop/start
    - Confirmation prompts
  - Automation features (macOS):
    - Daily scheduled backups via launchd
    - Configurable schedule (default: 3 AM)
    - Automatic log rotation
  - Comprehensive backup documentation (`docs/backups.md`)
  - Updated README with backups section
  - Added backup configuration variables to `.env.example`
- **Monitoring and Observability Stack** (Issue #7)
  - Added Prometheus for metrics collection and storage (30-day retention)
  - Added Grafana for metrics visualization and dashboards
  - Added qBittorrent Exporter for torrent-specific metrics (speeds, peers, ratio)
  - Added cAdvisor for container resource monitoring (CPU, memory, network)
  - Three pre-configured Grafana dashboards:
    - System Dashboard: Container resource usage (CPU, memory, network I/O)
    - qBittorrent Dashboard: Torrent metrics (speeds, total transferred, ratio)
    - VPN Dashboard: Gluetun status and uptime
  - Prometheus configuration with scrape targets for all exporters
  - Grafana datasource auto-provisioning for Prometheus
  - Comprehensive monitoring documentation (`docs/monitoring.md`)
  - Monitoring services use Docker Compose profiles (`--profile monitoring`)
  - Updated README with monitoring section and quick start guide
  - Added monitoring configuration variables to `.env.example`
- **Port Forwarding Automation** (Issue #5)
  - Enabled `gluetun-qbittorrent-port-manager` service via Docker Compose profiles
  - Automatic port synchronization from Gluetun VPN to qBittorrent
  - Added `PORT_SYNC_INTERVAL` configuration variable (default: 300 seconds)
  - Comprehensive port forwarding documentation (`docs/port-forwarding.md`)
  - Provider-specific setup guides for Mullvad, ProtonVPN, and Private Internet Access (PIA)
  - Troubleshooting section for common port forwarding issues
  - Updated README with port forwarding setup instructions
  - Enhanced `.env.example` with detailed port forwarding configuration comments
- GitHub Actions CI/CD pipeline (`.github/workflows/ci.yml`)
  - ShellCheck linting for all bash scripts
  - YAML linting for Docker Compose files and workflows
  - Docker Compose configuration validation
  - Markdown linting for documentation files
- Markdownlint configuration (`.markdownlint.json`)
- Yamllint configuration (`.yamllint`)
- CI status badge in README

### Fixed

- ShellCheck warnings in `scripts/setup.sh`:
  - Added shellcheck directive for unused RED color variable
  - Added `-r` flag to all `read` commands to properly handle backslashes
  - Quoted `$LOCAL_IP` variable to prevent word splitting
- ShellCheck warning in `scripts/verify-vpn.sh`:
  - Quoted URL with `${WEBUI_PORT}` variable expansion

### Changed

- Port sync service now uses Docker Compose profiles (`--profile port-forwarding`) instead of manual uncommenting
- Updated port configuration documentation to include dynamic VPN-assigned ports
- All shell scripts now pass ShellCheck linting with zero warnings
- Documentation now passes markdownlint validation
- Updated CI workflow to use `docker compose` instead of `docker-compose`

## [1.0.0] - 2026-01-03

### Added

#### Core Infrastructure
- Docker Compose stack with Gluetun VPN gateway and qBittorrent torrent client
- Kill switch implementation via Docker network namespace sharing (`network_mode: service:gluetun`)
- DNS-over-TLS (DoT) configuration for leak protection
- IPv6 disabled by default to prevent dual-stack leaks
- Gluetun firewall with LOCAL_SUBNET whitelist for LAN access
- Health checks and automatic restart policies
- Persistent storage via Docker volumes and bind mounts

#### Configuration
- `.env.example` - Comprehensive configuration template with inline documentation
- Support for WireGuard and OpenVPN protocols
- Multi-VPN provider support (Mullvad, ProtonVPN, NordVPN, Surfshark, PIA, etc.)
- Port forwarding configuration (optional, provider-dependent)
- macOS-optimized PUID/PGID settings

#### Scripts
- `scripts/setup.sh` - Interactive setup wizard with auto-detection
  - Network subnet auto-discovery
  - PUID/PGID detection for macOS
  - Password masking for sensitive inputs
  - macOS-specific compatibility (sed syntax, network commands)
- `scripts/verify-vpn.sh` - 7-step VPN verification script
  - Container health checks
  - VPN IP verification
  - Kill switch verification
  - DNS leak detection
  - IPv6 leak detection
  - Web UI accessibility check
- `scripts/check-leaks.sh` - Comprehensive 5-test leak detection suite
  - IP leak test (real IP vs VPN IP comparison)
  - DNS leak test (verify DNS servers)
  - IPv6 leak test (external connectivity check)
  - Multi-source IP verification (consistency across services)
  - Optional kill switch test (VPN disconnect simulation)

#### Documentation
- `README.md` - Comprehensive user documentation (95KB+)
  - Features list with security, usability, and compatibility details
  - Prerequisites and system requirements
  - Quick start guide (5 steps)
  - Detailed setup guide (7 steps)
  - Configuration reference table
  - Port configuration details
  - Security notes (kill switch, DNS, IPv6, firewall)
  - Troubleshooting guide (6+ common issues with solutions)
  - FAQ (13+ questions)
  - Architecture diagram (ASCII art)
  - Usage instructions
  - Research sources
- `docs/architecture.md` - Deep-dive architecture documentation
  - System architecture diagrams
  - Network architecture with kill switch explanation
  - Security layers (defense in depth)
  - Data flow diagrams
  - Container interaction sequence
  - Port forwarding architecture
  - Persistence & storage patterns
  - Failure modes & recovery procedures
  - Network namespace deep dive
- `.gitignore` - Protects `.env` and sensitive files from version control

### Security
- Non-root containers with minimal capabilities (NET_ADMIN only)
- Kill switch prevents traffic leaks if VPN disconnects
- DNS-over-TLS (Cloudflare 1.1.1.1) prevents ISP DNS snooping
- IPv6 disabled to prevent dual-stack IP leaks
- Firewall rules block all non-VPN traffic except LOCAL_SUBNET
- Web UI password protection
- Credential protection via `.gitignore`

### Compatibility
- macOS (Apple Silicon M1/M2/M3 and Intel)
- Docker Desktop for Mac
- All major VPN providers supported by Gluetun
- WireGuard (recommended) and OpenVPN protocols

### Research & Design
- Analyzed 12,000+ GitHub stars across similar projects
- Identified common failure modes (DNS leaks, port conflicts, routing issues)
- Documented best practices from high-star repositories
- Implemented differentiating enhancements:
  - Interactive setup wizard with auto-detection
  - Comprehensive leak testing (5 different tests)
  - macOS-optimized scripts and documentation
  - Kill switch verification capability
  - Multiple IP source verification
  - Extensive troubleshooting guide

[1.0.0]: https://github.com/ddmoney420/torrent-vpn-stack/releases/tag/v1.0.0
