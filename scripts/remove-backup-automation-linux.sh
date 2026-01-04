#!/usr/bin/env bash
#
# Torrent VPN Stack - Remove Linux Backup Automation
#
# Removes systemd timer or cron job created by setup-backup-automation-linux.sh.
#
# Usage:
#   ./scripts/remove-backup-automation-linux.sh [OPTIONS]
#
# Options:
#   --method <systemd|cron|both>  Which method to remove (default: both)
#   --force                       Skip confirmation
#   --help                        Show this help message
#

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_SCRIPT="${PROJECT_DIR}/scripts/backup.sh"

# systemd configuration
SYSTEMD_SERVICE_NAME="torrent-vpn-backup"
SYSTEMD_TIMER_NAME="torrent-vpn-backup"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"

# Configuration
METHOD="both"
FORCE=false

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

# Remove systemd timer and service
remove_systemd() {
    local found=false

    # Check if timer exists
    if systemctl --user list-unit-files "${SYSTEMD_TIMER_NAME}.timer" 2>/dev/null | grep -q "${SYSTEMD_TIMER_NAME}"; then
        found=true
        log_info "Found systemd timer: ${SYSTEMD_TIMER_NAME}.timer"

        # Stop and disable timer
        log_info "Stopping and disabling timer..."
        systemctl --user stop "${SYSTEMD_TIMER_NAME}.timer" 2>/dev/null || true
        systemctl --user disable "${SYSTEMD_TIMER_NAME}.timer" 2>/dev/null || true

        # Remove timer file
        local timer_file="${SYSTEMD_USER_DIR}/${SYSTEMD_TIMER_NAME}.timer"
        if [[ -f "${timer_file}" ]]; then
            rm -f "${timer_file}"
            log_info "Removed timer file: ${timer_file}"
        fi
    fi

    # Check if service exists
    if systemctl --user list-unit-files "${SYSTEMD_SERVICE_NAME}.service" 2>/dev/null | grep -q "${SYSTEMD_SERVICE_NAME}"; then
        found=true
        log_info "Found systemd service: ${SYSTEMD_SERVICE_NAME}.service"

        # Stop and disable service
        log_info "Stopping and disabling service..."
        systemctl --user stop "${SYSTEMD_SERVICE_NAME}.service" 2>/dev/null || true
        systemctl --user disable "${SYSTEMD_SERVICE_NAME}.service" 2>/dev/null || true

        # Remove service file
        local service_file="${SYSTEMD_USER_DIR}/${SYSTEMD_SERVICE_NAME}.service"
        if [[ -f "${service_file}" ]]; then
            rm -f "${service_file}"
            log_info "Removed service file: ${service_file}"
        fi
    fi

    if [[ "${found}" == "true" ]]; then
        # Reload systemd daemon
        log_info "Reloading systemd daemon..."
        systemctl --user daemon-reload

        log_info "✓ systemd timer and service removed successfully"
        return 0
    else
        log_warning "No systemd timer or service found"
        return 1
    fi
}

# Remove cron job
remove_cron() {
    # Check if cron job exists
    if crontab -l 2>/dev/null | grep -qF "${BACKUP_SCRIPT}"; then
        log_info "Found cron job for backup script"

        # Remove cron job
        log_info "Removing cron job..."
        crontab -l 2>/dev/null | grep -vF "${BACKUP_SCRIPT}" | crontab -

        log_info "✓ Cron job removed successfully"
        return 0
    else
        log_warning "No cron job found for backup script"
        return 1
    fi
}

# Main removal
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --method)
                METHOD="$2"
                shift 2
                ;;
            --force)
                FORCE=true
                shift
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
    log_info "  REMOVE BACKUP AUTOMATION"
    log_info "  Platform: Linux"
    log_info "=========================================="
    log_info ""

    # Confirm removal
    if [[ "${FORCE}" != "true" ]]; then
        read -rp "Remove backup automation? (y/N): " response
        if [[ "${response}" != "y" ]] && [[ "${response}" != "Y" ]]; then
            log_info "Cancelled by user"
            exit 0
        fi
    fi

    local removed=false

    # Remove based on method
    case "${METHOD}" in
        systemd)
            if remove_systemd; then
                removed=true
            fi
            ;;
        cron)
            if remove_cron; then
                removed=true
            fi
            ;;
        both)
            if remove_systemd; then
                removed=true
            fi
            if remove_cron; then
                removed=true
            fi
            ;;
        *)
            log_error "Invalid method: ${METHOD}"
            log_error "Valid methods: systemd, cron, both"
            exit 1
            ;;
    esac

    # Summary
    log_info ""
    if [[ "${removed}" == "true" ]]; then
        log_info "✓ Backup automation removed"
        log_info ""
        log_info "To re-enable automation, run:"
        echo -e "  ${GREEN}./scripts/setup-backup-automation-linux.sh${NC}"
    else
        log_warning "No backup automation found to remove"
    fi
    log_info ""
}

main "$@"
