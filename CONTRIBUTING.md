# Contributing to Torrent VPN Stack

Thank you for your interest in contributing to Torrent VPN Stack! This document provides guidelines and information for contributors.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Community](#community)

---

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

---

## How Can I Contribute?

### Reporting Bugs

Before submitting a bug report:
- Check the [existing issues](https://github.com/ddmoney420/torrent-vpn-stack/issues) to avoid duplicates
- Test with the latest version of the project
- Gather relevant information (OS, Docker version, VPN provider, logs)

When submitting a bug report, include:
- **Clear title** describing the issue
- **Steps to reproduce** the problem
- **Expected vs actual behavior**
- **Environment details:**
  - OS and version (Windows 10, Ubuntu 22.04, macOS 13, etc.)
  - Docker version (`docker --version`)
  - VPN provider
  - Relevant configuration (sanitized `.env` excerpt)
- **Logs:**
  ```bash
  docker logs gluetun
  docker logs qbittorrent
  ```

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md).

### Suggesting Enhancements

Enhancement suggestions are welcome! Before submitting:
- Check if the enhancement has already been suggested
- Clearly describe the problem and proposed solution
- Explain why this enhancement would be useful

Use the [Feature Request template](.github/ISSUE_TEMPLATE/feature_request.md).

### Contributing Code

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following our [Coding Standards](#coding-standards)
4. **Test your changes** on all supported platforms (if possible)
5. **Commit your changes:**
   ```bash
   git commit -m "Add feature: brief description"
   ```
6. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a Pull Request**

### Contributing Documentation

Documentation improvements are highly valued:
- Fix typos or unclear explanations
- Add examples or use cases
- Improve installation guides for specific platforms
- Translate documentation (future goal)

---

## Development Setup

### Prerequisites

- **Docker Desktop** (Windows/macOS) or **Docker Engine** (Linux)
- **Docker Compose** v2+
- **Git**
- **Text editor** (VS Code, Vim, etc.)
- **ShellCheck** (for bash script linting)
- **yamllint** (for YAML validation)

### Clone and Set Up

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/torrent-vpn-stack.git
cd torrent-vpn-stack

# Add upstream remote
git remote add upstream https://github.com/ddmoney420/torrent-vpn-stack.git

# Create .env from example
cp .env.example .env

# Edit .env with your VPN credentials (for testing)
nano .env
```

### Running Locally

```bash
# Start stack
docker compose up -d

# View logs
docker compose logs -f

# Stop stack
docker compose down
```

### Linting and Validation

```bash
# Lint shell scripts
shellcheck scripts/*.sh

# Lint YAML files
yamllint docker-compose.yml .github/workflows/*.yml

# Lint Markdown
markdownlint '**/*.md' --ignore node_modules

# Run all checks (same as CI)
./.github/workflows/ci.yml  # Review this file for exact commands
```

---

## Pull Request Process

### Before Submitting

- [ ] Test your changes on at least one platform (ideally all three: Windows, Linux, macOS)
- [ ] Ensure all scripts are executable (`chmod +x scripts/*.sh`)
- [ ] Lint your code (shellcheck, yamllint, markdownlint)
- [ ] Update documentation if needed
- [ ] Add or update tests if applicable
- [ ] Update `CHANGELOG.md` with your changes

### PR Guidelines

1. **Title:** Use a clear, descriptive title
   - ✅ Good: "Add support for AirVPN provider"
   - ❌ Bad: "Update files"

2. **Description:** Explain:
   - **What** changes were made
   - **Why** the changes were necessary
   - **How** the changes work
   - **Testing:** How you tested the changes

3. **Link related issues:**
   ```markdown
   Closes #123
   Relates to #456
   ```

4. **Keep PRs focused:** One feature or fix per PR
   - ✅ Good: One PR for Linux systemd support
   - ❌ Bad: One PR with systemd support + 5 unrelated fixes

5. **Commit messages:** Follow conventional commits format:
   ```
   type(scope): brief description

   Longer explanation if needed.

   Closes #123
   ```

   **Types:**
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation changes
   - `style:` Code style changes (formatting)
   - `refactor:` Code refactoring
   - `test:` Test additions or changes
   - `chore:` Maintenance tasks

### Review Process

- Maintainers will review your PR within a few days
- Address review feedback promptly
- All CI checks must pass before merging
- At least one approval is required for merge
- Maintainers may ask for changes or clarifications

---

## Coding Standards

### Shell Scripts (Bash)

- **Shebang:** Use `#!/usr/bin/env bash`
- **Error handling:** Use `set -euo pipefail` for strict mode
- **Quoting:** Always quote variables: `"${VAR}"`
- **Functions:** Use descriptive names and document complex functions
- **Comments:** Explain *why*, not *what*
- **ShellCheck:** Code must pass `shellcheck` with no errors

**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Function to check if Docker is running
is_docker_running() {
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker is not running"
        return 1
    fi
    return 0
}
```

### YAML Files

- **Indentation:** 2 spaces (no tabs)
- **Validation:** Must pass `yamllint`
- **Comments:** Explain non-obvious configurations

### Markdown Documentation

- **Headers:** Use ATX-style headers (`#`, `##`, `###`)
- **Code blocks:** Specify language for syntax highlighting
- **Line length:** Aim for 80-100 characters
- **Links:** Use reference-style links for readability

---

## Testing

### Manual Testing

Test your changes on all supported platforms if possible:

| Platform | Required Tests |
|----------|---------------|
| **Windows** | WSL 2, Git Bash, PowerShell scripts |
| **Linux** | Ubuntu, Debian, Fedora (if possible) |
| **macOS** | Intel and Apple Silicon (if available) |

### Testing Checklist

- [ ] VPN connection works
- [ ] Port forwarding works (if applicable)
- [ ] qBittorrent WebUI accessible
- [ ] Backup scripts work
- [ ] Monitoring dashboards work (if enabled)
- [ ] Scripts handle errors gracefully
- [ ] Cross-platform compatibility verified

### Automated Testing

Our CI pipeline runs on every push:
- ShellCheck for bash scripts
- yamllint for YAML files
- markdownlint for documentation
- Docker Compose validation

See `.github/workflows/ci.yml` for details.

---

## Documentation

### Documentation Structure

```
docs/
├── install-windows.md       # Windows installation guide
├── install-linux.md         # Linux installation guide
├── install-macos.md         # macOS installation guide
├── architecture.md          # System architecture
├── port-forwarding.md       # Port forwarding setup
├── monitoring.md            # Monitoring and observability
├── backups.md               # Backup and restore
├── provider-comparison.md   # VPN provider comparison
└── performance-tuning.md    # Performance optimization
```

### When to Update Documentation

- **New features:** Add documentation for new functionality
- **Breaking changes:** Update affected documentation with migration guides
- **Bug fixes:** If the bug affected documented behavior
- **Platform-specific changes:** Update relevant install guide

---

## Community

### Communication Channels

- **GitHub Issues:** Bug reports and feature requests
- **GitHub Discussions:** Q&A, ideas, general discussion
- **Pull Requests:** Code review and collaboration

### Getting Help

- Check [existing documentation](docs/)
- Search [closed issues](https://github.com/ddmoney420/torrent-vpn-stack/issues?q=is%3Aissue+is%3Aclosed)
- Ask in [GitHub Discussions](https://github.com/ddmoney420/torrent-vpn-stack/discussions)
- Open a new issue with the **Question** label

---

## Recognition

Contributors are recognized in:
- GitHub's built-in contributor graph
- Release notes (for significant contributions)
- `CHANGELOG.md` (for all contributions)

---

## License

By contributing to Torrent VPN Stack, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

## Questions?

If you have questions about contributing, feel free to:
- Open a [GitHub Discussion](https://github.com/ddmoney420/torrent-vpn-stack/discussions)
- Comment on a related issue
- Reach out to maintainers

Thank you for contributing! 🎉
