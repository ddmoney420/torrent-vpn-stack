# Post-Release Publishing Guide

## 📦 v1.0.0 Release Status

✅ **GitHub Release**: Published at https://github.com/ddmoney420/torrent-vpn-stack/releases/tag/v1.0.0
✅ **Git Tag**: v1.0.0 created and pushed
✅ **CHANGELOG**: Updated with all v1.0.0 features
✅ **SHA256 Checksums**: Calculated and updated in all package files
✅ **Package Files**: Ready for publication

## 🎯 Next Steps: Publish to Package Repositories

### 1. Homebrew Tap Repository

**Status**: Ready to publish
**Installation will be**: `brew install ddmoney420/torrent-vpn-stack/torrent-vpn-stack`

**Steps**:

1. **Create Tap Repository**
   ```bash
   # On GitHub, create a new public repository
   # Name: homebrew-torrent-vpn-stack
   # Description: Homebrew tap for Torrent VPN Stack
   ```

2. **Clone and Setup**
   ```bash
   git clone https://github.com/ddmoney420/homebrew-torrent-vpn-stack.git
   cd homebrew-torrent-vpn-stack
   ```

3. **Copy Formula**
   ```bash
   # Copy the formula to the tap repository root
   cp /path/to/torrent-vpn-stack/packaging/homebrew/torrent-vpn-stack.rb .
   cp /path/to/torrent-vpn-stack/packaging/homebrew/README.md .
   ```

4. **Commit and Push**
   ```bash
   git add torrent-vpn-stack.rb README.md
   git commit -m "Add Torrent VPN Stack v1.0.0 formula"
   git push origin main
   ```

5. **Test Installation**
   ```bash
   # Install from tap
   brew tap ddmoney420/torrent-vpn-stack
   brew install torrent-vpn-stack

   # Test commands
   torrent-vpn-setup --help

   # Uninstall
   brew uninstall torrent-vpn-stack
   brew untap ddmoney420/torrent-vpn-stack
   ```

6. **Announce**
   - Update main repository README to remove "(once published)" note
   - Announce in GitHub Discussions

**📖 Full Guide**: `packaging/homebrew/README.md`

---

### 2. Chocolatey Community Repository

**Status**: Ready to submit
**Installation will be**: `choco install torrent-vpn-stack`

**Steps**:

1. **Create Chocolatey Account**
   - Sign up at: https://community.chocolatey.org/account/Register
   - Verify email address

2. **Get API Key**
   - Go to: https://community.chocolatey.org/account
   - Copy your API key
   - Set API key locally:
     ```powershell
     choco apikey -k YOUR_API_KEY -s https://push.chocolatey.org/
     ```

3. **Build Package**
   ```powershell
   cd packaging/chocolatey
   choco pack
   ```

   This creates: `torrent-vpn-stack.1.0.0.nupkg`

4. **Test Package Locally**
   ```powershell
   # Install
   choco install torrent-vpn-stack -s . -y

   # Test
   torrent-vpn-setup --help

   # Uninstall
   choco uninstall torrent-vpn-stack -y
   ```

5. **Submit to Chocolatey**
   ```powershell
   choco push torrent-vpn-stack.1.0.0.nupkg -s https://push.chocolatey.org/
   ```

6. **Wait for Moderation**
   - Typical approval time: 24-48 hours
   - Monitor at: https://community.chocolatey.org/packages/torrent-vpn-stack
   - You'll receive email notifications

7. **Respond to Moderator Feedback**
   - If changes requested, update files, rebuild, and resubmit
   - Once approved, package is live!

8. **Announce**
   - Update main repository README
   - Announce in GitHub Discussions

**📖 Full Guide**: `packaging/chocolatey/README.md`

---

### 3. Arch User Repository (AUR)

**Status**: Ready to submit
**Installation will be**: `yay -S torrent-vpn-stack` or `paru -S torrent-vpn-stack`

**Steps**:

1. **Create AUR Account**
   - Sign up at: https://aur.archlinux.org/register
   - Verify email address

2. **Upload SSH Key**
   - Go to: https://aur.archlinux.org/account
   - Add your SSH public key (`~/.ssh/id_rsa.pub`)

3. **Clone AUR Repository**
   ```bash
   git clone ssh://aur@aur.archlinux.org/torrent-vpn-stack.git aur-torrent-vpn-stack
   cd aur-torrent-vpn-stack
   ```

   Note: Will be empty for first-time submission

4. **Copy Package Files**
   ```bash
   cp /path/to/torrent-vpn-stack/packaging/aur/PKGBUILD .
   cp /path/to/torrent-vpn-stack/packaging/aur/.SRCINFO .
   cp /path/to/torrent-vpn-stack/packaging/aur/torrent-vpn-stack.install .
   ```

5. **Test Package Build**
   ```bash
   # Build package
   makepkg -sf

   # Install and test
   sudo pacman -U torrent-vpn-stack-1.0.0-1-any.pkg.tar.zst
   torrent-vpn-setup --help

   # Clean up
   sudo pacman -R torrent-vpn-stack
   rm -rf pkg/ src/ *.pkg.tar.zst
   ```

6. **Submit to AUR**
   ```bash
   git add PKGBUILD .SRCINFO torrent-vpn-stack.install
   git commit -m "Initial release: Torrent VPN Stack v1.0.0"
   git push origin master
   ```

7. **Verify Submission**
   - Check package page: https://aur.archlinux.org/packages/torrent-vpn-stack
   - Package should be immediately available (no moderation queue)

8. **Test AUR Installation**
   ```bash
   yay -S torrent-vpn-stack
   # OR
   paru -S torrent-vpn-stack
   ```

9. **Announce**
   - Update main repository README
   - Post in AUR comments to introduce package
   - Announce in GitHub Discussions

**📖 Full Guide**: `packaging/aur/README.md`

---

## 📝 Updating Packages for Future Releases

### For v1.0.1, v1.1.0, etc.

1. **Create GitHub Release**
   ```bash
   # Update version in files
   # Create tag and release
   git tag -a v1.0.1 -m "Release v1.0.1"
   git push origin v1.0.1
   gh release create v1.0.1 --notes "..."
   ```

2. **Calculate New Checksums**
   ```bash
   # Tarball (Homebrew, AUR)
   curl -sL https://github.com/ddmoney420/torrent-vpn-stack/archive/refs/tags/v1.0.1.tar.gz | sha256sum

   # ZIP (Chocolatey)
   curl -sL https://github.com/ddmoney420/torrent-vpn-stack/archive/refs/tags/v1.0.1.zip | sha256sum
   ```

3. **Update Package Files**
   - `packaging/homebrew/torrent-vpn-stack.rb`: Update version and sha256
   - `packaging/chocolatey/tools/chocolateyinstall.ps1`: Update version and checksum
   - `packaging/chocolatey/torrent-vpn-stack.nuspec`: Update version
   - `packaging/aur/PKGBUILD`: Update pkgver, pkgrel, sha256sums
   - `packaging/aur/.SRCINFO`: Regenerate with `makepkg --printsrcinfo > .SRCINFO`

4. **Publish Updates**
   - **Homebrew**: Commit and push to tap repository
   - **Chocolatey**: Rebuild package and push: `choco push torrent-vpn-stack.1.0.1.nupkg -s https://push.chocolatey.org/`
   - **AUR**: Commit and push PKGBUILD and .SRCINFO updates

---

## ✅ Post-Publication Checklist

Once all packages are published:

- [ ] Test installation on each platform
  - [ ] macOS: `brew install ddmoney420/torrent-vpn-stack/torrent-vpn-stack`
  - [ ] Windows: `choco install torrent-vpn-stack`
  - [ ] Arch Linux: `yay -S torrent-vpn-stack`
- [ ] Verify all commands work correctly
  - [ ] `torrent-vpn-setup --help`
  - [ ] `torrent-vpn-verify --help`
  - [ ] `torrent-vpn-check-leaks --help`
  - [ ] `torrent-vpn-backup --help`
- [ ] Update main README.md
  - [ ] Remove "(once published)" notes
  - [ ] Add badges for package availability
  - [ ] Update installation instructions
- [ ] Announce release
  - [ ] GitHub Discussions
  - [ ] Reddit (r/selfhosted, r/torrents)
  - [ ] Twitter/X (optional)
- [ ] Monitor for issues
  - [ ] GitHub Issues
  - [ ] Package repository comments
  - [ ] Respond to user questions

---

## 🎉 Congratulations!

Once all packages are published, users can install with a single command on any platform!

```bash
# macOS/Linux
brew install ddmoney420/torrent-vpn-stack/torrent-vpn-stack

# Windows
choco install torrent-vpn-stack

# Arch Linux
yay -S torrent-vpn-stack
```

---

## 📚 Additional Resources

- **Homebrew Formula Cookbook**: https://docs.brew.sh/Formula-Cookbook
- **Chocolatey Package Creation**: https://docs.chocolatey.org/en-us/create/create-packages
- **AUR Submission Guidelines**: https://wiki.archlinux.org/title/AUR_submission_guidelines
- **Semantic Versioning**: https://semver.org/

---

**Questions?** Open an issue on GitHub or ask in Discussions.
