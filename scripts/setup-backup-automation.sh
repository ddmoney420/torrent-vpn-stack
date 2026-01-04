#!/usr/bin/env bash
#
# Torrent VPN Stack - Setup Backup Automation
#
# This script sets up automated daily backups using macOS launchd.
#
# Usage:
#   ./scripts/setup-backup-automation.sh [OPTIONS]
#
# Options:
#   --hour <0-23>    Hour to run backup (default: 3 for 3 AM)
#   --verbose        Enable verbose output
#   --help           Show this help message
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load .env if it exists
if [[ -f "${PROJECT_DIR}/.env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "${PROJECT_DIR}/.env"
    set +a
fi

# Configuration
BACKUP_HOUR="${BACKUP_SCHEDULE_HOUR:-3}"
VERBOSE=false

# Paths
PLIST_TEMPLATE="${PROJECT_DIR}/launchd/com.torrent-vpn-stack.backup.plist.template"
PLIST_NAME="com.torrent-vpn-stack.backup.plist"
PLIST_DEST="${HOME}/Library/LaunchAgents/${PLIST_NAME}"
BACKUP_SCRIPT="${SCRIPT_DIR}/backup.sh"
LOG_DIR="${HOME}/Library/Logs"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_verbose() {
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $*"
    fi
}

show_help() {
    head -n 15 "$0" | grep "^#" | sed 's/^# \?//'
    exit 0
}

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only"
        log_error "For Linux, use cron instead of launchd"
        exit 1
    fi

    log_verbose "Running on macOS"
}

check_files() {
    if [[ ! -f "${PLIST_TEMPLATE}" ]]; then
        log_error "Plist template not found: ${PLIST_TEMPLATE}"
        exit 1
    fi

    if [[ ! -f "${BACKUP_SCRIPT}" ]]; then
        log_error "Backup script not found: ${BACKUP_SCRIPT}"
        exit 1
    fi

    if [[ ! -x "${BACKUP_SCRIPT}" ]]; then
        log_error "Backup script is not executable: ${BACKUP_SCRIPT}"
        log_error "Run: chmod +x ${BACKUP_SCRIPT}"
        exit 1
    fi

    log_verbose "All required files present"
}

create_launchagents_dir() {
    local launchagents_dir="${HOME}/Library/LaunchAgents"

    if [[ ! -d "${launchagents_dir}" ]]; then
        log_info "Creating LaunchAgents directory: ${launchagents_dir}"
        mkdir -p "${launchagents_dir}"
    fi

    log_verbose "LaunchAgents directory ready"
}

generate_plist() {
    log_info "Generating launchd plist file..."

    # Read template and substitute placeholders
    local plist_content
    plist_content=$(cat "${PLIST_TEMPLATE}")

    # Substitute placeholders
    plist_content="${plist_content//__SCRIPT_PATH__/${BACKUP_SCRIPT}}"
    plist_content="${plist_content//__BACKUP_HOUR__/${BACKUP_HOUR}}"
    plist_content="${plist_content//__LOG_DIR__/${LOG_DIR}}"
    plist_content="${plist_content//__PROJECT_DIR__/${PROJECT_DIR}}"
    plist_content="${plist_content//__HOME_DIR__/${HOME}}"

    # Write to destination
    echo "${plist_content}" > "${PLIST_DEST}"

    log_verbose "Plist created: ${PLIST_DEST}"
}

load_launchd_job() {
    log_info "Loading launchd job..."

    # Unload if already loaded (ignore errors)
    launchctl unload "${PLIST_DEST}" 2>/dev/null || true

    # Load the job
    if launchctl load "${PLIST_DEST}"; then
        log_info "✓ Launchd job loaded successfully"
    else
        log_error "Failed to load launchd job"
        exit 1
    fi
}

verify_installation() {
    log_info "Verifying installation..."

    # Check if job is loaded
    if launchctl list | grep -q "com.torrent-vpn-stack.backup"; then
        log_info "✓ Job is loaded and ready"

        # Get job info
        log_verbose "Job details:"
        launchctl list com.torrent-vpn-stack.backup 2>/dev/null | log_verbose || true
    else
        log_warn "Job not found in launchctl list"
        log_warn "It may still work, but verification failed"
    fi
}

show_summary() {
    log_info ""
    log_info "=========================================="
    log_info "    BACKUP AUTOMATION SETUP COMPLETE"
    log_info "=========================================="
    log_info "Schedule: Daily at ${BACKUP_HOUR}:00 (${BACKUP_HOUR} AM/PM)"
    log_info "Script: ${BACKUP_SCRIPT}"
    log_info "Plist: ${PLIST_DEST}"
    log_info "Logs: ${LOG_DIR}/torrent-vpn-stack-backup.log"
    log_info ""
    log_info "To manually trigger a backup:"
    log_info "  ${BACKUP_SCRIPT}"
    log_info ""
    log_info "To manually trigger via launchd:"
    log_info "  launchctl start com.torrent-vpn-stack.backup"
    log_info ""
    log_info "To view logs:"
    log_info "  tail -f ${LOG_DIR}/torrent-vpn-stack-backup.log"
    log_info ""
    log_info "To uninstall automation:"
    log_info "  ./scripts/remove-backup-automation.sh"
    log_info "=========================================="
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --hour)
                BACKUP_HOUR="$2"
                if ! [[ "${BACKUP_HOUR}" =~ ^[0-9]+$ ]] || [[ ${BACKUP_HOUR} -lt 0 ]] || [[ ${BACKUP_HOUR} -gt 23 ]]; then
                    log_error "Invalid hour: ${BACKUP_HOUR}. Must be 0-23"
                    exit 1
                fi
                shift 2
                ;;
            --verbose)
                VERBOSE=true
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

    log_info "Setting up automated backups for Torrent VPN Stack..."
    log_verbose "Project Directory: ${PROJECT_DIR}"
    log_verbose "Backup Hour: ${BACKUP_HOUR}"

    # Checks
    check_macos
    check_files

    # Setup
    create_launchagents_dir
    generate_plist
    load_launchd_job
    verify_installation

    # Summary
    show_summary

    log_info "✓ Setup complete!"
}

# Run main function
main "$@"
