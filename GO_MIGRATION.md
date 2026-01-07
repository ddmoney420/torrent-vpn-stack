# Go-Native Migration Guide

## Overview

This project is evolving from a Docker-first architecture to a **Go-native cross-platform binary** with optional container support.

## Current Status: Phase 0 - Scaffolding Complete ✅

The initial Go project structure has been implemented as a foundation for the roadmap outlined in [Issue #18](https://github.com/ddmoney420/torrent-vpn-stack/issues/18).

### What's Implemented

**Project Structure:**
```
├── cmd/
│   ├── daemon/main.go     # Daemon entrypoint
│   └── cli/main.go        # CLI client
├── internal/
│   ├── api/server.go      # REST API server
│   ├── config/config.go   # Configuration management
│   ├── core/queue.go      # Job queue (skeleton)
│   ├── providers/         # Provider interface
│   └── vpn/              # VPN controller interface
├── docs/adr/             # Architecture Decision Records
├── .github/workflows/    # Go CI pipeline
├── Makefile              # Build targets
├── go.mod                # Go module definition
└── config.example.yaml   # Example configuration
```

**Build System:**
- ✅ Cross-platform Makefile (build, test, lint, release)
- ✅ GitHub Actions CI (test on Linux, macOS, Windows)
- ✅ Multi-platform release builds (linux/amd64, darwin/amd64, darwin/arm64, windows/amd64)
- ✅ golangci-lint configuration

**Core Interfaces:**
- ✅ `Provider` interface for pluggable download backends
- ✅ `VPN Controller` interface for VPN lifecycle management
- ✅ Job queue skeleton
- ✅ REST API with `/healthz` and `/version` endpoints

### Quick Start (Development)

```bash
# Install dependencies
make deps

# Build binaries
make build

# Run tests (once implemented)
make test

# Run linter
make lint

# Build for all platforms
make release

# Run daemon
make run-daemon

# Run CLI
./build/mediadownloader --help
```

### CLI Commands (Skeleton)

```bash
# Daemon management
mediadownloader daemon

# Job management
mediadownloader add <url>
mediadownloader list
mediadownloader status [job-id]
mediadownloader cancel <job-id>

# Provider info
mediadownloader providers

# VPN management
mediadownloader vpn status
mediadownloader vpn start
mediadownloader vpn stop
```

### What's Next: Phase 1 - MVP

See [Roadmap Issue #18](https://github.com/ddmoney420/torrent-vpn-stack/issues/18) for the full implementation plan.

**Phase 1 Goals (4 weeks):**
- HTTP download provider with resume/retry/checksum
- Functional job queue with persistence
- REST API with job management
- CLI integration
- Cross-platform builds

### Docker Stack (Current - Remains Functional)

The existing Docker Compose stack in the project root continues to work as-is. No changes to current functionality.

To use the Docker stack:
```bash
docker compose up -d
```

### Migration Timeline

**Now - Phase 0**: Go scaffolding ✅
**Next - Phase 1**: HTTP downloads + job queue (MVP)
**Future - Phase 2**: Provider plugins + BitTorrent
**Future - Phase 3**: VPN integration + kill-switch
**Future - Phase 4**: Advanced features (Web UI, Usenet, etc.)

See full timeline in [Issue #18](https://github.com/ddmoney420/torrent-vpn-stack/issues/18).

### Contributing to Go Development

1. **Setup Go 1.23+**
   ```bash
   # macOS
   brew install go

   # Linux
   sudo apt install golang-1.23  # or your package manager
   ```

2. **Development Workflow**
   ```bash
   # Create feature branch
   git checkout -b feature/your-feature

   # Make changes...

   # Run tests + linter
   make test
   make lint

   # Build
   make build

   # Commit (ensure CI passes)
   git commit -m "feat: your feature"
   ```

3. **Code Style**
   - Follow [Effective Go](https://go.dev/doc/effective_go)
   - Run `make fmt` before committing
   - Ensure `make lint` passes
   - Write tests for new functionality

### Questions?

See the comprehensive roadmap in [Issue #18](https://github.com/ddmoney420/torrent-vpn-stack/issues/18) or ask in Discussions.
