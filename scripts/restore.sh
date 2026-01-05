#!/usr/bin/env bash
#
# Torrent VPN Stack - Restore Script
#
# This script restores Docker volumes from backup archives.
#
# Usage:
#   ./scripts/restore.sh [OPTIONS]
#
# Options:
#   --list                  List available backups and exit
#   --backup <file>         Specify backup file to restore
#   --volume <name>         Specify volume name (auto-detected from filename if not provided)
#   --dry-run               Show what would be restored without actually doing it
#   --no-confirm            Skip confirmation prompt (use with caution!)
#   --verbose               Enable verbose output
#   --help                  Show this help message
#
# Examples:
#   # List available backups
#   ./scripts/restore.sh --list
#
#   # Interactive restore (will prompt for backup selection)
#   ./scripts/restore.sh
#
#   # Restore specific backup
#   ./scripts/restore.sh --backup qbittorrent-config-2026-01-03-030000.tar.gz
#
#   # Dry-run to preview actions
#   ./scripts/restore.sh --backup qbittorrent-config-2026-01-03-030000.tar.gz --dry-run
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
BACKUP_DIR="${BACKUP_DIR:-${HOME}/backups/torrent-vpn-stack}"
COMPOSE_PROJECT="${COMPOSE_PROJECT_NAME:-torrent-vpn-stack}"

# Flags
DRY_RUN=false
VERBOSE=false
NO_CONFIRM=false
LIST_ONLY=false
BACKUP_FILE=""
VOLUME_NAME=""

# Colors
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
    head -n 30 "$0" | grep "^#" | sed 's/^# \?//'
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
        exit 1
    fi

    log_verbose "All dependencies present"
}

list_backups() {
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_error "Backup directory not found: ${BACKUP_DIR}"
        exit 1
    fi

    log_info "Available backups in ${BACKUP_DIR}:"
    log_info ""

    # Find all backup files and group by volume
    local backup_files
    backup_files=$(find "${BACKUP_DIR}" -name "*.tar.gz" -type f 2>/dev/null | sort -r)

    if [[ -z "${backup_files}" ]]; then
        log_warn "No backups found"
        return 0
    fi

    # Group by volume type
    local current_volume=""
    while IFS= read -r backup_file; do
        local filename
        filename=$(basename "${backup_file}")

        # Extract volume name (everything before first dash)
        local volume
        volume=$(echo "${filename}" | sed 's/-config-.*$//')

        if [[ "${volume}" != "${current_volume}" ]]; then
            echo ""
            echo -e "${BLUE}${volume} backups:${NC}"
            current_volume="${volume}"
        fi

        # Get file info
        local file_date file_size
        file_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "${backup_file}" 2>/dev/null || stat -c "%y" "${backup_file}" 2>/dev/null | cut -d'.' -f1)
        file_size=$(du -h "${backup_file}" | cut -f1)

        echo "  ${filename} (${file_size}, ${file_date})"
    done <<< "${backup_files}"

    echo ""
}

select_backup_interactive() {
    if [[ ! -d "${BACKUP_DIR}" ]]; then
        log_error "Backup directory not found: ${BACKUP_DIR}"
        exit 1
    fi

    # Get list of backup files
    local backup_files
    mapfile -t backup_files < <(find "${BACKUP_DIR}" -name "*.tar.gz" -type f 2>/dev/null | sort -r)

    if [[ ${#backup_files[@]} -eq 0 ]]; then
        log_error "No backups found in ${BACKUP_DIR}"
        exit 1
    fi

    log_info "Select a backup to restore:"
    echo ""

    # Display numbered list
    local i=1
    for backup_file in "${backup_files[@]}"; do
        local filename file_date file_size
        filename=$(basename "${backup_file}")
        file_date=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "${backup_file}" 2>/dev/null || stat -c "%y" "${backup_file}" 2>/dev/null | cut -d'.' -f1)
        file_size=$(du -h "${backup_file}" | cut -f1)

        echo "  ${i}) ${filename}"
        echo "     ${file_size}, ${file_date}"
        echo ""
        ((i++))
    done

    # Prompt for selection
    local selection
    while true; do
        read -rp "Enter backup number (1-${#backup_files[@]}) or 'q' to quit: " selection

        if [[ "${selection}" == "q" ]]; then
            log_info "Restore cancelled"
            exit 0
        fi

        if [[ "${selection}" =~ ^[0-9]+$ ]] && [[ ${selection} -ge 1 ]] && [[ ${selection} -le ${#backup_files[@]} ]]; then
            BACKUP_FILE=$(basename "${backup_files[$((selection-1))]}")
            break
        else
            log_error "Invalid selection. Please enter a number between 1 and ${#backup_files[@]}"
        fi
    done

    log_info "Selected: ${BACKUP_FILE}"
}

extract_volume_name() {
    local filename=$1

    # Extract volume name from filename (e.g., "qbittorrent" from "qbittorrent-config-2026-01-03-030000.tar.gz")
    local volume
    volume=$(echo "${filename}" | sed 's/-config-.*$//')

    echo "${volume}"
}

confirm_restore() {
    if [[ "${NO_CONFIRM}" == "true" ]] || [[ "${DRY_RUN}" == "true" ]]; then
        return 0
    fi

    log_warn ""
    log_warn "⚠️  WARNING: This will OVERWRITE the current ${VOLUME_NAME} data!"
    log_warn ""
    log_info "Backup file: ${BACKUP_FILE}"
    log_info "Target volume: ${COMPOSE_PROJECT}_${VOLUME_NAME}-config"
    log_info ""

    local response
    read -rp "Are you sure you want to continue? (yes/no): " response

    if [[ "${response}" != "yes" ]]; then
        log_info "Restore cancelled"
        exit 0
    fi
}

stop_containers() {
    local container_name=$1

    log_info "Stopping ${container_name} container..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would stop container: ${container_name}"
        return 0
    fi

    # Check if container is running
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        if docker stop "${container_name}" &> /dev/null; then
            log_info "✓ Stopped ${container_name}"
        else
            log_warn "Failed to stop ${container_name} (may already be stopped)"
        fi
    else
        log_verbose "${container_name} is not running"
    fi
}

start_containers() {
    local container_name=$1

    log_info "Starting ${container_name} container..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would start container: ${container_name}"
        return 0
    fi

    # Use docker compose to start the container
    cd "${PROJECT_DIR}" || exit 1

    if docker compose start "${container_name}" &> /dev/null; then
        log_info "✓ Started ${container_name}"
    else
        log_error "Failed to start ${container_name}"
        log_error "You may need to manually start it with: docker compose start ${container_name}"
    fi
}

restore_volume() {
    local backup_path="${BACKUP_DIR}/${BACKUP_FILE}"
    local docker_volume="${COMPOSE_PROJECT}_${VOLUME_NAME}-config"

    # Check if it's a data volume (prometheus-data, grafana-data)
    if [[ "${VOLUME_NAME}" == "prometheus" ]] || [[ "${VOLUME_NAME}" == "grafana" ]]; then
        docker_volume="${COMPOSE_PROJECT}_${VOLUME_NAME}-data"
    fi

    # Check if backup file exists
    if [[ ! -f "${backup_path}" ]]; then
        log_error "Backup file not found: ${backup_path}"
        exit 1
    fi

    # Check if volume exists
    if ! docker volume inspect "${docker_volume}" &> /dev/null; then
        log_error "Volume ${docker_volume} not found"
        log_error "Create it first by starting the stack: docker compose up -d"
        exit 1
    fi

    log_info "Restoring ${docker_volume} from ${BACKUP_FILE}..."

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would restore from: ${backup_path}"
        log_info "[DRY-RUN] Would restore to volume: ${docker_volume}"
        return 0
    fi

    # Create safety backup of current state
    local safety_backup
    safety_backup="${BACKUP_DIR}/${VOLUME_NAME}-pre-restore-$(date +%Y-%m-%d-%H%M%S).tar.gz"
    log_info "Creating safety backup of current state: ${safety_backup}"

    docker run --rm \
        -v "${docker_volume}:/data:ro" \
        -v "${BACKUP_DIR}:/backup" \
        alpine:latest \
        tar czf "/backup/$(basename "${safety_backup}")" -C /data . &> /dev/null

    log_verbose "Safety backup created: ${safety_backup}"

    # Restore from backup
    # First, clear the volume
    log_verbose "Clearing volume contents..."
    docker run --rm \
        -v "${docker_volume}:/data" \
        alpine:latest \
        sh -c "rm -rf /data/* /data/..?* /data/.[!.]*" 2>/dev/null || true

    # Extract backup to volume
    log_verbose "Extracting backup to volume..."
    if docker run --rm \
        -v "${docker_volume}:/data" \
        -v "${backup_path}:/backup.tar.gz:ro" \
        alpine:latest \
        tar xzf /backup.tar.gz -C /data 2>&1 | log_verbose; then

        log_info "✓ Restore completed successfully!"
        log_info "  Safety backup saved to: ${safety_backup}"
    else
        log_error "Failed to restore from backup"
        log_error "Safety backup available at: ${safety_backup}"
        exit 1
    fi
}

# ============================================================================
# Main Script
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --list)
                LIST_ONLY=true
                shift
                ;;
            --backup)
                BACKUP_FILE="$2"
                shift 2
                ;;
            --volume)
                VOLUME_NAME="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                log_warn "DRY-RUN MODE: No actual restore will be performed"
                shift
                ;;
            --no-confirm)
                NO_CONFIRM=true
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

    log_info "Torrent VPN Stack - Restore Script"
    log_verbose "Project Directory: ${PROJECT_DIR}"
    log_verbose "Backup Directory: ${BACKUP_DIR}"

    # Check dependencies
    check_dependencies

    # List backups and exit if requested
    if [[ "${LIST_ONLY}" == "true" ]]; then
        list_backups
        exit 0
    fi

    # Interactive backup selection if not specified
    if [[ -z "${BACKUP_FILE}" ]]; then
        select_backup_interactive
    fi

    # Extract volume name from filename if not provided
    if [[ -z "${VOLUME_NAME}" ]]; then
        VOLUME_NAME=$(extract_volume_name "${BACKUP_FILE}")
        log_verbose "Auto-detected volume: ${VOLUME_NAME}"
    fi

    # Confirm restore
    confirm_restore

    # Determine container name based on volume
    local container_name="${VOLUME_NAME}"
    if [[ "${VOLUME_NAME}" == "prometheus" ]] || [[ "${VOLUME_NAME}" == "grafana" ]]; then
        container_name="${VOLUME_NAME}"
    fi

    # Stop affected containers
    stop_containers "${container_name}"

    # Restore volume
    restore_volume

    # Start containers
    start_containers "${container_name}"

    log_info ""
    log_info "✓ Restore process completed!"
    log_info ""
}

# Run main function
main "$@"
