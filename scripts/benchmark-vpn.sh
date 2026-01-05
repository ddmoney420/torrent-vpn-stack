#!/usr/bin/env bash
#
# Torrent VPN Stack - VPN Performance Benchmark Script
#
# Tests VPN performance: download/upload speed, latency, DNS resolution, resource usage
#
# Usage:
#   ./scripts/benchmark-vpn.sh [OPTIONS]
#
# Options:
#   --provider <name>    Provider name for results (default: detected from .env)
#   --output <file>      JSON output file (default: benchmark-results.json)
#   --verbose            Enable verbose output
#   --help               Show this help message
#

set -euo pipefail

# Script directory (resolve symlinks for Homebrew compatibility)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Load .env
if [[ -f "${PROJECT_DIR}/.env" ]]; then
    # shellcheck disable=SC1091
    set -a
    source "${PROJECT_DIR}/.env"
    set +a
fi

# Configuration
PROVIDER_NAME="${VPN_SERVICE_PROVIDER:-unknown}"
OUTPUT_FILE="${PROJECT_DIR}/benchmark-results.json"
VERBOSE=false

# Colors (exported for use in subshells)
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# Results
declare -A RESULTS

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
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

test_vpn_ip() {
    log_info "Testing VPN IP address..."

    local vpn_ip
    vpn_ip=$(docker exec gluetun wget -qO- https://api.ipify.org 2>/dev/null || echo "ERROR")

    if [[ "${vpn_ip}" == "ERROR" ]] || [[ -z "${vpn_ip}" ]]; then
        log_info "❌ Failed to get VPN IP"
        RESULTS[vpn_ip]="unknown"
    else
        log_info "✓ VPN IP: ${vpn_ip}"
        RESULTS[vpn_ip]="${vpn_ip}"
    fi
}

test_download_speed() {
    log_info "Testing download speed (10MB test file)..."

    local start_time end_time duration speed_mbps
    start_time=$(date +%s.%N)

    docker exec gluetun wget -O /dev/null http://speedtest.ftp.otenet.gr/files/test10Mb.db 2>&1 | grep -v "saving" > /dev/null || true

    end_time=$(date +%s.%N)
    duration=$(echo "${end_time} - ${start_time}" | bc)
    speed_mbps=$(echo "scale=2; (10 * 8) / ${duration}" | bc)

    log_info "✓ Download speed: ${speed_mbps} Mbps"
    RESULTS[download_mbps]="${speed_mbps}"
}

test_latency() {
    log_info "Testing latency..."

    local ping_result latency_ms
    ping_result=$(docker exec gluetun ping -c 5 8.8.8.8 2>/dev/null | grep "avg" || echo "")

    if [[ -n "${ping_result}" ]]; then
        latency_ms=$(echo "${ping_result}" | awk -F'/' '{print $5}' | awk '{print int($1)}')
        log_info "✓ Average latency: ${latency_ms}ms"
        RESULTS[latency_ms]="${latency_ms}"
    else
        log_info "❌ Latency test failed"
        RESULTS[latency_ms]="0"
    fi
}

test_dns_resolution() {
    log_info "Testing DNS resolution speed..."

    local start_time end_time dns_ms
    start_time=$(date +%s.%N)

    docker exec gluetun nslookup google.com > /dev/null 2>&1 || true

    end_time=$(date +%s.%N)
    dns_ms=$(echo "scale=0; (${end_time} - ${start_time}) * 1000" | bc | awk '{print int($1)}')

    log_info "✓ DNS resolution: ${dns_ms}ms"
    RESULTS[dns_ms]="${dns_ms}"
}

test_resource_usage() {
    log_info "Testing resource usage..."

    # CPU usage (Gluetun container)
    local cpu_percent
    cpu_percent=$(docker stats --no-stream --format "{{.CPUPerc}}" gluetun | sed 's/%//')
    log_info "✓ Gluetun CPU: ${cpu_percent}%"
    RESULTS[cpu_percent]="${cpu_percent}"

    # Memory usage
    local mem_usage
    mem_usage=$(docker stats --no-stream --format "{{.MemUsage}}" gluetun | awk '{print $1}')
    log_info "✓ Gluetun Memory: ${mem_usage}"
    RESULTS[memory_usage]="${mem_usage}"
}

generate_json_output() {
    log_info "Generating JSON output..."

    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat > "${OUTPUT_FILE}" <<EOF
{
  "provider": "${PROVIDER_NAME}",
  "protocol": "${VPN_TYPE:-unknown}",
  "timestamp": "${timestamp}",
  "metrics": {
    "vpn_ip": "${RESULTS[vpn_ip]:-unknown}",
    "download_mbps": ${RESULTS[download_mbps]:-0},
    "latency_ms": ${RESULTS[latency_ms]:-0},
    "dns_ms": ${RESULTS[dns_ms]:-0},
    "cpu_percent": ${RESULTS[cpu_percent]:-0},
    "memory_usage": "${RESULTS[memory_usage]:-0}"
  }
}
EOF

    log_info "✓ Results saved to: ${OUTPUT_FILE}"
}

show_summary() {
    log_info ""
    log_info "=========================================="
    log_info "     VPN PERFORMANCE BENCHMARK"
    log_info "=========================================="
    log_info "Provider: ${PROVIDER_NAME}"
    log_info "Protocol: ${VPN_TYPE:-unknown}"
    log_info "------------------------------------------"
    log_info "VPN IP: ${RESULTS[vpn_ip]:-unknown}"
    log_info "Download Speed: ${RESULTS[download_mbps]:-0} Mbps"
    log_info "Latency: ${RESULTS[latency_ms]:-0}ms"
    log_info "DNS Resolution: ${RESULTS[dns_ms]:-0}ms"
    log_info "CPU Usage: ${RESULTS[cpu_percent]:-0}%"
    log_info "Memory Usage: ${RESULTS[memory_usage]:-0}"
    log_info "=========================================="
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --provider)
                PROVIDER_NAME="$2"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="$2"
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
                echo "Unknown option: $1"
                show_help
                ;;
        esac
    done

    log_info "Starting VPN Performance Benchmark..."
    log_info "Provider: ${PROVIDER_NAME}"

    # Run tests
    test_vpn_ip
    test_download_speed
    test_latency
    test_dns_resolution
    test_resource_usage

    # Output results
    generate_json_output
    show_summary

    log_info "✓ Benchmark complete!"
}

main "$@"
