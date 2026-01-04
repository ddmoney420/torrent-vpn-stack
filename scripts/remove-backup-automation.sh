#!/usr/bin/env bash
#
# Torrent VPN Stack - Remove Backup Automation
#
# This script removes the automated backup launchd job.
#
# Usage:
#   ./scripts/remove-backup-automation.sh [OPTIONS]
#
# Options:
#   --verbose        Enable verbose output
#   --help           Show this help message
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Paths
PLIST_NAME="com.torrent-vpn-stack.backup.plist"
PLIST_PATH="${HOME}/Library/LaunchAgents/${PLIST_NAME}"
LOG_DIR="${HOME}/Library/Logs"

VERBOSE=false

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
    head -n 12 "$0" | grep "^#" | sed 's/^# \?//'
    exit 0
}

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only"
        exit 1
    fi
}

unload_job() {
    log_info "Unloading launchd job..."

    if [[ ! -f "${PLIST_PATH}" ]]; then
        log_warn "Plist file not found: ${PLIST_PATH}"
        log_warn "Job may not be installed"
        return 0
    fi

    # Unload the job
    if launchctl unload "${PLIST_PATH}" 2>/dev/null; then
        log_info "✓ Job unloaded"
    else
        log_verbose "Job was not loaded or already unloaded"
    fi
}

remove_plist() {
    log_info "Removing plist file..."

    if [[ -f "${PLIST_PATH}" ]]; then
        rm -f "${PLIST_PATH}"
        log_info "✓ Plist removed: ${PLIST_PATH}"
    else
        log_verbose "Plist file not found (already removed)"
    fi
}

remove_logs() {
    log_info "Would you like to remove backup logs? (y/n)"
    read -r response

    if [[ "${response}" == "y" ]] || [[ "${response}" == "Y" ]]; then
        local log_files=(
            "${LOG_DIR}/torrent-vpn-stack-backup.log"
            "${LOG_DIR}/torrent-vpn-stack-backup-error.log"
        )

        for log_file in "${log_files[@]}"; do
            if [[ -f "${log_file}" ]]; then
                rm -f "${log_file}"
                log_info "✓ Removed: ${log_file}"
            fi
        done
    else
        log_info "Logs preserved in ${LOG_DIR}"
    fi
}

verify_removal() {
    log_info "Verifying removal..."

    if launchctl list | grep -q "com.torrent-vpn-stack.backup"; then
        log_warn "Job still appears in launchctl list"
        log_warn "You may need to log out and log back in"
    else
        log_info "✓ Job successfully removed"
    fi
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
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

    log_info "Removing backup automation..."

    # Checks
    check_macos

    # Remove
    unload_job
    remove_plist
    remove_logs
    verify_removal

    log_info ""
    log_info "✓ Backup automation removed successfully!"
    log_info ""
    log_info "Note: Manual backups can still be run with:"
    log_info "  ./scripts/backup.sh"
    log_info ""
}

# Run main function
main "$@"
