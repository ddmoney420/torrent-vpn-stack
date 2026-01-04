# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions CI/CD pipeline (`.github/workflows/ci.yml`)
  - ShellCheck linting for all bash scripts
  - YAML linting for Docker Compose files and workflows
  - Docker Compose configuration validation
  - Markdown linting for documentation files
- Markdownlint configuration (`.markdownlint.json`)
- CI status badge in README

### Fixed
- ShellCheck warnings in `scripts/setup.sh`:
  - Added shellcheck directive for unused RED color variable
  - Added `-r` flag to all `read` commands to properly handle backslashes
  - Quoted `$LOCAL_IP` variable to prevent word splitting
- ShellCheck warning in `scripts/verify-vpn.sh`:
  - Quoted URL with `${WEBUI_PORT}` variable expansion

### Changed
- All shell scripts now pass ShellCheck linting with zero warnings
- Documentation now passes markdownlint validation

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
