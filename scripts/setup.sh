#!/usr/bin/env bash

# Torrent VPN Stack - Interactive Setup Wizard
# This script helps you configure your .env file interactively

set -e  # Exit on error

# Colors for output
# shellcheck disable=SC2034  # RED defined for potential future use
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Load platform detection
# shellcheck source=scripts/detect-platform.sh
source "${SCRIPT_DIR}/detect-platform.sh"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Torrent VPN Stack - Interactive Setup Wizard          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Detected platform: ${PLATFORM_NAME}${NC}"
echo ""

# Check if .env already exists
if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  .env file already exists!${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Setup cancelled. Your existing .env is unchanged.${NC}"
        exit 0
    fi
    echo -e "${YELLOW}Backing up existing .env to .env.backup${NC}"
    cp "$ENV_FILE" "$ENV_FILE.backup"
fi

# Start with example file
cp "$ENV_EXAMPLE" "$ENV_FILE"

echo -e "${GREEN}✓ Created .env from .env.example${NC}"
echo ""

# Helper function to update .env value
update_env() {
    local key=$1
    local value=$2
    if [[ "${PLATFORM}" == "macos" ]]; then
        # macOS requires empty string after -i
        sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
        # Linux and Windows (Git Bash)
        sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    fi
}

# Helper function to prompt for input
prompt() {
    local prompt_text=$1
    local default_value=$2
    local var_name=$3
    local is_secret=${4:-false}

    if [ -n "$default_value" ]; then
        read -r -p "${prompt_text} [${default_value}]: " value
        value=${value:-$default_value}
    else
        if [ "$is_secret" = true ]; then
            read -r -sp "${prompt_text}: " value
            echo
        else
            read -r -p "${prompt_text}: " value
        fi
    fi

    eval "$var_name='$value'"
}

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 1: VPN Provider Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Supported providers: mullvad, nordvpn, protonvpn, surfshark, privateinternetaccess, expressvpn, etc."
echo "Full list: https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers"
echo ""

prompt "Enter your VPN provider (e.g., mullvad, protonvpn)" "mullvad" VPN_PROVIDER
update_env "VPN_SERVICE_PROVIDER" "$VPN_PROVIDER"

echo ""
prompt "VPN protocol (wireguard or openvpn)" "wireguard" VPN_PROTOCOL
update_env "VPN_TYPE" "$VPN_PROTOCOL"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 2: VPN Credentials${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$VPN_PROTOCOL" = "wireguard" ]; then
    echo "You need WireGuard configuration from your VPN provider."
    echo ""
    echo "Where to get WireGuard config:"
    echo "  • Mullvad: https://mullvad.net/en/account/wireguard-config"
    echo "  • ProtonVPN: Account → Downloads → WireGuard configuration"
    echo "  • NordVPN: Dashboard → Manual Setup → WireGuard"
    echo ""

    prompt "WireGuard Private Key" "" WG_PRIVATE_KEY true
    update_env "WIREGUARD_PRIVATE_KEY" "$WG_PRIVATE_KEY"

    echo ""
    prompt "WireGuard IP Address (e.g., 10.2.0.2/32)" "10.2.0.2/32" WG_ADDRESS
    update_env "WIREGUARD_ADDRESSES" "$WG_ADDRESS"
else
    echo "Enter your VPN account credentials:"
    echo ""

    prompt "OpenVPN Username" "" OVPN_USER
    update_env "OPENVPN_USER" "$OVPN_USER"

    echo ""
    prompt "OpenVPN Password" "" OVPN_PASS true
    update_env "OPENVPN_PASSWORD" "$OVPN_PASS"
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 3: Network Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Try to detect local subnet using platform detection utility
LOCAL_IP=$(get_local_ip)
DETECTED_SUBNET=$(get_local_subnet "${LOCAL_IP}")

echo "Your local subnet allows LAN access to qBittorrent Web UI."
echo "Detected subnet: ${DETECTED_SUBNET}"
echo ""

prompt "Local network subnet" "$DETECTED_SUBNET" LOCAL_SUBNET
update_env "LOCAL_SUBNET" "$LOCAL_SUBNET"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 4: Downloads Configuration${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

DEFAULT_DOWNLOADS="$HOME/Downloads/torrents"
echo "Where should downloaded torrents be saved?"
echo ""

prompt "Downloads path" "$DEFAULT_DOWNLOADS" DOWNLOADS_PATH
# Expand ~ to home directory
DOWNLOADS_PATH="${DOWNLOADS_PATH/#\~/$HOME}"
update_env "DOWNLOADS_PATH" "$DOWNLOADS_PATH"

# Create downloads directory if it doesn't exist
if [ ! -d "$DOWNLOADS_PATH" ]; then
    echo ""
    read -p "Directory doesn't exist. Create it now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        mkdir -p "$DOWNLOADS_PATH"
        echo -e "${GREEN}✓ Created directory: $DOWNLOADS_PATH${NC}"
    fi
fi

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 5: User Permissions (macOS)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

echo "For proper file permissions, we need your user ID and group ID."
echo "Detected: UID=${CURRENT_UID}, GID=${CURRENT_GID}"
echo ""

prompt "User ID (PUID)" "$CURRENT_UID" PUID
update_env "PUID" "$PUID"

prompt "Group ID (PGID)" "$CURRENT_GID" PGID
update_env "PGID" "$PGID"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 6: Security Settings${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "⚠️  IMPORTANT: Set a strong password for qBittorrent Web UI"
echo "   Default is 'adminadmin' - you should change this!"
echo ""

prompt "qBittorrent Web UI password" "" QBIT_PASS true
update_env "QBITTORRENT_PASS" "$QBIT_PASS"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Step 7: Optional - Port Forwarding${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Port forwarding improves torrent speeds and connectivity."
echo "Only some VPN providers support it (Mullvad, ProtonVPN, PIA)."
echo ""

read -p "Enable port forwarding? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    update_env "VPN_PORT_FORWARDING" "on"
    prompt "Port forwarding provider (e.g., protonvpn)" "$VPN_PROVIDER" PF_PROVIDER
    update_env "VPN_PORT_FORWARDING_PROVIDER" "$PF_PROVIDER"

    echo ""
    echo -e "${YELLOW}NOTE: You'll need to uncomment the gluetun-qbittorrent-sync service${NC}"
    echo -e "${YELLOW}      in docker-compose.yml for automatic port syncing.${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 Setup Complete!                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ Configuration saved to .env${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review your .env file: nano .env"
echo "  2. Start the stack: docker-compose up -d"
echo "  3. Check VPN connection: docker-compose logs -f gluetun"
echo "  4. Access qBittorrent: http://localhost:8080"
echo "     Username: admin"
echo "     Password: (what you just set)"
echo "  5. Verify setup: ./scripts/verify-vpn.sh"
echo ""
echo -e "${YELLOW}⚠️  Security Reminders:${NC}"
echo "  • Never commit .env to version control"
echo "  • Change your qBittorrent password in the Web UI Settings"
echo "  • Run ./scripts/check-leaks.sh to verify no leaks"
echo ""
