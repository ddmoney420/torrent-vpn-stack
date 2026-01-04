class TorrentVpnStack < Formula
  desc "Cross-platform Docker Compose stack for secure torrenting via VPN"
  homepage "https://github.com/ddmoney420/torrent-vpn-stack"
  url "https://github.com/ddmoney420/torrent-vpn-stack/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "efb998c1b2be0fba8f4a01341606e352376e4ac7fb603a14c62db33e017734fc"
  license "MIT"
  head "https://github.com/ddmoney420/torrent-vpn-stack.git", branch: "main"

  depends_on "docker"
  depends_on "docker-compose"

  def install
    # Install all project files to the Cellar
    prefix.install Dir["*"]

    # Create symlinks for commonly used scripts
    bin.install_symlink prefix/"scripts/setup.sh" => "torrent-vpn-setup"
    bin.install_symlink prefix/"scripts/verify-vpn.sh" => "torrent-vpn-verify"
    bin.install_symlink prefix/"scripts/check-leaks.sh" => "torrent-vpn-check-leaks"
    bin.install_symlink prefix/"scripts/backup.sh" => "torrent-vpn-backup"
    bin.install_symlink prefix/"scripts/restore.sh" => "torrent-vpn-restore"
    bin.install_symlink prefix/"scripts/benchmark-vpn.sh" => "torrent-vpn-benchmark"

    # Platform-specific backup automation symlinks
    if OS.mac?
      bin.install_symlink prefix/"scripts/setup-backup-automation.sh" => "torrent-vpn-setup-automation"
      bin.install_symlink prefix/"scripts/remove-backup-automation.sh" => "torrent-vpn-remove-automation"
    elsif OS.linux?
      bin.install_symlink prefix/"scripts/setup-backup-automation-linux.sh" => "torrent-vpn-setup-automation"
      bin.install_symlink prefix/"scripts/remove-backup-automation-linux.sh" => "torrent-vpn-remove-automation"
    end
  end

  def caveats
    <<~EOS
      Torrent VPN Stack has been installed to:
        #{prefix}

      Quick Start:
        1. Copy the example environment file:
           cp #{prefix}/.env.example #{prefix}/.env

        2. Run the interactive setup wizard:
           torrent-vpn-setup
           OR
           cd #{prefix} && ./scripts/setup.sh

        3. Start the stack:
           cd #{prefix}
           docker compose up -d

        4. Access qBittorrent Web UI:
           http://localhost:8080

      Available Commands:
        torrent-vpn-setup              - Interactive setup wizard
        torrent-vpn-verify             - Verify VPN connection
        torrent-vpn-check-leaks        - Check for IP/DNS leaks
        torrent-vpn-backup             - Backup configuration
        torrent-vpn-restore            - Restore from backup
        torrent-vpn-benchmark          - Benchmark VPN performance
        torrent-vpn-setup-automation   - Setup automated backups
        torrent-vpn-remove-automation  - Remove automated backups

      Documentation:
        README:       #{prefix}/README.md
        Architecture: #{prefix}/docs/architecture.md
        Backups:      #{prefix}/docs/backups.md
        Monitoring:   #{prefix}/docs/monitoring.md

      Platform-Specific Guides:
        macOS:   #{prefix}/docs/install-macos.md
        Linux:   #{prefix}/docs/install-linux.md
        Windows: #{prefix}/docs/install-windows.md (if using Homebrew on Linux for WSL)

      Requirements:
        - Docker Desktop (macOS) or Docker Engine (Linux)
        - VPN subscription (Mullvad, ProtonVPN, PIA, or others)
        - 8 GB RAM minimum (16 GB recommended)

      Support:
        Issues:      https://github.com/ddmoney420/torrent-vpn-stack/issues
        Discussions: https://github.com/ddmoney420/torrent-vpn-stack/discussions
    EOS
  end

  test do
    # Test that the main scripts are executable
    assert_predicate prefix/"scripts/setup.sh", :executable?
    assert_predicate prefix/"scripts/verify-vpn.sh", :executable?

    # Test that docker-compose.yml exists
    assert_predicate prefix/"docker-compose.yml", :exist?

    # Test that .env.example exists
    assert_predicate prefix/".env.example", :exist?

    # Test that symlinks work
    system bin/"torrent-vpn-setup", "--help"
  end
end
