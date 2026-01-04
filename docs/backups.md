# Backup and Restore Guide

## Table of Contents

- [Overview](#overview)
- [Manual Backups](#manual-backups)
- [Automated Backups (macOS)](#automated-backups-macos)
- [Restoring from Backup](#restoring-from-backup)
- [Backup Rotation](#backup-rotation)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Overview

This backup solution protects your Torrent VPN Stack configuration and data through automated or manual backups.

### What Gets Backed Up

- **qBittorrent Configuration**: Settings, web UI preferences, RSS feeds, filters
- **Gluetun Configuration**: VPN settings, firewall rules (if stored in volume)
- **Prometheus Data** (optional): Metrics history
- **Grafana Data** (optional): Dashboards, datasources, users

### Backup Storage

- **Location**: `~/backups/torrent-vpn-stack/` (configurable via `.env`)
- **Format**: Compressed tar.gz archives with timestamps
- **Naming**: `{volume}-config-YYYY-MM-DD-HHMMSS.tar.gz`
- **Retention**: Last 7 days by default (configurable)

---

## Manual Backups

### Quick Start

```bash
# Run backup script
./scripts/backup.sh

# View what would be backed up (dry-run)
./scripts/backup.sh --dry-run

# Verbose output
./scripts/backup.sh --verbose
```

### Configuration

Edit `.env` to customize backup behavior:

```bash
# Backup directory
BACKUP_DIR=~/backups/torrent-vpn-stack

# Retention period (days)
BACKUP_RETENTION_DAYS=7

# Volumes to backup (comma-separated)
BACKUP_VOLUMES=qbittorrent,gluetun
```

### Example Output

```
[INFO] Starting Torrent VPN Stack Backup...
[INFO] Creating backup directory: /Users/you/backups/torrent-vpn-stack
[INFO] Backing up torrent-vpn-stack_qbittorrent-config...
[INFO] ✓ Backup created: qbittorrent-config-2026-01-03-150000.tar.gz (2.3M)
[INFO] Backing up torrent-vpn-stack_gluetun-config...
[INFO] ✓ Backup created: gluetun-config-2026-01-03-150000.tar.gz (45K)
[INFO] Rotating old backups (keeping last 7 days)...
[INFO] ✓ Deleted 2 old backup(s)
[INFO] ✓ Backup completed successfully!
```

---

## Automated Backups (macOS)

### Setup Automation

Run the setup script to schedule daily backups:

```bash
# Setup with default schedule (3 AM daily)
./scripts/setup-backup-automation.sh

# Customize backup time (24-hour format)
./scripts/setup-backup-automation.sh --hour 2  # 2 AM
```

### What It Does

1. Creates launchd plist in `~/Library/LaunchAgents/`
2. Schedules daily backup at specified hour
3. Logs output to `~/Library/Logs/torrent-vpn-stack-backup.log`
4. Automatically rotates old backups

### Verify Automation

```bash
# Check if job is loaded
launchctl list | grep torrent-vpn-stack

# Manually trigger backup to test
launchctl start com.torrent-vpn-stack.backup

# View logs
tail -f ~/Library/Logs/torrent-vpn-stack-backup.log
```

### Remove Automation

```bash
./scripts/remove-backup-automation.sh
```

---

## Restoring from Backup

### Interactive Restore

```bash
# List available backups
./scripts/restore.sh --list

# Interactive restore (select from list)
./scripts/restore.sh
```

### Command-Line Restore

```bash
# Restore specific backup
./scripts/restore.sh --backup qbittorrent-config-2026-01-03-030000.tar.gz

# Dry-run to preview
./scripts/restore.sh --backup qbittorrent-config-2026-01-03-030000.tar.gz --dry-run

# Skip confirmation (use with caution!)
./scripts/restore.sh --backup qbittorrent-config-2026-01-03-030000.tar.gz --no-confirm
```

### Restore Process

1. **Safety Backup**: Creates backup of current state before restore
2. **Stop Container**: Stops affected container (qbittorrent, gluetun, etc.)
3. **Clear Volume**: Removes existing data from Docker volume
4. **Extract Backup**: Extracts backup archive to volume
5. **Restart Container**: Starts container with restored data

### Safety Features

- **Automatic Safety Backup**: Current state backed up before restore
- **Confirmation Prompt**: Requires explicit "yes" to proceed
- **Dry-Run Mode**: Preview actions without making changes
- **Container Management**: Automatically stops/starts containers

---

## Backup Rotation

Old backups are automatically deleted based on retention policy.

### How It Works

- Runs after each backup
- Deletes backups older than `BACKUP_RETENTION_DAYS`
- Keeps backups from last N days
- Applies per-volume (qbittorrent backups independent of gluetun backups)

### Example

With `BACKUP_RETENTION_DAYS=7`:
- Daily backups at 3 AM
- After 7 days, oldest backup is deleted
- Always have 7 days of backup history

### Manual Cleanup

```bash
# Delete all backups older than 30 days
find ~/backups/torrent-vpn-stack -name "*.tar.gz" -mtime +30 -delete

# Delete specific volume backups
rm ~/backups/torrent-vpn-stack/qbittorrent-config-*.tar.gz
```

---

## Troubleshooting

### Backup Script Fails

**Symptoms**: Backup script exits with error

**Diagnosis**:
```bash
# Check Docker is running
docker ps

# Verify volumes exist
docker volume ls | grep torrent-vpn-stack

# Check disk space
df -h ~/backups
```

**Solutions**:
1. Start Docker Desktop
2. Start stack: `docker compose up -d`
3. Free up disk space if needed

---

### Cannot Restore Backup

**Symptoms**: Restore fails with "volume not found" error

**Solution**:
Start the stack first to create volumes:
```bash
docker compose up -d
```

Then retry restore.

---

### Launchd Job Not Running

**Symptoms**: No backups created automatically

**Diagnosis**:
```bash
# Check if job is loaded
launchctl list | grep torrent-vpn-stack

# View logs
cat ~/Library/Logs/torrent-vpn-stack-backup.log
cat ~/Library/Logs/torrent-vpn-stack-backup-error.log
```

**Solutions**:
1. **Reload job**:
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.torrent-vpn-stack.backup.plist
   launchctl load ~/Library/LaunchAgents/com.torrent-vpn-stack.backup.plist
   ```

2. **Check script permissions**:
   ```bash
   chmod +x ./scripts/backup.sh
   ```

3. **Manually test**:
   ```bash
   launchctl start com.torrent-vpn-stack.backup
   ```

---

### Backup Takes Too Long

**Symptoms**: Backup runs for many minutes

**Cause**: Large downloads directory or Prometheus data

**Solutions**:
1. **Exclude large volumes**:
   ```bash
   # In .env
   BACKUP_VOLUMES=qbittorrent,gluetun  # Don't backup prometheus, grafana
   ```

2. **Reduce Prometheus retention**:
   Edit `docker-compose.yml`:
   ```yaml
   prometheus:
     command:
       - '--storage.tsdb.retention.time=7d'  # Reduce from 30d
   ```

---

## FAQ

### Q: Can I backup while containers are running?

**A**: Yes, the backup script creates read-only snapshots and doesn't interrupt running containers.

###Q: What's the difference between volume backup and file backup?

**A**:
- **Volume Backup** (this solution): Backs up Docker volumes containing config
- **File Backup**: Would backup `~/Downloads/torrents` (user responsibility)

Note: Downloaded torrent files are NOT backed up automatically. Back up `DOWNLOADS_PATH` separately if needed.

### Q: Can I backup to external storage (NAS, cloud)?

**A**: Yes, set `BACKUP_DIR` to mounted network drive:
```bash
BACKUP_DIR=/Volumes/NAS/backups/torrent-vpn-stack
```

### Q: How do I backup before system migration?

**A**:
1. Run manual backup: `./scripts/backup.sh`
2. Copy `~/backups/torrent-vpn-stack/` to new system
3. Install stack on new system
4. Restore backups: `./scripts/restore.sh`

### Q: Can I encrypt backups?

**A**: Not built-in. For encryption:
```bash
# After backup, encrypt with GPG
gpg --symmetric ~/backups/torrent-vpn-stack/qbittorrent-config-*.tar.gz

# Decrypt before restore
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```

### Q: What if I accidentally delete a backup?

**A**: No automatic recovery. Best practices:
- Keep multiple retention days
- Sync backups to cloud storage
- Test restores periodically

### Q: How much disk space do backups use?

**A**: Typical sizes:
- qBittorrent config: 1-5 MB
- Gluetun config: < 100 KB
- Prometheus (30 days): 2-3 GB
- Grafana: 50-100 MB

With 7-day retention: ~500 MB total (excluding Prometheus)

---

## Additional Resources

- **Docker Volume Backup**: https://docs.docker.com/storage/volumes/#back-up-restore-or-migrate-data-volumes
- **macOS launchd**: https://www.launchd.info/
- **Cron Alternative (Linux)**: Use crontab instead of launchd

---

**Need Help?** Check the [main troubleshooting guide](../README.md#troubleshooting) or open an issue on GitHub.
