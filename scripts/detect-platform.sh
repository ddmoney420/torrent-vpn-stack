#!/usr/bin/env bash
#
# Platform Detection Utility for Torrent VPN Stack
#
# Detects the operating system and sets platform-specific variables.
# This script is meant to be sourced by other scripts.
#
# Usage:
#   source scripts/detect-platform.sh
#   if [[ "${PLATFORM}" == "macos" ]]; then
#       # macOS-specific code
#   fi
#
# Variables set:
#   PLATFORM       - "macos", "linux", or "windows" (via Git Bash/WSL)
#   PLATFORM_NAME  - Human-readable platform name
#   IS_WSL         - "true" if running in Windows Subsystem for Linux
#   IS_DOCKER_DESKTOP - "true" if Docker Desktop is detected
#

# Detect platform
detect_platform() {
    local uname_output
    uname_output=$(uname -s 2>/dev/null || echo "Unknown")

    case "${uname_output}" in
        Darwin*)
            PLATFORM="macos"
            PLATFORM_NAME="macOS"
            IS_WSL="false"
            ;;
        Linux*)
            PLATFORM="linux"
            PLATFORM_NAME="Linux"
            # Check if WSL
            if grep -qiE "(microsoft|wsl)" /proc/version 2>/dev/null; then
                IS_WSL="true"
                PLATFORM_NAME="Linux (WSL)"
            else
                IS_WSL="false"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            PLATFORM="windows"
            PLATFORM_NAME="Windows (Git Bash)"
            IS_WSL="false"
            ;;
        *)
            PLATFORM="unknown"
            PLATFORM_NAME="Unknown"
            IS_WSL="false"
            ;;
    esac
}

# Detect if running Docker Desktop
detect_docker_desktop() {
    IS_DOCKER_DESKTOP="false"

    if command -v docker &> /dev/null; then
        local docker_info
        docker_info=$(docker info 2>/dev/null || echo "")

        if echo "${docker_info}" | grep -qiE "docker desktop|desktop.*docker"; then
            IS_DOCKER_DESKTOP="true"
        fi

        # Additional check for macOS/Windows (Docker Desktop is common there)
        if [[ "${PLATFORM}" == "macos" ]] || [[ "${PLATFORM}" == "windows" ]]; then
            if echo "${docker_info}" | grep -qiE "com.docker.driver|Docker Desktop"; then
                IS_DOCKER_DESKTOP="true"
            fi
        fi
    fi
}

# Get platform-specific paths
get_platform_paths() {
    case "${PLATFORM}" in
        macos)
            USER_HOME="${HOME}"
            CONFIG_DIR="${HOME}/Library/Application Support/torrent-vpn-stack"
            LOG_DIR="${HOME}/Library/Logs/torrent-vpn-stack"
            CACHE_DIR="${HOME}/Library/Caches/torrent-vpn-stack"
            ;;
        linux)
            USER_HOME="${HOME}"
            if [[ "${IS_WSL}" == "true" ]]; then
                CONFIG_DIR="${HOME}/.config/torrent-vpn-stack"
                LOG_DIR="${HOME}/.local/state/torrent-vpn-stack/logs"
                CACHE_DIR="${HOME}/.cache/torrent-vpn-stack"
            else
                CONFIG_DIR="${HOME}/.config/torrent-vpn-stack"
                LOG_DIR="/var/log/torrent-vpn-stack"
                CACHE_DIR="${HOME}/.cache/torrent-vpn-stack"
            fi
            ;;
        windows)
            # Git Bash on Windows
            USER_HOME="${HOME}"
            CONFIG_DIR="${HOME}/.config/torrent-vpn-stack"
            LOG_DIR="${HOME}/.local/state/torrent-vpn-stack/logs"
            CACHE_DIR="${HOME}/.cache/torrent-vpn-stack"
            ;;
        *)
            USER_HOME="${HOME}"
            CONFIG_DIR="${HOME}/.torrent-vpn-stack"
            LOG_DIR="${HOME}/.torrent-vpn-stack/logs"
            CACHE_DIR="${HOME}/.torrent-vpn-stack/cache"
            ;;
    esac
}

# Get local network IP address (platform-specific)
get_local_ip() {
    local local_ip="192.168.1.100"  # Default fallback

    case "${PLATFORM}" in
        macos)
            # Try common network interfaces
            local_ip=$(ipconfig getifaddr en0 2>/dev/null || \
                      ipconfig getifaddr en1 2>/dev/null || \
                      ipconfig getifaddr eth0 2>/dev/null || \
                      echo "192.168.1.100")
            ;;
        linux)
            if command -v hostname &> /dev/null; then
                # Try hostname -I (most reliable on Linux)
                local_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
            fi

            # Fallback to ip addr
            if [[ -z "${local_ip}" ]] || [[ "${local_ip}" == "192.168.1.100" ]]; then
                local_ip=$(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
            fi

            # Final fallback
            if [[ -z "${local_ip}" ]]; then
                local_ip="192.168.1.100"
            fi
            ;;
        windows)
            # Git Bash on Windows - use ipconfig
            local_ip=$(ipconfig.exe 2>/dev/null | grep -oP '(?<=IPv4 Address.*:\s)\d+(\.\d+){3}' | head -n1)

            if [[ -z "${local_ip}" ]]; then
                local_ip="192.168.1.100"
            fi
            ;;
        *)
            local_ip="192.168.1.100"
            ;;
    esac

    echo "${local_ip}"
}

# Get local subnet from IP
get_local_subnet() {
    local ip="${1:-$(get_local_ip)}"
    echo "${ip}" | awk -F. '{print $1"."$2"."$3".0/24"}'
}

# Check if command exists (cross-platform)
command_exists() {
    command -v "$1" &> /dev/null
}

# Initialize platform detection
detect_platform
detect_docker_desktop
get_platform_paths

# Export variables for use in other scripts
export PLATFORM
export PLATFORM_NAME
export IS_WSL
export IS_DOCKER_DESKTOP
export USER_HOME
export CONFIG_DIR
export LOG_DIR
export CACHE_DIR
