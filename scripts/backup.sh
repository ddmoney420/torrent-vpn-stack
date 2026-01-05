#!/usr/bin/env bash
#
# Torrent VPN Stack - Automated Backup Script
#
# This script backs up Docker volumes to compressed tar archives with timestamps.
# Supports backup rotation based on retention policy.
#
# Usage:
#   ./scripts/backup.sh [OPTIONS]
#
# Options:
#   --dry-run         Show what would be backed up without actually doing it
#   --verbose         Enable verbose output
#   --help            Show this help message
#
# Configuration:
#   Set these in .env file or environment variables:
#   - BACKUP_DIR: Directory to store backups (default: ~/backups/torrent-vpn-stack)
#   - BACKUP_RETENTION_DAYS: Number of days to keep backups (default: 7)
#   - BACKUP_VOLUMES: Comma-separated list of volumes to backup (default: qbittorrent,gluetun)
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Script directory (resolve symlinks for Homebrew compatibility)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load .env if it exists
if [[ -f "${PROJECT_DIR}/.env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "${PROJECT_DIR}/.env"
    set +a
fi

# Backup configuration with defaults
BACKUP_DIR="${BACKUP_DIR:-${HOME}/backups/torrent-vpn-stack}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
BACKUP_VOLUMES="${BACKUP_VOLUMES:-qbittorrent,gluetun}"

# Timestamp for this backup run
TIMESTAMP=$(date +%Y-%m-%d-%H%M%S)

# Docker Compose project name (used for volume naming)
COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-torrent-vpn-stack}"

# Flags
DRY_RUN=false
VERBOSE=false

# Colors
# shellcheck disable=SC2034  # Colors defined for potential future use
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    head -n 20 "$0" | grep "^#" | sed 's/^# \?//'
    exit 0
}

check_dependencies() {
    local missing_deps=()

    for cmd in docker tar gzip; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install them and try again."
        exit 1
    fi

    log_verbose "All dependencies present: docker, tar, gzip"
}

create_backup_dir() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would create backup directory: ${BACKUP_DIR}"
        return 0
    fi

    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_info "Creating backup directory: ${BACKUP_DIR}"
        mkdir -p "${BACKUP_DIR}"
    fi

    log_verbose "Backup directory ready: ${BACKUP_DIR}"
}

backup_volume() {
    local volume_name=$1
    local docker_volume="${COMPOSE_PROJECT}_${volume_name}-config"

    # Check if it's a data volume (prometheus-data, grafana-data)
    if [[ "${volume_name}" == "prometheus" ]] || [[ "${volume_name}" == "grafana" ]]; then
        docker_volume="${COMPOSE_PROJECT}_${volume_name}-data"
    fi

    local backup_file="${BACKUP_DIR}/${volume_name}-config-${TIMESTAMP}.tar.gz"

    # Check if volume exists
    if ! docker volume inspect "${docker_volume}" &> /dev/null; then
        log_warn "Volume ${docker_volume} not found, skipping"
        return 0
    fi

    log_info "Backing up ${docker_volume}..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would create: ${backup_file}"
        return 0
    fi

    # Create backup using docker run with alpine
    # This mounts the volume and creates a tar archive
    if docker run --rm \
        -v "${docker_volume}:/data:ro" \
        -v "${BACKUP_DIR}:/backup" \
        alpine:latest \
        tar czf "/backup/$(basename "${backup_file}")" -C /data . 2>&1 | log_verbose; then

        local backup_size
        backup_size=$(du -h "${backup_file}" | cut -f1)
        log_info "✓ Backup created: ${backup_file} (${backup_size})"
    else
        log_error "Failed to backup ${volume_name}"
        return 1
    fi
}

rotate_backups() {
    local volume_pattern=$1

    log_info "Rotating old backups (keeping last ${BACKUP_RETENTION_DAYS} days)..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would delete backups older than ${BACKUP_RETENTION_DAYS} days"
        # Show what would be deleted
        find "${BACKUP_DIR}" -name "${volume_pattern}-*.tar.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} 2>/dev/null | while read -r old_backup; do
            log_info "[DRY-RUN] Would delete: $(basename "${old_backup}")"
        done
        return 0
    fi

    # Find and delete backups older than retention period
    local deleted_count=0
    while IFS= read -r -d '' old_backup; do
        log_verbose "Deleting old backup: $(basename "${old_backup}")"
        rm -f "${old_backup}"
        ((deleted_count++))
    done < <(find "${BACKUP_DIR}" -name "${volume_pattern}-*.tar.gz" -type f -mtime +${BACKUP_RETENTION_DAYS} -print0 2>/dev/null)

    if [[ ${deleted_count} -gt 0 ]]; then
        log_info "✓ Deleted ${deleted_count} old backup(s)"
    else
        log_verbose "No old backups to delete"
    fi
}

show_backup_summary() {
    log_info ""
    log_info "=========================================="
    log_info "           BACKUP SUMMARY"
    log_info "=========================================="
    log_info "Timestamp: ${TIMESTAMP}"
    log_info "Backup Directory: ${BACKUP_DIR}"
    log_info "Retention Policy: ${BACKUP_RETENTION_DAYS} days"
    log_info "Volumes Backed Up: ${BACKUP_VOLUMES}"
    log_info ""

    if [[ "${DRY_RUN}" == "false" ]] && [[ -d "${BACKUP_DIR}" ]]; then
        log_info "Recent backups:"
        # shellcheck disable=SC2012
        ls -lht "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | head -5 || log_info "  (no backups found)"
    fi

    log_info "=========================================="
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                log_warn "DRY-RUN MODE: No actual backups will be created"
                shift
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

    log_info "Starting Torrent VPN Stack Backup..."
    log_verbose "Project Directory: ${PROJECT_DIR}"
    log_verbose "Compose Project: ${COMPOSE_PROJECT}"

    # Check dependencies
    check_dependencies

    # Create backup directory
    create_backup_dir

    # Parse volumes to backup
    IFS=',' read -ra VOLUMES <<< "${BACKUP_VOLUMES}"

    # Backup each volume
    local backup_success=true
    for volume in "${VOLUMES[@]}"; do
        volume=$(echo "${volume}" | xargs)  # Trim whitespace
        if ! backup_volume "${volume}"; then
            backup_success=false
        fi

        # Rotate backups for this volume
        rotate_backups "${volume}-config"
    done

    # Show summary
    show_backup_summary

    if [[ "${backup_success}" == "true" ]]; then
        log_info "✓ Backup completed successfully!"
        exit 0
    else
        log_error "✗ Backup completed with errors"
        exit 1
    fi
}

# Run main function
main "$@"
