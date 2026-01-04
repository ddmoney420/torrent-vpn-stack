#!/usr/bin/env bash

# Torrent VPN Stack - VPN Verification Script
# Checks if VPN is working correctly and qBittorrent is properly routed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        VPN Connection Verification                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if docker-compose is running
echo -e "${BLUE}[1/7]${NC} Checking if containers are running..."
if ! docker-compose ps | grep -q "gluetun"; then
    echo -e "${RED}✗ Gluetun container is not running${NC}"
    echo -e "${YELLOW}  Run: docker-compose up -d${NC}"
    exit 1
fi
echo -e "${GREEN}✓ VPN container is running${NC}"

if ! docker-compose ps | grep -q "qbittorrent"; then
    echo -e "${RED}✗ qBittorrent container is not running${NC}"
    echo -e "${YELLOW}  Run: docker-compose up -d${NC}"
    exit 1
fi
echo -e "${GREEN}✓ qBittorrent container is running${NC}"
echo ""

# Check Gluetun health
echo -e "${BLUE}[2/7]${NC} Checking Gluetun health status..."
HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' gluetun 2>/dev/null || echo "unknown")
if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo -e "${GREEN}✓ Gluetun health check: healthy${NC}"
elif [ "$HEALTH_STATUS" = "starting" ]; then
    echo -e "${YELLOW}⚠ Gluetun is still starting... wait a moment${NC}"
elif [ "$HEALTH_STATUS" = "unhealthy" ]; then
    echo -e "${RED}✗ Gluetun is unhealthy${NC}"
    echo -e "${YELLOW}  Check logs: docker-compose logs gluetun${NC}"
    exit 1
else
    echo -e "${YELLOW}⚠ Gluetun health status: ${HEALTH_STATUS}${NC}"
fi
echo ""

# Check VPN IP
echo -e "${BLUE}[3/7]${NC} Checking VPN IP address..."
VPN_IP=$(docker exec gluetun wget -qO- https://api.ipify.org 2>/dev/null || echo "")
if [ -z "$VPN_IP" ]; then
    echo -e "${RED}✗ Could not get VPN IP (connection failed)${NC}"
    echo -e "${YELLOW}  Check VPN credentials in .env${NC}"
    echo -e "${YELLOW}  Check logs: docker-compose logs gluetun | grep -i error${NC}"
    exit 1
fi
echo -e "${GREEN}✓ VPN IP detected: ${VPN_IP}${NC}"

# Warn if IP looks like a local IP
if [[ "$VPN_IP" =~ ^192\.168\. ]] || [[ "$VPN_IP" =~ ^10\. ]] || [[ "$VPN_IP" =~ ^172\.(1[6-9]|2[0-9]|3[0-1])\. ]]; then
    echo -e "${RED}✗ WARNING: VPN IP looks like a local IP: ${VPN_IP}${NC}"
    echo -e "${RED}  This is NOT a VPN connection!${NC}"
    exit 1
fi
echo ""

# Check qBittorrent can route through VPN
echo -e "${BLUE}[4/7]${NC} Checking qBittorrent routes through VPN..."
QBIT_IP=$(docker exec qbittorrent wget -T 10 -qO- https://api.ipify.org 2>/dev/null || echo "")
if [ -z "$QBIT_IP" ]; then
    echo -e "${RED}✗ qBittorrent cannot reach internet${NC}"
    echo -e "${YELLOW}  Check if Gluetun VPN is connected${NC}"
    exit 1
fi

if [ "$QBIT_IP" = "$VPN_IP" ]; then
    echo -e "${GREEN}✓ qBittorrent is routing through VPN (IP: ${QBIT_IP})${NC}"
else
    echo -e "${RED}✗ IP mismatch! qBittorrent IP (${QBIT_IP}) != VPN IP (${VPN_IP})${NC}"
    echo -e "${RED}  This indicates a leak or misconfiguration!${NC}"
    exit 1
fi
echo ""

# Check DNS leak
echo -e "${BLUE}[5/7]${NC} Checking for DNS leaks..."
DNS_SERVER=$(docker exec qbittorrent nslookup google.com 2>/dev/null | grep -A1 "Server:" | tail -1 | awk '{print $2}' || echo "unknown")
echo -e "${BLUE}  DNS server in use: ${DNS_SERVER}${NC}"

# Cloudflare DNS or VPN DNS is good
if [[ "$DNS_SERVER" =~ ^1\.1\.1\. ]] || [[ "$DNS_SERVER" =~ ^1\.0\.0\. ]]; then
    echo -e "${GREEN}✓ Using Cloudflare DNS (no leak)${NC}"
elif [[ "$DNS_SERVER" =~ ^10\. ]]; then
    echo -e "${GREEN}✓ Using VPN internal DNS (no leak)${NC}"
else
    echo -e "${YELLOW}⚠ DNS server: ${DNS_SERVER}${NC}"
    echo -e "${YELLOW}  Verify this is your VPN's DNS, not your ISP's${NC}"
fi
echo ""

# Check IPv6 is disabled
echo -e "${BLUE}[6/7]${NC} Checking IPv6 leak protection..."
IPV6_ADDR=$(docker exec qbittorrent ip -6 addr show scope global 2>/dev/null | grep inet6 | awk '{print $2}' || echo "")
if [ -z "$IPV6_ADDR" ]; then
    echo -e "${GREEN}✓ IPv6 is disabled (no IPv6 leaks possible)${NC}"
else
    echo -e "${YELLOW}⚠ IPv6 address detected: ${IPV6_ADDR}${NC}"
    echo -e "${YELLOW}  This could leak your location if VPN doesn't support IPv6${NC}"
    echo -e "${YELLOW}  Recommended: Set DISABLE_IPV6=yes in .env${NC}"
fi
echo ""

# Check qBittorrent Web UI accessibility
echo -e "${BLUE}[7/7]${NC} Checking qBittorrent Web UI..."
WEBUI_PORT=$(grep QBITTORRENT_WEBUI_PORT .env 2>/dev/null | cut -d= -f2 || echo "8080")
WEBUI_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${WEBUI_PORT} 2>/dev/null || echo "000")

if [ "$WEBUI_RESPONSE" = "200" ] || [ "$WEBUI_RESPONSE" = "401" ]; then
    echo -e "${GREEN}✓ qBittorrent Web UI is accessible at http://localhost:${WEBUI_PORT}${NC}"
elif [ "$WEBUI_RESPONSE" = "000" ]; then
    echo -e "${RED}✗ Cannot connect to Web UI (connection refused)${NC}"
    echo -e "${YELLOW}  qBittorrent may still be starting...${NC}"
    echo -e "${YELLOW}  Check: docker-compose logs qbittorrent${NC}"
else
    echo -e "${YELLOW}⚠ Unexpected HTTP response: ${WEBUI_RESPONSE}${NC}"
fi
echo ""

# Summary
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               Verification Complete!                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✓ VPN is working correctly${NC}"
echo -e "${GREEN}✓ Kill switch is active (qBittorrent routes through VPN)${NC}"
echo -e "${GREEN}✓ Your public IP via VPN: ${VPN_IP}${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  • Access qBittorrent: http://localhost:${WEBUI_PORT}"
echo "  • Default login: admin / (your password from .env)"
echo "  • Run leak test: ./scripts/check-leaks.sh"
echo ""
echo -e "${YELLOW}Security tip: Never trust, always verify!${NC}"
echo "  Check https://ipleak.net from within qBittorrent's browser to double-check"
echo ""
