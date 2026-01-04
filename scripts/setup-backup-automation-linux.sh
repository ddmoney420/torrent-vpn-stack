#!/usr/bin/env bash
#
# Torrent VPN Stack - Linux Backup Automation Setup
#
# Sets up automated daily backups using systemd timers (preferred) or cron (fallback).
#
# Usage:
#   sudo ./scripts/setup-backup-automation-linux.sh [OPTIONS]
#
# Options:
#   --method <systemd|cron>  Force specific method (default: auto-detect)
#   --hour <0-23>            Hour to run backup (default: 3 for 3 AM)
#   --retention <days>       Days to keep backups (default: 7)
#   --help                   Show this help message
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_SCRIPT="${PROJECT_DIR}/scripts/backup.sh"

# Default configuration
METHOD="auto"
BACKUP_HOUR=3
BACKUP_RETENTION_DAYS=7
BACKUP_DIR="${HOME}/backups/torrent-vpn-stack"

# systemd configuration
SYSTEMD_SERVICE_NAME="torrent-vpn-backup"
SYSTEMD_TIMER_NAME="torrent-vpn-backup"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

show_help() {
    head -n 15 "$0" | grep "^#" | sed 's/^# \?//'
    exit 0
}

# Detect if systemd is available
has_systemd() {
    if command -v systemctl &> /dev/null; then
        if systemctl --user list-units &> /dev/null; then
            return 0
        fi
    fi
    return 1
}

# Detect if running as root (not recommended for user systemd services)
is_root() {
    [[ $EUID -eq 0 ]]
}

# Create systemd service and timer
setup_systemd() {
    log_info "Setting up systemd timer..."

    # Create user systemd directory
    mkdir -p "${SYSTEMD_USER_DIR}"

    # Create service file
    local service_file="${SYSTEMD_USER_DIR}/${SYSTEMD_SERVICE_NAME}.service"
    log_info "Creating service file: ${service_file}"

    cat > "${service_file}" <<EOF
[Unit]
Description=Torrent VPN Stack Backup
Documentation=https://github.com/ddmoney420/torrent-vpn-stack
After=network.target docker.service

[Service]
Type=oneshot
Environment="BACKUP_DIR=${BACKUP_DIR}"
Environment="BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS}"
Environment="PROJECT_DIR=${PROJECT_DIR}"
WorkingDirectory=${PROJECT_DIR}
ExecStart=${BACKUP_SCRIPT}
StandardOutput=journal
StandardError=journal

# Security hardening
PrivateTmp=yes
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=${BACKUP_DIR}

[Install]
WantedBy=default.target
EOF

    # Create timer file
    local timer_file="${SYSTEMD_USER_DIR}/${SYSTEMD_TIMER_NAME}.timer"
    log_info "Creating timer file: ${timer_file}"

    # Format: OnCalendar=*-*-* HH:00:00 (daily at specified hour)
    local on_calendar
    printf -v on_calendar "*-*-* %02d:00:00" "${BACKUP_HOUR}"

    cat > "${timer_file}" <<EOF
[Unit]
Description=Torrent VPN Stack Backup Timer
Documentation=https://github.com/ddmoney420/torrent-vpn-stack

[Timer]
# Run daily at ${BACKUP_HOUR}:00
OnCalendar=${on_calendar}
# Run on boot if missed
Persistent=true
# Randomize start time by up to 10 minutes to avoid load spikes
RandomizedDelaySec=10min

[Install]
WantedBy=timers.target
EOF

    # Reload systemd daemon
    log_info "Reloading systemd daemon..."
    systemctl --user daemon-reload

    # Enable and start timer
    log_info "Enabling and starting timer..."
    systemctl --user enable "${SYSTEMD_TIMER_NAME}.timer"
    systemctl --user start "${SYSTEMD_TIMER_NAME}.timer"

    # Verify
    if systemctl --user is-active --quiet "${SYSTEMD_TIMER_NAME}.timer"; then
        log_info "✓ systemd timer configured successfully"
        show_systemd_status
        return 0
    else
        log_error "Failed to start systemd timer"
        return 1
    fi
}

# Show systemd status
show_systemd_status() {
    log_info ""
    log_info "=========================================="
    log_info "  BACKUP AUTOMATION CONFIGURED (systemd)"
    log_info "=========================================="
    log_info "Service         : ${SYSTEMD_SERVICE_NAME}.service"
    log_info "Timer           : ${SYSTEMD_TIMER_NAME}.timer"
    log_info "Backup Schedule : Daily at ${BACKUP_HOUR}:00"
    log_info "Backup Directory: ${BACKUP_DIR}"
    log_info "Retention       : ${BACKUP_RETENTION_DAYS} days"
    log_info "=========================================="
    log_info ""
    log_info "Timer status:"
    systemctl --user status "${SYSTEMD_TIMER_NAME}.timer" --no-pager --lines=0 || true
    log_info ""
    log_info "Next scheduled run:"
    systemctl --user list-timers "${SYSTEMD_TIMER_NAME}.timer" --no-pager || true
    log_info ""
    log_info "To test backup manually:"
    echo -e "  ${BLUE}systemctl --user start ${SYSTEMD_SERVICE_NAME}.service${NC}"
    log_info ""
    log_info "To view logs:"
    echo -e "  ${BLUE}journalctl --user -u ${SYSTEMD_SERVICE_NAME}.service${NC}"
    log_info ""
    log_info "To disable automation:"
    echo -e "  ${BLUE}./scripts/remove-backup-automation-linux.sh${NC}"
    log_info ""
}

# Create cron job
setup_cron() {
    log_info "Setting up cron job..."

    # Cron format: MIN HOUR DOM MON DOW COMMAND
    local cron_line="0 ${BACKUP_HOUR} * * * cd ${PROJECT_DIR} && BACKUP_DIR=${BACKUP_DIR} BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS} ${BACKUP_SCRIPT} >> ${HOME}/.torrent-vpn-stack/backup.log 2>&1"

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -qF "${BACKUP_SCRIPT}"; then
        log_warning "Cron job already exists. Removing old entry..."
        crontab -l 2>/dev/null | grep -vF "${BACKUP_SCRIPT}" | crontab -
    fi

    # Add new cron job
    (crontab -l 2>/dev/null; echo "${cron_line}") | crontab -

    # Verify
    if crontab -l 2>/dev/null | grep -qF "${BACKUP_SCRIPT}"; then
        log_info "✓ Cron job configured successfully"
        show_cron_status
        return 0
    else
        log_error "Failed to create cron job"
        return 1
    fi
}

# Show cron status
show_cron_status() {
    log_info ""
    log_info "=========================================="
    log_info "  BACKUP AUTOMATION CONFIGURED (cron)"
    log_info "=========================================="
    log_info "Backup Schedule : Daily at ${BACKUP_HOUR}:00"
    log_info "Backup Directory: ${BACKUP_DIR}"
    log_info "Retention       : ${BACKUP_RETENTION_DAYS} days"
    log_info "Log File        : ${HOME}/.torrent-vpn-stack/backup.log"
    log_info "=========================================="
    log_info ""
    log_info "Cron entry:"
    crontab -l | grep "${BACKUP_SCRIPT}" || true
    log_info ""
    log_info "To test backup manually:"
    echo -e "  ${BLUE}${BACKUP_SCRIPT}${NC}"
    log_info ""
    log_info "To view all cron jobs:"
    echo -e "  ${BLUE}crontab -l${NC}"
    log_info ""
    log_info "To disable automation:"
    echo -e "  ${BLUE}./scripts/remove-backup-automation-linux.sh${NC}"
    log_info ""
}

# Main setup
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --method)
                METHOD="$2"
                shift 2
                ;;
            --hour)
                BACKUP_HOUR="$2"
                shift 2
                ;;
            --retention)
                BACKUP_RETENTION_DAYS="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done

    log_info "=========================================="
    log_info "  TORRENT VPN STACK - BACKUP AUTOMATION"
    log_info "  Platform: Linux"
    log_info "=========================================="
    log_info ""

    # Validate backup hour
    if [[ ${BACKUP_HOUR} -lt 0 ]] || [[ ${BACKUP_HOUR} -gt 23 ]]; then
        log_error "Backup hour must be between 0 and 23"
        exit 1
    fi

    # Check if backup script exists
    if [[ ! -f "${BACKUP_SCRIPT}" ]]; then
        log_error "Backup script not found: ${BACKUP_SCRIPT}"
        exit 1
    fi

    # Make backup script executable
    chmod +x "${BACKUP_SCRIPT}"

    # Create backup directory
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_info "Creating backup directory: ${BACKUP_DIR}"
        mkdir -p "${BACKUP_DIR}"
    fi

    # Determine method
    if [[ "${METHOD}" == "auto" ]]; then
        if has_systemd; then
            METHOD="systemd"
            log_info "Auto-detected: systemd available"
        elif command -v crontab &> /dev/null; then
            METHOD="cron"
            log_info "Auto-detected: using cron (systemd not available)"
        else
            log_error "Neither systemd nor cron is available"
            exit 1
        fi
    fi

    # Warn if running as root with systemd
    if [[ "${METHOD}" == "systemd" ]] && is_root; then
        log_warning "Running as root. User systemd services are recommended."
        log_warning "Consider running as your regular user instead."
    fi

    # Setup automation
    case "${METHOD}" in
        systemd)
            setup_systemd
            ;;
        cron)
            setup_cron
            ;;
        *)
            log_error "Invalid method: ${METHOD}"
            log_error "Valid methods: systemd, cron"
            exit 1
            ;;
    esac
}

main "$@"
